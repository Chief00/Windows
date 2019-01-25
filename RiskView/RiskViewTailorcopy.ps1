
# Run as admin script
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

$logFile = "C:\Users\$([Environment]::UserName)\AppData\Local\Temp\riskview-cs.log"
$appFolderLocation = "C:\Program Files\RiskView-CS"
$appData = "C:\Users\$([Environment]::UserName)\AppData\Local\RiskView-CS"
$configFile = "$appFolderLocation\app\RiskView-CS.cfg"

function printLogo {
Write-Host "
           ___  _     __  _   ___
          / _ \(_)__ / /_| | / (_)__ _    __
         / , _/ (_-</  '_/ |/ / / -_) |/|/ /
        /_/|_/_/___/_/\_\|___/_/\__/|__,__/
        /_  __/__ _(_) /___ ____
         / / / _ '/ / / ,  ) __/
        /_/  \_,_/_/_/\___/_/


"}

function choiceExceptions ($choice, $subChoice = "FALSE", $subSubChoice = "FALSE") {
    if (($choice -eq "b") -or ($subChoice -eq "b")) {
        break
    }
    if (($choice -eq "") -or ($subChoice -eq "")) {
        continue
    }
    if ($choice -eq "?") {
        choiceHelp "Main Menu"
        continue
    }
    if ($choice -eq "Search") {
        if ($subChoice -eq "?") {
            choiceHelp $choice
            continue
        }
    }
    if ($choice -eq "Run App") {
        if ($subChoice -eq "?") {
            choiceHelp $choice
        }
    }
    if ($choice -eq "Options") {
        if ($subChoice -eq "?") {
            choiceHelp $choice
        }
    }
}

function userChoicesList ($title, $type) {

    cls
    printLogo

    Write-Host "Logged in as: " $([Environment]::UserName) `n
    Write-Host $type -Foregroundcolor Green
    Write-Host `n$title `n
    $i = 0
    $choiceArrayDesc[$type].GetEnumerator() | ForEach-Object{
        Write-Host "[$i]" $_.key
        $i += 1
    }
    Write-Host "[?] Help"
    $choice = Read-Host "`n`nWhat do you choose? "
    if (0..$choiceArrayDesc[$type].Count -Contains $choice){
        $output = $ChoiceArrayDesc[$type].keys | select -Index $choice
        return $output
    } else {
        return $choice
    }

}

function choiceHelp ($type){

    cls
    printLogo
    $i = 1
    $choiceArrayDesc[$type].GetEnumerator() | ForEach-Object{
        Write-Host "[$i]" $_.key
        Write-Host "   " $_.value
        Write-Host `n
        $i += 1
    }
    Write-Host "[b] Back" `n
    Read-Host "Press any key to return "
}


function mainChoices ($choice) {

    if ($choice -eq "Run App") {
        $subChoice = ""
        while ($subChoice -ne "b") {
            $subChoice = userChoicesList "How would you like to run the app: " $choice
            choiceExceptions $choice $subChoice
            runAppChoices $subChoice
        }
    }

    if ($choice -eq "Tailer") {
        while ($subchoice -ne "b") {
            $subChoice = userChoicesList "How would you like to tail: " $choice
            choiceExceptions $choice $subChoice
            tailerChoices $subChoice
        }
    }

    if ($choice -eq "Search") {
        $subChoice = ""
        while ($subChoice -ne "b") {
            $subChoice = userChoicesList "How do you want to search: " $choice
            choiceExceptions $choice $subChoice
            searchChoices $subChoice
        }
    }


    if ($choice -eq "Options") {
        $subChoice = ""
        while ($subChoice -ne "b") {
            $subChoice = userChoicesList "What options do you want to change:  " $choice
            choiceExceptions $choice $subChoice
            optionsChoices $subChoice
        }
    }
}

function tailerChoices ($choice) {

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

    if ($choice -eq "Ram Usage") {
        get-content $logFile -wait -Tail ((select-string $logFile -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string $logFile -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains("Current Free Memory")}
    }

    if ($choice -eq "Current File") {
        get-content $logFile -wait -Tail ((select-string $logFile -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string $logFile -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains("[FileGathererToItems] Processing file") -Or $_.contains("[TikaFileGathererBase] File Excluded")}
    }
}

function searchChoices ($choice) {

    if ($choice -eq "Simple") {

        $userString = Read-Host "What do you want to search? "
        if (($userString -eq "b") -or ($userString -eq "")) {return ""}
        select-string $logFile -Pattern $userString
        Read-Host "`nPress anything to return"
    }
    if ($choice -eq "Extra") {

        $userString = Read-Host "What do you want to search? "
        if (($userString -eq "b") -or ($userString -eq "")) {return ""}
        $extraLines = Read-Host "How many extra lines do you want to print? "
        if (($extraLines -eq "b") -or ($userString -eq "")) {return ""}
        select-string $logFile -Pattern $userString -Context 0, $extraLines
        Read-Host "`nPress anything to return"
    }
    if ($choice -eq "Tailing") {
        ""
        "This is case sensitive"
        $userString = Read-Host "What do you want to search? "
        if (($userString -eq "b") -or ($userString -eq "")) {return ""}
        get-content $logFile -wait -Tail ((select-string $logFile -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string $logFile -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains($userString)}
    }
}

function runAppChoices ($choice) {

    if ($choice -eq "Gui") {
        &$appFolderLocation\RiskView-CS.exe
        Break
    }

    if ($choice -eq "NoGui") {

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

function optionsChoices ($choice) {


    $configFileContent = Get-Content $configFile
    if ($choice -eq "Current RAM") {
        [regex]$regexRAM = "\d+m"
        Write-Host "`nCurrent RAM is: " $regexRAM.Matches($configFileContent) | foreach-object {$_.value}
        Read-Host "`nPress any key to continue"
    }

    if ($choice -eq "Change RAM Allowance") {
        [regex]$regexRAM = "-Xmx=\d+"
        $currentRAM = $regexRAM.Matches($configFileContent) | foreach-object {$_.value}
        $newRAM = Read-Host "How much RAM do you want to allow (MB) "
        ($configFileContent).Replace($currentRAM +'m','-Xmx='+ $newRAM +'m') | Out-File $configFile
    }

    if ($choice -eq "Reset RAM") {
        [regex]$regexRAM = "-Xmx=\d+"
        $currentRAM = $regexRAM.Matches($configFileContent) | foreach-object {$_.value}
        ($configFileContent).Replace($currentRAM +'m','-Xmx=3048m') | Out-File $configFile
    }

    if ($choice -eq "Uninstall") {
        $app = Get-WmiObject -Class Win32_Product | Where-Object {
        $_.Name -match "RiskView-CS"
        }
        $app.Uninstall()
        rm $appFolderLocation
        rm $appData
    }

    if ($choice -eq "Upgrade") {
        $app = Get-WmiObject -Class Win32_Product | Where-Object {
        $_.Name -match "RiskView-CS"
        }
        $app.Uninstall()
        rm $appData\Resources
    }
}

$ChoiceArrayDesc = [ordered]@{
    "Main Menu" = [ordered]@{
        "Run App" = "This will run the app.";
        "Tailer" = "This will tail the logs.";
        "Search" = "This will search the log file.";
        "Options" = "Configurable options for the this script adn the app."
    };

    "Run App" = [ordered]@{
        "GUI" = "This will open the app with a General User Interface.";
        "NoGui" = "This will run the app without a GUI and will run the commands via command line. `n    This will provide a simple User Interface to make it easier. `n    Removing the last scan data will allow you to run a full scan as by defualt this `n     is set to scan files since the last scan was run."
    };

    "Tailer" = [ordered]@{
        "App Opened" = "This will display the log since the app was opened and then tail it.";
        "Last Gather" = "This will display the log since the last gather was run and then tail it.";
        "Never" = "This will just tail the log from the last line, not showing the log previous to the last line.";
        "All" = "This will display the whole log and then tail it.";
        "RAM Usage" = "This will tail the log for the RAM usage.";
        "Current File" = "This will tail the log only displaying the current file being processed and any excluded files."
    };

    "Search" = [ordered]@{
        "Simple" = "This will do a simple search in the log for a phrase.";
        "Extra" = "This will do a search and display n extra lines after the matched phrases line.";
        "Tailing" = "This will search the log for the occurance of the phrase and display them all. `n    Then tail the log only displaying lines that contain the phrase.`n    This is CaSe SeNsItIvE!!"
    };

    "Options" = [ordered]@{
        "Current RAM" = "This will display the current amount of RAM the app has access to.";
        "Change RAM Allowance" = "This will change the amount of ram the app has access to.";
        "Reset RAM" = "This willl reset the ram of the app back to its default (3048 MB).";
        "Uninstall" = "This will completely Uninstall the app removing all files and folders.";
        "Upgrade" = "Upgrade to a specified version."
    }
}

# This is the user main input loop
$userChoice = ""

while ($userChoice -ne "b") {
    $userChoice = ""
    $userChoice = userChoicesList "What would you like to do: " "Main Menu"
    choiceExceptions $userChoice
    mainChoices $userChoice
}
