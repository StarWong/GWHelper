program Reflective;

uses
  Forms,
  Main in 'Main.pas' {Form1},
  LoadLibraryR in 'LoadLibraryR.pas',
  GetProcAddressR in 'GetProcAddressR.pas',
  Inject in 'Inject.pas',
  Logger in 'Logger.pas',
  DllRes in 'DllRes.pas',
  NTLib in 'NTLib.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
