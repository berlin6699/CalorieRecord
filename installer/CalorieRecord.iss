#ifndef MyAppVersion
  #define MyAppVersion "1.0.12"
#endif
#ifndef MySourceDir
  #define MySourceDir "..\build\windows\x64\runner\Release"
#endif
#ifndef MyOutputDir
  #define MyOutputDir "..\dist"
#endif

#define MyAppName "CalorieRecord"
#define MyAppPublisher "CalorieRecord"
#define MyAppExeName "CalorieRecord.exe"

[Setup]
AppId={{C392FA88-4C3D-4FB6-8C91-872D4DEB7828}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\CalorieRecord
DefaultGroupName=CalorieRecord
DisableProgramGroupPage=yes
OutputDir={#MyOutputDir}
OutputBaseFilename=CalorieRecord-Setup-v{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
CloseApplications=force
RestartApplications=no
UsePreviousAppDir=yes
SetupLogging=yes

[Languages]
Name: "chinesesimplified"; MessagesFile: "ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "快捷方式："; Flags: checkedonce

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\CalorieRecord"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\CalorieRecord"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 CalorieRecord"; Flags: nowait postinstall skipifsilent
