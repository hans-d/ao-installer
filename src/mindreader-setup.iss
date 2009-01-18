; AO Installer
;   see www.activityowner.com for the AO Tools

; History:
; Jan 17, 09 - Hans.Donner@pobox.com
;   - add MM 6 support
;   - fixed a 'sleeping' bug regarding moment of version checking
;   - checks if MyMaps can be found
;   - non-editable destination dir
;   - check for used apps (RM, Gyroq)
; Jan 16, 09 - Hans.Donner@pobox.com
;   - spelling and correct GyroQ
; Jan 12, 09 - Hans.Donner@pobox.com
;   - show license, warning and install to AO
; Jan 4, 09 - Hans.Donner@pobox.com
;   - added PrivilegesRequired = none to prevent required Admin rights (not yet needed)
;   - adding comments
; Jan 1, 09 - Hans.Donner@pobox.com
;   - First version

; uses http://www.vincenzo.net/isxkb/index.php?title=PSVince to detect running files

; Install flow;
; - Welcome
; - License Agreement - LicenseFile is set
; - Information - InfoBeforeFile is set
; - MmVersion - User selects used MmVersion, perform checks
; - Select Destination Location - Shown, but not able to change the Destination
; - Select Components
; Select Start Menu Folder
; Shown if there are any [Icons] entries, but can be disabled via DisableProgramGroupPage.
; - Select Tasks
; - Ready to Install
; - Preparing to Install - Normally, Setup will never stop on this page.
; - Installing
; Information
; Shown if InfoAfterFile is set.
; - Setup Completed


; ======

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

[Messages]
SelectDirBrowseLabel=This is a fixed location (AO) under your MyMaps folder.

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
Name: gyroQ; Description: REPLACE GyroQ tags with MindReader default setup

[Files]
; the actual files used in the setup process
; first the files directly needed by the setup
Source: psvince.dll; Flags: dontcopy

