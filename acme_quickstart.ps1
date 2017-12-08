import-module ACMESharp
# from https://marc.durdin.net/2017/02/lets-encrypt-on-windows-redux/ 

#
# Script parameters
#

$domain = "my.example.com"
$iissitename = "my.example.com"
$certname = "my.example.com-$(get-date -format yyyy-MM-dd--HH-mm)"

#
# Environmental variables
#

$PSEmailServer = "localhost"
$LocalEmailAddress = "admin@example.com"
$OwnerEmailAddress = "marc@durdin.net"
$pfxfile = "c:\Admin\Certs\$certname.pfx"
$CertificatePassword = "PASSWORD!"

#
# Script setup - should be no need to change things below this point
#

$ErrorActionPreference = "Stop"
$EmailLog = @()

#
# Utility functions
#

function Write-Log {
  Write-Host $args[0]
  $script:EmailLog  += $args[0]
}

Try {
  Write-Log "Generating a new identifier for $domain"
  New-ACMEIdentifier -Dns $domain -Alias $certname
  
  Write-Log "Completing a challenge via http"
  Complete-ACMEChallenge $certname -ChallengeType http-01 -Handler iis -HandlerParameters @{ WebSiteRef = $iissitename }
  
  Write-Log "Submitting the challenge"
  Submit-ACMEChallenge $certname -ChallengeType http-01
  
  # Check the status of the identifier every 6 seconds until we have an answer; fail after a minute
  $i = 0
  do {
    $identinfo = (Update-ACMEIdentifier $certname -ChallengeType http-01).Challenges | Where-Object {$_.Status -eq "valid"}
    if($identinfo -eq $null) {
      Start-Sleep 6
      $i++
    }
  } until($identinfo -ne $null -or $i -gt 10)

  if($identinfo -eq $null) {
    Write-Log "We did not receive a completed identifier after 60 seconds"
    $Body = $EmailLog | out-string
    Send-MailMessage -From $LocalEmailAddress -To $OwnerEmailAddress -Subject "Attempting to renew Let's Encrypt certificate for $domain" -Body $Body
    Exit
  }
  
  # We now have a new identifier... so, let's create a certificate
  Write-Log "Attempting to renew Let's Encrypt certificate for $domain"

  # Generate a certificate
  Write-Log "Generating certificate for $domain"
  New-ACMECertificate $certname -Generate -Alias $certname

  # Submit the certificate
  Submit-ACMECertificate $certname

  # Check the status of the certificate every 6 seconds until we have an answer; fail after a minute
  $i = 0
  do {
    $certinfo = Update-AcmeCertificate $certname
    if($certinfo.SerialNumber -eq "") {
      Start-Sleep 6
      $i++
    }
  } until($certinfo.SerialNumber -ne "" -or $i -gt 10)

  if($i -gt 10) {
    Write-Log "We did not receive a completed certificate after 60 seconds"
    $Body = $EmailLog | out-string
    Send-MailMessage -From $LocalEmailAddress -To $OwnerEmailAddress -Subject "Attempting to renew Let's Encrypt certificate for $domain" -Body $Body
    Exit
  }

  # Export Certificate to PFX file
  Get-ACMECertificate $certname -ExportPkcs12 $pfxfile -CertificatePassword $CertificatePassword

  # Import the certificate to the local machine certificate store 
  Write-Log "Import pfx certificate $pfxfile"
  $certRootStore = "LocalMachine"
  $certStore = "My"
  $pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
  $pfx.Import($pfxfile,$CertificatePassword,"Exportable,PersistKeySet,MachineKeySet") 
  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore) 
  $store.Open('ReadWrite')
  $store.Add($pfx) 
  $store.Close() 
  $certThumbprint = $pfx.Thumbprint

  # Bind the certificate to the requested IIS site (all https bindings)
  Write-Log "Bind certificate with Thumbprint $certThumbprint"
  $obj = get-webconfiguration "//sites/site[@name='$iissitename']"
  for($i = 0; $i -lt $obj.bindings.Collection.Length; $i++) {
    $binding = $obj.bindings.Collection[$i]
    if($binding.protocol -eq "https") {
      $method = $binding.Methods["AddSslCertificate"]
      $methodInstance = $method.CreateInstance()
      $methodInstance.Input.SetAttributeValue("certificateHash", $certThumbprint)
      $methodInstance.Input.SetAttributeValue("certificateStoreName", $certStore)
      $methodInstance.Execute()
    }
  }

  # Remove expired LetsEncrypt certificates for this domain
  Write-Log "Remove old certificates"
  $certRootStore = "LocalMachine"
  $certStore = "My"
  $date = Get-Date
  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore) 
  $store.Open('ReadWrite')
  foreach($cert in $store.Certificates) {
    if($cert.Subject -eq "CN=$domain" -And $cert.Issuer.Contains("Let's Encrypt") -And $cert.Thumbprint -ne $certThumbprint) {
      Write-Log "Removing certificate $($cert.Thumbprint)"
      $store.Remove($cert)
    }
  }
  $store.Close() 

  # Finished
  Write-Log "Finished"
  $Body = $EmailLog | out-string
  Send-MailMessage -From $LocalEmailAddress -To $OwnerEmailAddress -Subject "Let's Encrypt certificate renewed for $domain" -Body $Body
} Catch {
  Write-Host $_.Exception
  $ErrorMessage = $_.Exception | format-list -force | out-string
  $EmailLog += "Let's Encrypt certificate renewal for $domain failed with exception`n$ErrorMessage`r`n`r`n"
  $Body = $EmailLog | Out-String
  Send-MailMessage -From $LocalEmailAddress -To $OwnerEmailAddress -Subject "Let's Encrypt certificate renewal for $domain failed with exception" -Body $Body
  Exit
}