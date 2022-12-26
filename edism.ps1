function insertAndCopyFileWim {
	$currentPath = Get-Location
	Write-Output $currentPath

	$isoIMG = Get-ChildItem $currentPath\*win*.iso | Select-Object BaseName | ForEach-Object {$_.BaseName + ".ISO"}

	if($null -eq $isoIMG){
		Write-Host "ISO image not found`t:-(" -ForegroundColor Red
		exit
	}

	Get-ChildItem *.wim | Rename-Item -NewName { $_.Name -replace '.wim','.old.wim' }

	$pathToFile = "$currentPath\$isoIMG"
	Write-Output $isoIMG

	$driveLetter =  Get-ChildItem function:[d-z]: -n | ?{ !(test-path $_) } | random

	$diskImg = Mount-DiskImage -ImagePath $pathToFile  -NoDriveLetter
	$volInfo = $diskImg | Get-Volume

	try {
		Write-Host "Mount disk..." -ForegroundColor green
		mountvol $driveLetter $volInfo.UniqueId

		$path = $driveLetter + "sources\install.wim"
		Copy-Item -Path $path -Destination .\
		Write-Host "`n`t==> install.wim copied!`n`n" -ForegroundColor green

		$path = $driveLetter + "sources\boot.wim"
		Copy-Item -Path $path -Destination .\
		Write-Host "`n`t==> boot.wim copied!`n`n" -ForegroundColor green
	}
	catch {
		Write-Host "Copy failed `t:-(" -ForegroundColor red
	}
	finally {
		Write-Host "Unmount disk..." -ForegroundColor green
		DisMount-DiskImage -ImagePath $pathToFile
	}
}

function mountWIM {
	param (
		$imgWIM
	)

	$InfoImage = Get-WindowsImage -ImagePath .\$imgWIM
	Write-Output $InfoImage

	try {
		[byte]$indexImage = Read-Host -Prompt "Select index or (ENTER) to exit"
	}
	catch {
		Write-Host "Index is not a number`t:-(" -ForegroundColor red
		return
	}

	if ($indexImage -le 0) {
		return
	}

	$pathMountImg = New-Item -Path .\temp\"$imgWIM" -ItemType Directory
	
	try {
		attrib -r .\$imgWIM
		Mount-WindowsImage -ImagePath .\$imgWIM -Index $indexImage -Path $pathMountImg
	}
	catch {
		# attrib +r .\$imgWIM
		Write-Host "==============================" -ForegroundColor red
		Write-Host "Index is not correct`t=(" -ForegroundColor red
	}
}

function unmountWIM {
	param (
		$imgWIM
	)

	$change = Read-Host "Are you sure you want to save the changes?`v[y/N]"

	try {
		
		if($change -eq 'y') {
			Write-Host "Unmount and saving wim file..." -ForegroundColor green
			Dismount-WindowsImage -Path .\temp\"$imgWIM" -Save
		}
		else {
			Write-Host "Unmount without saving wim file..." -ForegroundColor Red
			Dismount-WindowsImage -Path .\temp\"$imgWIM" -Discard
		}
		Remove-Item ".\temp\$imgWIM"
		
		Write-Host "Done" -ForegroundColor green
	}
	catch {
		Write-Host "File not mouting" -ForegroundColor red
	}
}

function Menu {
	#Check if elevated
    [Security.Principal.WindowsPrincipal]$User = [Security.Principal.WindowsIdentity]::GetCurrent();
    $Admin = $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
	
	if(!$Admin){
		Write-Host "`t You need administrator rights" -ForegroundColor Red
	}

	while (1) {
		Write-Host "`t===============" -NoNewline -ForegroundColor Green
		Write-Host " eDism Program " -NoNewline -ForegroundColor Green
		Write-Host "=================" -ForegroundColor Green
		Write-Host "`t`t1 " -NoNewline -ForegroundColor DarkGreen
		Write-Host "- Copy from ISO " -ForegroundColor DarkGray
		Write-Host "`t`t2 " -NoNewline -ForegroundColor DarkGreen
		Write-Host "- Mount [install.wim] " -ForegroundColor DarkGray 
		Write-Host "`t`t3 " -NoNewline -ForegroundColor DarkGreen
		Write-Host "- Unmount [install.wim] " -ForegroundColor DarkGray
		Write-Host "`t`t4 " -NoNewline -ForegroundColor DarkGreen
		Write-Host "- Mount [boot.wim] " -ForegroundColor DarkGray 
		Write-Host "`t`t5 " -NoNewline -ForegroundColor DarkGreen
		Write-Host "- Unmount [boot.wim] " -ForegroundColor DarkGray
		Write-Host "`t`tq " -NoNewline -ForegroundColor DarkRed
		Write-Host "or any - exit" -ForegroundColor DarkGray
		Write-Host "`t===============================================" -ForegroundColor Green
		$choice = Read-Host "Select an action"

		switch ($choice) {
			1 {insertAndCopyFileWim}
			2 {mountWIM(".\install.wim")}
			3 {unmountWIM(".\install.wim")}
			4 {mountWIM(".\boot.wim")}
			5 {unmountWIM(".\boot.wim")}
			Default {exit}
		}
	}
}

Menu