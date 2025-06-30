# ad-dev-workspace-tool
Import-Module BitsTransfer
clear;

############################
# Tickers                  #
############################
$workItems = @(
   # Examples
   [WorkItem]::new("X2-65342", "Constraint manager - Z-axis Clearance Rule"),
   [WorkItem]::new("X2-64931", "PCB-Z-axis-Clearance-Rule", $true),               # Alien!
   [WorkItem]::new("X2-66474", "Constraint Manager wrong inheritance")

   # Insert your tickets here!
)

############################
# Main - ticket menu       #
############################
for (($i = 0); $i -lt $workItems.Count; $i++)
{
    $item = $workItems[$i]
    Write-Host "$i - $($item.ticket) - $($item.description) - $($item.directoryDescription)"
}

# Read selected work item 
$selectedWorkItem = 0
do {
    $inputValid = [int]::TryParse((Read-Host 'Podaj numer taska'), [ref]$selectedWorkItem)
    if (-not $inputValid) {
        Write-Host "your input was not an integer..."
    }

    if ($selectedWorkItem -lt 0 -or $selectedWorkItem -ge $workItems.Count)
    {
        $inputValid = $false;
        
        Write-Host "Wrong number..."
    }
} while (-not $inputValid)

# Create state
$workItem = $workItems[$selectedWorkItem];
$ticket = $workItem.ticket;
$pullMaster = $true;


if ($workItem.alien)
{
    $schPostfix = "";
}
else
{
    $schPostfix = "-SchTeam";
}

############################
# Personalization          #
############################

# Directory when main branch will be kept, clone here new X2 repo or change to your current directory
$srcAdRootDirectory = "C:\Develop\X2"
# Directory when alle git worktree for tickets will be created, at the begining it will be empty dir. Path should be the shorest to skip git max path length limit.
$srcRootDirectory = "C:\Dev"
# Git X2 repo with schdev branch (create it using git worktree or clone X2 again) 
$schDevDirectory = "C:\Dev\X2-sch-dev"
# Directory when all AD will be installed
$adRootDirectory = "C:\Altium"
# Directory where all bat runners will be created
$runnersRootDirectory = "C:\Dev\!Runners"
$adEmail="michal.ciolek@altium.com"
$maxBranchLength = 74 #82 is too long - 260 char path limit - Windows
$maxDirectoryLength = 70 #82 is too long - 260 char path limit - Windows
$runnersExamplesRootDirectory = Join-Path "$($runnersRootDirectory)" "Examples"
$descriptionNormalized = $workItem.description.ToLower().Replace(",", "-").Replace(".", "-").Replace(" ", "-").Replace(":", "-").Replace("--", "-").Replace("--", "-")
$directoryDescriptionNormalized = $workItem.directoryDescription.ToLower().Replace(",", "-").Replace(".", "-").Replace(":", "-").Replace(" ", "-").Replace("--", "-").Replace("--", "-")
$branchName = "feature/$($ticket)-$($descriptionNormalized)$($schPostfix)"
$directory = "$($ticket)-$($directoryDescriptionNormalized)"

Write-Host "Selected: $($workItem.ticket) - $($workItem.description) - $($workItem.directoryDescription)"
Write-Host "Directory: $directory"
Write-Host "Branch name: $branchName"

if ($branchName.Length -gt $maxBranchLength)
{
    $diff = $branchName.Length - $maxBranchLength
    Write-Error "Branch name is longer than $($maxBranchLength) chars. Remove $($diff) chars."
    exit 1;
}

if ($directory.Length -gt $maxDirectoryLength)
{
    $diff = $directory.Length - $maxDirectoryLength
    Write-Error "Directory name is longer than $($maxDirectoryLength) chars. Remove $($diff) chars."
    exit 1;
}

$srcDirectory = Join-Path "$($srcRootDirectory)" "$($directory)"
$runnersDirectory = Join-Path "$($runnersRootDirectory)" "$($directory)"
$adDirectory = Join-Path "$($adRootDirectory)" "$($directory)"
$adFilesDirectory = Join-Path "$($adDirectory)" "AD"
$adInstallersDirectory = Join-Path "$($adDirectory)" "Installers"
$adDataDirectory = Join-Path "$($adDirectory)" "ADData"
$adProjectsDirectory = Join-Path "$($adDirectory)" "Projects"

