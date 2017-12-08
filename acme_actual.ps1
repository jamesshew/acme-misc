Import-Module ACMESharp

Enable-ACMEExtensionModule ACMESharp.Providers.IIS

$domain = "bunker011.com"
$email = "james@bluenotch.com"
$vault = "C:\letsencrypt"

Initialize-ACMEVault 
#-BaseURI https://acme-v01.api.letsencrypt.org/

New-ACMERegistration -Contacts mailto:$email
Update-ACMERegistration -AcceptTOS

New-ACMEIdentifier -Dns $domain -Alias dns01
New-ACMEProviderConfig -WebServerProvider Manual -Alias manualHttpProvider -FilePath $vault\answer.txt

Get-ACMEIdentifier -Ref dns01

Complete-ACMEChallenge dns01 -ChallengeType dns-01 -Handler manual

#go to DNS and make the TXT Record

#check status
(Update-ACMEIdentifier dns01 -ChallengeType dns-01).Challenges

#after DNS propigates
Submit-ACMEChallenge dns01 -ChallengeType dns-01

(Update-ACMEIdentifier dns01 -ChallengeType dns-01).Challenges | where {$_.Type -eq "dns-01"} | Select-object -ExpandProperty submitResponse | Out-Host -Paging

(Update-ACMEIdentifier dns01 -ChallengeType dns-01).Challenges | Where-Object {$_.Type -eq "dns-01"}

New-ACMECertificate dns01 -Generate -Alias cert1

New-ACMEIdentifier -DNS u.bunker011.com -Alias util01
New-ACMEIdentifier -DNS v.bunker011.com -Alias vsphere01

Complete-ACMEChallenge util01 -ChallengeType dns-01 -Handler manual
Complete-ACMEChallenge vsphere01 -ChallengeType dns-01 -Handler manual

(Update-ACMEIdentifier util01 -ChallengeType dns-01).Challenges
(Update-ACMEIdentifier vsphere01 -ChallengeType dns-01).Challenges

Submit-ACMEChallenge util01 -ChallengeType dns-01 
Submit-ACMEChallenge vsphere01 -ChallengeType dns-01

Update-ACMEIdentifier util01
Update-ACMEIdentifier vsphere01

New-ACMECertificate dns01 -Generate -AlternativeIdentifierRefs util01,vsphere01 -alias mastercert

Submit-ACMECertificate mastercert
Update-ACMECertificate mastercert

Get-ACMECertificate mastercert -ExportPkcs12 C:\Users\guacadmin\Documents\2017-bunker011-master.pfx

import-module pkitools

# still no "import-pfxcertificate" cmdlet?

function Import-PfxCertificate {

param([String]$certPath,[String]$certRootStore = “localmachine”,[String]$certStore = “My”)
$pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2

$pfx.import($certPath,"","Exportable,PersistKeySet")

$store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)
$store.open("MaxAllowed")
$store.add($pfx)
$store.close()
}

Import-PfxCertificate C:\Users\guacadmin\Documents\2017-bunker011-master.pfx "LocalMachine" "My"

dir Cert:\LocalMachine\my | format-list *

#for transfering to apache
Get-ACMECertificate mastercert -ExportKeyPEM C:\Users\guacadmin\Documents\2017-bunker011-master.pem
Get-ACMECertificate mastercert -ExportCertificatePEM C:\Users\guacadmin\Documents\2017-bunker011-certificate.pem

#realize I forgot www and dev, so log back in and
Import-Module ACMESharp

$domain = "bunker011.com"
$email = "james@bluenotch.com"
$vault = "C:\letsencrypt"

New-ACMERegistration -Contacts mailto:$email -AcceptTos

New-ACMEIdentifier -Dns $domain -Alias bunker01 

New-ACMEIdentifier -DNS www.bunker011.com -Alias www01
New-ACMEIdentifier -DNS dev.bunker011.com -Alias dev01
New-ACMEIdentifier -DNS admin.bunker011.com -Alias admin01
New-ACMEIdentifier -DNS guac.bunker011.com -Alias guac01
New-ACMEIdentifier -DNS util.bunker011.com -Alias util01
New-ACMEIdentifier -DNS u.bunker011.com -Alias u01
New-ACMEIdentifier -DNS v.bunker011.com -Alias v01

. C:\scripts\acme_selectdnstxt.ps1


$completedChallenge = Complete-ACMEChallenge bunker01 -ChallengeType dns-01 -Handler manual

(Update-ACMEIdentifier bunker01 -ChallengeType dns-01).Challenges 
$dnstodo = $completedChallenge.Challenges | Where-Object { $_.Type -eq "dns-01" } | select HandlerHandleMessage
Select-DNSTXT $dnstodo
#paste into DNS records

#Complete-ACMEChallenge www01 -ChallengeType dns-01 -Handler manual

$completedChallenge = Complete-ACMEChallenge www01 -ChallengeType dns-01 -Handler manual
$dnstodo = $completedChallenge.Challenges | Where-Object { $_.Type -eq "dns-01" } | select HandlerHandleMessage
Select-DNSTXT $dnstodo
#paste into DNS records

Complete-ACMEChallenge admin01 -ChallengeType dns-01 -Handler manual

$completedChallenge = Complete-ACMEChallenge admin01 -ChallengeType dns-01 -Handler manual
$dnstodo = $completedChallenge.Challenges | Where-Object { $_.Type -eq "dns-01" } | select HandlerHandleMessage
Select-DNSTXT $dnstodo
#paste into DNS records

Complete-ACMEChallenge guac01 -ChallengeType dns-01 -Handler manual
$completedChallenge = Complete-ACMEChallenge guac01 -ChallengeType dns-01 -Handler manual
$dnstodo = $completedChallenge.Challenges | Where-Object { $_.Type -eq "dns-01" } | select HandlerHandleMessage
Select-DNSTXT $dnstodo
#paste into DNS records

Complete-ACMEChallenge util01 -ChallengeType dns-01 -Handler manual
$completedChallenge = Complete-ACMEChallenge util01 -ChallengeType dns-01 -Handler manual
$dnstodo = $completedChallenge.Challenges | Where-Object { $_.Type -eq "dns-01" } | select HandlerHandleMessage
Select-DNSTXT $dnstodo
#paste into DNS records


Complete-ACMEChallenge dev01 -ChallengeType dns-01 -Handler manual
$completedChallenge = Complete-ACMEChallenge dev01 -ChallengeType dns-01 -Handler manual
$dnstodo = $completedChallenge.Challenges | Where-Object { $_.Type -eq "dns-01" } | select HandlerHandleMessage
Select-DNSTXT $dnstodo
#paste into DNS records

Complete-ACMEChallenge u01 -ChallengeType dns-01 -Handler manual
$completedChallenge = Complete-ACMEChallenge u01 -ChallengeType dns-01 -Handler manual
$dnstodo = $completedChallenge.Challenges | Where-Object { $_.Type -eq "dns-01" } | select HandlerHandleMessage
Select-DNSTXT $dnstodo
#paste into DNS records

Complete-ACMEChallenge v01 -ChallengeType dns-01 -Handler manual
$completedChallenge = Complete-ACMEChallenge v01 -ChallengeType dns-01 -Handler manual
$dnstodo = $completedChallenge.Challenges | Where-Object { $_.Type -eq "dns-01" } | select HandlerHandleMessage
Select-DNSTXT $dnstodo
#paste into DNS records

New-ACMEProviderConfig -WebServerProvider Manual -Alias manualHttpProvider -FilePath $vault\answer2.txt
