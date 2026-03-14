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
        $checkout_state = $true;
        if([string]::IsNullOrWhiteSpace($Repository) -or -not(Test-Path .git)) {
            $checkout_state = $false
        }
        try {
            $originUrl = git remote get-url origin 2>$null
            if($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($originUrl)) {
                $checkout_state = $false
            }
            $checkout_state = ($originUrl -match "(^|[:/])$([regex]::Escape($Repository))(\.git)?$")
        } catch {
            $checkout_state = $false
        }
        $checkout_state = $checkout_state.ToString().ToLowerInvariant()
        if($null -ne $env:GITHUB_OUTPUT) {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "checkout_state=$checkout_state" -Encoding utf8
        } else {
            return $checkout_state
        }
    }
    end {
    }
}
