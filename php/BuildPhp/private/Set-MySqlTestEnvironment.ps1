function Set-MySqlTestEnvironment {
    <#
    .SYNOPSIS
        Configure environment variables for MySQL-related PHP tests and ensure the test database exists.
    #>
    [CmdletBinding()]
    param (
    )
    process {
        $Database = 'test'
        $DbHost = '127.0.0.1'
        $User = 'root'
        $Password = 'Password12!'
        $Port = 3306
        if(-not(Test-Path mysql_init)) {
            & mysqld --initialize-insecure
            & mysqld --install
            & net start "MySQL"
            & mysql --port=$Port --user=root --password="" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$( $Password )'; FLUSH PRIVILEGES;" 2> $null
            Set-Content -Path mysql_init -Value "initialized" -Encoding ASCII
        }

        $env:MYSQL_PWD = $Password
        $env:MYSQL_TEST_PASSWD = $env:MYSQL_PWD
        $env:MYSQL_TEST_USER = $User
        $env:MYSQL_TEST_HOST = $DbHost
        $env:MYSQL_TEST_PORT = "$Port"
        $env:MYSQL_TEST_DB = $Database

        $env:PDO_MYSQL_TEST_USER = $env:MYSQL_TEST_USER
        $env:PDO_MYSQL_TEST_PASS = $env:MYSQL_PWD
        $env:PDO_MYSQL_TEST_HOST = $env:MYSQL_TEST_HOST
        $env:PDO_MYSQL_TEST_PORT = $env:MYSQL_TEST_PORT
        $env:PDO_MYSQL_TEST_DSN = "mysql:host=$($env:PDO_MYSQL_TEST_HOST);port=$($env:PDO_MYSQL_TEST_PORT);dbname=$Database"

        $params = @(
            "--host=$($env:PDO_MYSQL_TEST_HOST)",
            "--port=$($env:MYSQL_TEST_PORT)",
            "--user=$($env:MYSQL_TEST_USER)",
            "--password=$($env:MYSQL_TEST_PASSWD)",
            "-e", "CREATE DATABASE IF NOT EXISTS $Database"
        )

        if(-not(Test-Path mysql_db_created)) {
            & mysql @params 2>$null
            Set-Content -Path mysql_db_created -Value "db_created" -Encoding ASCII
        }
    }
}
