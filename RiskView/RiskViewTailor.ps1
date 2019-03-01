$currentVersion = "1.0.0"
# These are the locations of the RiskView files which the user can specify, shouldnt have to.
$userLogFile = ""
$userappFolderLocation = ""
$userAppData = ""

if ($userLogFile -eq "") {
    $logFile = "C:\Users\$([Environment]::UserName)\AppData\Local\Temp\riskview-cs.log"
} else {$logFile = $userLogFile}
if ($userappFolderLocation -eq "") {
    $appFolderLocation = "C:\Program Files\RiskView-CS"
} else {$appFolderLocation = $userappFolderLocation}
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
        /_/  \_,_/_/_/\___/_/       V$currentVersion


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
    # Run appropriate help from any part of script
    if ($subChoice -eq "?") {
        choiceHelp $choice
        Continue
    }
    if ($choice -eq "Options") {
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
    $i = 0
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

    if ($choice -eq "Thread Buffer") {

        if (-Not (Test-Path $logFile)) {
            Write-Host "Log file not found, select one"
            Start-Sleep -s 2
            $script:logFile = Select-File 'All files (*.*)| *.*'
        }
        $oldTotalLines = (select-string $logFile -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)
        $bufferLoop = $True

        while ($bufferLoop) {
            $totalLines = (Get-Content $logFile | Measure-Object -line).Lines
            if ($totalLines -gt $oldTotalLines) {
                for ($i=$oldTotalLines; $i -lt $totalLines; $i++) {
                    collectBuffer (Get-Content $logFile | Select-Object -Index ($i-1))

                    if ($i -eq $totalLines) {
                        $oldTotalLines = $totalLines
                    }
                }
            }
            Start-Sleep -s 0.5
        }
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
        $scanLocation = Select-Folder
        [regex]$regexGUID = "\w{8}-(\w{4}-){3}\w{12}"
        $GUID = $regexGUID.Matches($serverLink) | foreach-object {$_.value}
        if (Test-Path $appData\Resources\$GUID) {
            $removeLastScan = Read-Host "Do you want to remove the last scan data (y/n)"
            if ($removeLastScan -eq "y") {
                rm $appData\Resources\$GUID\ScanInfo.json
            }
        }
        &$appFolderLocation\RiskView-CS.exe nogui $serverLink "file://$scanLocation"
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

    if ($choice -eq "Check RiskView Files") {
        for ($i=1; $i -lt $checkLocations.Count; $i++) {
            if (-Not(Test-Path $checkLocations[$i])) {
                Write-Host "File not found, path: "$checkLocations[$i]
            } else {
                if ($i -eq $checkLocations.Count-1) {
                    Write-Host "All files are correct" -Foregroundcolor "Green"
                }
            }
        }
        Read-Host "Press Enter to continue"
    }

    if ($choice -eq "Probe Permissions") {
    $scanLocation = Select-Folder
    &$appFolderLocation\RiskView-CS.exe probe "file://$scanLocation"
    }
}

function checkaccess ($Folder) {
    # $script:notPermissionLocations = @()
    # $user = $([Environment]::UserName)
    # $permission = (Get-Acl -LiteralPath $Folder -ErrorAction SilentlyContinue).Access | ?{$_.IdentityReference -match $User} | Select IdentityReference,FileSystemRights
    # if (-Not($permission)) {
    #     write-host "not permission $Folder"
    #     $script:notPermissionLocations += $Folder
    #     }
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

function collectBuffer ($line) {
    if ($line -like "*Completed analysing batch.*") {
        Write-Host "Done!"
        $script:bufferLoop = $False
        Break
    }

    if ($procfileRegex.matches($line).success) {
        # Get appropriate parsing
        $thread = ($line.split()[2]).substring($line.split()[2].length-1)
        $filenumber = $line.split()[9]
        # Turning the multi line filepath with space, from splitting, into one line
        if ($line.split().length -gt 14) {
            $FilePath = $line.split()[13]
            for ($i=14;$i -lt $line.split().length-1;$i++) {
                $FilePath += " " + $line.split()[$i]
            }
            $filePath = $FilePath.TrimEnd(".")
        } else {$filepath = $line.split()[13].TrimEnd(".")}
        $filename = $filePath.split("//")[$filePath.split("//").length-1].TrimEnd(".")

        # Replace file in buffer if the thread matches
        if ($buffertable | where {$_.Thread -eq $thread}) {
            $script:buffertable | where {$_.Thread -eq $thread} | foreach {
                $_.Filename = $Filename;
                $_.Filenumber = $filenumber;
                $_.FilePath = $filepath
            }

        # If the thread doesnt exist add the file normally
        } else {
            [void]$script:buffertable.Rows.Add(
                $thread,
                $filenumber,
                $filename,
                $filepath
            )
        }
    }
    cls
    $buffertable | sort-object thread |Format-Table
}

function checkUpdates {


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
    } else {

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
        "Current File" = "This will tail the log only displaying the current file being processed and any excluded files.";
        "Thread Buffer" = "This shows the current file on each thread"
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
        "Reset RAM" = "This will reset the ram of the app back to its default (3048 MB).`n    Requires Administrator Access.";
        "Uninstall" = "This will completely Uninstall the app removing all files and folders.`n    Requires Administrator Access.";
        "Upgrade" = "Upgrade to a specified version.`n    Requires Administrator Access.";
        "Check RiskView Files" = "This will check that all the files have been installed.";
        "Probe Permissions" = "Checks the user has access to the scanned folder."
    }
}


$checkLocations =
    "$appFolderLocation\api-ms-win-core-console-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-datetime-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-debug-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-errorhandling-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-file-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-file-l1-2-0.dll",
    "$appFolderLocation\api-ms-win-core-file-l2-1-0.dll",
    "$appFolderLocation\api-ms-win-core-handle-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-heap-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-interlocked-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-libraryloader-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-localization-l1-2-0.dll",
    "$appFolderLocation\api-ms-win-core-memory-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-namedpipe-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-processenvironment-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-processthreads-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-processthreads-l1-1-1.dll",
    "$appFolderLocation\api-ms-win-core-profile-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-rtlsupport-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-string-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-synch-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-synch-l1-2-0.dll",
    "$appFolderLocation\api-ms-win-core-sysinfo-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-timezone-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-core-util-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-conio-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-convert-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-environment-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-filesystem-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-heap-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-locale-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-math-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-multibyte-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-private-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-process-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-runtime-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-stdio-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-string-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-time-l1-1-0.dll",
    "$appFolderLocation\api-ms-win-crt-utility-l1-1-0.dll",
    "$appFolderLocation\msvcp140.dll",
    "$appFolderLocation\msvcr100.dll",
    "$appFolderLocation\packager.dll",
    "$appFolderLocation\RiskView-CS.exe",
    "$appFolderLocation\RiskView-CS.ico",
    "$appFolderLocation\ucrtbase.dll",
    "$appFolderLocation\vcruntime140.dll",
    "$appFolderLocation\app\boilerpipe-1.2.0\boilerpipe-1.2.0.jar",
    "$appFolderLocation\app\hibernate\antlr-2.7.7.jar",
    "$appFolderLocation\app\hibernate\dom4j-1.6.1.jar",
    "$appFolderLocation\app\hibernate\hibernate-commons-annotations-4.0.2.Final.jar",
    "$appFolderLocation\app\hibernate\hibernate-core-4.2.20.Final.jar",
    "$appFolderLocation\app\hibernate\hibernate-jpa-2.0-api-1.0.1.Final.jar",
    "$appFolderLocation\app\hibernate\jboss-logging-3.1.0.GA.jar",
    "$appFolderLocation\app\hibernate\jboss-transaction-api_1.1_spec-1.0.0.Final.jar",
    "$appFolderLocation\app\hibernate\mchange-commons-java-0.2.3.4.jar",
    "$appFolderLocation\app\javacsv-2.1\javacsv.jar",
    "$appFolderLocation\app\javamail-1.4.5\mailapi.jar",
    "$appFolderLocation\app\javamail-1.4.5\smtp.jar",
    "$appFolderLocation\app\resources\fonts\Exo-Bold.ttf",
    "$appFolderLocation\app\resources\fonts\Exo-Regular.ttf",
    "$appFolderLocation\app\resources\fonts\OpenSans-Bold.ttf",
    "$appFolderLocation\app\resources\fonts\OpenSans-Regular.ttf",
    "$appFolderLocation\app\resources\img\app_icon_16.png",
    "$appFolderLocation\app\resources\img\app_icon_32.png",
    "$appFolderLocation\app\resources\img\app_icon_64.png",
    "$appFolderLocation\app\resources\img\assessment_report_logo.png",
    "$appFolderLocation\app\resources\img\assessment_report_logo_white.png",
    "$appFolderLocation\app\resources\img\riskview_logo.png",
    "$appFolderLocation\app\resources\img\riskview_logo_white.png",
    "$appFolderLocation\app\resources\img\riskview_report_logo.png",
    "$appFolderLocation\app\resources\img\riskview_report_logo_2.png",
    "$appFolderLocation\app\resources\img\tileEntity_address.png",
    "$appFolderLocation\app\resources\img\tileEntity_bci_risk.png",
    "$appFolderLocation\app\resources\img\tileEntity_behaviour_risk.png",
    "$appFolderLocation\app\resources\img\tileEntity_credit_card.png",
    "$appFolderLocation\app\resources\img\tileEntity_email_address.png",
    "$appFolderLocation\app\resources\img\tileEntity_gdpr_low_risk.png",
    "$appFolderLocation\app\resources\img\tileEntity_gdpr_major_term.png",
    "$appFolderLocation\app\resources\img\tileEntity_gdpr_minor_term.png",
    "$appFolderLocation\app\resources\img\tileEntity_gdpr_risk.png",
    "$appFolderLocation\app\resources\img\tileEntity_iban_number.png",
    "$appFolderLocation\app\resources\img\tileEntity_national_insurance.png",
    "$appFolderLocation\app\resources\img\tileEntity_non-corporate_address.png",
    "$appFolderLocation\app\resources\img\tileEntity_organisations.png",
    "$appFolderLocation\app\resources\img\tileEntity_pci_risk.png",
    "$appFolderLocation\app\resources\img\tileEntity_people.png",
    "$appFolderLocation\app\resources\img\tileEntity_phishing_risk.png",
    "$appFolderLocation\app\resources\img\tileEntity_phone_number.png",
    "$appFolderLocation\app\resources\img\tileEntity_postcode.png",
    "$appFolderLocation\app\resources\img\tileEntity_security_risk.png",
    "$appFolderLocation\app\resources\img\tileEntity_swift_number.png",
    "$appFolderLocation\app\resources\img\tileEntity_uk_bank_account.png",
    "$appFolderLocation\app\resources\img\tileEntity_uk_car_registration.png",
    "$appFolderLocation\app\resources\img\tileEntity_uk_driving_licence.png",
    "$appFolderLocation\app\resources\img\triangle.png",
    "$appFolderLocation\app\resources\addressCues.csv",
    "$appFolderLocation\app\resources\fileExclusions.tsv",
    "$appFolderLocation\app\resources\swiftcodes.txt",
    "$appFolderLocation\app\tomahawk\batik-awt-util-1.6-1.jar",
    "$appFolderLocation\app\tomahawk\batik-ext-1.6-1.jar",
    "$appFolderLocation\app\tomahawk\batik-gui-util-1.6-1.jar",
    "$appFolderLocation\app\tomahawk\batik-util-1.6-1.jar",
    "$appFolderLocation\app\tomahawk\commons-beanutils-1.7.0.jar",
    "$appFolderLocation\app\tomahawk\commons-collections-3.2.1.jar",
    "$appFolderLocation\app\tomahawk\commons-digester-1.6.jar",
    "$appFolderLocation\app\tomahawk\commons-el-1.0.jar",
    "$appFolderLocation\app\tomahawk\commons-fileupload-1.2.1.jar",
    "$appFolderLocation\app\tomahawk\commons-validator-1.3.1.jar",
    "$appFolderLocation\app\tomahawk\oro-2.0.8.jar",
    "$appFolderLocation\app\tomahawk\tomahawk20-1.1.14.jar",
    "$appFolderLocation\app\tomahawk\xmlParserAPIs-2.0.2.jar",
    "$appFolderLocation\app\twitter4j\twitter4j-core-3.0.5.jar",
    "$appFolderLocation\app\activation.jar",
    "$appFolderLocation\app\aopalliance.jar",
    "$appFolderLocation\app\apache-mime4j-core.jar",
    "$appFolderLocation\app\apache-mime4j-dom.jar",
    "$appFolderLocation\app\asm.jar",
    "$appFolderLocation\app\aspectjweaver.jar",
    "$appFolderLocation\app\bcmail-jdk15on.jar",
    "$appFolderLocation\app\bcpkix-jdk15on.jar",
    "$appFolderLocation\app\bcprov-jdk15on.jar",
    "$appFolderLocation\app\boilerpipe.jar",
    "$appFolderLocation\app\cdm.jar",
    "$appFolderLocation\app\classloader-leak-prevention.jar",
    "$appFolderLocation\app\classmate.jar",
    "$appFolderLocation\app\cngram.jar",
    "$appFolderLocation\app\commons-codec.jar",
    "$appFolderLocation\app\commons-collections.jar",
    "$appFolderLocation\app\commons-collections4.jar",
    "$appFolderLocation\app\commons-compress.jar",
    "$appFolderLocation\app\commons-csv.jar",
    "$appFolderLocation\app\commons-dbcp2.jar",
    "$appFolderLocation\app\commons-exec.jar",
    "$appFolderLocation\app\commons-io.jar",
    "$appFolderLocation\app\commons-lang.jar",
    "$appFolderLocation\app\commons-lang3.jar",
    "$appFolderLocation\app\commons-pool2.jar",
    "$appFolderLocation\app\commons-vfs2.jar",
    "$appFolderLocation\app\cxf-rt-rs-client.jar",
    "$appFolderLocation\app\dbunit.jar",
    "$appFolderLocation\app\disruptor.jar",
    "$appFolderLocation\app\ews-java-api.jar",
    "$appFolderLocation\app\fontbox.jar",
    "$appFolderLocation\app\fr.opensagres.poi.xwpf.converter.core.jar",
    "$appFolderLocation\app\fr.opensagres.poi.xwpf.converter.xhtml.jar",
    "$appFolderLocation\app\freemarker.jar",
    "$appFolderLocation\app\geoapi.jar",
    "$appFolderLocation\app\grib.jar",
    "$appFolderLocation\app\gson.jar",
    "$appFolderLocation\app\guava.jar",
    "$appFolderLocation\app\hamcrest-core.jar",
    "$appFolderLocation\app\hamcrest-library.jar",
    "$appFolderLocation\app\harvest-pg.jar",
    "$appFolderLocation\app\hibernate-validator.jar",
    "$appFolderLocation\app\HikariCP-1.4.0.jar",
    "$appFolderLocation\app\hsqldb.jar",
    "$appFolderLocation\app\htmlcleaner-2.2.jar",
    "$appFolderLocation\app\httpasyncclient.jar",
    "$appFolderLocation\app\httpclient.jar",
    "$appFolderLocation\app\httpcore-nio.jar",
    "$appFolderLocation\app\httpcore.jar",
    "$appFolderLocation\app\httpservices.jar",
    "$appFolderLocation\app\icu4j.jar",
    "$appFolderLocation\app\isoparser.jar",
    "$appFolderLocation\app\itextpdf.jar",
    "$appFolderLocation\app\jackcess-encrypt.jar",
    "$appFolderLocation\app\jackcess.jar",
    "$appFolderLocation\app\jackson-annotations.jar",
    "$appFolderLocation\app\jackson-core.jar",
    "$appFolderLocation\app\jackson-databind.jar",
    "$appFolderLocation\app\jackson-datatype-jdk8.jar",
    "$appFolderLocation\app\jackson-datatype-jsr310.jar",
    "$appFolderLocation\app\jai-imageio-core.jar",
    "$appFolderLocation\app\java-uuid-generator.jar",
    "$appFolderLocation\app\javassist.jar",
    "$appFolderLocation\app\javax.faces.jar",
    "$appFolderLocation\app\javax.inject.jar",
    "$appFolderLocation\app\jawr-core.jar",
    "$appFolderLocation\app\jawr-spring-extension.jar",
    "$appFolderLocation\app\jbig2-imageio.jar",
    "$appFolderLocation\app\jcl-over-slf4j.jar",
    "$appFolderLocation\app\jcommon.jar",
    "$appFolderLocation\app\jdom-1.0.jar",
    "$appFolderLocation\app\jdom.jar",
    "$appFolderLocation\app\jempbox.jar",
    "$appFolderLocation\app\jest-common.jar",
    "$appFolderLocation\app\jest.jar",
    "$appFolderLocation\app\jfreechart.jar",
    "$appFolderLocation\app\jmatio.jar",
    "$appFolderLocation\app\jna-platform.jar",
    "$appFolderLocation\app\jna.jar",
    "$appFolderLocation\app\jnode-fs.jar",
    "$appFolderLocation\app\joda-time.jar",
    "$appFolderLocation\app\jpedal_lgpl.jar",
    "$appFolderLocation\app\junit.jar",
    "$appFolderLocation\app\juniversalchardet.jar",
    "$appFolderLocation\app\junrar.jar",
    "$appFolderLocation\app\log4j-api.jar",
    "$appFolderLocation\app\log4j-core.jar",
    "$appFolderLocation\app\log4j-slf4j-impl.jar",
    "$appFolderLocation\app\log4j.jar",
    "$appFolderLocation\app\lucene-analyzers-common.jar",
    "$appFolderLocation\app\lucene-core.jar",
    "$appFolderLocation\app\lucene-queryparser.jar",
    "$appFolderLocation\app\mail.jar",
    "$appFolderLocation\app\metadata-extractor.jar",
    "$appFolderLocation\app\metrics-annotation.jar",
    "$appFolderLocation\app\metrics-core.jar",
    "$appFolderLocation\app\metrics-healthchecks.jar",
    "$appFolderLocation\app\metrics-json.jar",
    "$appFolderLocation\app\metrics-servlet.jar",
    "$appFolderLocation\app\metrics-servlets.jar",
    "$appFolderLocation\app\metrics-spring.jar",
    "$appFolderLocation\app\mmpt.jar",
    "$appFolderLocation\app\mock-javamail.jar",
    "$appFolderLocation\app\mockito-core.jar",
    "$appFolderLocation\app\mybatis-spring.jar",
    "$appFolderLocation\app\mybatis.jar",
    "$appFolderLocation\app\nekohtml-1.9.18.jar",
    "$appFolderLocation\app\netcdf4.jar",
    "$appFolderLocation\app\objenesis.jar",
    "$appFolderLocation\app\omnifaces-1.3.jar",
    "$appFolderLocation\app\ooxml-schemas.jar",
    "$appFolderLocation\app\opennlp-tools.jar",
    "$appFolderLocation\app\org.json.jar",
    "$appFolderLocation\app\oshi-core.jar",
    "$appFolderLocation\app\outpost.jar",
    "$appFolderLocation\app\pdfbox-tools.jar",
    "$appFolderLocation\app\pdfbox.jar",
    "$appFolderLocation\app\poi-ooxml-schemas.jar",
    "$appFolderLocation\app\poi-ooxml.jar",
    "$appFolderLocation\app\poi-scratchpad.jar",
    "$appFolderLocation\app\poi.jar",
    "$appFolderLocation\app\postgresql.jar",
    "$appFolderLocation\app\powermock-api-mockito-common.jar",
    "$appFolderLocation\app\powermock-api-mockito.jar",
    "$appFolderLocation\app\powermock-api-support.jar",
    "$appFolderLocation\app\powermock-core.jar",
    "$appFolderLocation\app\powermock-module-junit4-common.jar",
    "$appFolderLocation\app\powermock-module-junit4.jar",
    "$appFolderLocation\app\powermock-reflect.jar",
    "$appFolderLocation\app\rhino.jar",
    "$appFolderLocation\app\RiskView-CS.cfg",
    "$appFolderLocation\app\rome-1.0.jar",
    "$appFolderLocation\app\rome-modules-1.0.jar",
    "$appFolderLocation\app\rome.jar",
    "$appFolderLocation\app\servlet-api.jar",
    "$appFolderLocation\app\slf4j-api.jar",
    "$appFolderLocation\app\spring-aop.jar",
    "$appFolderLocation\app\spring-beans.jar",
    "$appFolderLocation\app\spring-context-support.jar",
    "$appFolderLocation\app\spring-context.jar",
    "$appFolderLocation\app\spring-core.jar",
    "$appFolderLocation\app\spring-expression.jar",
    "$appFolderLocation\app\spring-jdbc.jar",
    "$appFolderLocation\app\spring-orm.jar",
    "$appFolderLocation\app\spring-retry.jar",
    "$appFolderLocation\app\spring-test-dbunit.jar",
    "$appFolderLocation\app\spring-test.jar",
    "$appFolderLocation\app\spring-tx.jar",
    "$appFolderLocation\app\spring-web.jar",
    "$appFolderLocation\app\spring-webmvc.jar",
    "$appFolderLocation\app\sqlite-jdbc.jar",
    "$appFolderLocation\app\sqljdbc42.jar",
    "$appFolderLocation\app\super-csv.jar",
    "$appFolderLocation\app\tagsoup.jar",
    "$appFolderLocation\app\tika-core.jar",
    "$appFolderLocation\app\tika-parsers.jar",
    "$appFolderLocation\app\twitter-text-1.6.1.jar",
    "$appFolderLocation\app\urlbuilder.jar",
    "$appFolderLocation\app\validation-api.jar",
    "$appFolderLocation\app\vorbis-java-core.jar",
    "$appFolderLocation\app\vorbis-java-tika.jar",
    "$appFolderLocation\app\xercesImpl-2.10.0.jar",
    "$appFolderLocation\app\xml-apis-1.4.01.jar",
    "$appFolderLocation\app\xmlbeans.jar",
    "$appFolderLocation\app\xmpcore.jar",
    "$appFolderLocation\app\xz.jar",
    "$appFolderLocation\runtime\bin\plugin2\msvcr100.dll",
    "$appFolderLocation\runtime\bin\plugin2\npjp2.dll",
    "$appFolderLocation\runtime\bin\server\classes.jsa",
    "$appFolderLocation\runtime\bin\server\jvm.dll",
    "$appFolderLocation\runtime\bin\server\Xusage.txt",
    "$appFolderLocation\runtime\bin\api-ms-win-core-console-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-datetime-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-debug-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-errorhandling-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-file-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-file-l1-2-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-file-l2-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-handle-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-heap-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-interlocked-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-libraryloader-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-localization-l1-2-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-memory-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-namedpipe-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-processenvironment-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-processthreads-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-processthreads-l1-1-1.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-profile-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-rtlsupport-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-string-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-synch-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-synch-l1-2-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-sysinfo-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-timezone-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-core-util-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-conio-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-convert-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-environment-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-filesystem-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-heap-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-locale-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-math-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-multibyte-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-private-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-process-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-runtime-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-stdio-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-string-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-time-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\api-ms-win-crt-utility-l1-1-0.dll",
    "$appFolderLocation\runtime\bin\attach.dll",
    "$appFolderLocation\runtime\bin\awt.dll",
    "$appFolderLocation\runtime\bin\bci.dll",
    "$appFolderLocation\runtime\bin\concrt140.dll",
    "$appFolderLocation\runtime\bin\dcpr.dll",
    "$appFolderLocation\runtime\bin\decora_sse.dll",
    "$appFolderLocation\runtime\bin\deploy.dll",
    "$appFolderLocation\runtime\bin\dt_shmem.dll",
    "$appFolderLocation\runtime\bin\dt_socket.dll",
    "$appFolderLocation\runtime\bin\fontmanager.dll",
    "$appFolderLocation\runtime\bin\fxplugins.dll",
    "$appFolderLocation\runtime\bin\glass.dll",
    "$appFolderLocation\runtime\bin\glib-lite.dll",
    "$appFolderLocation\runtime\bin\gstreamer-lite.dll",
    "$appFolderLocation\runtime\bin\hprof.dll",
    "$appFolderLocation\runtime\bin\instrument.dll",
    "$appFolderLocation\runtime\bin\j2pcsc.dll",
    "$appFolderLocation\runtime\bin\j2pkcs11.dll",
    "$appFolderLocation\runtime\bin\jaas_nt.dll",
    "$appFolderLocation\runtime\bin\java.dll",
    "$appFolderLocation\runtime\bin\JavaAccessBridge-64.dll",
    "$appFolderLocation\runtime\bin\javafx_font.dll",
    "$appFolderLocation\runtime\bin\javafx_font_t2k.dll",
    "$appFolderLocation\runtime\bin\javafx_iio.dll",
    "$appFolderLocation\runtime\bin\java_crw_demo.dll",
    "$appFolderLocation\runtime\bin\jawt.dll",
    "$appFolderLocation\runtime\bin\JAWTAccessBridge-64.dll",
    "$appFolderLocation\runtime\bin\jdwp.dll",
    "$appFolderLocation\runtime\bin\jfr.dll",
    "$appFolderLocation\runtime\bin\jfxmedia.dll",
    "$appFolderLocation\runtime\bin\jfxwebkit.dll",
    "$appFolderLocation\runtime\bin\jli.dll",
    "$appFolderLocation\runtime\bin\jpeg.dll",
    "$appFolderLocation\runtime\bin\jsdt.dll",
    "$appFolderLocation\runtime\bin\jsound.dll",
    "$appFolderLocation\runtime\bin\jsoundds.dll",
    "$appFolderLocation\runtime\bin\kcms.dll",
    "$appFolderLocation\runtime\bin\lcms.dll",
    "$appFolderLocation\runtime\bin\management.dll",
    "$appFolderLocation\runtime\bin\mlib_image.dll",
    "$appFolderLocation\runtime\bin\msvcp140.dll",
    "$appFolderLocation\runtime\bin\msvcr100.dll",
    "$appFolderLocation\runtime\bin\net.dll",
    "$appFolderLocation\runtime\bin\nio.dll",
    "$appFolderLocation\runtime\bin\npt.dll",
    "$appFolderLocation\runtime\bin\prism_common.dll",
    "$appFolderLocation\runtime\bin\prism_d3d.dll",
    "$appFolderLocation\runtime\bin\prism_sw.dll",
    "$appFolderLocation\runtime\bin\resource.dll",
    "$appFolderLocation\runtime\bin\sawindbg.dll",
    "$appFolderLocation\runtime\bin\splashscreen.dll",
    "$appFolderLocation\runtime\bin\sunec.dll",
    "$appFolderLocation\runtime\bin\sunmscapi.dll",
    "$appFolderLocation\runtime\bin\t2k.dll",
    "$appFolderLocation\runtime\bin\ucrtbase.dll",
    "$appFolderLocation\runtime\bin\unpack.dll",
    "$appFolderLocation\runtime\bin\vcruntime140.dll",
    "$appFolderLocation\runtime\bin\verify.dll",
    "$appFolderLocation\runtime\bin\w2k_lsa_auth.dll",
    "$appFolderLocation\runtime\bin\WindowsAccessBridge-64.dll",
    "$appFolderLocation\runtime\bin\zip.dll",
    "$appFolderLocation\runtime\lib\amd64\jvm.cfg",
    "$appFolderLocation\runtime\lib\cmm\CIEXYZ.pf",
    "$appFolderLocation\runtime\lib\cmm\GRAY.pf",
    "$appFolderLocation\runtime\lib\cmm\LINEAR_RGB.pf",
    "$appFolderLocation\runtime\lib\cmm\PYCC.pf",
    "$appFolderLocation\runtime\lib\cmm\sRGB.pf",
    "$appFolderLocation\runtime\lib\ext\access-bridge-64.jar",
    "$appFolderLocation\runtime\lib\ext\cldrdata.jar",
    "$appFolderLocation\runtime\lib\ext\dnsns.jar",
    "$appFolderLocation\runtime\lib\ext\jaccess.jar",
    "$appFolderLocation\runtime\lib\ext\jfxrt.jar",
    "$appFolderLocation\runtime\lib\ext\localedata.jar",
    "$appFolderLocation\runtime\lib\ext\meta-index",
    "$appFolderLocation\runtime\lib\ext\nashorn.jar",
    "$appFolderLocation\runtime\lib\ext\sunec.jar",
    "$appFolderLocation\runtime\lib\ext\sunjce_provider.jar",
    "$appFolderLocation\runtime\lib\ext\sunmscapi.jar",
    "$appFolderLocation\runtime\lib\ext\sunpkcs11.jar",
    "$appFolderLocation\runtime\lib\ext\zipfs.jar",
    "$appFolderLocation\runtime\lib\fonts\LucidaBrightDemiBold.ttf",
    "$appFolderLocation\runtime\lib\fonts\LucidaBrightDemiItalic.ttf",
    "$appFolderLocation\runtime\lib\fonts\LucidaBrightItalic.ttf",
    "$appFolderLocation\runtime\lib\fonts\LucidaBrightRegular.ttf",
    "$appFolderLocation\runtime\lib\fonts\LucidaSansDemiBold.ttf",
    "$appFolderLocation\runtime\lib\fonts\LucidaSansRegular.ttf",
    "$appFolderLocation\runtime\lib\fonts\LucidaTypewriterBold.ttf",
    "$appFolderLocation\runtime\lib\fonts\LucidaTypewriterRegular.ttf",
    "$appFolderLocation\runtime\lib\images\cursors\cursors.properties",
    "$appFolderLocation\runtime\lib\images\cursors\invalid32x32.gif",
    "$appFolderLocation\runtime\lib\images\cursors\win32_CopyDrop32x32.gif",
    "$appFolderLocation\runtime\lib\images\cursors\win32_CopyNoDrop32x32.gif",
    "$appFolderLocation\runtime\lib\images\cursors\win32_LinkDrop32x32.gif",
    "$appFolderLocation\runtime\lib\images\cursors\win32_LinkNoDrop32x32.gif",
    "$appFolderLocation\runtime\lib\images\cursors\win32_MoveDrop32x32.gif",
    "$appFolderLocation\runtime\lib\images\cursors\win32_MoveNoDrop32x32.gif",
    "$appFolderLocation\runtime\lib\jfr\default.jfc",
    "$appFolderLocation\runtime\lib\jfr\profile.jfc",
    "$appFolderLocation\runtime\lib\management\jmxremote.access",
    "$appFolderLocation\runtime\lib\management\jmxremote.password.template",
    "$appFolderLocation\runtime\lib\management\management.properties",
    "$appFolderLocation\runtime\lib\management\snmp.acl.template",
    "$appFolderLocation\runtime\lib\security\policy\limited\local_policy.jar",
    "$appFolderLocation\runtime\lib\security\policy\limited\US_export_policy.jar",
    "$appFolderLocation\runtime\lib\security\policy\unlimited\local_policy.jar",
    "$appFolderLocation\runtime\lib\security\policy\unlimited\US_export_policy.jar",
    "$appFolderLocation\runtime\lib\security\blacklist",
    "$appFolderLocation\runtime\lib\security\blacklisted.certs",
    "$appFolderLocation\runtime\lib\security\cacerts",
    "$appFolderLocation\runtime\lib\security\java.policy",
    "$appFolderLocation\runtime\lib\security\java.security",
    "$appFolderLocation\runtime\lib\security\javaws.policy",
    "$appFolderLocation\runtime\lib\security\trusted.libraries",
    "$appFolderLocation\runtime\lib\accessibility.properties",
    "$appFolderLocation\runtime\lib\calendars.properties",
    "$appFolderLocation\runtime\lib\charsets.jar",
    "$appFolderLocation\runtime\lib\classlist",
    "$appFolderLocation\runtime\lib\content-types.properties",
    "$appFolderLocation\runtime\lib\currency.data",
    "$appFolderLocation\runtime\lib\flavormap.properties",
    "$appFolderLocation\runtime\lib\fontconfig.bfc",
    "$appFolderLocation\runtime\lib\fontconfig.properties.src",
    "$appFolderLocation\runtime\lib\hijrah-config-umalqura.properties",
    "$appFolderLocation\runtime\lib\javafx.properties",
    "$appFolderLocation\runtime\lib\javaws.jar",
    "$appFolderLocation\runtime\lib\jce.jar",
    "$appFolderLocation\runtime\lib\jfr.jar",
    "$appFolderLocation\runtime\lib\jfxswt.jar",
    "$appFolderLocation\runtime\lib\jsse.jar",
    "$appFolderLocation\runtime\lib\jvm.hprof.txt",
    "$appFolderLocation\runtime\lib\logging.properties",
    "$appFolderLocation\runtime\lib\management-agent.jar",
    "$appFolderLocation\runtime\lib\meta-index",
    "$appFolderLocation\runtime\lib\net.properties",
    "$appFolderLocation\runtime\lib\plugin.jar",
    "$appFolderLocation\runtime\lib\psfont.properties.ja",
    "$appFolderLocation\runtime\lib\psfontj2d.properties",
    "$appFolderLocation\runtime\lib\resources.jar",
    "$appFolderLocation\runtime\lib\rt.jar",
    "$appFolderLocation\runtime\lib\sound.properties",
    "$appFolderLocation\runtime\lib\tzdb.dat",
    "$appFolderLocation\runtime\lib\tzmappings"





# Sets the userchoice to zero to start the loop
$userChoice = ""
# Gets the current Access Level
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Runs on startup
checkRiskViewFiles
$buffertable = New-Object system.Data.DataTable "RiskView Thread Buffer"
[void]$buffertable.Columns.Add("Thread")
[void]$buffertable.Columns.Add("FileNumber")
[void]$buffertable.Columns.Add("Filename")
[void]$buffertable.Columns.Add("FilePath")
[regex]$procfileRegex = ".* Processing file: [0-9]* .*"


# This is the user main input loop, can only exit the loop with b
while ($userChoice -ne "b") {
    $userChoice = ""
    $userChoice = userChoicesList "What would you like to do: " "Main Menu"
    choiceExceptions $userChoice
    mainChoices $userChoice
}
