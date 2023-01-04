$version = Get-Content ./src/main/resources/version
Write-Output "The version is $version"
$version -match 'v(.*)'
$letterFreeVersion = $Matches[1];
Write-Output "Letter free version is $letterFreeVersion"
Write-Output "Update launch4j.cfg.xml"
$fileContent = (Get-Content ./launch4j.cfg.xml) -replace '{version}',$letterFreeVersion
Set-Content -Path ./launch4j.cfg.xml -Value $fileContent
Write-Output "Update install.nsi"
$fileContent = (Get-Content ./install.nsi) -replace '{version}',$letterFreeVersion
Set-Content -Path ./install.nsi -Value $fileContent