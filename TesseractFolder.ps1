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
            $script:res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Would you like to try again or exit?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if($script:res -eq "Cancel")
            {
                #Ends script
                return
            }
        }
    }
    $browse.SelectedPath
    $browse.Dispose()
}

"FileNames will be messed up if they contain \"
$Folder = Select-Folder
cd $Folder

if ($script:res -ne "Cancel"){
    Get-ChildItem $Folder | Foreach-object {
        Tesseract $_.FullName $_.FullName.Split("\\")[$_.FullName.split("\\").length-1]
    }
}
