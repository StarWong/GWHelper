unit FunctionList;

interface

var
addNum:function(a:Integer;b:Integer):Integer;stdcall;
ClientRoutine:function:LongInt;stdcall;
procedure PullBackFunctions;
implementation
uses
SysUtils,MemoryModule,DllRes;
type
  TNativeUIntFunc = function: NativeUInt;
var
  lib:TMemoryModule;
procedure PullBackFunctions;
procedure DllCall(const FuncName:AnsiString;var Addr:Pointer);
var
Func:TNativeUIntFunc;
begin
       Func := TNativeUIntFunc(MemoryGetProcAddress(lib, @FuncName[1]));
       if Assigned(func) then Addr:=@Func
       else
       raise Exception.Create('Error Do Not find this fun');
end;
begin
  lib := MemoryLoadLibary(ClientRes.Memory);
  if lib = nil then Exit;
  DllCall('StartClientRoutine',@ClientRoutine);
  DllCall('sum',@addNum);

end;

initialization
PullBackFunctions;
finalization
MemoryFreeLibrary(lib);
end.
