<#
.SYNOPSIS
HPE-Extract-CustomSppDrivers version 2.0 , March 2018
Powershell Script which extracts appropriate drivers from Custom SPP provided as parameter to the script

.DESCRIPTION
This script shall create folders with appropriate driver name extracting each component out of a custom SPP path provided.

.EXAMPLE
.\HPE-Extract-CustomSppDrivers.ps1 "C:\Program Files\7-Zip" "D:\gen10snap2\2012Custom" "D:\gen10snap2\OutputDrivers"
The above command shall read all the components present in "2012Custom" folder and process each component .
The drivers processed shall be placed under "drivers" folder in "OutputDrivers" folder.

.NOTES
Please refer to the Whitepaper for more details on usage.
7z is required to be installed in the system for this script to function.
7z License information :- http://www.7-zip.org/license.txt
7-zip download location :- http://www.7-zip.org/ 

.LINK
Git repo https://github.com/HewlettPackard/sccm-scvmm-osdeployment 

#>

param(
    [Parameter(Mandatory=$true)]
    [string]$7ZipExecutablePath,

    [Parameter(Mandatory=$true)]
    [string]$CustomSPPOutputFolder,

    [Parameter(Mandatory=$true)]
    [string]$OutputFolderLocation
)

# Validate Parameters
if( -Not (Test-Path -Path $7ZipExecutablePath)){
    throw "Invalid 7-Zip executable location passed into 7ZipexecutablePath"
}

if( -Not (Test-Path -Path $CustomSPPOutputFolder)){
    throw "Invalid directory passed into CustomSPPOutputFolder"
}

if( -Not (Test-Path -Path $OutputFolderLocation)){
    throw "Invalid directory passed into OutputFolderLocation"
}

$path = $CustomSPPOutputFolder
$OutPutLocationofDrivers = $OutputFolderLocation
$ComponentsPath = '"' + $CustomSPPOutputFolder + "\*.exe" + '"'
$ComponentsExtractionPath = "-o" + $CustomSPPOutputFolder + "\*"
$7zipLocation = '"' +  $7ZipExecutablePath + "\7z.exe" + '"'
$OutputFolderLocation = '"' + $OutputFolderLocation + '"'

# Invoking this command shall extract all the Custom SPP components to appropriate folder.
$command = "cmd.exe /C $7zipLocation x $ComponentsPath $ComponentsExtractionPath"

Invoke-Expression -Command:$command

$items = Get-ChildItem -Path $CustomSPPOutputFolder

$driversFolder = $CustomSPPOutputFolder + "\" + "drivers"

New-Item -Path $driversFolder -ItemType directory -force

