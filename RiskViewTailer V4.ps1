cd C:\Users\$([Environment]::UserName)\AppData\Local\Temp


function mainChoice {

Read-Host "

       ___  _     __  _   ___           
      / _ \(_)__ / /_| | / (_)__ _    __
     / , _/ (_-</  '_/ |/ / / -_) |/|/ /
    /_/|_/_/___/_/\_\|___/_/\__/|__,__/ 
    /_  __/__ _(_) /__ ____             
     / / / _ '/ / / -_) __/             
    /_/  \_,_/_/_/\__/_/                
                                    

 
Tail the log:
[1] Since App Opened
[2] Since Last Gather
[3] Never
[4] All
[5] Search - Simple
[6] Search - Extended
[7] Free Ram 
[8] Current File
[9] Search - Tail

What do you choose?"

}


function logChoice ($choice){

if ($choice -eq 1){
get-content riskview-cs.log -Wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1) - (select-string riskview-cs.log -Pattern "main info" | select-object -ExpandProperty 'LineNumber' -Last 1)+1)
}

if ($choice -eq 2){
get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1)
}

if ($choice -eq 3 -or ""){
get-content riskview-cs.log -wait -Tail 0
} 

if ($choice -eq 4){
get-content riskview-cs.log -wait
}

if ($choice -eq 5){
$ynLoop = "y"
while ($ynLoop -eq "y") {
$userString = Read-Host "What do you want to search? "
select-string riskview-cs.log -Pattern $userString -Context 0, 2

$ynLoop = Read-Host "Do you want to search something else? (y or n)"
}
}

if ($choice -eq 6){
$ynLoop = "y"
while ($ynLoop -eq "y") {
$userString = Read-Host "What do you want to search? "
$extraLines = Read-Host "How many extra lines do you want to print? "
select-string riskview-cs.log -Pattern $userString -Context 0, $extraLines

$ynLoop = Read-Host "Do you want to search something else? (y or n)"
}
}

if ($choice -eq 9){
""
"This is case sensitive"
$userString = Read-Host "What do you want to search? "
get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains($userString)}
}

if ($choice -eq 7){
get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains("Current Free Memory")}
}

if ($choice -eq 8){
get-content riskview-cs.log -wait -Tail ((select-string riskview-cs.log -Pattern ":" | select-object -ExpandProperty 'LineNumber' -Last 1)-(select-string riskview-cs.log -Pattern "Requesting project details" | select-object -ExpandProperty 'LineNumber' -Last 1)+1) | where {$_.contains("[FileGathererToItems] Processing file") -Or $_.contains("[TikaFileGathererBase] File Excluded")}
}
}



# This is the user input loop
$userChoice = 0
while (($userChoice -lt 1) -or ($userChoice -gt 9)){
$userChoice = 0
$userChoice = mainChoice
cls
}


logChoice $userChoice

# Add cool graphics
# Change search types to a sub choice instead of 2 main choices
# Add choice to describe the choices
# Look at other logs
# Search Tailing
# AND searching
# Quit feature