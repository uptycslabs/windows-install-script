# windows-install-script
Powershell script to install the Uptycs Windows agent (supports silent installation). 

Example command: 
.\install_sensor.ps1 -MsiPath "C:\Users\abacus\quality2\assets-uptycs-protect-5.14.1.17-Uptycs-LTS-windows.msi"

Example output: 
Installing MSI: C:\Users\abacus\quality2\assets-uptycs-protect-5.14.1.17-Uptycs-LTS-windows.msi
Log file: C:\Users\abacus\AppData\Local\Temp\assets-uptycs-protect-5.14.1.17-Uptycs-LTS-windows_install_20250721_032110.log
Silent mode: True
Starting installation...
/i "C:\Users\abacus\quality2\assets-uptycs-protect-5.14.1.17-Uptycs-LTS-windows.msi" /quiet /norestart /l*v "C:\Users\abacus\AppData\Local\Temp\assets-uptycs-protect-5.14.1.17-Uptycs-LTS-windows_install_20250721_032110.log"
Installation completed successfully!

