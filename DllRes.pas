unit DllRes;

interface
uses Classes,SysUtils;
var
ServerRes:TResourceStream;
ClientRes:TResourceStream;

function GetResStream:Boolean;
procedure FreeResStream;
implementation
{$R DllServer.RES}
{$R DllClient.RES}
function GetResStream:Boolean;
begin
 Result:=True;
  try
    ServerRes:=TResourceStream.Create(HInstance,'ServerData','DllBin');
    ClientRes:=TResourceStream.Create(HInstance,'ClientData','DllBin');
  except
  Result:=False;
  end;
end;

procedure FreeResStream;
begin
  if Assigned(ServerRes) then
  begin
    ServerRes.Free;
    ServerRes:=nil;
  end;
    if Assigned(ClientRes) then
  begin
    ClientRes.Free;
    ClientRes:=nil;
  end;
end;

initialization
if not GetResStream then raise Exception.Create('Get ResourceStream Failed!');
finalization
FreeResStream;

end.
