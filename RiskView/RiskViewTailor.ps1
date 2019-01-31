
# These are the locations of the RiskView files which the user can specify, shouldnt have to.
$userLogFile = ""
$userAppFolderLocation = ""
$userAppData = ""

if ($userLogFile -eq "") {
    $logFile = "C:\Users\$([Environment]::UserName)\AppData\Local\Temp\riskview-cs.log"
} else {$logFile = $userLogFile}
if ($userAppFolderLocation -eq "") {
    $appFolderLocation = "C:\Program Files\RiskView-CS"
} else {$appFolderLocation = $userAppFolderLocation}
if ($userAppData -eq "") {
    $appData = "C:\Users\$([Environment]::UserName)\AppData\Local\RiskView-CS"
} else {$appData = $userAppData}
$configFile = "$appFolderLocation\app\RiskView-CS.cfg"
$filename = "RiskViewTailor.ps1"


# This prints the RiskView logo
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

# This function contains the exceptions for the user input
function choiceExceptions ($choice, $subChoice = "FALSE", $subSubChoice = "FALSE") {
    # Only allows access to subchoices that require admin access
    if ($subChoice -ne "FALSE") {
            if (($ChoiceArrayDesc.$choice[$subChoice] -Match "Requires Administrator Access") -AND (-Not($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))) {
                cls
                printLogo
                Write-Host "Access Denied" -Foregroundcolor "Red"
                Write-Host `n"Get Administrator Access" -Foregroundcolor "Red"
                Start-Sleep -s 2
                continue
            }
    }
    # Go back for b
    if (($choice -eq "b") -or ($subChoice -eq "b")) {
        break
    }
    # Continue for enter
    if (($choice -eq "") -or ($subChoice -eq "")) {
        continue
    }
    # Run help function for main menu
    if ($choice -eq "?") {
        choiceHelp "Main Menu"
        continue
    }
    if ($choice -eq "Search") {
        # Runs help function for search
        if ($subChoice -eq "?") {
            choiceHelp $choice
            continue
        }
    }
    if ($choice -eq "Run App") {
        # Runs help function for run app
        if ($subChoice -eq "?") {
            choiceHelp $choice
            continue
        }
    }
    if ($choice -eq "Options") {
        # Runs help function for options
        if ($subChoice -eq "?") {
            choiceHelp $choice
            continue
        }
        # Throws "error" for trying to run a function on a non existant filepath
        if (($subChoice -eq "Current RAM") -or ($subChoice -eq "Change RAM Allowance") -or ($subChoice -eq "Reset RAM") -AND (-Not(Test-Path $configFile))) {
            cls
            printLogo
            Write-Host "Config File Not Found" -Foregroundcolor "Red"
            Start-Sleep -s 2
            continue
        }
        if ($subChoice -eq "Change RAM Allowance") {
            # Backs out of changing ram when entering b
            if ($subSubChoice -eq "b") {
                continue
            }
            # Makes sure that if not b a number is entered
            if ($subSubChoice -ne "FALSE") {
                $value = $subSubChoice -as [Double]
                $ok = $value -ne $NULL
                if ( -not $ok ) { write-host "You must enter a numeric value" }
                Start-Sleep -s 2
                continue
            }
        }
    }
}

# This function displays the choices and gets the users input
function userChoicesList ($title, $type) {

    cls
    printLogo
    # Checks access level and displays it
    Write-Host "Logged in as: " $([Environment]::UserName)
    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host -NoNewline "Access Level: "
        Write-Host "Administrator" -Foregroundcolor "Yellow"
    } else {
        Write-Host "Access Level: Non-Administrator"
    }
    Write-Host `n$type -Foregroundcolor "Green"
    Write-Host `n$title `n
    # Displays options and if they you dont have admin display as red for ones you need access to run
    $i = 0
    $choiceArrayDesc[$type].GetEnumerator() | ForEach-Object{
        if (($_.value -Match "Requires Administrator Access") -AND (-Not($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))) {
            $accessColour = "Red"
        } else {
            $accessColour = "White"
        }
        Write-Host "[$i]" $_.key -Foregroundcolor $accessColour
        $i += 1
    }
    Write-Host "[?] Help"
    $choice = Read-Host "`n`nWhat do you choose? "
    # Returns the choice as its name (string)
    if ((0..$choiceArrayDesc[$type].Count -Contains $choice) -AND ($choice -ne "")) {
        $output = $ChoiceArrayDesc[$type].keys | select -Index $choice
        return $output
    } else {
        return $choice
    }

}

# This function displays the descriptions for the choices
function choiceHelp ($type) {

    cls
    printLogo
    # Checks the access level needed for the choice and displays it in appropriate colour
    $i = 1
    $choiceArrayDesc[$type].GetEnumerator() | ForEach-Object{
        if (($_.value -Match "Requires Administrator Access") -AND (-Not($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))) {
            $accessColour = "Red"
        } else {
            $accessColour = "White"
        }
        Write-Host "[$i]" $_.key -Foregroundcolor $accessColour
        Write-Host "   " $_.value
        Write-Host `n
        $i += 1
    }

    Write-Host "[b] Back" `n
    Write-Host -NoNewline "Anthing in "
    Write-Host -NoNewline "red" -Foregroundcolor "Red"
    Write-Host " you do not have the correct access to. Get Administrator Access.`n"
    Read-Host "Press Enter to return "
}

# This function is the main menu chocies
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

    if ($choice -eq "Administrator Access") {
        # Elevates to Administrator
        if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            cls
            printLogo
            Write-Host "You already have Administrator access"
            Start-Sleep -s 2
        } else {
            $ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
            $ScriptDir += "\$filename"
            Start-Process powershell -Verb runAs -ArgumentList "-file `"$ScriptDir`""
            break
        }
    }
}

# This fucntion is the tailer options
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

# This fucntion is the search options
function searchChoices ($choice) {

    if ($choice -eq "Simple") {

        Write-Host "Log located at: $logFile"
        $userString = Read-Host "What do you want to search? "
        if (($userString -eq "b") -or ($userString -eq "")) {return ""}
        select-string $logFile -Pattern $userString
        Read-Host "`nPress anything to return"
    }
    if ($choice -eq "Extra") {

        Write-Host "Log located at: $logFile"
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

# This fucntion is the options for running the app
function runAppChoices ($choice) {

    if ($choice -eq "Gui") {
        &$appFolderLocation\RiskView-CS.exe
        Break
    }

    if ($choice -eq "NoGui") {
        # Gets the GUID for the project and locates that folder
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

# This fucntion is the options options
function optionsChoices ($choice) {
    $functionGroup = "Options"
    choiceExceptions $functionGroup $choice

    if ($choice -eq "Current RAM") {
        # Regex for the current RAM
        $configFileContent = Get-Content $configFile
        [regex]$regexRAM = "\d+m"
        Write-Host "`nCurrent RAM is: " $regexRAM.Matches($configFileContent) | foreach-object {$_.value}
        Start-Sleep -s 2
    }

    if ($choice -eq "Change RAM Allowance") {
        $configFileContent = Get-Content $configFile
        [regex]$regexRAM = "-Xmx=\d+"
        $currentRAM = $regexRAM.Matches($configFileContent) | foreach-object {$_.value}
        $newRAM = Read-Host "How much RAM do you want to allow (MB) "
        choiceExceptions $functionGroup $choice $newRAM
        ($configFileContent).Replace($currentRAM +'m','-Xmx='+ $newRAM +'m') | Out-File $configFile
    }

    if ($choice -eq "Reset RAM") {
        $configFileContent = Get-Content $configFile
        [regex]$regexRAM = "-Xmx=\d+"
        $currentRAM = $regexRAM.Matches($configFileContent) | foreach-object {$_.value}
        ($configFileContent).Replace($currentRAM +'m','-Xmx=3048m') | Out-File $configFile
        Write-Host "RAM has been Reset"
        Start-Sleep -s 2
    }

    if ($choice -eq "Uninstall") {
        $app = Get-WmiObject -Class Win32_Product | Where-Object {
        $_.Name -match "RiskView-CS"
        }
        $app.Uninstall()
        rm $appData
        Write-Host "Done!"
        Read-Host "Press Enter to continue"
    }

    if ($choice -eq "Upgrade") {
        $app = Get-WmiObject -Class Win32_Product | Where-Object {
        $_.Name -match "RiskView-CS"
        }
        $app.Uninstall()
        Write-Host "Uninstalled"
        if (Test-Path "$appData\Resources") {
            rm "$appData\Resources"
            Write-Host "Removed Resources"
        }
        $latestVersionPath = Select-File 'MSI (*.msi)|*.msi'
        &$latestVersionPath
        Read-Host "Press Enter to continue"
    }
    if ($choice -eq "Change Log File") {
        $script:logFile = Select-File 'All files (*.*)| *.*'
        Write-Host "File Changed to: $logFile"
        Start-Sleep -s 2
    }
}

function Select-File ($filter) {
    Add-Type -AssemblyName System.Windows.Forms
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Multiselect = $false # Multiple files can be chosen
    	Filter = $filter # Specified file types
    }

    [void]$FileBrowser.ShowDialog()

    $FileBrowser.FileName;
}

function Select-Folder {
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.SelectedPath = "C:\"
    $browse.ShowNewFolderButton = $false
    $browse.Description = "Select a directory"

    $loop = $true
    while($loop)
    {
        if ($browse.ShowDialog() -eq "OK")
        {
        $loop = $false

		#Insert your script here

        } else
        {
            $res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Would you like to try again or exit?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if($res -eq "Cancel")
            {
                #Ends script
                return
            }
        }
    }
    $browse.SelectedPath
    $browse.Dispose()
}

# This function checks that the RiskView default files/folders are there
function checkRiskViewFiles {

    printLogo
    if (-Not (Test-Path $appFolderLocation)) {
        Write-Host "RiskView Program Files folder not found"
    }

    if (-Not (Test-Path $appData)) {
        Write-Host "RiskView AppData folder not found"
    }

    if ((-Not (Test-Path $appFolderLocation)) -or (-Not (Test-Path $appData))) {
        Read-Host `n"Press anything to continue"
    }
}

# This is all the options and their descriptions
$ChoiceArrayDesc = [ordered]@{
    "Main Menu" = [ordered]@{
        "Run App" = "This will run the app.";
        "Tailer" = "This will tail the logs.";
        "Search" = "This will search the log file.";
        "Options" = "Configurable options for the this script adn the app.";
        "Administrator Access" = "Restarts the script with Administrator access"
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
        "Change Log File" = "This will change the log for searching and tailing.`n    This will be forgotten when getting Administrator Acess";
        "Current RAM" = "This will display the current amount of RAM the app has access to.";
        "Change RAM Allowance" = "This will change the amount of ram the app has access to.`n    Requires Administrator Access.";
        "Reset RAM" = "This willl reset the ram of the app back to its default (3048 MB).`n    Requires Administrator Access.";
        "Uninstall" = "This will completely Uninstall the app removing all files and folders.`n    Requires Administrator Access.";
        "Upgrade" = "Upgrade to a specified version.`n    Requires Administrator Access."
    }
}

# Sets the userchoice to zero to start the loop
$userChoice = ""
# Gets the current Access Level
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Runs on startup
checkRiskViewFiles

# This is the user main input loop, can only exit the loop with b
while ($userChoice -ne "b") {
    $userChoice = ""
    $userChoice = userChoicesList "What would you like to do: " "Main Menu"
    choiceExceptions $userChoice
    mainChoices $userChoice
}