; all the other files
; specify locations in the variables (config file)
Source: {#AppSourceDirMindReader}\\*; DestDir: {app}; Components: main; Flags: ignoreversion recursesubdirs createallsubdirs
Source: {#AppSourceDirMindReaderLegacy}\\*; DestDir: {app}\\..; Components: main; Flags: skipifsourcedoesntexist ignoreversion recursesubdirs createallsubdirs
Source: {#AppSourceDirMindReaderConfig}\\*; DestDir: {app}; Components: config; Flags: skipifsourcedoesntexist ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist uninsneveruninstall
Source: {#AppSourceDirMindReaderConfigLegacy}\\*; DestDir: {app}\\..; Components: config; Flags: skipifsourcedoesntexist ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist uninsneveruninstall
Source: {#AppSourceDirMindReaderSample}\\*; DestDir: {app}; Components: sample; Flags: skipifsourcedoesntexist ignoreversion recursesubdirs createallsubdirs
Source: {#AppSourceDirMindReaderSampleLegacy}\\*; DestDir: {app}\\..; Components: sample; Flags: skipifsourcedoesntexist ignoreversion recursesubdirs createallsubdirs
Source: {#AppSourceDirGyroQConfig}\\*; DestDir: {app}\\..\GyroQ; Tasks: gyroQ; Flags: ignoreversion recursesubdirs createallsubdirs uninsneveruninstall


[Code]
{
 As this is Pascal scripting, procedures/functions must
 first be declared/defined before they can be called!
}

const
{ Tasks used
  - keep in sync with previous sections
}
  TASK_GYROQ = 'gyroQ';

{ DataKey
  - Used for storing in registry
}
  DATAKEY_MMVERSION = 'MindManager';

{ MmVersion String
  - keep in synch with other MmVersion functions/procedures/variables
  - used for 'translation', and stored in registry (thus change with caution)
}
  MMVERSION_STRING6 = '6';
  MMVERSION_STRING7 = '7';
  MMVERSION_STRING8 = '8';
  MMVERSION_STRING_UNKNOWN = '';

{ Running
  - names of apps that can be running and maybe have to be closed
}
  RUNNING_GYROQ = 'GyroQ.exe';

{ Registry settings for lookup
}
  REGPATH_MINDJET_SETTINGS_PREFIX = 'Software\Mindjet\MindManager\';
  REGPATH_MINDJET_SETTINGS_SUFFIX = '\Settings';
  REGVAL_MINDJET_SETTINGS_DOCUMENTDIRECTORY = 'DocumentDirectory';

  REGPATH_GYRONIX_ACTIVATOR_SETTINGS = 'Software\Gyronix\GyroActivator\Settings';
  REGVAL_GYRONIX_ACTIVATOR_SETTINGS_MINDMANGER = 'MindManager';

  REGPATH_GYRONIX_GYROQ_SETTINGS = 'Software\Gyronix\GyroQ\Settings';
  REGVAL_GYRONIX_GYROQ_SETTINGS_WKGDIR = 'WkgDir';

  REGPATH_GYRONIX_RESULTSMANAGER_SETTINGS = 'Software\Gyronix\ResultsManager\Settings';
  REGVAL_GYRONIX_RESULTSMANAGER_SETTINGS_PATH = 'Path';

{ Various
}
  DIR_UNKNOWN = '';
  DIR_AO_DEAFULT = 'AO';
  MEMO_INDENT = '      ';

var
{ Custom Wizard Pages
}
  MmVersionPage: TInputOptionWizardPage;
  CheckInstalledPage: TOutputMsgMemoWizardPage;


{ MmVersion_Indexes
  - keep in sync with other MmVersion functions/procedures/constants
  - values are set in CreateMmVersionPage
  - used for 'translation'
}
  MmVersion_Index6,
  MmVersion_Index7,
  MmVersion_Index8,
  MmVersion_IndexUnknown: Integer;

// TODO:
// - check for RM
// - check for GyroQ
// - rerun GyroQ

// TODO:
// Use registry for correct placing of GyroQ ini file:
// HKCU | Software\Gyronix\GyroQ\Settings | WkgDir:
// {code: ...}

{ ==========
  External
  ==========
}

function IsModuleLoaded(modulename: String ):  Boolean;
  external 'IsModuleLoaded@files:psvince.dll stdcall';
  // from http://www.vincenzo.net/isxkb/index.php?title=PSVince


{ ==========
  MmVersion
  ==========
}
function TranslateMMVERSION_STRING(VersionString: String): Integer;
{ Converts from the registry stored value to the Wizard page option index
  - keep in synch with other MmVersion function/procedures
}
begin
  case VersionString of
    MMVERSION_STRING6: Result := MmVersion_Index6;
    MMVERSION_STRING7: Result := MmVersion_Index7;
    MMVERSION_STRING8: Result := MmVersion_Index8;
  else
    Result := MmVersion_IndexUnknown;
  end;
end;

function TranslateMmVersion_Index(VersionIndex: Integer): String;
{ Converts from the Wizard page option index to the registry stored value
  - keep in synch with other MmVersion function/procedures
}
begin
  case VersionIndex of
    MmVersion_Index6: Result := MMVERSION_STRING6;
    MmVersion_Index7: Result := MMVERSION_STRING7;
    MmVersion_Index8: Result := MMVERSION_STRING8;
  else
    Result := MMVERSION_STRING_UNKNOWN;
  end;
end;

function GuessMmVersion(): string;
{ Tries to guess what Mm version is running
}
var
  MmVersion: String;
begin
  if not RegQueryStringValue(HKCU,
    REGPATH_GYRONIX_ACTIVATOR_SETTINGS, REGVAL_GYRONIX_ACTIVATOR_SETTINGS_MINDMANGER,
    MmVersion) then begin
      MmVersion := MMVERSION_STRING_UNKNOWN;
  end;

  Result := MmVersion;
end;

procedure CreateMmVersionPage;
{ Keep in synch with other MmVersion function/procedures
}
begin
  MmVersionPage := CreateInputOptionPage(wpUserInfo,
    'MindManager Version', 'What version of MindManager are you using?',
    'Please specify what version of MindManager you are using, then click Next.',
    True, False);

  // Number MmVersion_Index.. sequentially, starting at 0

  MmVersionPage.Add('MindManager v6');
  MmVersion_Index6 := 0;

  MmVersionPage.Add('MindManager v7');
  MmVersion_Index7 := MmVersion_Index6 + 1; // reference to previous

  MmVersionPage.Add('MindManager v8');
  MmVersion_Index8 := MmVersion_Index7 + 1; // reference to previous

  MmVersionPage.Add('Unknown/Not listed here (not supported)');
  MmVersion_IndexUnknown := MmVersion_Index8 + 1; // reference to previous;

  MmVersionPage.SelectedValueIndex := TranslateMMVERSION_STRING(GetPreviousData (DATAKEY_MMVERSION,GuessMmVersion()));
end;

{ ==========
  ConfirmDir / SelectDir
  ==========
}
function getMyMapsDir(): String;
{ Tries to guess where the install must be done
}
var
  MindjetPathKeyName,
  DocDir: String;
begin
  MindjetPathKeyName := REGPATH_MINDJET_SETTINGS_PREFIX
    + TranslateMmVersion_Index(MmVersionPage.SelectedValueIndex)
    + REGPATH_MINDJET_SETTINGS_SUFFIX;

  if not RegQueryStringValue(HKCU,
    MindjetPathKeyName, REGVAL_MINDJET_SETTINGS_DOCUMENTDIRECTORY,
    DocDir) then begin
      DocDir := DIR_UNKNOWN;
  end;

  Result := DocDir;
end;

procedure UpdateSelectDirPage;
{ Adjust SelectDir
}
begin
  // Set Default value
  WizardForm.DirEdit.Text := addbackslash(getMyMapsDir) + DIR_AO_DEAFULT;

  // hide the Browse button
  WizardForm.DirBrowseButton.Visible := false;

  // Edit box for folder is non-editable
  WizardForm.DirEdit.Enabled := false;

end;

{ ==========
  Checking Apps / Settings
  ==========
}
function AllAppsClosed(): Boolean;
{ Check if all related apps are not running
}
begin
  Result := Not(IsTaskSelected(TASK_GYROQ) And IsModuleLoaded(RUNNING_GYROQ));
end;

function CheckMyMaps(): Boolean;
var
  regPath,
  temp: String;
begin
  regPath := REGPATH_MINDJET_SETTINGS_PREFIX
    + TranslateMmVersion_Index(MmVersionPage.SelectedValueIndex)
    + REGPATH_MINDJET_SETTINGS_SUFFIX;

  Result:= RegQueryStringValue(HKCU,
    regPath, REGVAL_MINDJET_SETTINGS_DOCUMENTDIRECTORY, temp);
end;

function CheckInstalledRM(): Boolean;
var
  temp: String;
begin
  Result:= RegQueryStringValue(HKCU,
    REGPATH_GYRONIX_RESULTSMANAGER_SETTINGS, REGVAL_GYRONIX_RESULTSMANAGER_SETTINGS_PATH, temp);
end;

function CheckInstalledGyroQ(): Boolean;
var
  temp: String;
begin
  Result:= RegQueryStringValue(HKCU,
    REGPATH_GYRONIX_GYROQ_SETTINGS, REGVAL_GYRONIX_GYROQ_SETTINGS_WKGDIR, temp);
end;

function CheckInstalled(): Boolean;
begin
  Result := CheckInstalledGyroQ and CheckInstalledRM;
end;

procedure CreateCheckInstalledPage;
var
  msg: String;
begin
  msg := ''
  if not CheckInstalledRM then
    msg := 'ResultsManager' #13
      + MEMO_INDENT + 'Visit: www.gyronix.com' #13#13 + msg;

  if not CheckInstalledGyroQ then
    msg := 'GyroQ' #13
      + MEMO_INDENT + 'Visit: www.gyronix.com' #13#13 + msg;

  msg := msg + 'See www.activityowner.com for more information';

  CheckInstalledPage := CreateOutputMsgMemoPage(MmVersionPage.ID,
    'Dependancies', 'Some other applications are required to enable all functionality',
    'Setup could not detect the following applications.'#13 They are not required, but highly recommended.',
    msg);

  CheckInstalledPage.RichEditViewer.Color := clBtnFace;

end;

{ ==========
  INNO Event procedures/functions
    see INNO help for additional information
 ==========
}
procedure InitializeWizard;
{ Init
}
begin
  // Create additional wizard pages
  CreateMmVersionPage;
  CreateCheckInstalledPage;
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
{ Store previous data used by installer
}
begin
  SetPreviousData(PreviousDataKey, DATAKEY_MMVERSION, TranslateMmVersion_Index(MmVersionPage.SelectedValueIndex));
end;

function NextButtonClick(CurPageID: Integer): Boolean;
{ Can we continue to the next page?
}
begin
  // By default continue to next page
  Result := True;

  // unless
  case CurPageID of

  // MmVersion is unknown
    MmVersionPage.ID:
      begin
        if MmVersionPage.SelectedValueIndex = MmVersion_IndexUnknown then begin
            Result := False;
            MsgBox('Only the listed version of MindManager are supported' #13#13
              'Please select one of the listed versions or Cancel thet setup.', mbInformation, MB_OK);
          end
        else
          if Not CheckMyMaps then begin
            Result := False;
            MsgBox('Could not locate information for the selected MindManager version!' #13#13
			  'Please select an installed version.', mbError, MB_OK);
          end;
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
{ Do some page updates
}
begin
  case CurPageID of
    wpSelectDir:
	  UpdateSelectDirPage;
  end;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
{ Skip these pages?
}
begin
  case PageId of
    CheckInstalledPage.ID:
      Result := CheckInstalled;
  end;
end;

// TODO:
// Use registry for correct placing of GyroQ ini file:
// HKCU | Software\Gyronix\GyroQ\Settings | WkgDir:
// {code: ...}


{ ==========
  for debug purposes
  - write out the 'true' story
  - must be at the end of all coding to give a complete file
}
#ifdef Debug
  #expr SaveToFile(AddBackslash(SourcePath) + "Preprocessed.iss")
#endif

// place nothing below!
