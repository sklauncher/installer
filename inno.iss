#define AppName "SKlauncher"
#define AppURL "https://skmedix.pl"
#define AppVersion "3.2.12.0"
#define AppVersionPretty "3.2.12"
#define AppVersionShort "3.2"
#define AppAuthor "skmedix.pl"
#define AppDir "sklauncher"
#define JREVersion "25+36"
#define JREFolder "jdk-25+36-jre"
#define JRESHA256 "66abb3213ce984ecb7b3ae7edfeac2d58622297f8c114eb467518dd63e42aa3f"
#define JavaFXVersion "22.0.2"
#define MainJarFile "SKlauncher.jar"

[Setup]
AppId={{A151427E-7A46-4D6D-8534-C4C04BADA77A}
AppName={#AppName} {#AppVersionShort}
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
UninstallDisplayName={#AppName} {#AppVersionShort}
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
MinVersion=6.2.9200

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
  TempJREPath, FinalJREPath: String;
begin
  TempJREPath := ExpandConstant('{tmp}\{#JREFolder}');
  FinalJREPath := ExpandConstant('{app}\jre');

  Log('Starting JRE directory management...');
  Log('Temp JRE path: ' + TempJREPath);
  Log('Final JRE path: ' + FinalJREPath);

  // Remove existing jre directory if it exists
  if DirExists(FinalJREPath) then
  begin
    Log('Removing existing jre directory...');
    if DelTree(FinalJREPath, True, True, True) then
      Log('Successfully removed existing jre directory')
    else
      Log('Failed to remove existing jre directory');
  end;

  // Move the extracted JRE directory from temp to app directory
  if DirExists(TempJREPath) then
  begin
    Log('Moving JRE directory from ' + TempJREPath + ' to ' + FinalJREPath);

    // Ensure the app directory exists
    if not DirExists(ExpandConstant('{app}')) then
    begin
      Log('Creating app directory...');
      ForceDirectories(ExpandConstant('{app}'));
    end;

    if RenameFile(TempJREPath, FinalJREPath) then
      Log('Successfully moved JRE directory')
    else
      Log('Failed to move JRE directory');
  end
  else
    Log('Source JRE directory not found: ' + TempJREPath);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  ErrorMsg: String;
  i: Integer;
  URL: String;
begin
  Result := True;
  
  if CurPageID = wpReady then begin
    DownloadPage.Clear;
    
    Log('Starting download process...');
    
    // Add JRE download
    Log('Adding JRE download to queue...');
    DownloadPage.Add('https://github.com/adoptium/temurin25-binaries/releases/download/jdk-{#JREVersion}/OpenJDK25U-jre_x64_windows_hotspot_{#StringChange(JREVersion, '+', '_')}.zip',
      'jre.zip', '{#JRESHA256}');

    // Add JavaFX module downloads
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
        Log('Starting downloads...');
        DownloadPage.Download;
        Log('Downloads completed successfully');
      except
        if DownloadPage.AbortedByUser then begin
          Log('Download aborted by user.');
          ErrorMsg := 'Download was cancelled. SKlauncher requires Java and JavaFX to function. Setup cannot continue.';
        end else begin
          DownloadError := GetExceptionMessage;
          Log('Download error: ' + DownloadError);
          ErrorMsg := 'Failed to download required files: ' + DownloadError + #13#10 +
                     'SKlauncher requires Java and JavaFX to function. Please check your internet connection and try again.';
        end;
        SuppressibleMsgBox(ErrorMsg, mbCriticalError, MB_OK, IDOK);
        Result := False;
      end;
    finally
      DownloadPage.Hide;
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

procedure DoInstall;
begin
  RenameJRE;
  CopyJavaFXFiles;
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
Type: filesandordirs; Name: "{app}\{#JREFolder}"
Type: filesandordirs; Name: "{userappdata}\.minecraft\{#AppDir}"
Type: filesandordirs; Name: "{userappdata}\.minecraft\{#AppDir}\javafx"