function insertAndCopyFileWim {
	$currentPath = Get-Location
	Write-Output $currentPath

	if (-Not(Test-Path -Path "$currentPath\*.iso")) {
		Write-Host "File not found " -ForegroundColor Red
		return
	}

	$isoIMG = Get-ChildItem $currentPath\*win*.iso | Select-Object BaseName | ForEach-Object { $_.BaseName + ".ISO" }

	if ($null -eq $isoIMG) {
		Write-Host "ISO image not found`t:-(" -ForegroundColor Red
		exit
	}

	Get-ChildItem *.wim | Rename-Item -NewName { $_.Name -replace '.wim', '.old.wim' }

	$pathToFile = "$currentPath\$isoIMG"
	Write-Output $isoIMG

	$driveLetter = Get-ChildItem function:[d-z]: -n | ? { !(test-path $_) } | random

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

	if (-Not(Test-Path -Path $imgWIM)) {
		Write-Host "File $imgWIM not found " -ForegroundColor Red
		return
	}

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

	if (-Not(Test-Path -Path ".\temp\$imgWIM")) {
		Write-Host "Mount image not found " -ForegroundColor Red
		return
	}

	$change = Read-Host "Are you sure you want to save the changes?`v[y/N]"

	try {
		
		if ($change -eq 'y') {
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
		Write-Host "Error" -ForegroundColor red
	}
}

function addPackage {
	param (
		$mountDisk
	)
	$rootLocation = Get-Location
	$foldersPackages

	if (-Not(Test-Path -Path $mountDisk)) {
		Write-Host "Mount image not found " -ForegroundColor Red
		return
	}

	Write-Host "`t`t1 " -NoNewline -ForegroundColor DarkGreen
	Write-Host " - Drivers " -ForegroundColor DarkGray

	Write-Host "`t`t2 " -NoNewline -ForegroundColor DarkGreen
	Write-Host " - Packages " -ForegroundColor DarkGray

	try {
		[byte]$indexPachage = Read-Host "Add Drivers or Packages?"
	}
	catch {
		Write-Host "Invalid value`t:-("
		return
	}

	if ($indexPachage -eq 1) {
		$foldersPackages = "Drivers"
	}
	elseif ($indexPachage -eq 2) {
		$foldersPackages = "Packages"
	}
	else {
		Write-Host "Invalid index`t:-("
		return
	}

	if (-Not(Test-Path -Path "$rootLocation\$foldersPackages\*")) {
		if (-Not(Test-Path -Path "$rootLocation\$foldersPackages")) {
			New-Item -Path "$rootLocation\$foldersPackages" -ItemType Directory
		}

		Write-Host "Put the files in a folder " -NoNewline
		Write-Host "$foldersPackages " -ForegroundColor Blue -NoNewline
		Read-Host "End press ENTER"
	}
	$PackagesDirDefaul = "$rootLocation\$foldersPackages"

	# Add Drivers
	if ($indexPachage -eq 1) {
		try {
			Add-WindowsDriver -Path $mountDisk -Driver "$PackagesDirDefaul" -Recurse	# -ForceUnsigned
		}
		catch {
			Write-Output "Error. Drivers not add`t:-("
		}
	}
	# Add Packages
	elseif ($indexPachage -eq 2) {
		try {
			Add-WindowsPackage -Path $mountDisk -PackagePath $PackagesDirDefaul 	#-IgnoreCheck
		}
		catch {
			Write-Output "Error. Packages not add`t:-("
		}
	}
}

function Menu {
	#Check if elevated
	[Security.Principal.WindowsPrincipal]$User = [Security.Principal.WindowsIdentity]::GetCurrent();
	$Admin = $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
	
	if (!$Admin) {
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

		Write-Host "`t`t6 " -NoNewline -ForegroundColor DarkGreen
		Write-Host "- Add Package [boot.wim] " -ForegroundColor DarkGray

		Write-Host "`t`t7 " -NoNewline -ForegroundColor DarkGreen
		Write-Host "- Add Package [install.wim] " -ForegroundColor DarkGray

		Write-Host "`t`tq " -NoNewline -ForegroundColor DarkRed
		Write-Host "or any - exit" -ForegroundColor DarkGray

		Write-Host "`t===============================================" -ForegroundColor Green
		$choice = Read-Host "Select an action"

		switch ($choice) {
			1 { insertAndCopyFileWim }
			2 { mountWIM(".\install.wim") }
			3 { unmountWIM(".\install.wim") }
			4 { mountWIM(".\boot.wim") }
			5 { unmountWIM(".\boot.wim") }
			6 { addPackage(".\temp\boot.wim") }
			7 { addPackage(".\temp\install.wim") }
			Default { exit }
		}
	}
}

Menu