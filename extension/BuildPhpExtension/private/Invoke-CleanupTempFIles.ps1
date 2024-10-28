Function Invoke-CleanupTempFiles {
    $currentSystemState = Get-ChildItem -Path "C:\Windows\Temp" -Recurse -File | Select-Object FullName
    $currentUserState = Get-ChildItem -Path $env:TEMP -Recurse -File | Select-Object FullName

    $newSystemFiles = Compare-Object -ReferenceObject $script:initialSystemState -DifferenceObject $currentSystemState -Property FullName | Where-Object {$_.SideIndicator -eq "=>"}
    $newUserFiles = Compare-Object -ReferenceObject $script:initialUserState -DifferenceObject $currentUserState -Property FullName | Where-Object {$_.SideIndicator -eq "=>"}
    $newSystemFiles + $newUserFiles | ForEach-Object {
        Remove-Item -Path $_.FullName -Force
    }
}
