Function Set-AmqpTestEnvironment {
    <#
    .SYNOPSIS
        Set up environment variables for AMQP extension tests
    .PARAMETER Config
        Extension Configuration
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension Configuration')]
        [PSCustomObject] $Config
    )
    process {
        $env:PHP_AMQP_HOST = "rabbitmq"
        $env:PHP_AMQP_SSL_HOST = "rabbitmq.example.org"
    }
}
