#define AppName "SKlauncher"
#define AppURL "https://skmedix.pl"
#define AppVersion "3.2.17.0"
#define AppVersionPretty "3.2.17"
#define AppAuthor "skmedix.pl"
#define AppDir "sklauncher"
#define JavaFXVersion "22.0.2"
#define MainJarFile "SKlauncher.jar"

#define ZuluJREUrl "https://cdn.azul.com/zulu/bin/zulu21.46.19-ca-jre21.0.9-win_x64.zip"
#define ZuluJREFolder "zulu21.46.19-ca-jre21.0.9-win_x64"
#define ZuluJRESHA256 "a72b61a7902ea2baf940fca8e89913e2347b98c294943632a4f9621c0226e684"

#define AdoptiumJREUrl "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.9%2B10/OpenJDK21U-jre_x64_windows_hotspot_21.0.9_10.zip"
#define AdoptiumJREFolder "jdk-21.0.9+10-jre"
#define AdoptiumJRESHA256 "39c5e23f3ce4d420663afba8ffde28034b72e2b3e240943dc2321bc1f912eef9"

#define Zulu8JREUrl "https://cdn.azul.com/zulu/bin/zulu8.90.0.19-ca-fx-jre8.0.472-win_x64.zip"
#define Zulu8JREFolder "zulu8.90.0.19-ca-fx-jre8.0.472-win_x64"
#define Zulu8JRESHA256 "4383fed694c640886dc99a1c38c4f2b3d035a6a4911f17ea8f8dcd35188b527a"

