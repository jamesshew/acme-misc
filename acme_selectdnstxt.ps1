function Select-DNSTXT 
{
         [CmdletBinding()]
         [Alias()]
         [OutputType([int])]
         Param
         (
             # Param1 help description
             [Parameter(Mandatory=$true,
                        ValueFromPipelineByPropertyName=$true,
                        Position=0)]
             $mystr

         )
  Begin {
    if ($mystr -match ‘Name:\s+\[(.+)\]') {
      Write-Verbose "Name:" -Verbose
      $Matches[1]
    }

    if ($mystr -match 'Value:\s+\[(.+)\]’) {
      Write-Verbose "Value:" -Verbose
      $Matches[1]
      $Matches[1] | clip
    }
  }
}