# enumerate the items array
foreach ($item in $items)
{
        # if the item is a directory, then process it.
    if ($item.Attributes -eq "Directory")
    {
        # the item is a folder .
        # now read the contens of the folder
        # if folder doesnt contain any .inf file and also no .cab file and *elxdrvr or *brcmdrvr file , continue
        Write-Host "Iterating component --- " + $item.Name -ForegroundColor Green
        $subitems = Get-ChildItem -Path ($item.FullName)
        foreach ( $subitem in $subitems)
        {
            if($subitem.Extension -contains ".inf")
            {
                # the component has at least one driver.
                # Perform the task on this.
                # try to open cp*.xml file and read the <swkey>
                # create a folder with the same name as in the swkey and copy the .inf , .cat , .sys and other files in that folder.
                [XML]$userfile = Get-Content ($path + "\" + $item.Name + "\" + $item.Name +  ".xml")
                $swkey = $userfile
                foreach($driverEntry in $userfile.cpq_package.sw_keys.sw_keys_and.sw_key){
                    Write-Host $driverEntry.name
                    # $driverEntry is the <sw_key> name which we need to create a folder and copy the same name inf , sys , cat and #dll files to this
                    $associatedDriverFolderName = $driverEntry.name.Substring(0,$driverEntry.name.Length-4)
                    $associatedDriverFolderNameCornerCase = $driverEntry.name.Substring(0,$driverEntry.name.Length-5)
                    $SpecialDriverINFName = $driverEntry.name.Substring(0,$driverEntry.name.Length-7)
                    Write-Host ($path+"\"+$item)
                    Write-Host $associatedDriverFolderName + ".inf" -foregroundcolor Green

                    if (Test-Path ($path+"\"+$item+"\"+$associatedDriverFolderName + ".inf") -PathType Leaf)
                    # the above statement will copy associated driver files only if it finds the .inf file with the
                    #same name as the sw_key .

                    {
                        New-Item -Path ($driversFolder + "\" + $associatedDriverFolderName) -ItemType directory -force

                        Copy-Item ($path+"\"+$item+"\"+$associatedDriverFolderName + ".inf") ($driversFolder + "\" + $associatedDriverFolderName)

                        Copy-Item ($path+"\"+$item+"\"+$associatedDriverFolderName + ".cat") ($driversFolder + "\" + $associatedDriverFolderName)
                        Copy-Item ($path+"\"+$item+"\"+"*" + ".sys") ($driversFolder + "\" + $associatedDriverFolderName)
                        Copy-Item ($path+"\"+$item+"\"+"*" + ".dll") ($driversFolder + "\" + $associatedDriverFolderName)
                        Copy-Item ($path+"\"+$item+"\"+"*" + ".din") ($driversFolder + "\" + $associatedDriverFolderName)
                        Copy-Item ($path+"\"+$item+"\"+"*" + ".pdb") ($driversFolder + "\" + $associatedDriverFolderName)
                        Copy-Item ($path+"\"+$item+"\"+"*" + ".exe") ($driversFolder + "\" + $associatedDriverFolderName)
                        Copy-Item ($path+"\"+$item+"\"+"*" + ".rtf") ($driversFolder + "\" + $associatedDriverFolderName)
                        Copy-Item ($path+"\"+$item+"\"+"*" + ".def") ($driversFolder + "\" + $associatedDriverFolderName)
						Copy-Item ($path+"\"+$item+"\"+"*" + ".cz") ($driversFolder + "\" + $associatedDriverFolderName)
                        Copy-Item ($path+"\"+$item+"\"+"*" + ".ml") ($driversFolder + "\" + $associatedDriverFolderName)
                        Copy-Item ($path+"\"+$item+"\"+"*" + ".bin") ($driversFolder + "\" + $associatedDriverFolderName)
                        Copy-Item ($path+"\"+$item+"\"+"*" + ".config") ($driversFolder + "\" + $associatedDriverFolderName)
                    }

                    # for special cases

                    elseif (Test-Path ($path+"\"+$item+"\"+$associatedDriverFolderNameCornerCase + ".inf") -PathType Leaf)
                        # the above statement will copy associated driver files only if it finds the .inf file with the
                        #same name as the sw_key .

                    {
                        if($associatedDriverFolderNameCornerCase -like "evbd")
                        {
                            New-Item -Path ($driversFolder + "\" + $associatedDriverFolderNameCornerCase) -ItemType directory -force
                            Copy-Item ($path+"\"+$item+"\"+"evb" + "*" + ".inf") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)

                            Copy-Item ($path+"\"+$item+"\"+"*" + ".cat") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".sys") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".dll") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".din") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".pdb") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".exe") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".rtf") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".def") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)

                            $associatedDriverFolderNameCornerCasebxnd = "bxnd"
                            New-Item -Path ($driversFolder + "\" + $associatedDriverFolderNameCornerCasebxnd) -ItemType directory -force
                            Copy-Item ($path+"\"+$item+"\"+"bxn" + "*" + ".inf") ($driversFolder + "\" + $associatedDriverFolderNameCornerCasebxnd)

                            Copy-Item ($path+"\"+$item+"\"+"*" + ".cat") ($driversFolder + "\" + $associatedDriverFolderNameCornerCasebxnd)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".sys") ($driversFolder + "\" + $associatedDriverFolderNameCornerCasebxnd)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".dll") ($driversFolder + "\" + $associatedDriverFolderNameCornerCasebxnd)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".din") ($driversFolder + "\" + $associatedDriverFolderNameCornerCasebxnd)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".pdb") ($driversFolder + "\" + $associatedDriverFolderNameCornerCasebxnd)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".exe") ($driversFolder + "\" + $associatedDriverFolderNameCornerCasebxnd)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".rtf") ($driversFolder + "\" + $associatedDriverFolderNameCornerCasebxnd)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".def") ($driversFolder + "\" + $associatedDriverFolderNameCornerCasebxnd)


                        }

                        else
                        {
                            New-Item -Path ($driversFolder + "\" + $associatedDriverFolderNameCornerCase) -ItemType directory -force
                            Copy-Item ($path+"\"+$item+"\"+$associatedDriverFolderNameCornerCase + ".inf") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".cat") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".sys") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".dll") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".din") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".pdb") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".exe") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".rtf") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".def") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
			    Copy-Item ($path+"\"+$item+"\"+"*" + ".cz") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
			    Copy-Item ($path+"\"+$item+"\"+"*" + ".ml") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
			    Copy-Item ($path+"\"+$item+"\"+"*" + ".bin") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)
			    Copy-Item ($path+"\"+$item+"\"+"*" + ".config") ($driversFolder + "\" + $associatedDriverFolderNameCornerCase)


                        }


                    }

                    # ql2300 , matrox and similar ones
                    elseif (Test-Path ($path+"\"+$item+"\"+$SpecialDriverINFName + "*.inf") -PathType Leaf)
                    # the above statement will copy associated driver files only if it finds the .inf file with the
                    #same name as the sw_key .

                    {
                            New-Item -Path ($driversFolder + "\" + $SpecialDriverINFName) -ItemType directory -force

                            Copy-Item ($path+"\"+$item+"\"+$SpecialDriverINFName + "*.inf") ($driversFolder + "\" + $SpecialDriverINFName)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".cat") ($driversFolder + "\" + $SpecialDriverINFName)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".sys") ($driversFolder + "\" + $SpecialDriverINFName)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".dll") ($driversFolder + "\" + $SpecialDriverINFName)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".din") ($driversFolder + "\" + $SpecialDriverINFName)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".pdb") ($driversFolder + "\" + $SpecialDriverINFName)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".exe") ($driversFolder + "\" + $SpecialDriverINFName)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".rtf") ($driversFolder + "\" + $SpecialDriverINFName)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".def") ($driversFolder + "\" + $SpecialDriverINFName)
			    Copy-Item ($path+"\"+$item+"\"+"*" + ".cz") ($driversFolder + "\" + $SpecialDriverINFName)
			    Copy-Item ($path+"\"+$item+"\"+"*" + ".ml") ($driversFolder + "\" + $SpecialDriverINFName)
			    Copy-Item ($path+"\"+$item+"\"+"*" + ".bin") ($driversFolder + "\" + $SpecialDriverINFName)
			    Copy-Item ($path+"\"+$item+"\"+"*" + ".config") ($driversFolder + "\" + $SpecialDriverINFName)
                    }

                    elseif ($driverEntry.name -like "MxG2h*")
                            # the above statement will copy associated driver files only if it finds the .inf file with the
                            #same name as the sw_key .

                    {
                            $FolderNameMX = "MxG2h"
                            New-Item -Path ($driversFolder + "\" + $FolderNameMX) -ItemType directory -force

                            Copy-Item ($path+"\"+$item+"\"+$FolderNameMX + "*.inf") ($driversFolder + "\" + $FolderNameMX)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".cat") ($driversFolder + "\" + $FolderNameMX)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".sys") ($driversFolder + "\" + $FolderNameMX)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".dll") ($driversFolder + "\" + $FolderNameMX)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".din") ($driversFolder + "\" + $FolderNameMX)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".pdb") ($driversFolder + "\" + $FolderNameMX)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".exe") ($driversFolder + "\" + $FolderNameMX)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".rtf") ($driversFolder + "\" + $FolderNameMX)
                            Copy-Item ($path+"\"+$item+"\"+"*" + ".def") ($driversFolder + "\" + $FolderNameMX)

                    }

                }

            }

            #special applications which have driver files .
            if(($subitem -like "elxdrvr*") -or ($subitem -like "brcmdrvr*"))
            {
                Write-Host "Contains elxdrvr or brcmdrvr ... installing to fetch driver information" -foregroundcolor "magenta"
                $exepath = ($path + "\" + $item + "\" + $subitem)
                & $exepath /s /q2 extract=2
                Start-Sleep -s 5
                [XML]$userfile = Get-Content ($path + "\" + $item.Name + "\" + $item.Name +  ".xml")
                if($subitem -like "elxdrvr*")
                {
                $associatedDriverFolderName = "elxfc"
                }
                else
                {
                $associatedDriverFolderName = "elxcna"
                }
                New-Item -Path ($driversFolder + "\" + $associatedDriverFolderName) -ItemType directory -force
                $mydocuments = [environment]::getfolderpath("mydocuments")


                if($path -like "*2016Custom*")
                {
                if($subitem -like "elxdrvr*")
                {
                $elxdrvrFolderPath = ($mydocuments + "\Emulex\Drivers\*\x64\win2016")
                Copy-Item ($elxdrvrFolderPath + "\" + "elxplus.inf") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.cat") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.sys") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.dll") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.exe") ($driversFolder + "\" + $associatedDriverFolderName)

                }
                else
                {
                $elxdrvrFolderPath = ($mydocuments + "\Broadcom\Drivers\*\x64\win2016")
                Copy-Item ($elxdrvrFolderPath + "\" + "oemsetup.inf") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.cat") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.sys") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.dll") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.exe") ($driversFolder + "\" + $associatedDriverFolderName)
                }


                }


                if($path -like "*2012Custom*")
                {

                if($subitem -like "elxdrvr*")
                {
                $elxdrvrFolderPath = ($mydocuments + "\Emulex\Drivers\*\x64\win2012")
                Copy-Item ($elxdrvrFolderPath + "\" + "elxplus.inf") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.cat") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.sys") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.dll") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.exe") ($driversFolder + "\" + $associatedDriverFolderName)
                }
                else
                {
                $elxdrvrFolderPath = ($mydocuments + "\Broadcom\Drivers\*\x64\win2012")
                Copy-Item ($elxdrvrFolderPath + "\" + "oemsetup.inf") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.cat") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.sys") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.dll") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.exe") ($driversFolder + "\" + $associatedDriverFolderName)
                }

                }

                if($path -like "*2012r2Custom*")
                {

                if($subitem -like "elxdrvr*")
                {
                $elxdrvrFolderPath = ($mydocuments + "\Emulex\Drivers\*\x64\win2012R2")
                Copy-Item ($elxdrvrFolderPath + "\" + "elxplus.inf") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.cat") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.sys") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.dll") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.exe") ($driversFolder + "\" + $associatedDriverFolderName)
                }
                else
                {
                $elxdrvrFolderPath = ($mydocuments + "\Broadcom\Drivers\*\x64\win2012R2")
                Copy-Item ($elxdrvrFolderPath + "\" + "oemsetup.inf") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.cat") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.sys") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.dll") ($driversFolder + "\" + $associatedDriverFolderName)
                Copy-Item ($elxdrvrFolderPath + "\" + "*.exe") ($driversFolder + "\" + $associatedDriverFolderName)

                }

                }


            }
			# For items containing .cab file .Few.cab file contain drivers which is fetched here.
			if($subitem.Extension -contains ".cab")
            {
                # its a cabinet file and can contain driver
                # If this cabinet file contains .inf file , create a driver entry .
                # 1. Extract this cab file
                # 2. From the extracted path , fetch the drivers in appropriate folder
				
                $ComponentsCabPath = ($path + "\" + $item + "\" + $subitem)
                $ComponentsCabFile = ($path + "\" + $item + "\" + $subitem.name)

                Write-Host $ComponentsCabFile

                $ComponentsCabExtractionPath = "-o" +$ComponentsCabFile.Substring(0,$ComponentsCabFile.Length-4)

                $ComponentsCabExtractionPathName = $ComponentsCabFile.Substring(0,$ComponentsCabFile.Length-4)
				
                #BE: I modified this to not be a here string.  Not sure it needs to be so this needs to be revalidated.
				#UT : Validated . Works perfect. Shall get a sanitation done by the QA 
                $commandCabExtract = "cmd.exe /C $7zipLocation x $ComponentsCabPath $ComponentsCabExtractionPath"

                Invoke-Expression -Command:$commandCabExtract

                # cab file extracted
                # look out for .inf file in the above extracted folder and create a folder in driver with same name .
                # copy inf and related files

                if(Test-Path $ComponentsCabExtractionPathName -PathType Container)
                {
                    $subitemsExtracted = Get-ChildItem -Path ($ComponentsCabExtractionPathName)

                    Write-Host "Waiting .... " -foregroundcolor "magenta"
                    Start-Sleep -s 2

                    foreach ( $extractedItem in $subitemsExtracted)
                    {
                        Write-Host ("Extracted item--" +  $extractedItem.name)
                        if($extractedItem.Extension -like "*.inf")
                        {

                            $associatedDriverFolderName = $extractedItem.name.Substring(0,$extractedItem.name.Length-4)

                            New-Item -Path ($driversFolder + "\" + $associatedDriverFolderName) -ItemType directory -force

                                                        Copy-Item ($path+"\"+$item+"\"+$associatedDriverFolderName + "\" + $associatedDriverFolderName + ".inf") ($driversFolder + "\" + $associatedDriverFolderName)

                                                        Copy-Item ($path+"\"+$item+"\"+$associatedDriverFolderName + "\" + $associatedDriverFolderName + ".cat") ($driversFolder + "\" + $associatedDriverFolderName)

                                                        Copy-Item ($path+"\"+$item+"\"+$associatedDriverFolderName + "\" + $associatedDriverFolderName + ".sys") ($driversFolder + "\" + $associatedDriverFolderName)
                                                        Copy-Item ($path+"\"+$item+"\"+$associatedDriverFolderName + "\" + "*.dll") ($driversFolder + "\" + $associatedDriverFolderName)

                                                        Copy-Item ($path+"\"+$item+"\"+"*" + ".sys") ($driversFolder + "\" + $associatedDriverFolderName)
                                                        Copy-Item ($path+"\"+$item+"\"+"*" + ".dll") ($driversFolder + "\" + $associatedDriverFolderName)
                                                        Copy-Item ($path+"\"+$item+"\"+"*" + ".din") ($driversFolder + "\" + $associatedDriverFolderName)
                                                        Copy-Item ($path+"\"+$item+"\"+"*" + ".pdb") ($driversFolder + "\" + $associatedDriverFolderName)
                                                        Copy-Item ($path+"\"+$item+"\"+"*" + ".exe") ($driversFolder + "\" + $associatedDriverFolderName)
                                                        Copy-Item ($path+"\"+$item+"\"+"*" + ".rtf") ($driversFolder + "\" + $associatedDriverFolderName)
                                                        Copy-Item ($path+"\"+$item+"\"+"*" + ".def") ($driversFolder + "\" + $associatedDriverFolderName)
							Copy-Item ($path+"\"+$item+"\"+"*" + ".cz") ($driversFolder + "\" + $associatedDriverFolderName)
							Copy-Item ($path+"\"+$item+"\"+"*" + ".ml") ($driversFolder + "\" + $associatedDriverFolderName)
							Copy-Item ($path+"\"+$item+"\"+"*" + ".bin") ($driversFolder + "\" + $associatedDriverFolderName)
							Copy-Item ($path+"\"+$item+"\"+"*" + ".config") ($driversFolder + "\" + $associatedDriverFolderName)

                        }
                    }
                }

            }
       
        }


    }
}
#drivers output folders
$2016drviersFolder = "ws2016-x64"
$2012drviersFolder = "ws2012-x64"
$2012r2drviersFolder = "ws2012r2-x64"

New-Item -Path ($OutPutLocationofDrivers + "\" + "drivers") -ItemType directory -force

if($path -like "*2016Custom*")
{

    New-Item -Path ($OutPutLocationofDrivers + "\" + "drivers\" + $2016drviersFolder) -ItemType directory -force
    Copy-Item ($path+"\"+"drivers"+"\"+"*" + "*") ($OutPutLocationofDrivers + "\" + "drivers\" + $2016drviersFolder) -recurse -force
}
if($path -like "*2012Custom*")
{

    New-Item -Path ($OutPutLocationofDrivers + "\" + "drivers\" + $2012drviersFolder) -ItemType directory -force
    Copy-Item ($path+"\"+"drivers"+"\"+"*" + "*") ($OutPutLocationofDrivers + "\" + "drivers\" + $2012drviersFolder) -recurse -force
}

if($path -like "*2012r2Custom*")
{

    New-Item -Path ($OutPutLocationofDrivers + "\" + "drivers\" + $2012r2drviersFolder) -ItemType directory -force
    Copy-Item ($path+"\"+"drivers"+"\"+"*" + "*") ($OutPutLocationofDrivers + "\" + "drivers\" + $2012r2drviersFolder) -recurse -force
}





