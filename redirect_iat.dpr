program Project1;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
  {$IFDEF FPC}Interfaces,{$ENDIF}
  Forms,
  ufrmMain in 'ufrmMain.pas' {Form1};

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
