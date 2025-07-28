# windows-install-script
Powershell script to install the Uptycs Windows agent (supports silent installation). 
This script will install the Uptycs agent msi on a Windows machine that does or does not have Smart App Control. 
If Smart App Control is set to 'OFF',then you can double click and directly install else you can use the below script irrespective of Smart APP control status. 
Download the MSI , Flags& Secrets Separately and need to pass them as variables as shown below.

Example usage:  
` .\install_sensor.ps1 -MsiPath "C:\Users\abacus\uptycs-protect-5.14.1.17-Uptycs-202503281456.msi" -FSPath "C:\Users\abacus\flags&secrets"`

If you face any unauthorized access error run below commands:

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned  
powershell -ExecutionPolicy Bypass -File "C:\Path\To\install_sensor.ps1" -MsiPath "C:\path_to_msi\assets-uptycs-protect-5.14.1.17-Uptycs-LTS-windows.msi" -FSPath "C:\path_to_flags_and_secret"
