#define MyAppName "Alignment POC"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "JohanGrims"
#define MyAppExeName "alignment_poc.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{5E4B2F5D-A08C-49D6-BC6D-55A3D0AE217F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\build\windows\x64\installer
OutputBaseFilename=Alignment_POC_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\windows\runner\resources\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
