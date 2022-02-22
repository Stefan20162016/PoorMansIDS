#define ExeName "PoorMansIDS"

[Setup]
AppName=PoorMansIDS
AppVersion=0.1
AppVerName=PoorMansIDS Beta
AppPublisherURL=https://github.com/Stefan20162016/PoorMansIDS
ArchitecturesInstallIn64BitMode=x64
Compression=lzma2/ultra64
SolidCompression=yes
DefaultDirName={code:DefDirRoot}\{#ExeName}
SetupIconFile=PoorIDS.ico
UninstallDisplayIcon={app}\PoorIDS.ico
PrivilegesRequired=lowest
WizardImageFile=installer-large.bmp
WizardSmallImageFile=installer-small.bmp

[Files]
Source: "PoorMansIDS.exe"; DestDir: "{app}"
Source: "PoorMansIDS.ps1"; DestDir: "{app}"
Source: "Hardcodet.NotifyIcon.Wpf.dll"; DestDir: "{app}"
Source: "Hardcodet.NotifyIcon.Wpf.xml"; DestDir: "{app}"
Source: "PoorIDS.ico"; DestDir: "{app}"

[Registry]
Root: HKCU; Subkey: Software\Microsoft\Windows\CurrentVersion\Run; ValueType: string; ValueName: {#ExeName}; ValueData: """{app}\{#ExeName}.exe"""; Permissions: users-modify; Flags: uninsdeletevalue noerror; Tasks: startup; Check: IsRegularUser
; HKEY_LOCAL_MACHINE - for all users when admin
Root: HKLM; Subkey: Software\Microsoft\Windows\CurrentVersion\Run; ValueType: string; ValueName: {#ExeName}; ValueData: """{app}\{#ExeName}.exe"""; Permissions: admins-modify; Flags: uninsdeletevalue noerror; Tasks: startup; Check: not IsRegularUser

[Tasks]
Name: startup; Description: "Start with Windows a.k.a. RUN registry entry"

[Dirs]
Name: {app}; Permissions: users-full

[Code]
function IsRegularUser(): Boolean;
begin
	Result := not (IsAdmin or IsAdminInstallMode);
end;

function DefDirRoot(Param: String): String;
begin
	if IsRegularUser then
		Result := ExpandConstant('{localappdata}')
	else
		Result := ExpandConstant('{pf}')
end;


[Run]
Filename: "{app}\{#ExeName}.exe"; Description: "Start (poor) IDS"; WorkingDir: "{app}"; Flags: nowait postinstall runasoriginaluser


