#Creates the SyncHash table
$Global:SyncHash = [hashtable]::Synchronized(@{})
# Sets the ScriptPath Variabel so the converted code can find the path the script is running from
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript"){$Global:syncHash.ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition }else{$Global:syncHash.ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])}
$Global:ScriptPath = $Global:syncHash.ScriptPath
# Loads the needed assembly for the theme to work
try {
	#imports the xaml
	#region dll
	$DLLPath = "$ScriptPath\Mainwindow.dll"
	$Secure = Get-Content $DLLPath | ConvertTo-SecureString -Key (136,64,54,48,143,47,20,22,56,49,162,26,187,38,152,62,103,0,167,125,171,100,148,117,119,108,121,33,120,19,14,132)
	$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
	$InputXML = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
	#endregion dll
	#region xaml
	# $InputXML = Get-Content "$GLOBAL:ScriptPath\Mainwindow.xaml" -ErrorAction Stop
	#endregion xaml
	[xml]$XAML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:Name",'Name' -replace '^<Win.*', '<Window'
	[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
	$Reader=(New-Object System.Xml.XmlNodeReader $XAML -ErrorAction Stop)
	$MainForm=[Windows.Markup.XamlReader]::Load($Reader)

} catch {Throw "Error: $_"}
# Adds all controls to the sync hash
$xaml.SelectNodes("//*[@Name]") | ForEach-Object{$Global:SyncHash."$($_.Name)" = $MainForm.FindName($_.Name)}
# Creats a variable as WPF_<VariableName> for each control
$xaml.SelectNodes("//*[@Name]") | ForEach-Object{ Set-Variable -Name "WPF_$($_.Name)" -Value $MainForm.FindName($_.Name)}
$Global:syncHash.MainForm = $MainForm

$Path = "$ScriptPath\SelectFolder.dll"
$secure = Get-Content $path | ConvertTo-SecureString -Key (176,131,72,138,100,90,82,89,94,51,112,85,30,118,196,79,17,63,80,62,47,123,102,158,198,84,61,67,137,179,6,12)
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
$SelectFolderCode = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
Invoke-Expression $SelectFolderCode | Out-Null

#Function to get ini file settins
function Get-IniFile{
	param([string]$filePath)
	$anonymous = "NoSection"
	$ini = @{}
	switch -regex -file "$filePath"{
	"^\[(.+)\]$"
		{
		   $section = $matches[1]
		   $ini[$section] = @{}
		   $CommentCount = 0
		 }

	   "^(;.*)$"
		{
			if (!(section)){
				$section = anonymous
				$ini[$section] = @{}
			}
			$value = $matches[1]
			$CommentCount = $CommentCount + 1
			$name = "Comment" + $CommentCount
			$ini[$section][$name] = $value
		}

		"(.+?)\s*=\s*(.*)"
		{
			if (!($section)){
				$section = $anonymous
				$ini[$section] = @{}
			}
			$name,$value = $matches[1..2]
			$ini[$section][$name] = $value
		}
	}
	return $ini
}

$Settings = Get-IniFile "$ScriptPath\Settings.ini"

#region variables
#endregion variables

#region funtions
#Function used to call in a new runspace
function Invoke-SeparateRunspace {
	param ([parameter(Mandatory=$true)]$Task)
	<#
	 tasks that update a control must be put into a control dispatcher
	 $Global:syncHash.OutputWindow.Dispatcher.Invoke({
		 $Global:syncHash.OutputWindow.AppendText("`nBeginning Operation: 'Start Button Pressed' `n")
	 })
	#>
	$newRunspace =[runspacefactory]::CreateRunspace()
	$newRunspace.ApartmentState = "STA"
	$newRunspace.ThreadOptions = "ReuseThread"
	$newRunspace.Open()
	$newRunspace.SessionStateProxy.SetVariable("SyncHash",$Global:SyncHash)
	$PowerShell = [PowerShell]::Create().AddScript($Task)
	$PowerShell.Runspace = $newRunspace
	$PowerShell.BeginInvoke()
}

function Get-ChildProcesses ($ParentProcessId) {
	$filter = "parentprocessid = '$($ParentProcessId)'"
	Get-CIMInstance -ClassName win32_process -filter $filter | Foreach-Object {
			if ($_.ParentProcessId -ne $_.ProcessId) {
				Get-ChildProcesses $_.ProcessId
			}
		}
}

function Stop-Script {
	# $rpid = (Get-ChildProcesses -ParentProcessId $([System.Diagnostics.Process]::GetCurrentProcess().Id) | Where {$_.Name -like "Robocopy*"}).ProcessId
	# Stop-Process -ID $rpid -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
	$WPFApp.Exit
	Stop-Process $([System.Diagnostics.Process]::GetCurrentProcess().Id) -Force
}

#Function to clear memory from an unused variable
function Clear-Memory {
	PARAM{[array]$Value}
	foreach ($Function:V in $Function:Value){Clear-Variable $Function:V}
	Clear-Variable -Scope function -Name Value
	[System.GC]::Collect()
}

#endregion functions

#region code

$WPF_Settings.Add_Click({
	try {
		#imports the xaml
		#region dll
		$DLLPath = "$Scriptpath\settings.dll"
		$Secure = Get-Content $DLLPath | ConvertTo-SecureString -Key (127,44,50,191,28,146,68,140,193,196,30,108,93,195,165,198,91,134,58,12,128,19,158,55,169,185,100,173,22,36,126,151)
		$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
		$InputXML2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		#endregion dll
		#region xaml
		# $InputXML2 = Get-Content "$GLOBAL:ScriptPath\Settings.xaml" -ErrorAction Stop
		#endregion xaml
		[xml]$XAML2 = $inputXML2 -replace 'mc:Ignorable="d"','' -replace "x:Name",'Name' -replace '^<Win.*', '<Window'
		$Reader2=(New-Object System.Xml.XmlNodeReader $XAML2 -ErrorAction Stop)
		$SettingsForm=[Windows.Markup.XamlReader]::Load($Reader2)
	} catch {Throw "Error: $_"}
	$xaml2.SelectNodes("//*[@Name]") | ForEach-Object{ Set-Variable -Name "SF_$($_.Name)" -Value $SettingsForm.FindName($_.Name)}

	$SF_STPreview.Background = $Settings.Settings.StatusText
	$SF_SBPreview.Background = $Settings.Settings.StatusBackgroud
	$SF_SPBPreview.Background = $Settings.Settings.StatusBar
	$SF_PBPreview.Background = $Settings.Settings.ProgressBar
	$SF_CheckForUpdates.IsChecked = $Settings.Settings.CheckForUpdates

	function Call-ColorPicker {
		param (
			$Start
		)
		$colorDialog = new-object System.Windows.Forms.ColorDialog
		$colorDialog.AllowFullOpen = $true
		[void]$colorDialog.ShowDialog()
		$Color = $colorDialog.Color.name
		IF ($Color -match '\d'){$Color = "#" + $Color}
		Return $Color
	}

	$SF_ok.Add_Click({
		Remove-Item "$ScriptPath\Settings.ini"
		New-Item -ItemType File "$ScriptPath\Settings.ini"
		$Content = @"
[Settings]
CheckForUpdates = $($SF_CheckForUpdates.IsChecked)
StatusText = $($SF_STPreview.Background)
StatusBackgroud = $($SF_SBPreview.Background)
StatusBar = $($SF_SPBPreview.Background )
ProgressBar = $($SF_PBPreview.Background)
"@
		Add-Content -Value $Content -Path "$ScriptPath\Settings.ini"
		$SettingsForm.Close()
	})

	$SF_STChange.Add_Click({$SF_STPreview.Background = Call-ColorPicker})
	$SF_SBChange.Add_Click({$SF_SBPreview.Background = Call-ColorPicker})
	$SF_SPBChange.Add_Click({$SF_SPBPreview.Background = Call-ColorPicker})
	$SF_PBChange.Add_Click({$SF_PBPreview.Background = Call-ColorPicker})

	$SF_Cancel.Add_Click({ $SettingsForm.Close()})
	[void]$SettingsForm.Focus()
	[void]$SettingsForm.ShowDialog()
})

$WPF_Help.Add_Click({
	$WPF_output.Clear()
	$WPF_output.AppendText("PowerCopy - V 4.0.0`n")
	$WPF_output.AppendText("Created By: MosaicMK Software LLC`n")
	$WPF_output.AppendText("Email: Contact@mosaicmk.com`n")
	$WPF_output.AppendText("Updates can be found at: https://www.sccmtst.com/p/powercopy.html `n")
	$WPF_output.AppendText("This version of PowerCopy uses robocopy to copy files and folders.`n")
	$WPF_output.AppendText("How To Use:`n")
	$WPF_output.AppendText("`n")
	$WPF_output.AppendText("1. Browse to or type the path to the content you want to copy or move`n")
	$WPF_output.AppendText("`n")
	$WPF_output.AppendText("2. Browse to or type the path to where you want the content to be copied or moved to`n")
	$WPF_output.AppendText("`n")
	$WPF_output.AppendText("3. Choose the options that meet your needs. Hover your mouse over the option for a desctiption of the option`n")
	$WPF_output.AppendText("`n")
	$WPF_output.AppendText("4. Click Start to start the copy process`n")
	$WPF_output.AppendText("`n")
})

$WPF_Stop.add_click({
	$rpid = (Get-ChildProcesses -ParentProcessId $([System.Diagnostics.Process]::GetCurrentProcess().Id) | Where {$_.Name -like "Robocopy*"}).ProcessId
	Stop-Process -ID $rpid -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
	$WPF_Help.IsEnabled = "True"
})

$WPF_Start.Add_Click({
	$WPF_Help.IsEnabled = $False
	$WPF_Total.Value = 0
	$WPF_Progress.Value = 0
	$S = "Nor"
	#Sets the filter text to null so the same filter dosnt get used on a second copy job
	$FilterFiles = $null
	#sets the source for the Source box
	$Source = $WPF_Source.Text
	#sets the Destination for the Destination box
	$Destination = $WPF_Destination.text
	#if the log check box is checked create a log file
	if ($WPF_Log.IsChecked){
		$log = "$Destination\$('PowerCopy_'+ $(get-date -Format MM-dd-yyyy_hh-mm-ss) + '.log')"
		New-Item -ItemType File $log -force | Out-Null
	}
	#if FSonly check box sets needs swtches to copy only the file structure
	if ($WPF_FSOnly.IsChecked){
		$FilterFiles = "*"
		$switchMIR = "/MIR"
		$ExcludeSwitch = "/xf"
		$S = "FSOnly"
	}

	if ($WPF_Backup.IsChecked){
		$switchBackup = "/B"
	}

	#if move check box checked sets switches needs to move all files and folders
	if ($WPF_Move.IsChecked){
		$switchMOVE = "/MOVE"
	}
	#if the xf check box is checked sets the xf switch and reads the filter fromt he xfbox
	IF ($WPF_Exclude.IsChecked){
		$S = "EX"
		$ExcludeSwitch = "/xf"
		$FilterFiles = "$($WPF_ExcludeBox.text)"
		$FilterFiles = $FilterFiles -split ";"
		[array]$array = @()
		Foreach ($File in $FilterFiles){$array += """$File"""}
		$FilterFiles = $null
		$FilterFiles = $array -join " "
	}

	switch ($WPF_OverWrite.SelectedIndex) {
		"0" {
				$ISScwitch = "/IS"
				$ITSwitch = "/IT"
				$IMSwitch = "/IM"
				$OverWrite = 1
			}
		"1" {
				$OverWrite = 0
				$XCSwitch = "/XC"
				$XNSwitch = "/XN"
			}
		"2" {
			$OverWrite = 2
			$IMSwitch = "/IM"
		}
	}

	#Clears the output so its easy to read after each copy job
	$WPF_output.Clear()
	#runs the copy process with the options you selected
	# switch ($S) {
	# 	"FSOnly" {$ScourceCount = (Get-ChildItem $Source -Recurse -Directory).count}
	# 	"EX" {
	# 		$FilterFiles = "$($WPF_ExcludeBox.text)"
	# 		$FilterFiles = $FilterFiles -split ";"
	# 		$F = $($WPF_ExcludeBox.text) -split ";" | ForEach-Object {$_.trim()}
	# 		$ScourceCount = (Get-ChildItem $Source -Recurse -exclude $F).count
	# 		[array]$array = @()
	# 		Foreach ($File in $FilterFiles){
	# 			$array += """$File"""
	# 		}
	# 		$FilterFiles = $null
	# 		$FilterFiles = $array -join " "
	# 	}
	# 	Default {$ScourceCount = (Get-ChildItem $Source -Recurse ).count}
	# }
	$N = 0
	$ScourceCount = 0
	Robocopy.exe $Source $Destination $switchBackup /E /J /V /R:0 /W:0 /L $switchMIR $ExcludeSwitch $FilterFiles $ISScwitch $ITSwitch $IMSwitch $XNSwitch $XCSwitch $switchMOVE /TEE | foreach-Object {
		$ErrorActionPreference = "silentlycontinue"
		$out = $_.trim()
		switch -Wildcard ($out) {
			"New*"{ If ($Out -notlike "Newer*") {$ScourceCount++}}
			"Modified*"{  IF ($OverWrite -NE 0) {$ScourceCount++} }
			"Same*"{IF ($OverWrite -EQ 1) {$ScourceCount++} }
			"Newer*"{ If ($OverWrite -NE 0){$ScourceCount++} }
		}
	}
	IF ($ScourceCount -ne 0){
		Robocopy.exe $Source $Destination $switchBackup /E /J /V /R:0 /W:0 $switchMIR $ExcludeSwitch $FilterFiles $ISScwitch $ITSwitch $IMSwitch $XNSwitch $XCSwitch $switchMOVE /TEE | foreach-Object {
			$ErrorActionPreference = "silentlycontinue"
			$out = $_.trim()
			switch -Wildcard ($out) {
				"*%*" { $WPF_Progress.Value = $($out -replace "%","") }
				"New*"{
					If ($Out -notlike "Newer*"){
						$WPF_output.AppendText($out + "`r`n")
						$N++
						$WPF_Total.Value = ($N/$ScourceCount).tostring("P") -replace '%',""
						IF ($WPF_Log.IsChecked){Add-Content -Value $out -Path $log}
					}
				}
				"Modified*"{
					IF ($OverWrite -NE 0){
						$WPF_output.AppendText($out + "`r`n")
						$N++
						$WPF_Total.Value = ($N/$ScourceCount).tostring("P") -replace '%',""
						IF ($WPF_Log.IsChecked){Add-Content -Value $out -Path $log}
					}
				}
				"Same*"{
					IF ($OverWrite -eq 1){
						$WPF_output.AppendText($out + "`r`n")
						$N++
						$WPF_Total.Value = ($N/$ScourceCount).tostring("P") -replace '%',""
						IF ($WPF_Log.IsChecked){Add-Content -Value $out -Path $log}
					}
				}
				"Newer*"{
					IF ($OverWrite -NE 0){
						$WPF_output.AppendText($out + "`r`n")
						$N++
						$WPF_Total.Value = ($N/$ScourceCount).tostring("P") -replace '%',""
						IF ($WPF_Log.IsChecked){Add-Content -Value $out -Path $log}
					}
				}
				"*ERROR*(0x*"{$WPF_output.AppendText($out + "`r`n")}
				"*ERROR : Invalid Parameter*" {$WPF_output.AppendText($out + "`r`n")}
				Default {
					IF ($WPF_Log.IsChecked){
						if ($Out -eq "Total    Copied   Skipped  Mismatch    FAILED    Extras"){$out = "           " + $out}
						Add-Content -Value $out -Path $log
					}
				}
			}
			$WPF_output.ScrollToEnd()
			[void] [System.Windows.Forms.Application]::DoEvents()
		}
	} else {
		$Out = "Nothing was coppied"
		$WPF_output.AppendText($Out + "`r`n")
		[void] [System.Windows.Forms.Application]::DoEvents()
		$Out = "No files or folders match the criteria"
		$WPF_output.AppendText($Out + "`r`n")
		[void] [System.Windows.Forms.Application]::DoEvents()
	}

	$WPF_Help.IsEnabled = "True"
})

$WPF_BrowseSource.Add_click({
	$SourceForm = New-Object FolderSelect.FolderSelectDialog
	$SourceForm.Title = "Select Source Folder"
	$SourceForm.ShowDialog()
	IF ($SourceForm.FileName){$WPF_Source.Text = $SourceForm.FileName}
})

$WPF_BrowseDestination.Add_click({
	$SourceForm = New-Object FolderSelect.FolderSelectDialog
	$SourceForm.Title = "Select Destination Folder"
	$SourceForm.ShowDialog()
	IF ($SourceForm.FileName){$WPF_Destination.Text = $SourceForm.FileName}
})

$WPF_output.foreground = $Settings.Settings.StatusText
$WPF_output.Background = $Settings.Settings.StatusBackgroud
$WPF_Progress.foreground = $Settings.Settings.StatusBar
$WPF_Total.foreground = $Settings.Settings.ProgressBar

$WPF_Exclude.Add_Checked({ $WPF_ExcludeBox.IsEnabled = "True"})
$WPF_Exclude.Add_UnChecked({ $WPF_ExcludeBox.IsEnabled = "False"})

#endregion code

#region shows the from
$MainForm.Add_Closing({Stop-Script})
$WPFApp = [Windows.Application]::new()
$WPFApp.Run($MainForm)
#endregion shows the formsr