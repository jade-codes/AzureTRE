# 1) Block the privacy consent screen (system-wide)
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE' `
  -Name 'DisablePrivacyExperience' -Value 1 -PropertyType DWord -Force

# 2) Disable "Let's finish setting up..." for all future users
reg load HKU\DefUser "C:\Users\Default\NTUSER.DAT"
reg add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" `
  /v ScoobeSystemSettingEnabled /t REG_DWORD /d 0 /f
reg unload HKU\DefUser

# 3) (Optional) Turn off consumer experiences
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' `
  -Name 'DisableConsumerFeatures' -Value 1 -PropertyType DWord -Force
