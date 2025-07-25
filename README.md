# windows-install-script
Powershell script to install the Uptycs Windows agent (supports silent installation). 
This script will install the Uptycs agent msi on a Windows machine that does or does not have Smart App Control. 
If Smart App Control is set to 'On', it will set it to 'Eval' mode then ask the user to reboot (for changes to take effect), then run the script again.
The second time the script runs it will detect Smart App Control is not 'On' and will install Uptycs. 
For users without Smart App Control it will directly install Uptycs. 

Example usage:  
`.\install_sensor.ps1 -MsiPath "C:\Users\abacus\quality2\assets-uptycs-protect-5.14.1.17-Uptycs-LTS-windows.msi"`

If you face any unauthorize access error run below commands
1)Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
2)powershell -ExecutionPolicy Bypass -File "C:\Path\To\install_sensor.ps1" -MsiPath "C:\Users\abacus\quality2\assets-uptycs-protect-5.14.1.17-Uptycs-LTS-windows.msi"
