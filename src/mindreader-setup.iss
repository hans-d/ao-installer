; Don't overwrite gyroq.ini if you would rather install the tags one by one from the wiki.
; If you do want to install all the tags at once, make sure you fully exit from GyroQ to avoid confusing it.
; For existing users, AO-PACK provides a way to update your system with most recent tags/macros if you haven't
; added significant customizations. See MindReader Quick Start for installation instructions.

#include "mindreader-setup-config.iss"

; From: http://www.vincenzo.net/isxkb/index.php?title=Incrementing_build_number_every_time_the_script_is_compiled
#define BuildNum Int(ReadIni(SourcePath	+ "\\BuildInfo.ini","Info","Build","0"))
#expr BuildNum = BuildNum + 1
#expr WriteIni(SourcePath + "\\BuildInfo.ini","Info","Build", BuildNum)

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{6F5BB59E-63DC-4C70-A649-7942BA9EC6B8}
AppName={#AppName}
AppVerName={#AppName} v {#AppMajorVersion}.{#BuildNum}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}

DefaultDirName=.
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes

OutputDir={#AppSetupDir}
OutputBaseFilename={#AppSetupFile}
Compression=lzma
SolidCompression=yes

[Languages]
Name: english; MessagesFile: compiler:Default.isl

[Types]
Name: Full; Description: Full installation; Languages: 
Name: Custom; Description: Custom; Flags: iscustom

[Components]
Name: main; Description: MindReader (main components); Types: Full
Name: config; Description: MindReader Configuration (only installed when they do not exist); Types: Full
Name: sample; Description: MindReader Sample Map; Types: Full


[Tasks]
Name: gyroQ; Description: Replace GiroQ tags with MindReader defaul setup

[Files]
Source: psvince.dll; Flags: dontcopy; Components: 
Source: {#AppSourceDirMindReader}\\*; DestDir: {app}; Flags: ignoreversion recursesubdirs createallsubdirs; Components: main
Source: {#AppSourceDirMindReaderConfig}\\*; DestDir: {app}; Flags: ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist uninsneveruninstall; Components: config
Source: {#AppSourceDirMindReaderSample}\\*; DestDir: {app}; Flags: ignoreversion recursesubdirs createallsubdirs; Components: sample
Source: {#AppSourceDirGyroQConfig}\\*; DestDir: {app}; Flags: ignoreversion recursesubdirs createallsubdirs uninsneveruninstall; Tasks: gyroQ


[Code]
// uses http://www.vincenzo.net/isxkb/index.php?title=PSVince

function IsModuleLoaded(modulename: String ):  Boolean;
external 'IsModuleLoaded@files:psvince.dll stdcall';


var
  MmVersionPage: TInputOptionWizardPage;
  ConfirmDirPage: TInputDirWizardPage;

const
  DataKeyMmVersion = 'MindManager';

  RunningGyroQ = 'GyroQ.exe';

// Keep in synch with other MmVersion function/procedures
  MmVersionString7 = '7';
  MmVersionString8 = '8';

  MmVersionIndex7 = 0;
  MmVersionIndex8 = 1;
  MmVersionIndexUnknown = 2;

// ==========
// Running Apps
// ==========

function AllAppsClosed(): Boolean;
begin
  Result := Not(IsTaskSelected('gyroQ') And IsModuleLoaded(RunningGyroQ));
end;


// ==========
// MmVersion
// ==========

function TranslateMmVersionString(VersionString: String): Integer;
// Keep in synch with other MmVersion function/procedures
begin
  case VersionString of
    MmVersionString7: Result := MmVersionIndex7;
    MmVersionString8: Result := MmVersionIndex8;
  else
    Result := MmVersionIndexUnknown;
  end;
end;

function TranslateMmVersionIndex(VersionIndex: Integer): String;
// Keep in synch with other MmVersion function/procedures
begin
  case VersionIndex of
    MmVersionIndex7: Result := MmVersionString7;
    MmVersionIndex8: Result := MmVersionString8;
  else
    Result := '';
  end;
end;

function GuessMmVersion(): string;
var
  GyroActivatorPathKeyName,
  GyroActivatorPathValueName,
  MmVersion: String;
begin
  GyroActivatorPathKeyName := 'Software\Gyronix\GyroActivator\Settings';
  GyroActivatorPathValueName := 'MindManager';

  if not RegQueryStringValue(HKCU, GyroActivatorPathKeyName, GyroActivatorPathValueName, MmVersion) then begin
    MmVersion := '';
  end;

  Result := MmVersion;
end;

procedure CreateMmVersionPage;
// Keep in synch with other MmVersion function/procedures
begin
  MmVersionPage := CreateInputOptionPage(wpWelcome,
    'MindManager Version', 'What version of MindManager are you using?',
    'Please specify what version of MindManager you are using, then click Next.',
    True, False);
  MmVersionPage.Add('MindManager v7');
  MmVersionPage.Add('MindManager v8');
  MmVersionPage.Add('Unknown/Not listed here (not supported)');

  MmVersionPage.SelectedValueIndex := TranslateMmVersionString(GetPreviousData (DataKeyMmVersion,GuessMmVersion()));
end;

// ==========

function getInstallDir(): String;
var
  MindjetPathKeyName,
  MindjetPathValueName,
  DocDir: String;
begin
  MindjetPathKeyName := 'Software\Mindjet\MindManager\'
    + TranslateMmVersionIndex(MmVersionPage.SelectedValueIndex) + '\Settings';
  MindjetPathValueName := 'DocumentDirectory';

  if not RegQueryStringValue(HKCU, MindjetPathKeyName, MindjetPathValueName, DocDir) then begin
    DocDir := '';
  end;

  Result := DocDir;

end;

procedure UpdateSelectDirPage;
// Adjusting is easier as creating a whole new Wizard Page
var
	x: TNewStaticText;
begin
  // Adjust labels
  WizardForm.PageNameLabel.Caption := 'Confirm MyMaps Directory';
  WizardForm.PageDescriptionLabel.Caption := 'Is this the location of your MyMaps Directory?';
  WizardForm.SelectDirLabel.Caption := 'Setup assumes your MyMaps is the following folder';

  // Set Default value
  WizardForm.DirEdit.Text := getInstallDir;

end;


// ==========

procedure InitializeWizard;
begin
	CreateMmVersionPage;
//	CreateConfirmDirPage;
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
begin
  SetPreviousData(PreviousDataKey, DataKeyMmVersion, TranslateMmVersionIndex(MmVersionPage.SelectedValueIndex));
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True; // By default continue

  case CurPageID of
    MmVersionPage.ID:
      if MmVersionPage.SelectedValueIndex = MmVersionIndexUnknown then begin
          Result := False;
          MsgBox('Only the listed version of MindManager are supported' #13#13
            'Please select one of the listed versions or Cancel thet setup.', mbInformation, MB_OK);
      end
    wpSelectTasks:
      if not AllAppsClosed() then begin
        // TODO: make this a nice page etc.
        Result := False;
        MsgBox('GyroQ is detected to be running. Please close it and retry.', mbError, MB_OK);
      end;
  end;

end;

procedure CurPageChanged(CurPageID: Integer);
begin
  case CurPageID of
    wpSelectDir:
	  UpdateSelectDirPage;
  end;
end;


// HKCU | Software\Gyronix\GyroActivator\Settings | MindManager
// HKCU | Software\Gyronix\GyroQ\Settings | WkgDir
// HKCU | Software\Mindjet\8\Settings | DocumentDirectory




// For Debug purposes
#ifdef Debug
  #expr SaveToFile(AddBackslash(SourcePath) + "Preprocessed.iss")
#endif
