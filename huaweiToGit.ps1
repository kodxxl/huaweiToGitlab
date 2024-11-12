#--------------
$subnet = "100"
$config = "vrpcfg.cfg"
$exten = "zip"
$currentloc = Get-Location

$archdir = "huawei"
if(!(Test-Path ".\$archdir")) {
    throw "$archdir not exist!"
}

$repodir = "huaweibackup"
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
    $zip = ".\$archdir\$archsubdir\$archfile"
    $cfg = "$currentloc\$repodir\$archsubdir\$config"
    $readme = "$currentloc\$repodir\$archsubdir\README.md"

    Expand-Archive -Path $zip -DestinationPath ".\$repodir\$archsubdir\" -Force

# Add UTF header and delete ending NUL
    $ascii = [System.IO.File]::ReadAllBytes($cfg)
    $utf8 = [byte[]](0xEF, 0xBB, 0xBF) + $ascii[0..($ascii.Length - 3)]
    [System.IO.File]::WriteAllBytes($readme, $utf8)

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
