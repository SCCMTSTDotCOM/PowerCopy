PARAM (
    $Target,
    $Destination
)
$Global:SyncHash = [hashtable]::Synchronized(@{})
$Global:SyncHash.Target = $Target
$Global:SyncHash.Dest = $Destination
If ((Get-ChildItem $Target).Attributes -notlike "*Directory*"){
    
} Else {
    
}

$Global:SyncHash.size = (Get-ChildItem $Target -Recurse | measure Length -s).sum / 1Mb

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

$Global:SyncHash.PercentDone = 0
$SPSize = Invoke-SeparateRunspace -Task ({
    $DestSize = (gci $Global:SyncHash.Dest | measure Length -s).sum / 1Mb
    $Size = $Global:SyncHash.size
    while ($DestSize -ne  $Size) {
        Start-Sleep -Milliseconds 15
        $DestSize = (gci $Global:SyncHash.Dest | measure Length -s).sum / 1Mb
        $Global:SyncHash.PercentDone = $DestSize/$Size*100
    }
    $Global:SyncHash.Running = 0
})

$SPWatch = Invoke-SeparateRunspace -Task ({
    while ($($Global:SyncHash.Running) -eq 1) {
        Start-Sleep -Milliseconds 35
        Get-Runspace | Where-Object -Property RunspaceAvailability -like Available | foreach {$_.Dispose()}
    }
})

$List = Get-ChildItem $Target -Recurse
$RSP = (Get-Runspace).count
foreach ($Item in $List) {
    $Global:SyncHash.Item = $($Item.fullname)
    while ($RSC -gt 9) { write-host Sleeping ; Start-Sleep -Seconds 3 ; $RSP = (Get-Runspace).count}
    Write-Host $($Item.fullname)
    Invoke-SeparateRunspace -Task ({
        $I = $($Global:SyncHash.Item) -replace "$($Global:SyncHash.Target)","$($Global:SyncHash.Dest)"
        Add-Content -Value $I -Path C:\list.txt
        # if ( (Get-Item $I).Attributes -like "*Directory*" ){
        #     New-Item -ItemType Directory $I -Force
        # } else {Copy-Item $I $Global:SyncHash.Dest -Force}
    })
}

while ($($Global:SyncHash.Running) -eq 1) {
    cls
    Write-Host Coppying 
    Write-Host $($Global:SyncHash.PercentDone)
    Start-Sleep -Seconds 1
}