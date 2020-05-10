# parameters
param([string]$source = ".\Documents\temp\source", [string]$destination = ".\Documents\temp\destination")

# functions
function CheckFolder([string]$path, [switch]$create) {
    $exists = Test-Path $path

    if(!$exists -and $create){
        #create the directory because it doesn't exist
        New-Item $path | out-null #out-null gets rid of all the feedback when creating a new directory in the console
        $exists = Test-Path $path
    }
    return $exists
}

function DisplayFolderStats([string]$path){
    $files = Get-ChildItem $path -Recurse | Where-Object {!$_.PSIsContainer}
    $totals = $files | Measure-Object -Property length -sum
    $stats = "" | Select-Object path,count,size
    $stats.path = $path
    $stats.count = $totals.count
    $stats.size = [math]::round($totals.sum/1MB,2)
    return $stats
}

DisplayFolderStats ".\Documents"

CheckFolder ".\Documents\temp\destination" -create


# main processing
#Test for existence of the source folder (using CheckFolder function)
$sourceexists = CheckFolder $source

if (!$sourceexists){
    Write-Host "The source directory is not found. Script can not continue."
    Exit
}

#Test for the existence of the destination folder; create it if it is not found (using the CheckFolder function
#with the create switch).Write-Host "Testing Destination Directory - $destination"
$destinationexists = CheckFolder $destination -create

if (!$destinationexists){
    Write-Host "The destination directory is not found. Script can not continue."
    Exit
}

#Copy each file to the appropriate destination.
#get all the files that need to be copied
$files = Get-ChildItem $source -Recurse | Where-Object {!$_.PSIsContainer} #gets all the files

#Display a message when copying a file. The message should list where the file is being
#moved from and where it is being moved to.
foreach ($file in $files){
    $ext = $file.Extension.Replace(".", "")
    $extdestdir = "$destination\$ext"
    $extdestdir
    #check to see if the folder exists, if not create it
    $extdestdirexists = CheckFolder $extdestdir -create
    if ($extdestdirexists){
        Write-Host "The destination directory ($extdestdir) can't be created."
        Exit
    }

    #copy file
    Copy-Item $file.FullName $extdestdir
}

#Display each target folder name with the file count and byte count for each folder.
$dirs = Get-ChildItem $destination | Where-Object {$_.PSIsContainer}

$allstats = @()
foreach($dir in $dirs){
    $allstats += DisplayFolderStats $dir.FullName
}

$allstats | Sort-Object -Descending