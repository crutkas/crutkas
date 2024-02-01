$mypath = $MyInvocation.MyCommand.Path
Write-Output "Path of the script : $mypath"
Write-Output "Args for script: $Args"

$isWinGetRecent = (winget -v).Trim('v').TrimEnd("-preview").split('.')
if(!(($isWinGetRecent[0] -gt 1) -or ($isWinGetRecent[0] -ge 1 && $isWinGetRecent[1] -ge 6))) # WinGet is greater than v1 or v1.6 or higher
{
   
   $paths = "Microsoft.VCLibs.x64.14.00.Desktop.appx", "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle", "Microsoft.UI.Xaml.2.7.x64.appx"

   Write-Information "Downloading WinGet and its dependencies..."

   Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile $paths[0]
   Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx -OutFile $paths[1]
   Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile $paths[2]

   Write-Information "Installing WinGet and its dependencies..."
   Add-AppxPackage $paths[0] # Microsoft.VCLibs.x64.14.00.Desktop.appx
   Add-AppxPackage $paths[1] # Microsoft.UI.Xaml.2.7.x64.appx
   Add-AppxPackage $paths[2] # Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle

   Write-Information "Verifying Version number of WinGet"
   winget -v

   Write-Information "Cleaning up"
   foreach($filePath in $paths)
   {
      if (Test-Path $filePath) 
      {
         Remove-Item $filePath -verbose
      } 
      else
      {
         Write-Error "Path doesn't exits: " + $filePath
      }
   }
}
else {
   Write-Information "WinGet in decent state"
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$dscUri = "https://raw.githubusercontent.com/crutkas/crutkas/main/setup/"
$dscNonAdmin = "crutkas.nonAdmin.dsc.yml";
$dscAdmin = "crutkas.dsc.yml";

$dscNonAdminUri = $dscUri + $dscNonAdmin 
$dscAdminUri = $dscUri + $dscAdmin

# amazing, we can now run WinGet get fun stuff
if (!$isAdmin) {
   # love tap terminal to it gets registered moving foward
   Start-Process shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App

   Invoke-WebRequest -Uri $dscNonAdminUri -OutFile $dscNonAdmin 
   winget configuration -f $dscNonAdmin 
   
   # clean up, Clean up, everyone wants to clean up
   Remove-Item $dscNonAdmin -verbose

   # restarting for Admin now
	Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$mypath' $Args;`"";
	exit;
}
else {
   # admin section now
   Invoke-WebRequest -Uri $dscAdminUri -OutFile $dscAdmin 
   winget configuration -f $dscAdmin 
   
   # clean up, Clean up, everyone wants to clean up
   Remove-Item $dscAdmin -verbose
}