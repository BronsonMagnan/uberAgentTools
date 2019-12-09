#If I make another function I will convert this to a module.

function Update-uberAgentLicense {
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][string]$Path,
        [parameter(Mandatory)][string[]]$ComputerName,
        [PSCredential]$Credential
    )
    begin {
        try {
            $test = Test-Path $Path 
        } catch {
            Write-Error "Cannot validate path to license file $path"
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Creating the PSSession to $Computer"
            if ($Credential) {
                $session = New-PSSession -ComputerName $Computer -Credential $Credential
            } else {
                $session = New-PSSession -ComputerName $Computer
            }
            try {
                Write-Verbose "Preserve the existing license"
                Invoke-Command -Session $session -ScriptBlock {
                    $test = test-path "c:\Program Files\vast limits\uberAgent\oldLicenses" -ErrorAction SilentlyContinue
                    if (-not ($test) ) {
                        new-item -ItemType Directory -Path "c:\Program Files\vast limits\uberAgent" -Name "oldLicenses" | Out-Null
                    }
                    Move-Item -Path "c:\Program Files\vast limits\uberAgent\uberAgent.lic" -Destination "c:\Program Files\vast limits\uberAgent\oldLicenses"
                    Rename-item -Path "c:\Program Files\vast limits\uberAgent\oldLicenses\uberAgent.lic" -NewName $("{0:yyyyMMdd-HHmmss}.lic" -f (get-date) )
                }
                Write-Verbose "Copy the licensing file from $path to $Computer"
                Copy-Item -ToSession $session -Path $Path -Destination "c:\Program Files\vast limits\uberAgent\uberAgent.lic"
                Write-Verbose "Restarting the uberAgent service on $Computer"
                Invoke-Command -Session $session -ScriptBlock {
                    Get-service -Name uberAgentSVc | Restart-Service
                }
                Write-Verbose "License update is complete on $Computer"
            } catch {
                Write-Error "Cannot create a PSSession to $Computer"
            }
            if ($session) { 
                Write-Verbose "Closing the PSSession to $Computer"
                Remove-PSSession $session
            }
        }
    }
    end {
    }
}
