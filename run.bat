Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

powershell -ExecutionPolicy Bypass -File "C:\Users\Public\Documents\uptycs\install_sensor.ps1" -MsiPath "C:\Users\Public\Documents\uptycs\assets-uptycs-protect-5.14.1.17-Uptycs-LTS-windows.msi" -FSPath "C:\Users\Public\Documents\uptycs\assets-additionalFiles"

.\install_sensor.ps1 -MsiPath "C:\Users\Public\Documents\uptycs\uptycs-protect-5.14.1.17-Uptycs-202503281456.msi" -FSPath "C:\Users\Public\Documents\uptycs\assets-additionalFiles"
