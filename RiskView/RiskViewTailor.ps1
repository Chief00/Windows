

# To add a new option, add it to the choiceArray or relevent subchoicearray
# Then add the code for the option in the relevent logchoice
# Then add the description to the relevent choiceArrayDesc

# Run as admin script
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

$logFile = "C:\Users\$([Environment]::UserName)\AppData\Local\Temp\riskview-cs.log"
$appFolderLocation = "C:\Program Files\RiskView-CS"
$appData = "C:\Users\$([Environment]::UserName)\AppData\Local\RiskView-CS"
$configFile = $appData\app\RiskView-CS.cfg

function printLogo {
Write-Host "
           ___  _     __  _   ___
          / _ \(_)__ / /_| | / (_)__ _    __
         / , _/ (_-</  '_/ |/ / / -_) |/|/ /
        /_/|_/_/___/_/\_\|___/_/\__/|__,__/
        /_  __/__ _(_) /__ ____
         / / / _ '/ / / -_) __/
        /_/  \_,_/_/_/\__/_/


"}

function choiceExceptions ($choice, $subChoice) {
    if (($choice -eq "b") -or ($subChoice -eq "b")) {
        break
    }
    if (($choice -eq "") -or ($subChoice -eq "")) {
        continue
    }
    if ($choice -eq "?") {
        choiceHelp $choiceArray $choiceArrayDesc
        continue
    }
    if ($choice -eq "Search") {
        if ($subChoice -eq "?") {
            choiceHelp $searchSubChoiceArray $searchSubChoiceArrayDesc
            continue
        }
    }
    if ($choice -eq "Run App") {
        if ($subChoice -eq "?") {
            choiceHelp $runAppSubChoiceArray $runAppSubChoiceArrayDesc
        }
    }
    if ($choice -eq "Options") {
        if ($subChoice -eq "?") {
            choiceHelp $optionsSubChoiceArray $optionsSubChoiceArrayDesc
        }
    }
}

function userChoicesList ($title, $choiceArray) {

    cls
    printLogo

    Write-Host "Logged in as: " $([Environment]::UserName)
    Write-Host `n$title `n
    for ($i = 0; $i -lt $choiceArray.length; $i++) {
        Write-Host "[$i]" $choiceArray[$i]
    }
    Write-Host "[?] Help"
    $choice = Read-Host "`n`nWhat do you choose? "
    return $choice
}

function choiceHelp ($Array, $ArrayDesc){

    cls
    printLogo
    for ($i = 0; $i -lt $Array.length; $i++) {
        Write-Host
        Write-Host "[$i]" $Array[$i]
        Write-Host "   " $ArrayDesc[$i]
        Write-Host `n
    }
    Write-Host "[b] Back" `n
    Read-Host "Press any key to return "
}


function logChoice ($choice) {

    if ($choice -eq "Run App") {
        $subChoice = ""
        while ($subChoice -ne "b") {
            $subChoice = userChoicesList "How would you like to run the app: " $runAppSubChoiceArray
            choiceExceptions $choice $subChoice
            logRunAPPChoice $runAppSubChoiceArray[$subChoice]
        }
        $choice = ""
    }

    if ($choice -eq "App Opened") {
        get-content $logFile -Wait -Tail ((select-string $logFile -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1) - (select-string $logFile -Pattern "RiskView CS Version" | select-object -ExpandProperty 'LineNumber' -Last 1)+1)
    }

    if ($choice -eq "Last Gather") {
        get-content $logFile -wait -Tail ((select-string $logFile -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string $logFile -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1)
    }

    if ($choice -eq "Never") {
        get-content $logFile -wait -Tail 0
    }

    if ($choice -eq "All"){
        get-content $logFile -wait
    }

    if ($choice -eq "Search") {
        $subChoice = ""
        while ($subChoice -ne "b") {
            $subChoice = userChoicesList "How do you want to search: " $searchSubChoiceArray
            choiceExceptions $choice $subChoice
            logSearchChoice $searchSubChoiceArray[$subChoice]
        }
        $choice = ""
    }


    if ($choice -eq "Ram Usage") {
        get-content $logFile -wait -Tail ((select-string $logFile -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string $logFile -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains("Current Free Memory")}
    }

    if ($choice -eq "Current File") {
        get-content $logFile -wait -Tail ((select-string $logFile -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string $logFile -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains("[FileGathererToItems] Processing file") -Or $_.contains("[TikaFileGathererBase] File Excluded")}
    }


    if ($choice -eq "Options") {
        $subChoice = ""
        while ($subChoice -ne "b") {
            $subChoice = userChoicesList "What options do you want to change:  " $optionsSubChoiceArray
            choiceExceptions $choice $subChoice
            logOptionsChoice $optionsSubChoiceArray[$subChoice]
        }
    }
    return $choice
}

function logSearchChoice ($subChoice) {

    if ($subChoice -eq "Simple") {

        $userString = Read-Host "What do you want to search? "
        if (($userString -eq "b") -or ($userString -eq "")) {return ""}
        select-string $logFile -Pattern $userString
        Read-Host "`nPress anything to return"
    }
    if ($subChoice -eq "Extra") {

        $userString = Read-Host "What do you want to search? "
        if (($userString -eq "b") -or ($userString -eq "")) {return ""}
        $extraLines = Read-Host "How many extra lines do you want to print? "
        if (($extraLines -eq "b") -or ($userString -eq "")) {return ""}
        select-string $logFile -Pattern $userString -Context 0, $extraLines
        Read-Host "`nPress anything to return"
    }
    if ($subChoice -eq "Tailing") {
        ""
        "This is case sensitive"
        $userString = Read-Host "What do you want to search? "
        if (($userString -eq "b") -or ($userString -eq "")) {return ""}
        get-content $logFile -wait -Tail ((select-string $logFile -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string $logFile -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains($userString)}
    }
}

function logRunAPPChoice ($subChoice) {

    if ($subChoice -eq "Gui") {
        &$appFolderLocation\RiskView-CS.exe
    }

    if ($subChoice -eq "NoGui") {

        $serverLink = Read-Host "What is the server link "
        $scanLocation = Read-Host "Where is the location you want to scan "
        [regex]$regexGUID = "\w{8}-(\w{4}-){3}\w{12}"
        $GUID = $regexGUID.Matches($serverLink) | foreach-object {$_.value}
        if (Test-Path $appData\Resources\$GUID) {
            $removeLastScan = Read-Host "Do you want to remove the last scan data (y/n)"
            if ($removeLastScan -eq "y") {
                rm $appData\Resources\$GUID\ScanInfo.json
            }
        }
        &$appFolderLocation\RiskView-CS.exe nogui $serverLink $scanLocation
    }
}

function logOptionsChoice ($subChoice) {


    $configFileContent = Get-Content $configFile
    if ($subChoice -eq "Current RAM") {
        [regex]$regexRAM = "\d+m"
        Write-Host "`nCurrent RAM is: " $regexRAM.Matches($configFileContent) | foreach-object {$_.value}
        Read-Host "`nPress any key to continue"
    }

    if ($subChoice -eq "Change RAM Allowance") {
        [regex]$regexRAM = "-Xmx=\d+"
        $currentRAM = $regexRAM.Matches($configFileContent) | foreach-object {$_.value}
        $newRAM = Read-Host "How much RAM do you want to allow (MB) "
        ($configFileContent).Replace($currentRAM +'m','-Xmx='+ $newRAM +'m') | Out-File $configFile
    }

    if ($subChoice -eq "Reset RAM") {
        [regex]$regexRAM = "-Xmx=\d+"
        $currentRAM = $regexRAM.Matches($configFileContent) | foreach-object {$_.value}
        ($configFileContent).Replace($currentRAM +'m','-Xmx=3048m') | Out-File $configFile
    }

    if ($subChoice -eq "Uninstall") {
        $app = Get-WmiObject -Class Win32_Product | Where-Object {
        $_.Name -match "RiskView-CS"
        }
        $app.Uninstall()
        rm $appFolderLocation
        rm $appData
    }

    if ($subChoice -eq "Upgrade") {
        $app = Get-WmiObject -Class Win32_Product | Where-Object {
        $_.Name -match "RiskView-CS"
        }
        $app.Uninstall()
        rm $appData\Resources
    }
}



$choiceArray = "Run App","App Opened", "Last Gather", "Never", "All", "Search", "RAM Usage", "Current File", "Options"
$searchSubChoiceArray = "Simple", "Extra", "Tailing"
$runAppSubChoiceArray = "Gui", "NoGui"
$optionsSubChoiceArray = "Current RAM", "Change RAM Allowance", "Reset RAM", "Uninstall", "Upgrade"

$choiceArrayDesc =
"This will run the app, and reset this screen for tailing options",
"This will display the log since the app was opened and then tail it.",
"This will display the log since the last gather was run and then tail it.",
"This will just tail the log from the last line, not showing the log previous to the last line.",
"This will display the whole log and then tail it.",
"You can search the log for phrases.",
"This will tail the log for the RAM usage.",
"This will tail the log only displaying the current file being processed and any excluded files.",
"Change some parameters of the app"

$searchSubChoiceArrayDesc =
"This will do a simple search in the log for a phrase.",
"This will do a search and display n extra lines after the matched phrases line.",
"This will search the log for the occurance of the phrase and display them all. `n    Then tail the log only displaying lines that contain the phrase.`n    This is CaSe SeNsItIvE!!"

$runAppSubChoiceArrayDesc =
"This will open the app with a General User Interface.",
"This will run the app without a GUI and will run the commands via command line. `n    This will provide a simple User Interface to make it easier. `n    Removing the last scan data will allow you to run a full scan as by defualt this `n     is set to scan files since the last scan was run."

$optionsSubChoiceArrayDesc =
"This will display the current amount of RAM the app has access to.",
"This will change the amount of ram the app has access to.",
"This willl reset the ram of the app back to its default (3048 MB).",
"This will completely Uninstall the app removing all files and folders.",
"Upgrade to a specified version."

# This is the user main input loop
$userChoice = ""

while ($userChoice -ne "b") {
    $userChoice = ""
    $userChoice = userChoicesList "What do you want to tail: " $choiceArray
    choiceExceptions $userChoice $subChoice
    logChoice $choiceArray[$userChoice]
}