#############################################################
# Create all neccessary folders with content for new ticket #
#############################################################
function CreateDirectories {
    # Source
    if (Test-Path -Path "$srcDirectory") {
        Write-Warning "Src directory already exists"
    } else {
        Write-Host "Creating Src directory $($srcDirectory)..."
        
        cd $srcAdRootDirectory

        # TODO check if worktree exist for this branch and remove it/reuse
        git checkout main


        if ($pullMaster)
        {
            Write-Host "Pulling new master..."
            git pull origin main
        }
        else
        {
            Write-Host Pullig master skipped!
        }

        
        Write-Host "Create new worktree (drink some coffee)..."

        $result = &git worktree add -b $branchName "$($srcDirectory)" 2>&1 | Out-String

        Write-Host $result
        Write-Host $result.GetType();
        Write-Host $result.Contains("already exists")
        if ($result.Contains("already exists"))
        {
            Write-Host "Current branch alread exists. Use it!..."
            git worktree add "$($srcDirectory)" $($branchName) 
        }
    }

    # Runners
    if (Test-Path -Path "$runnersDirectory") {
        Write-Warning "Runners directory already exists"
    } else {
        Write-Host "Creating Runners directory $($runnersDirectory)..."
        
        New-Item -ItemType "directory" -Path $runnersDirectory
    }

    # AD
    if (Test-Path -Path "$adDirectory") {
        Write-Warning "AD directories already exists"
    } else {
        Write-Host "Creating AD diresctories $($srcDirectory)..."

        New-Item -ItemType "directory" -Path $adDirectory
        New-Item -ItemType "directory" -Path $adFilesDirectory
        New-Item -ItemType "directory" -Path $adInstallersDirectory
        New-Item -ItemType "directory" -Path $adDataDirectory
        New-Item -ItemType "directory" -Path $adProjectsDirectory
    }
}


function RemoveSrcDirectories() {
    if (Test-Path -Path "$srcDirectory") {
        Write-Warning "Removing $($srcDirectory) directory git worktree and branch..."
                
        cd $srcAdRootDirectory

        $result = &git worktree remove -f "$($srcDirectory)" 2>&1 | Out-String

        git branch --delete --force $($branchName)

        Write-Host $result
    } else {
        Write-Host "Src already removed..."
    }
}

###########################################################
# Download AD from master branch                          #
# AD installer version will be extracted from git tags    #
# so you should create installer (push branch and run MM) #
# and fetch tags                                          #
# Installer will be downloaded from:                      #
# \\builds-new.altium.biz                                 #
###########################################################
function DownloadLatestAd {
    Write-Host "Downloading Latest AD..."
    cd $srcAdRootDirectory
    $tagsRaw = git tag --points-at HEAD
    $tags = $tagsRaw.Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries);
    $tags = $tags | where {$_ -like "builds-of-altium-designer-dev*"} | Sort-Object -Descending

    
    if  ($tags -isnot [array])
    {
        $varsion = $tags
    }
    else
    { 
        foreach ($tag in $tags)
        {
            $matches = ([regex]::Matches($tag, "/" )).count

            if ($matches -eq 2)
            {
                 $varsion = $tag
                 break
            }
        }
    }

    $tagParts = $varsion.Split("/", [StringSplitOptions]::RemoveEmptyEntries);
    $adInstallerName = "AltiumDesigner$($tagParts[1])Setup.exe"
    $adInstallerPath = "\\builds-new.altium.biz\Products\New\X2\Dev\AD\Build $($tagParts[2])\$($adInstallerName)"

    $newFileName = "AltiumDesigner$($tagParts[1])Setup_$($tagParts[2]).exe"
    $newPath = Join-Path "$($adInstallersDirectory)" "$($newFileName)"

    if (Test-Path -Path "$newPath" -PathType Leaf)
    {
        Write-Warning "Installer $($newFileName) already exists. Skipping download."
    }
    else 
    {
        Start-BitsTransfer -Source $adInstallerPath -Destination $newPath -Description "$adInstallerPath" -DisplayName "Downloading $adInstallerName"
    }

    return $newPath
}

