Function Get-CheckoutState {
    <#
    .SYNOPSIS
        Get whether the current directory already contains the expected repository checkout.
    .PARAMETER Repository
        Expected owner/repository name.
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false, Position=0, HelpMessage='Expected owner/repository name.')]
        [string] $Repository = ''
    )
    begin {
    }
    process {
        if([string]::IsNullOrWhiteSpace($Repository)) {
            $Repository = $env:GITHUB_REPOSITORY
        }

        if([string]::IsNullOrWhiteSpace($Repository) -or -not(Test-Path .git)) {
            return $false.ToString().ToLowerInvariant()
        }

        try {
            $originUrl = git remote get-url origin 2>$null
            if($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($originUrl)) {
                return $false.ToString().ToLowerInvariant()
            }

            return ($originUrl -match "(^|[:/])$([regex]::Escape($Repository))(\.git)?$").ToString().ToLowerInvariant()
        } catch {
            return $false.ToString().ToLowerInvariant()
        }
    }
    end {
    }
}
