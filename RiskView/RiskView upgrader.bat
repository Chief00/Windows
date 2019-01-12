@echo off

echo       ___  _     __  _   ___              
echo      / _ \(_)__ / /_^| ^| / (_)__ _    __   
echo     / , _/ (_-^</  '_/ ^|/ / / -_) ^|/^|/ /   
echo    /_/^|_/_/___/_/\_\^|___/_/\__/^|__,__/    
echo      __  __                      __       
echo     / / / /__  ___ ________ ____/ /__ ____
echo    / /_/ / _ \/ _ `/ __/ _ `/ _  / -_) __/
echo    \____/ .__/\_, /_/  \_,_/\_,_/\__/_/   
echo        /_/   /___/                                             
echo.
echo.

 
if NOT "%1"=="" (
	wmic product where "name like 'RiskView-CS'" call uninstall
	wmic product where "name like 'OutPost'" call uninstall
	RD /Q /S "%userprofile%/AppData/Local/RiskView-CS/resources"
	wmic product call install true, "", "%~dp0\RiskView-CS-%1-64bit.msi"
) ELSE (
	set /p version="What is the version number you want to upgrade to: "
	wmic product where "name like 'RiskView-CS'" call uninstall
	wmic product where "name like 'OutPost'" call uninstall
	RD /Q /S "%userprofile%/AppData/Local/RiskView-CS/resources"
	wmic product call install true, "", "%~dp0\RiskView-CS-%version%-64bit.msi"
)