###########################################################
# Download AD from current branch                         #
# AD installer version will be extracted from git tags    #
# so you should create installer (push branch and run MM) #
# and fetch tags                                          #
# Installer will be downloaded from:                      #
# \\builds-new.altium.biz                                 #
###########################################################
function DownloadLatestAdFature {
    Write-Host "Downloading Feature AD..."
    cd $srcDirectory
    $tagsRaw = git tag --points-at HEAD
    $tags = $tagsRaw.Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries);
    $tags = $tags | where {$_ -like "builds-of-altium-designer-feature-$($workItem.ticket)*"} | Sort-Object -Descending

    if  ($tags -isnot [array])
    {
        $varsion = $tags
    }
    else
    { 
        foreach ($tag in $tags)
        {
            $matches = ([regex]::Matches($tag, "/" )).count

            if ($matches -eq 2)
            {
                 $varsion = $tag
                 break
            }
        }
    }

    # TODO catch exception when no tags

    $tagParts = $varsion.Split("/", [StringSplitOptions]::RemoveEmptyEntries);
    $dirName = $branchName.Replace("/", "-")

    $adInstallerName = "AltiumDesigner$($tagParts[1])Setup.exe"
    $adInstallerPath = "\\builds-new.altium.biz\Products\New\X2\Branch\Altium Designer - $($dirName)\Build $($tagParts[2])\$($adInstallerName)"
 

    $newFileName = "AltiumDesigner$($tagParts[1])Setup_$($ticket)_$($tagParts[2]).exe"
    $newPath = Join-Path "$($adInstallersDirectory)" "$($newFileName)"

    if (Test-Path -Path "$newPath" -PathType Leaf)
    {
        Write-Warning "Installer $($newFileName) already exists. Skipping download."
    }
    else 
    {
        Start-BitsTransfer -Source $adInstallerPath -Destination $newPath -Description "$adInstallerPath" -DisplayName "Downloading $adInstallerName"
    }

    return $newPath
}

function InstallLatestAd {
    $adInstaller = DownloadLatestAd

    InstallAd($adInstaller)
}

function InstallLatestAdFeature {
    $uninstallAd = $false;
    do {
        $inputValid = [bool]::TryParse((Read-Host 'Should I uninstall the current AD? (yes not)'), [ref]$uninstallAd)
        if (-not $inputValid) {
            Write-Host "your input was not an bool..."
        }
    } while (-not $inputValid)

    if ($uninstallAd)
    {
        UninstallAd
    }
    
    $adInstaller = DownloadLatestAdFature
    InstallAd($adInstaller)
}

function InstallLatestAdFromPath {
    $adInstaller = Read-Host 'Podaj ścieżkę instalatora AD'

    InstallAd($adInstaller)
}

function InstallAd($adInstaller) {
    Write-Host "Installing $($adInstaller)..."

    $arguments = "-Programs:`"$($adFilesDirectory)`" -Documents:`"$($adDataDirectory)`" -UI:Full -AutoInstall -InstallAll -User:`"$($adEmail)`""

    Write-Host "Installing $($adInstaller) with: $($arguments)..."

    Start-Process $adInstaller $arguments -NoNewWindow -Wait

    $id = GetAdId;
    Set-Content -Path "$($runnersDirectory)\id.txt" -Value $id

    $applicationDir = GetAdApplication
    Set-Content -Path "$($runnersDirectory)\applicationDir.txt" -Value $applicationDir
}

function CreateRunners {
    Write-Host "Copying template runners to $($runnersDirectory)..."
    Copy-item -Force -Recurse "$runnersExamplesRootDirectory\*" -Destination $runnersDirectory
}

function RemoveRunners() {
   Write-Host "Removing template runners from $($runnersDirectory)..."
   Remove-Item -LiteralPath "$($runnersDirectory)" -Force -Recurse
}

function Get-IniContent ($filePath)
{
	$ini = @{}
	switch -regex -file $FilePath
	{
    	“^\[(.+)\]” # Section
    	{
        	$section = $matches[1]
        	$ini[$section] = @{}
        	$CommentCount = 0
    	}
    	“^(;.*)$” # Comment
    	{
        	$value = $matches[1]
        	$CommentCount = $CommentCount + 1
        	$name = “Comment” + $CommentCount
        	$ini[$section][$name] = $value
    	}
    	“(.+?)\s*=(.*)” # Key
    	{
        	$name,$value = $matches[1..2]
        	$ini[$section][$name] = $value
    	}
	}
	return $ini
}

function GetAdId
{
    write-host "Getting AD ID..."
    $adInstaller = Join-Path "$($adFilesDirectory)" "System\Installation\AltiumInstaller.exe" 
    $prefFolderIni = Join-Path "$($adFilesDirectory)" "System\PrefFolder.ini" 

    $pref = Get-IniContent $prefFolderIni
    write-host $pref["Preference Location"].UniqueID
    write-host $pref["Preference Location"].Application

    return $pref["Preference Location"].UniqueID
}

