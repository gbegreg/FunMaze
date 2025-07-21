program FunMaze;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {frmMain},
  uLabyrinthe in 'uLabyrinthe.pas',
  uGBEPathFinder in 'uGBEPathFinder.pas',
  uConsts in 'uConsts.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
