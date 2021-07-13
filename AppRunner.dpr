program AppRunner;

uses
  Forms,
  untMain in 'untMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'App Runner';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
