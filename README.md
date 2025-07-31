# windows-install-script
Powershell script to install the Uptycs Windows agent (supports silent installation). 
This script will install the Uptycs agent msi on a Windows machine that does or does not have Smart App Control. 
If Smart App Control is set to 'OFF', then you can double click the .msi install package (you can use the package with flags and secret) and directly install.  
  
If Smart App Control is 'ON' (or 'OFF') you can use this script to install. Note this requires that you download the install package and flags/secret separately (as Smart App Control does not recognize the signature of the combined package). 
This script works by installing silently then copying the flags/secret to the correct location. 

Example Powershell usage:  
\# Authorize access for the script to run as RemoteSigned  
`Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`    
`powershell -ExecutionPolicy Bypass -File "C:\Users\Public\Documents\uptycs\install_sensor.ps1" -MsiPath "C:\Users\Public\Documents\uptycs\assets-uptycs-protect-5.14.1.17-Uptycs-LTS-windows.msi" -FSPath "C:\Users\Public\Documents\uptycs\assets-additionalFiles"`  
\# Run the script  
`.\install_sensor.ps1 -MsiPath "C:\Users\Public\Documents\uptycs\uptycs-protect-5.14.1.17-Uptycs-202503281456.msi" -FSPath "C:\Users\Public\Documents\uptycs\assets-additionalFiles"`

Note: There is also a run.bat provided that contains the above Powershell lines
