; Jan 1, 09 - First version, by Hans.Donner@pobox.com
; Jan 4, 09 - added PrivilegesRequired = none to prevent required Admin rights (not yet neede)
; - adding comments

; uses http://www.vincenzo.net/isxkb/index.php?title=PSVince to detect running files

; seperate installer logic from installer configuration (where to find stuff etc.)
#include "mindreader-setup-config.iss"

; make sure builds are uniquely identified
; from: http://www.vincenzo.net/isxkb/index.php?title=Incrementing_build_number_every_time_the_script_is_compiled
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

// TODO: change to AO? (but keep in mind the .. files=
DefaultDirName=''
DefaultGroupName={#AppName}
// TODO: add program group with links=
DisableProgramGroupPage=yes

OutputDir={#AppSetupDir}
OutputBaseFilename={#AppSetupFile}

LicenseFile={#LicenseFile}
InfoBeforeFile={#WarningFile}

Compression=lzma
SolidCompression=yes
PrivilegesRequired=none

[Languages]
; currently only available in 1 language
Name: english; MessagesFile: compiler:Default.isl

[Types]
; provide packages to choose from; these have default components (see below)
Name: Full; Description: Full installation
Name: Custom; Description: Custom; Flags: iscustom

[Components]
; logical grouping of various part
Name: main; Description: MindReader (main components); Types: Full
Name: config; Description: MindReader Configuration (selecting this option will NOT overwrite any existing configuration); Types: Full
Name: sample; Description: MindReader Sample Map; Types: Full

[Tasks]
; additional stuff to do
Name: gyroQ; Description: REPLACE GiroQ tags with MindReader default setup

[Files]
; the actual files used in the setup process
; first the files directly needed by the setup
Source: psvince.dll; Flags: dontcopy

; all the other files
Source: {#AppSourceDirMindReader}\\*; DestDir: {app}; Flags: ignoreversion recursesubdirs createallsubdirs; Components: main
Source: {#AppSourceDirMindReaderLegacy}\\*; DestDir: {app}\\..; skipifsourcedoesntexist Flags: ignoreversion recursesubdirs createallsubdirs; Components: main

Source: {#AppSourceDirMindReaderConfig}\\*; DestDir: {app}; Flags: skipifsourcedoesntexist ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist uninsneveruninstall; Components: config
Source: {#AppSourceDirMindReaderConfigLegacy}\\*; DestDir: {app}\\..; Flags: skipifsourcedoesntexist ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist uninsneveruninstall; Components: config

Source: {#AppSourceDirMindReaderSample}\\*; DestDir: {app}; Flags: skipifsourcedoesntexist ignoreversion recursesubdirs createallsubdirs; Components: sample
Source: {#AppSourceDirMindReaderSampleLegacy}\\*; DestDir: {app}\\..; Flags: skipifsourcedoesntexist ignoreversion recursesubdirs createallsubdirs; Components: sample

Source: {#AppSourceDirGyroQConfig}\\*; DestDir: {app}; Flags: ignoreversion recursesubdirs createallsubdirs uninsneveruninstall; Tasks: gyroQ

// Use registry for correct placing of GyroQ ini file: 
// HKCU | Software\Gyronix\GyroQ\Settings | WkgDir: 


[Code]
// As this is Pascal scripting, procedures/functions must
// first be declared/defined before they can be called!

function IsModuleLoaded(modulename: String ):  Boolean;
  external 'IsModuleLoaded@files:psvince.dll stdcall';
  // from http://www.vincenzo.net/isxkb/index.php?title=PSVince

var

// Custom Wizard Pages
  MmVersionPage: TInputOptionWizardPage;
  ConfirmDirPage: TInputDirWizardPage;

// MmVersionIndexes
  // keep in sync with other MmVersion functions/procedures/constants
  // values are set in CreateMmVersionPage
  // used for 'translation'
  MmVersionIndex7,
  MmVersionIndex8,
  MmVersionIndexUnknown: Integer;

const
// TODO: rename to UPPERCASE_UNDERSCORE

  DEFAULT_AO_DIR = 'AO';

// Tasks used
  TaskGyroQ = 'gyroQ';

// DataKey
  // Used for storing in registry
  DataKeyMmVersion = 'MindManager';

// MmVersionString
  // keep in synch with other MmVersion functions/procedures/variables
  // used for 'translation', and stored in registry (thus change with caution)
  MmVersionString7 = '7';
  MmVersionString8 = '8';
  MmVersionStringUnknown = '';

// Running
  // names of apps that can be running and maybe have to be closed
  RunningGyroQ = 'GyroQ.exe';

// Various
  DirUnknown = '';



// ==========
// Running Apps
// ==========

function AllAppsClosed(): Boolean;
// Check if all related apps are not running
begin
  Result := Not(IsTaskSelected(taskGyroQ) And IsModuleLoaded(RunningGyroQ));
end;

// ==========
// MmVersion
// ==========

function TranslateMmVersionString(VersionString: String): Integer;
// Converts from the registry stored value to the Wizard page option index
  // keep in synch with other MmVersion function/procedures
begin
  case VersionString of
    MmVersionString7: Result := MmVersionIndex7;
    MmVersionString8: Result := MmVersionIndex8;
  else
    Result := MmVersionIndexUnknown;
  end;
end;

function TranslateMmVersionIndex(VersionIndex: Integer): String;
// Converts from the Wizard page option index to the registry stored value
  // keep in synch with other MmVersion function/procedures
begin
  case VersionIndex of
    MmVersionIndex7: Result := MmVersionString7;
    MmVersionIndex8: Result := MmVersionString8;
  else
    Result := MmVersionStringUnknown;
  end;
end;

function GuessMmVersion(): string;
// Tries to guess what Mm version is running
var
  GyroActivatorPathKeyName,
  GyroActivatorPathValueName,
  MmVersion: String;
begin
  // TODO: move to Const?
  GyroActivatorPathKeyName := 'Software\Gyronix\GyroActivator\Settings';
  GyroActivatorPathValueName := 'MindManager';

  if not RegQueryStringValue(HKCU, GyroActivatorPathKeyName, GyroActivatorPathValueName, MmVersion) then begin
    MmVersion := MmVersionStringUnknown;
  end;

  Result := MmVersion;
end;

procedure CreateMmVersionPage;
// Keep in synch with other MmVersion function/procedures
begin
  MmVersionPage := CreateInputOptionPage(wpUserInfo,
    'MindManager Version', 'What version of MindManager are you using?',
    'Please specify what version of MindManager you are using, then click Next.',
    True, False);

  // Number MmVersionIndex.. sequentially, starting at 0

  MmVersionPage.Add('MindManager v7');
  MmVersionIndex7 := 0;

  MmVersionPage.Add('MindManager v8');
  MmVersionIndex8 := 1;

  MmVersionPage.Add('Unknown/Not listed here (not supported)');
  MmVersionIndexUnknown := 2;

  MmVersionPage.SelectedValueIndex := TranslateMmVersionString(GetPreviousData (DataKeyMmVersion,GuessMmVersion()));
end;

// ==========

function getMyMapsDir(): String;
// Tries to guess where the install must be done
var
  MindjetPathKeyName,
  MindjetPathValueName,
  DocDir: String;
begin
  // TODO: move to Const?
  // TODO: create function for replacement?
  MindjetPathKeyName := 'Software\Mindjet\MindManager\'
    + TranslateMmVersionIndex(MmVersionPage.SelectedValueIndex) + '\Settings';
  MindjetPathValueName := 'DocumentDirectory';

  if not RegQueryStringValue(HKCU, MindjetPathKeyName, MindjetPathValueName, DocDir) then begin
    DocDir := DirUnknown;
  end;

  Result := DocDir;
end;

procedure createConfirmDirPage;
begin
  ConfirmDirPage := CreateInputDirPage(MmVersionPage.ID,
    'Confirm MyMaps Directory', 'Is this the location of your MyMaps Directory?',
    'Setup assumes your MyMaps is the following folder.'#13#10 +
    'If you specify another folder as the MyMaps folder, AO might not work!',
    False, 'New Folder');

  ConfirmDirPage.Add('To continue, click Next. If you would like to select a different folder, click Browse.');

  ConfirmDirPage.Values[0] := getMyMapsDir;

end;

procedure UpdateSelectDirPage;
begin
  // Adjust labels
  WizardForm.SelectDirLabel.Caption := 'If you specify another folder as the MyMaps\'
    + DEFAULT_AO_DIR + ' folder, AO will not work!.'

  // Set Default value
  WizardForm.DirEdit.Text := addbackslash(ConfirmDirPage.Values[0]) + DEFAULT_AO_DIR;
end;

// ==========
// INNO Event procedures/functions
//   see INNO help for additional information
// ==========

procedure InitializeWizard;
begin

  // Create additional wizard pages
	CreateMmVersionPage;
    CreateConfirmDirPage;
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
begin
  SetPreviousData(PreviousDataKey, DataKeyMmVersion, TranslateMmVersionIndex(MmVersionPage.SelectedValueIndex));
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  // By default continue to next page
  Result := True;

  // unless
  case CurPageID of

  // MmVersion is unknown
    MmVersionPage.ID:
      if MmVersionPage.SelectedValueIndex = MmVersionIndexUnknown then begin
          Result := False;
          MsgBox('Only the listed version of MindManager are supported' #13#13
            'Please select one of the listed versions or Cancel thet setup.', mbInformation, MB_OK);
      end;

  // Apps are running that must be closed down first
  // TODO: setup to re-start them?
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

// ==========
// for debug purposes
  // write out the 'true' story
  // must be at the end of all coding to give a complete file

#ifdef Debug
  #expr SaveToFile(AddBackslash(SourcePath) + "Preprocessed.iss")
#endif

// place nothing below!
