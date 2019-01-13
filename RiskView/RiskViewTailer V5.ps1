cd C:\Users\$([Environment]::UserName)\AppData\Local\Temp


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
}

function userChoicesList ($title, $choiceArray) {

    Write-Host $title `n
    for ($i = 0; $i -lt $choiceArray.length; $i++) {
        Write-Host "[$i]" $choiceArray[$i]
    }
    Write-Host "[?] Help"
    $choice = Read-Host "`n`nWhat do you choose? "
    return $choice
}

function mainChoice {

    cls
    printLogo
    $choice = userChoicesList "What do you want to tail: " $choiceArray
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

    if ($choice -eq "App Opened") {
        get-content riskview-cs.log -Wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1) - (select-string riskview-cs.log -Pattern "main info" | select-object -ExpandProperty 'LineNumber' -Last 1)+1)
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
            $subChoice = searchSubChoice
            choiceExceptions $choice $subChoice
            $subChoice = logSearchChoice $searchSubChoiceArray[$subChoice]
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
        if (($userString -eq "" -or "b")) {return ""}
        select-string riskview-cs.log -Pattern $userString -Context 0, 2

        $ynLoop = Read-Host "Do you want to search something else? (y or n)"
        if ($ynLoop -eq "y") {
            return ""
        }else {break}

    }
    if ($subChoice -eq "Extra") {

        $userString = Read-Host "What do you want to search? "
        if (($userString -eq "" -or "b")) {return ""}
        $extraLines = Read-Host "How many extra lines do you want to print? "
        if (($extraLines -eq "" -or "b")) {return ""}
        select-string riskview-cs.log -Pattern $userString -Context 0, $extraLines

        $ynLoop = Read-Host "Do you want to search something else? (y or n)"
        if ($ynLoop -eq "y") {
            return ""
        }else {break}
    }
    if ($subChoice -eq "Tailing") {
        $ynLoop = 0
        ""
        "This is case sensitive"
        $userString = Read-Host "What do you want to search? "
        get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains($userString)}
    }
}



$choiceArray = "App Opened", "Last Gather", "Never", "All", "Search", "RAM Usage", "Current File"
$searchSubChoiceArray = "Simple", "Extra", "Tailing"

$choiceArrayDesc =
"This will display the log since the app was opened and then tail it.",
"This will display the log since the last gather was run and then tail it.",
"This will just tail the log from the last line, not showing the log previous to the last line.",
"This will display the whole log and then tail it.",
"You can search the log for phrases.",
"This will tail the log for the RAM usage.",
"This will tail the log only displaying the current file being processed and any excluded files."

$searchSubChoiceArrayDesc=
"This will do a simple search in the log for a phrase.",
"This will do a search and display n extra lines after the matched phrases line.",
"This will search the log for the occurance of the phrase and display them all. `n    Then tail the log only displaying lines that contain the phrase.`n    This is CaSe SeNsItIvE!!"

# This is the user main input loop
$userChoice = ""

while ($choiceArray -NotContains $userChoice) {
    $userChoice = ""
    $userChoice = mainChoice
    choiceExceptions $userChoice $subChoice
    $userChoice = logChoice $choiceArray[$userChoice]
}



# Add cool graphics
# Look at other logs
# AND searching
# Integers only, and yn only
