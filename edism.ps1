function insertAndCopyFileWim {
	$currentPath = Get-Location
	Write-Output $currentPath

	$isoIMG = Get-ChildItem $currentPath\*win*.iso | Select-Object BaseName | ForEach-Object {$_.BaseName + ".ISO"}

	$pathToFile = "$currentPath\$isoIMG"
	Write-Output $isoIMG

	$driveLetter =  ls function:[d-z]: -n | ?{ !(test-path $_) } | random

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

	$change = Read-Host "Are you sure you want to save the changes?`v(y/N)"

	# Read-Host "y/N?" | ?{$_} | Write-Output

	

	try {
		Write-Host "Unmount wim file..." -ForegroundColor green
		if($change -eq "y") {
			Dismount-WindowsImage -Path .\temp\"$imgWIM" -Save
			# $change = "-Save"
		}
		else {
			Dismount-WindowsImage -Path .\temp\"$imgWIM" -Discard
			# $change = "-Discard"
		}
		
		Write-Host "Done" -ForegroundColor green
	}
	catch {
		Write-Host "File not mouting" -ForegroundColor red
	}
}

function Menu {
	#Check if elevated
    [Security.Principal.WindowsPrincipal]$global:User = [Security.Principal.WindowsIdentity]::GetCurrent();
    $global:Admin = $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);

	while (1) {
		Write-Host "`t================================= eDism Program =================================" -ForegroundColor green
		Write-Host "`t1 - Copy From ISO | 2 - Mount Image | 3 - Unmount Image | q or any - exit" -ForegroundColor DarkGreen
		Write-Host "`t=================================================================================" -ForegroundColor green
		$x = Read-Host "Select an action"

		switch ($x) {
			1 {insertAndCopyFileWim}
			2 {mountWIM(".\install.wim")}
			3 {unmountWIM(".\install.wim")}
			Default {exit}
		}
	}
}

Menu