function GetAdApplication
{
    $adInstaller = Join-Path "$($adFilesDirectory)" "System\Installation\AltiumInstaller.exe" 
    $prefFolderIni = Join-Path "$($adFilesDirectory)" "System\PrefFolder.ini" 

    $test = Get-IniContent $prefFolderIni
    write-host $test["Preference Location"].UniqueID
    
    write-host $test["Preference Location"].Application

    return $test["Preference Location"].Application
}

function UninstallAd {
    $id = GetAdId

    $adInstaller = "$($adFilesDirectory)\System\Installation\AltiumInstaller.exe"

    $arguments = "-Uninstall -UniqueID:`"$($id)`""
    Write-Host "Uninstalling with: $arguments"

    Start-Process $adInstaller $arguments -NoNewWindow -Wait
}

###########################################################
# Start new ticker - create dirs and install AD from main #
###########################################################
function StartTicket() {
    $pullMaster = $false;
    do {
        $inputValid = [bool]::TryParse((Read-Host 'Pull new master (recomended false - git tag for new installer may not exist yet)? (true/false)'), [ref]$pullMaster)
        if (-not $inputValid) {
            Write-Host "your input was not an bool..."
        }
    } while (-not $inputValid)
        
    CreateDirectories
    CreateRunners
    InstallLatestAd
}

#########################################
# Remove all ticket dirs and files      #
# Run after ticket is done              #
#########################################
function RemoveTicket() {
    Write-Warning "Are you sure you want to delete the ticket? (true/false)" -WarningAction Inquire

    RemoveSrcDirectories
    RemoveRunners
    UninstallAd
}

#########################################
# Merge current ticket branch and main  #
# into SchDev branch                    #
#########################################
function MergeToSchDev() {
    Write-Warning "Are you sure you want to merge to SchDev?" -WarningAction Inquire

    cd $srcAdRootDirectory
    git checkout main
    git pull origin main

    cd $schDevDirectory

    git checkout branches/sch-dev
    git pull
    git merge main
    git merge $branchName

    exit
    # TODO update test ad
    cd C:\Dev\test-ad
    git checkout main
    git pull
    git checkout branches/sch-dev
    git pull
    git merge main

}

#########################
# Ticket menu - actions #
#########################
Write-Host "1 Create new ticket"
Write-Host "2 Remove ticket"
Write-Host "3 Install AD - from latest main"
Write-Host "4 Install AD - from this branch"
Write-Host "5 Install AD - from path"
Write-Host "6 Uninstall AD"
Write-Host "7 Print AD guid"
Write-Host "8 Merge to SchDev"

$maxAction = 8
$selectedAction = 0
do {
    $inputValid = [int]::TryParse((Read-Host 'Podaj numer zadania'), [ref]$selectedAction)
    if (-not $inputValid) {
        Write-Host "your input was not an integer..."
    }

    if ($selectedAction -lt 0 -or $selectedAction -ge $maxAction)
    {
        $inputValid = $false;
        
        Write-Host "Wrong number..."
    }
} while (-not $inputValid)


switch ($selectedAction) {
    1 { StartTicket }
    2 { RemoveTicket }
    3 { InstallLatestAd }
    4 { InstallLatestAdFeature }
    5 { InstallLatestAdFromPath }
    6 { UninstallAd }
    7 { GetAdId }
    8 { MergeToSchDev }
}

Write-Host "bye, bye!"

class WorkItem {
    [string]$ticket
    [string]$description;
    [string]$directoryDescription;

    # If false "-SchTeam wont be added to branch"
    [bool]$alien;

    WorkItem([string]$ticket, [string]$description)
    {
        $this.ticket = $ticket
        $this.description = $description
        $this.directoryDescription = $description
        $this.alien = $false
    }

    WorkItem([string]$ticket, [string]$description, [string]$directoryDescription)
    {
        $this.ticket = $ticket
        $this.description = $description
        $this.directoryDescription = $directoryDescription
        $this.alien = $false
    }

    
    WorkItem([string]$ticket, [string]$description, [bool]$alien)
    {
        $this.ticket = $ticket
        $this.description = $description
        $this.directoryDescription = $description
        $this.alien = $alien
    }
}