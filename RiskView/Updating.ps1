
rm RiskViewTailor.ps1
$downloadURL = "https://raw.githubusercontent.com/Chief00/Windows/master/RiskView/RiskViewTailor.ps1"
Invoke-WebRequest $downloadURL -OutFile RiskViewTailor.ps1
Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force
