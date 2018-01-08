# HPE-Inject-DriversToWinpe version 1.0
$mountdir = "c:\mount"
 
$winpeimage = "c:\folder\custom_winpe.wim"
 
$winpeimagetemp = $winpeimage + ".tmp"
 
mkdir "c:\mount"
 
copy $winpeimage $winpeimagetemp
 
dism /mount-wim /wimfile:$winpeimagetemp /index:1 /mountdir:$mountdir
 
$drivers = get-scdriverpackage | where { $_.tags -match "hpeproliant-winpe100" }
 foreach ($driver in $drivers) 
{ 
    $path = $driver.sharepath 
    dism /image:$mountdir /add-driver /driver:$path
 }
 
Dism /Unmount-Wim /MountDir:$mountdir /Commit
 
publish-scwindowspe -path $winpeimagetemp
 
del $winpeimagetemp