[Setup]
AppId={{A151427E-7A46-4D6D-8534-C4C04BADA77A}
AppName={#AppName} {#AppVersionPretty}
AppVersion={#AppVersion}
AppPublisher={#AppAuthor}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
VersionInfoVersion={#AppVersion}
DefaultDirName={userappdata}\{#AppDir}
DisableProgramGroupPage=no
DefaultGroupName={#AppName}
PrivilegesRequired=lowest
OutputBaseFilename={#AppName}_{#AppVersionPretty}_Setup
SetupIconFile=img/icon.ico
UninstallDisplayIcon={app}\icon.ico
UninstallDisplayName={#AppName} {#AppVersionPretty}
ArchiveExtraction=full
; start - https://stackoverflow.com/a/77553798
Compression=zip
SolidCompression=no
; stop  - https://stackoverflow.com/a/77553798
WizardStyle=modern
WizardSmallImageFile=img/small.bmp
WizardImageFile=img/large.bmp
ExtraDiskSpaceRequired=52428800
DisableWelcomePage=no
DisableDirPage=auto
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DirExistsWarning=no
MinVersion=6.1.7600

[Files]
Source: "{#MainJarFile}"; DestDir: "{app}"; Flags: ignoreversion
Source: "img\icon.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "{tmp}\jre.zip"; DestDir: "{tmp}"; Flags: external extractarchive recursesubdirs createallsubdirs ignoreversion deleteafterinstall

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\jre\bin\javaw.exe"; Parameters: "-Xmx512M -jar ""{app}\{#MainJarFile}"""; IconFilename: "{app}\icon.ico"; WorkingDir: "{app}"
Name: "{userdesktop}\{#AppName}"; Filename: "{app}\jre\bin\javaw.exe"; Parameters: "-Xmx512M -jar ""{app}\{#MainJarFile}"""; IconFilename: "{app}\icon.ico"; WorkingDir: "{app}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"; IconFilename: "{app}\icon.ico"

[Install]
Name: "JavaFXCopy"; Description: "Copy JavaFX files"; Types: full; Flags: fixed

[Messages]
WelcomeLabel1=Welcome to the installation of {#AppName}!
WelcomeLabel2=This will install {#AppName} on your computer.%n%nIt is recommended that you close all other applications before continuing.

[Dirs]
Name: "{userappdata}\.minecraft\{#AppDir}"
Name: "{userappdata}\.minecraft\{#AppDir}\javafx"

[Code]
var
  DownloadPage: TDownloadWizardPage;
  DownloadError: String;
  JavaFXModules: array[0..5] of string;
  CurrentJREFolder: String;

function OnDownloadProgress(Url, FileName: String; Progress, ProgressMax: Int64): Boolean;
begin
  if Progress = ProgressMax then
    Log(Format('Successfully downloaded file to {tmp}: %s', [FileName]));
  Result := True;
end;

procedure InitializeWizard;
begin
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), @OnDownloadProgress);

  JavaFXModules[0] := 'javafx-base';
  JavaFXModules[1] := 'javafx-graphics';
  JavaFXModules[2] := 'javafx-controls';
  JavaFXModules[3] := 'javafx-media';
  JavaFXModules[4] := 'javafx-swing';
  JavaFXModules[5] := 'javafx-web';
end;

function GetJavaFXDownloadURL(Module: String; IsSHA1: Boolean): String;
var
  BaseURL: String;
begin
  BaseURL := 'https://maven.skmedix.pl/org/openjfx/' + Module + '/' + '{#JavaFXVersion}' + '/' + Module + '-' + '{#JavaFXVersion}';
  
  if IsSHA1 then
    Result := BaseURL + '-win.jar.sha1'
  else
    Result := BaseURL + '-win.jar';
  
  Log('Generated URL: ' + Result);
end;

function LoadSHA1(const FileName: String; var SHA1: String): Boolean;
var
  LoadedString: AnsiString;
begin
  Result := False;
  SHA1 := '';
  
  if FileExists(FileName) then
  begin
    if LoadStringFromFile(FileName, LoadedString) then
    begin
      SHA1 := Trim(String(LoadedString));
      Result := True;
      Log('Successfully loaded SHA1 from: ' + FileName + ' - Value: ' + SHA1);
    end
    else
      Log('Failed to load content from SHA1 file: ' + FileName);
  end
  else
    Log('SHA1 file not found: ' + FileName);
end;

procedure RenameJRE;
var
  TempJREPath, FinalJREPath, TempBackupPath: String;
begin
  TempJREPath := ExpandConstant('{tmp}\') + CurrentJREFolder;
  FinalJREPath := ExpandConstant('{app}\jre');
  TempBackupPath := ExpandConstant('{app}\jre_backup');

  Log('Starting JRE directory management...');
  Log('Temp JRE path: ' + TempJREPath);
  Log('Final JRE path: ' + FinalJREPath);

  if not DirExists(TempJREPath) then
  begin
    Log('Source JRE directory not found: ' + TempJREPath);
    Log('Keeping existing JRE directory if present to avoid leaving user with empty JRE');
    Exit;
  end;

  if not FileExists(TempJREPath + '\bin\javaw.exe') then
  begin
    Log('Extracted JRE appears to be empty or invalid (javaw.exe not found)');
    Log('Keeping existing JRE directory if present to avoid leaving user with broken JRE');
    Exit;
  end;

  Log('New JRE extracted and validated successfully, proceeding with replacement...');

  if not DirExists(ExpandConstant('{app}')) then
  begin
    Log('Creating app directory...');
    ForceDirectories(ExpandConstant('{app}'));
  end;

  if DirExists(FinalJREPath) then
  begin
    if FileExists(FinalJREPath + '\bin\javaw.exe') then
    begin
      Log('Existing JRE is valid, backing up to: ' + TempBackupPath);
      if DirExists(TempBackupPath) then
        DelTree(TempBackupPath, True, True, True);
      
      if RenameFile(FinalJREPath, TempBackupPath) then
        Log('Successfully backed up existing jre directory')
      else
      begin
        Log('Failed to backup existing jre directory, trying direct delete...');
        if DelTree(FinalJREPath, True, True, True) then
          Log('Successfully removed existing jre directory')
        else
          Log('Failed to remove existing jre directory');
      end;
    end
    else
    begin
      Log('Existing JRE is broken (javaw.exe not found), deleting directly...');
      if DelTree(FinalJREPath, True, True, True) then
        Log('Successfully removed broken jre directory')
      else
        Log('Failed to remove broken jre directory');
    end;
  end;

  Log('Moving JRE directory from ' + TempJREPath + ' to ' + FinalJREPath);
  if RenameFile(TempJREPath, FinalJREPath) then
  begin
    Log('Successfully moved JRE directory');
    if DirExists(TempBackupPath) then
    begin
      Log('Removing backup directory...');
      DelTree(TempBackupPath, True, True, True);
    end;
  end
  else
  begin
    Log('Failed to move JRE directory');
    if DirExists(TempBackupPath) and not DirExists(FinalJREPath) then
    begin
      Log('Restoring backup JRE directory...');
      if RenameFile(TempBackupPath, FinalJREPath) then
        Log('Successfully restored backup JRE directory')
      else
        Log('Failed to restore backup JRE directory');
    end;
  end;
end;

function TryDownloadJRE(JREURL, JRESHA256, JREFolderName: String): Boolean;
begin
  Result := False;
  DownloadPage.Clear;
  Log('Trying JRE download from: ' + JREURL);
  DownloadPage.Add(JREURL, 'jre.zip', JRESHA256);
  
  DownloadPage.Show;
  try
    try
      DownloadPage.Download;
      Log('JRE download completed successfully from: ' + JREURL);
      Result := True;
    except
      if DownloadPage.AbortedByUser then
        Log('Download aborted by user')
      else
      begin
        DownloadError := GetExceptionMessage;
        Log('JRE download failed from ' + JREURL + ': ' + DownloadError);
      end;
    end;
  finally
    DownloadPage.Hide;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  ErrorMsg: String;
  i: Integer;
  URL: String;
  JavaFXDownloadFailed: Boolean;
  JREDownloaded: Boolean;
  WindowsVersion: TWindowsVersion;
  IsLegacyWindows: Boolean;
begin
  Result := True;
  
  if CurPageID = wpReady then begin
    JavaFXDownloadFailed := False;
    JREDownloaded := False;
    
    GetWindowsVersionEx(WindowsVersion);
    IsLegacyWindows := (WindowsVersion.Major < 10);
    
    Log('Windows version: ' + IntToStr(WindowsVersion.Major) + '.' + IntToStr(WindowsVersion.Minor));
    if IsLegacyWindows then
      Log('Legacy Windows detected (7/8/8.1)')
    else
      Log('Modern Windows detected (10+)');
    
    if IsLegacyWindows then
    begin
      Log('Detected Windows 7/8/8.1, using Zulu JRE 8 with JavaFX...');
      if TryDownloadJRE('{#Zulu8JREUrl}', '{#Zulu8JRESHA256}', '{#Zulu8JREFolder}') then
      begin
        JREDownloaded := True;
        CurrentJREFolder := '{#Zulu8JREFolder}';
      end;
    end
    else
    begin
      Log('Detected Windows 10+, using JRE 21 with mirror support...');
      
      Log('Trying primary mirror (Azul Zulu 21)...');
      if TryDownloadJRE('{#ZuluJREUrl}', '{#ZuluJRESHA256}', '{#ZuluJREFolder}') then
      begin
        JREDownloaded := True;
        CurrentJREFolder := '{#ZuluJREFolder}';
      end
      else
      begin
        Log('Primary mirror failed, trying fallback (Adoptium)...');
        if TryDownloadJRE('{#AdoptiumJREUrl}', '{#AdoptiumJRESHA256}', '{#AdoptiumJREFolder}') then
        begin
          JREDownloaded := True;
          CurrentJREFolder := '{#AdoptiumJREFolder}';
        end;
      end;
    end;
    
    if not JREDownloaded then
    begin
      ErrorMsg := 'Failed to download Java Runtime from all mirrors.' + #13#10 +
                 'SKlauncher requires Java to function. Please check your internet connection and try again.';
      SuppressibleMsgBox(ErrorMsg, mbCriticalError, MB_OK, IDOK);
      Result := False;
      Exit;
    end;
    
    if IsLegacyWindows then
    begin
      Log('Skipping JavaFX download for legacy Windows (JRE 8 includes JavaFX)');
    end
    else
    begin
      DownloadPage.Clear;
      Log('Starting JavaFX download process...');
      
      for i := 0 to 5 do begin
        URL := GetJavaFXDownloadURL(JavaFXModules[i], False);
        Log('Adding JavaFX module to queue: ' + URL);
        DownloadPage.Add(URL, 'javafx-' + IntToStr(i) + '.jar', '');
        
        URL := GetJavaFXDownloadURL(JavaFXModules[i], True);
        Log('Adding JavaFX SHA1 to queue: ' + URL);
        DownloadPage.Add(URL, 'javafx-' + IntToStr(i) + '.jar.sha1', '');
      end;

      DownloadPage.Show;
      try
        try
          Log('Starting JavaFX downloads...');
          DownloadPage.Download;
          Log('JavaFX downloads completed successfully');
        except
          if DownloadPage.AbortedByUser then begin
            Log('JavaFX download aborted by user.');
            ErrorMsg := 'JavaFX download was cancelled. The launcher will attempt to download JavaFX on first run.';
          end else begin
            DownloadError := GetExceptionMessage;
            Log('JavaFX download error (non-critical): ' + DownloadError);
            ErrorMsg := 'Failed to download JavaFX: ' + DownloadError + #13#10#13#10 +
                       'Installation will continue. The launcher will attempt to download JavaFX on first run.';
          end;
          SuppressibleMsgBox(ErrorMsg, mbInformation, MB_OK, IDOK);
          JavaFXDownloadFailed := True;
        end;
      finally
        DownloadPage.Hide;
      end;
      
      if JavaFXDownloadFailed then
        Log('Continuing installation despite JavaFX download failure');
    end;
  end;
end;

procedure CopyJavaFXFiles;
var
  i: Integer;
  SourceFile, SourceSHA1, DestFile, DestSHA1, DestDir: String;
begin
  Log('Starting JavaFX files copy process...');
  
  DestDir := ExpandConstant('{userappdata}\.minecraft\{#AppDir}\javafx');
  Log('Destination directory: ' + DestDir);
  
  // Ensure the destination directory exists
  if not DirExists(DestDir) then
  begin
    Log('Creating destination directory...');
    if ForceDirectories(DestDir) then
      Log('Successfully created directory: ' + DestDir)
    else
      Log('Failed to create directory: ' + DestDir);
  end;
    
  for i := 0 to 5 do begin
    SourceFile := ExpandConstant('{tmp}\javafx-' + IntToStr(i) + '.jar');
    SourceSHA1 := ExpandConstant('{tmp}\javafx-' + IntToStr(i) + '.jar.sha1');
    DestFile := DestDir + '\' + JavaFXModules[i] + '-{#JavaFXVersion}-win.jar';
    DestSHA1 := DestFile + '.sha1';

    Log('Processing JavaFX module ' + IntToStr(i) + ':');
    Log('  Source: ' + SourceFile);
    Log('  Source SHA1: ' + SourceSHA1);
    Log('  Destination: ' + DestFile);
    Log('  Destination SHA1: ' + DestSHA1);

    if FileExists(SourceFile) then begin
      if CopyFile(SourceFile, DestFile, False) then
        Log('  Successfully copied JavaFX module')
      else
        Log('  Failed to copy JavaFX module');
        
      if FileExists(SourceSHA1) then begin
        if CopyFile(SourceSHA1, DestSHA1, False) then
          Log('  Successfully copied SHA1 file')
        else
          Log('  Failed to copy SHA1 file');
      end else
        Log('  SHA1 file not found: ' + SourceSHA1);
    end else
      Log('  Source file not found: ' + SourceFile);
  end;
  
  Log('JavaFX files copy process completed');
end;

function ValidateInstallation: Boolean;
var
  JavawPath: String;
begin
  Result := True;
  JavawPath := ExpandConstant('{app}\jre\bin\javaw.exe');
  
  Log('Validating installation...');
  Log('Checking for javaw.exe at: ' + JavawPath);
  
  if not FileExists(JavawPath) then
  begin
    Log('CRITICAL: javaw.exe not found at expected location');
    Result := False;
  end
  else
    Log('Validation successful: javaw.exe found');
end;

procedure DoInstall;
var
  ErrorMsg: String;
begin
  RenameJRE;
  CopyJavaFXFiles;
  
  if not ValidateInstallation then
  begin
    ErrorMsg := 'Installation validation failed: Java Runtime (javaw.exe) was not found.' + #13#10#13#10 +
               'This may be due to a download or extraction failure.' + #13#10 +
               'Please try running the installer again or contact support.';
    SuppressibleMsgBox(ErrorMsg, mbCriticalError, MB_OK, IDOK);
    Abort;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    DoInstall;
  end;
end;

[Run]

; Launch the JAR file after installation
Filename: "{app}\jre\bin\javaw.exe"; Parameters: "-Xmx512M -jar ""{app}\{#MainJarFile}"""; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\jre"
Type: filesandordirs; Name: "{userappdata}\.minecraft\{#AppDir}"
Type: filesandordirs; Name: "{userappdata}\.minecraft\{#AppDir}\javafx"
