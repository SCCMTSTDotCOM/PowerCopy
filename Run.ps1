if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript"){$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition }else{$ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])}
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
				ini[$section] = @{}
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

function Start-App {
	$Path = "$ScriptPath\PowerCopy.dll"
	$secure = Get-Content $path | ConvertTo-SecureString -Key (106,39,107,63,133,120,45,139,187,5,101,13,114,100,79,153,90,157,25,99,42,191,27,105,74,3,145,82,98,23,134,89)
	$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
	$Script = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
	Invoke-Expression $Script
}

function Get-Version{
	Add-Type -AssemblyName PresentationFramework
	$exe = Get-ChildItem -path $Scriptpath -filter "PowerCopy*.exe" -ErrorAction SilentlyContinue
	$AppVersion = (Get-Item "$exe" -ErrorAction SilentlyContinue).VersionInfo
	$AppVersion = $AppVersion.FileVersion
	$VFromServer = $web.DownloadString("http://downloads.mosaicmk.com/downloads/PowerCopy/version.txt")
	if ($AppVersion -lt $VFromServer){
		$msgBoxInput = [System.Windows.MessageBox]::Show("There is a new version avaibale, Would you like to download it now ?",'PowerCopy','YesNo','Info')
		switch ($msgBoxInput){
			'Yes'{
				$exe = "PowerCopy-"+"$VFromServer"+".zip"
				$Web.DownloadFile("http://downloads.mosaicmk.com/downloads/PowerCopy/$VFromServer/$exe","$ENV:USERPROFILE\Downloads\$exe")
				Exit 1
			}
			'No'{start-app}
		}
	} else {Start-App}
}

$ini = Get-IniFile -filePath "$ScriptPath\Settings.ini"
IF ($ini.Settings.CheckForUpdates -eq "True"){
	try {
		[void]$web.DownloadString("http://downloads.mosaicmk.com/downloads/PowerCopy/version.txt")
		Get-Version
	}catch{Start-App}
} Else {Start-App}