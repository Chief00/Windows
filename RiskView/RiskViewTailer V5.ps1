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

function choiceLoop ($Low, $High, $userFunction){
    $choice = ""
	while (($choice -lt $Low) -or ($choice -gt $High)){
        $choice = $userFunction
	}
}

function userChoicesList ($title, $choiceArray) {

    Write-Host $title `n
    for ($i = 0; $i -lt $choiceArray.length; $i++) {
        Write-Host "[$i]" $choiceArray[$i]
    }
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


function logChoice ($choice){

    if ($choice -eq "Since App Opened")  {
        get-content riskview-cs.log -Wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1) - (select-string riskview-cs.log -Pattern "main info" | select-object -ExpandProperty 'LineNumber' -Last 1)+1)
    }

    if ($choice -eq "Since Last Gather")  {
        get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1)
    }

    if ($choice -eq "Never")   {
        get-content riskview-cs.log -wait -Tail 0
    }

    if ($choice -eq "All"){
        get-content riskview-cs.log -wait
    }

    if ($choice -eq "Search"){
        $subChoice = ""
        while (($subChoice -lt 0) -or ($subChoice -gt $searchSubChoiceArray.length)){
            $subChoice = searchSubChoice
            if (($subChoice -lt 0) -or ($subChoice -gt $searchSubChoiceArray.length)){
                continue
            }
            $subChoice = logSearchChoice $searchSubChoiceArray[$subChoice]
        }
    }


    if ($choice -eq "Ram Usage"){
        get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains("Current Free Memory")}
    }

    if ($choice -eq "Current File"){
        get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains("[FileGathererToItems] Processing file") -Or $_.contains("[TikaFileGathererBase] File Excluded")}
    }
}

function logSearchChoice ($subChoice) {

    if ($subChoice -eq "Simple"){

        $userString = Read-Host "What do you want to search? "
        select-string riskview-cs.log -Pattern $userString -Context 0, 2

        $ynLoop = Read-Host "Do you want to search something else? (y or n)"
        if ($ynLoop -eq "y") {
            $ynLoop = ""
        }else {$ynLoop = 0}

    }
    if ($subChoice -eq "Extra"){

            $userString = Read-Host "What do you want to search? "
            $extraLines = Read-Host "How many extra lines do you want to print? "
            select-string riskview-cs.log -Pattern $userString -Context 0, $extraLines

            $ynLoop = Read-Host "Do you want to search something else? (y or n)"
            if ($ynLoop -eq "y") {
                $ynLoop = ""
            }else {$ynLoop = 0}
    }
    if ($subChoice -eq "Tailing"){
        $ynLoop = 0
        ""
        "This is case sensitive"
        $userString = Read-Host "What do you want to search? "
        get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains($userString)}
    }

    return $ynLoop
}

function choiceHelp {
    cls
    Write-Host "Hello"
    Read-Host "Press Enter to continue "
}

# This is the user main input loop
$userChoice = ""
$choiceArray = "Since App Opened", "Since Last Gather", "Never", "All", "Search", "Ram Usage", "Current File"
$searchSubChoiceArray = "Simple", "Extra", "Tailing"
while (($userChoice -lt 0) -or ($userChoice -gt $choiceArray.length-1)){
    $userChoice = ""
    $userChoice = $(mainChoice)
    if ($userChoice -eq "?"){
        choiceHelp
    }elseif (($userChoice -lt 0) -or ($userChoice -gt $choiceArray.length-1)){
        continue
    }
    logChoice $choiceArray[$userChoice]
}



# Add cool graphics
# Add choice to describe the choices
# Look at other logs
# AND searching
# Quit feature
# Integers only, and yn only
