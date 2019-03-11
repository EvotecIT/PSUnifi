function Repair-UnifiPackage {
    param(
        [uri] $Url
    )
    $TemporaryPackageName = 'unifi-package.deb'
    $FinalPackageName = 'unifi-package-fixed.db'
    $TemporaryDirectory = Get-TemporaryDirectory # creates directory
    if ($null -ne $TemporaryDirectory) {
        Write-Color '[+] ', 'Creating temporary directory ', $TemporaryDirectory, ' for storing ', $TemporaryPackageName -Color Green, Yellow, Green, White, Green
        $BinaryPath = [System.IO.Path]::Combine($TemporaryDirectory, $TemporaryPackageName)
        Write-Color '[*] ', 'Package path ', $BinaryPath -Color Blue, Yellow, Green
        $Invoke = Invoke-WebRequest -Uri $Url -OutFile $BinaryPath
        if (Test-Path -LiteralPath $BinaryPath) {
            Write-Color '[+] ', 'Package downloaded to ', $BinaryPath -Color Green, Yellow, Green
            $TemporaryUnpackDirectory = Get-TemporaryDirectory # creates directory
            if ($null -ne $TemporaryUnpackDirectory) {
                Write-Color '[+]', ' Temporary directory ', $TemporaryUnpackDirectory, ' for unpacking ', $TemporaryPackageName -Color Green, Yellow, Green, White, Green
                try {
                    dpkg-deb -R $BinaryPath $TemporaryUnpackDirectory
                } catch {
                    $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                    Write-Color '[-]', ' Command ', 'dpkg-deb', ' error: ', $ErrorMessage -Color Red, Yellow, Red, White, Red
                    return
                }
                $ControlFile = [System.IO.Path]::Combine($TemporaryUnpackDirectory, 'DEBIAN', 'control')

                $FileContent = Get-Content -LiteralPath $ControlFile
                $NewContent = foreach ($Line in $FileContent) {
                    if ($Line -like '*mongodb*') {
                        #Write-Color $File -Color Green
                    } else {
                        #Write-Color $File -Color Yellow
                        $Line
                    }
                }
                $LinesBefore = $FileContent.Count
                $LinesAfter = $NewContent.Count
                $LinesCount = ($LinesBefore - $LinesAfter)
                if ($LinesCount -eq 0) {
                    Write-Color '[-]', ' Lines removed ', 0, '. Terminating, something is wrong!' -Color Red, Yellow, Red, White
                    return
                } else {
                    Write-Color '[+]', ' Lines removed ', ($LinesCount) -Color White, Yellow, Green
                    $NewContent | Set-Content -LiteralPath $ControlFile
                }
            } else {
                Write-Color '[-]',' Generating Temporary Directory for unpacking ', 'Failed' -Color Red, White, Red
            }

            $BinaryPathFinal = [System.IO.Path]::Combine($TemporaryDirectory, $FinalPackageName)
            try {
                dpkg-deb -b $TemporaryUnpackDirectory $BinaryPathFinal   
            } catch {
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                Write-Color '[-]', ' Command ', 'dpkg-deb', ' error: ', $ErrorMessage -Color Red, Yellow, Red, White, Red
                return
            }         
            if (Test-Path -LiteralPath $BinaryPathFinal) {
                Write-Color '[+]', ' File ', $FinalPackageName, ' was saved to location ', $BinaryPathFinal -Color Green, Yellow, Green, Yellow
            } else {
                Write-Color '[-]', ' File ', $FinalPackageName, ' was NOT saved to location ', $BinaryPathFinal -Color Red, Yellow, Red, Yellow
            }
        }
    } else {
        Write-Color '[-]',' Generating Temporary Directory for downloading ', 'Failed' -Color Red, White, Red
    }
}