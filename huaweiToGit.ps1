#--------------CONFIG
$subnet = "100"
$archdir = "HuaweiBackup"
$repodir = "schuaweibak"
#--------------

$config = "vrpcfg.cfg"
$exten = "zip"
$currentloc = Get-Location

if(!(Test-Path ".\$archdir")) {
    throw "$archdir not exist!"
}

if(!(Test-Path ".\$repodir")) {
    throw "$repodir not exist!"
}

function Invoke-CommitConfig {
  param(
    [Parameter(ValueFromPipeline)]
    [string]$archfile,

    [Parameter()]
    [string]$archsubdir        
  )
  process{
    if(Test-Path ".\$repodir\$archsubdir\vrpcfg.cfg") {
      Remove-item ".\$repodir\$archsubdir\vrpcfg.cfg" -Force
    }
    $zip = ".\$archdir\$archsubdir\$archfile"
    Expand-Archive -Path $zip -DestinationPath ".\$repodir\$archsubdir\" -Force
    Get-ChildItem ".\$repodir\$archsubdir\" | Where-Object name -like *.cfg | Select-object -First 1 | Rename-Item -NewName $config -Force

# Add UTF header and delete ending NUL
    $cfg = "$currentloc\$repodir\$archsubdir\$config"
    $ascii = [System.IO.File]::ReadAllBytes($cfg)

    $utf8 = [byte[]](0xEF, 0xBB, 0xBF) + $ascii[0..($ascii.Length - 3)]
    $readme = "$currentloc\$repodir\$archsubdir\README.md"
    [System.IO.File]::WriteAllBytes($readme, $utf8)

# Push every file into repository
    Set-Location -Path ".\$repodir\"
        git add *
        git commit -am "$archsubdir - $archfile"
    Set-Location $currentloc
    Rename-Item -Path $zip -NewName "$archfile.pushed"
  }
}

function Get-Subdirs {
  param(
    [Parameter(ValueFromPipeline)]
    [string]$archsubdir      
  )
  process{
    $archfiles = Get-ChildItem ".\$archdir\$archsubdir\" | Where-Object name -like *.$exten | Sort-Object -Property LastWriteTime
    if($archfiles.Count -gt 0) {
        $archfiles.Name | Invoke-CommitConfig -archsubdir $archsubdir
    }    
  }
}

$archsubdirs = Get-ChildItem -Directory -Path $archdir | Where-Object name -like $subnet*
if($archsubdirs.Count -eq 0) {
    throw "Could not find configuration archieve folders"
}
#Main loop
$archsubdirs.Name | Get-Subdirs

Set-Location -Path "$repodir"
    git push
Set-Location $currentloc
