function Get-VsProductIds {
    <#
    .SYNOPSIS
        Get the Visual Studio product IDs to pass to vswhere -products.
    .DESCRIPTION
        Other products such as SQL Server Management Studio also register with the Visual Studio installer,
        so vswhere -products * can return them, and -latest can prefer them over Visual Studio.
    #>
    [OutputType([string[]])]
    param ()
    begin {
    }
    process {
        return @(
            'Microsoft.VisualStudio.Product.Enterprise',
            'Microsoft.VisualStudio.Product.Professional',
            'Microsoft.VisualStudio.Product.Community',
            'Microsoft.VisualStudio.Product.BuildTools'
        )
    }
    end {
    }
}
