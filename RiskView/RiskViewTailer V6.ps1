

# To add a new option, add it to the choiceArray or relevent subchoicearray
# Then add the code for the option in the relevent logchoice
# Then add the description to the relevent choiceArrayDesc

function printLogo {
Write-Host "
           ___  _     __  _   ___
          / _ \(_)__ / /_| | / (_)__ _    __
         / , _/ (_-</  '_/ |/ / / -_) |/|/ /
        /_/|_/_/___/_/\_\|___/_/\__/|__,__/
        /_  __/__ _(_) /__ ____
         / / / _ '/ / / -_) __/
        /_/  \_,_/_/_/\__/_/


"
}

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
}

function userChoicesList ($title, $choiceArray) {

    cls
    printLogo

    Write-Host $title `n
    for ($i = 0; $i -lt $choiceArray.length; $i++) {
        Write-Host "[$i]" $choiceArray[$i]
    }
    Write-Host "[?] Help"
    $choice = Read-Host "`n`nWhat do you choose? "
    return $choice
}

function searchSubChoice {

    cls
    printLogo
    $choice = userChoicesList "What type of search: " $searchSubChoiceArray
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


function logChoice ($choice){
    cd C:\Users\$([Environment]::UserName)\AppData\Local\Temp

    if ($choice -eq "Run App") {
        $subChoice = ""
        while (($subChoice -lt 0) -or ($subChoice -gt $appopenedSubChoiceArray.length)) {
            $subChoice = userChoicesList "How would you like to run the app: " $runAppSubChoiceArray
            choiceExceptions $choice $subChoice
            logRunAPPChoice $runAppSubChoiceArray[$subChoice]
        }
        $choice = ""
    }

    if ($choice -eq "App Opened") {
        get-content riskview-cs.log -Wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1) - (select-string riskview-cs.log -Pattern "RiskView CS Version" | select-object -ExpandProperty 'LineNumber' -Last 1)+1)
    }

    if ($choice -eq "Last Gather") {
        get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1)
    }

    if ($choice -eq "Never") {
        get-content riskview-cs.log -wait -Tail 0
    }

    if ($choice -eq "All"){
        get-content riskview-cs.log -wait
    }

    if ($choice -eq "Search") {
        $subChoice = ""
        while (($subChoice -lt 0) -or ($subChoice -gt $searchSubChoiceArray.length)) {
            $subChoice = userChoicesList "How do you want to search: " $searchSubChoiceArray
            choiceExceptions $choice $subChoice
            logSearchChoice $searchSubChoiceArray[$subChoice]
        }
        $choice = ""
    }


    if ($choice -eq "Ram Usage") {
        get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains("Current Free Memory")}
    }

    if ($choice -eq "Current File") {
        get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains("[FileGathererToItems] Processing file") -Or $_.contains("[TikaFileGathererBase] File Excluded")}
    }
    return $choice
}

function logSearchChoice ($subChoice) {

    if ($subChoice -eq "Simple") {

        $userString = Read-Host "What do you want to search? "
        if (($userString -eq "b") -or ($userString -eq "")) {return ""}
        select-string riskview-cs.log -Pattern $userString
        Read-Host "`nPress anything to return"
    }
    if ($subChoice -eq "Extra") {

        $userString = Read-Host "What do you want to search? "
        if (($userString -eq "b") -or ($userString -eq "")) {return ""}
        $extraLines = Read-Host "How many extra lines do you want to print? "
        if (($extraLines -eq "b") -or ($userString -eq "")) {return ""}
        select-string riskview-cs.log -Pattern $userString -Context 0, $extraLines
        Read-Host "`nPress anything to return"
    }
    if ($subChoice -eq "Tailing") {
        $ynLoop = 0
        ""
        "This is case sensitive"
        $userString = Read-Host "What do you want to search? "
        if (($userString -eq "b") -or ($userString -eq "")) {return ""}
        get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains($userString)}
    }
}

function logRunAPPChoice ($subChoice) {
    cd "C:/Program Files/RiskView-CS"

    if ($subChoice -eq "Gui") {
        .\RiskView-CS.exe
    }

    if ($subChoice -eq "NoGui") {

        $serverLink = Read-Host "What is the server link "
        $scanLocation = Read-Host "Where is the location you want to scan "
        [regex]$regex = "\w{8}-(\w{4}-){3}\w{12}"
        $GUID = $regex.Matches($serverLink) | foreach-object {$_.value}
        if (Test-Path C:\Users\$([Environment]::UserName)\AppData\Local\RiskView-CS\Resources\$GUID) {
            $removeLastScan = Read-Host "Do you want to remove the last scan data (y/n)"
            if ($removeLastScan -eq "y") {
                cd C:\Users\$([Environment]::UserName)\AppData\Local\RiskView-CS\Resources\$GUID
                rm ScanInfo.json
            }
        }
        cd "C:/Program Files/RiskView-CS"
        .\RiskView-CS.exe nogui $serverLink $scanLocation
    }
}



$choiceArray = "Run App","App Opened", "Last Gather", "Never", "All", "Search", "RAM Usage", "Current File"
$searchSubChoiceArray = "Simple", "Extra", "Tailing"
$runAppSubChoiceArray = "Gui","NoGui"

$choiceArrayDesc =
"This will run the app, and reset this screen for tailing options",
"This will display the log since the app was opened and then tail it.",
"This will display the log since the last gather was run and then tail it.",
"This will just tail the log from the last line, not showing the log previous to the last line.",
"This will display the whole log and then tail it.",
"You can search the log for phrases.",
"This will tail the log for the RAM usage.",
"This will tail the log only displaying the current file being processed and any excluded files."

$searchSubChoiceArrayDesc =
"This will do a simple search in the log for a phrase.",
"This will do a search and display n extra lines after the matched phrases line.",
"This will search the log for the occurance of the phrase and display them all. `n    Then tail the log only displaying lines that contain the phrase.`n    This is CaSe SeNsItIvE!!"

$runAppSubChoiceArrayDesc =
"This will open the app with a General User Interface",
"This will run the app without a GUI and will run the commands via command line. `n    This will provide a simple User Interface to make it easier `n    Removing the last scan data will allow you to run a full scan as by defualt this `n     is set to scan files since the last scan was run"

# This is the user main input loop
$userChoice = ""

while ($choiceArray -NotContains $userChoice) {
    $userChoice = ""
    $userChoice = userChoicesList "What do you want to tail: " $choiceArray
    choiceExceptions $userChoice $subChoice
    logChoice $choiceArray[$userChoice]
}
