unit DllRes;

interface
uses Classes;
var
Res:TResourceStream;

function GetResStream:Boolean;
procedure FreeResStream;
implementation
{$R DllServer.RES}
function GetResStream:Boolean;
begin
 Result:=True;
  try
    Res:=TResourceStream.Create(HInstance,'DllBin','DllData');
  except
  Result:=False;
  end;
end;

procedure FreeResStream;
begin
  if Assigned(Res) then
  begin
    Res.Free;
    Res:=nil;
  end;
end;

end.
