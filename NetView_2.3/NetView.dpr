program NetView;

uses
  Forms,
  NvMain in 'NvMain.pas' {MainForm},
  NvFind in 'NvFind.pas' {FindDialog},
  NvPing in 'NvPing.pas' {PingDialog},
  NvMsg in 'NvMsg.pas' {MessageDialog},
  NvAbout in 'NvAbout.pas' {AboutBox},
  NvConst in 'NvConst.pas';

{$R *.RES}
{$R AVI.RES}
{$R WAVE.RES}
{$IFDEF VER150}
{$R WindowsXP.res}
{$ENDIF}

begin
  Application.Initialize;
  Application.Title := 'NetView';
  Application.HintShortCuts := False;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
