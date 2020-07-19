unit Inject;

interface

procedure InjectDll(const cpDllFile:PAnsiChar;const Title:string);overload;
procedure InjectDll(const Title:string);overload;

implementation
uses
Windows,SysUtils,LoadLibraryR,DllRes;
var
mWindow:Cardinal = 0;
mHwnd:THandle = 0;
mDebugHwnd:THandle = 0;
function WinList(const Title:string): Boolean;
var
  s: string;
  //Pid: THandle;
begin
  Result := False;
  mWindow := FindWindow(nil, PChar(Title));
  if mWindow <> 0 then
    if GetWindowThreadProcessId(mWindow, mHwnd) <> 0 then
      Result := True;
end;

function EnableDebug(out hToken:THandle): Boolean;
Const
  SE_DEBUG_NAME = 'SeDebugPrivilege';
var
  _Luit: Int64;
  TP: TOKEN_PRIVILEGES;
  RetLen: DWORD;
begin
  Result := False;
  hToken:=0;
  if not OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, hToken)
    then
    Exit;
  if not LookupPrivilegeValue(nil, SE_DEBUG_NAME, _Luit) then
  begin
    Exit;
  end;
  TP.PrivilegeCount := 1;
  TP.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
  TP.Privileges[0].Luid := _Luit;
  RetLen := 0;
  Result := AdjustTokenPrivileges(hToken, False, TP, SizeOf(TP), nil, RetLen);
end;

procedure InjectDll(const cpDllFile:PAnsiChar;const Title:string);
var
hFile:THandle;
dwLength:Cardinal;
lpBuffer:Pointer;
dwBytesRead:Cardinal;
hToken:THandle;
priv:TOKEN_PRIVILEGES;
RetLen:Cardinal;
hProcess:THandle;
dwProcessId:Cardinal;
hModule:THandle;
begin
   hFile := CreateFileA( cpDllFile, GENERIC_READ, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0 );

   if hFile = INVALID_HANDLE_VALUE then raise Exception.Create('Failed to open the DLL file');
    dwLength := GetFileSize( hFile, nil );
   if ((dwLength =0) or (dwLength = INVALID_FILE_SIZE)) then  raise Exception.Create('Failed to get the DLL file size');

   lpBuffer := HeapAlloc( GetProcessHeap(), 0, dwLength );
   if lpBuffer = nil then  raise Exception.Create('Failed to get the DLL file size');
   if( not ReadFile( hFile, lpBuffer^, dwLength, dwBytesRead, nil ) ) then
   raise Exception.Create('Failed to alloc a buffer!')
   else
   CloseHandle(hFile);

   //if not EnableDebug(mDebugHwnd) then Exit;

   if( OpenProcessToken( GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken ) ) then
   begin
       FillChar(priv,SizeOf(TOKEN_PRIVILEGES),#0);
       priv.PrivilegeCount:=1;
       priv.Privileges[0].Attributes:=SE_PRIVILEGE_ENABLED;
       if( LookupPrivilegeValue( nil, 'SeDebugPrivilege', &priv.Privileges[0].Luid ) ) then
       AdjustTokenPrivileges( hToken, False, priv, 0, nil, RetLen );
       CloseHandle(hToken);
   end;

  // mHwnd:=6128;

  if Not WinList(Title) then Exit;

   hProcess := OpenProcess( PROCESS_CREATE_THREAD or
    PROCESS_QUERY_INFORMATION or
     PROCESS_VM_OPERATION or
      PROCESS_VM_WRITE or
       PROCESS_VM_READ, FALSE, mHwnd );

   //hProcess :=OpenProcess($1F0FFF, True, mHwnd);
   if (hProcess = 0) then
   raise Exception.Create('Failed to open the target process');
   hModule:=LoadRemoteLibraryR(hProcess, lpBuffer, dwLength, nil);
   if ( hModule = 0 ) then raise Exception.Create('Failed to inject the DLL');
   WaitForSingleObject(hModule, $FFFFFFFF);
  if (lpBuffer <> nil) then HeapFree( GetProcessHeap(), 0, lpBuffer );
  if (hProcess <> 0) then CloseHandle( hProcess );
  if (mDebugHwnd <> 0) then CloseHandle(mDebugHwnd);
  if (hModule <> 0) then  CloseHandle(hModule);


end;

procedure InjectDll(const Title:string);
var
dwBytesRead:Cardinal;
hToken:THandle;
priv:TOKEN_PRIVILEGES;
RetLen:Cardinal;
hProcess:THandle;
dwProcessId:Cardinal;
hModule:THandle;
begin




   //if not GetResStream then  raise Exception.Create('Failed to get the DLL file size');


   //if not EnableDebug(mDebugHwnd) then Exit;

   if( OpenProcessToken( GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken ) ) then
   begin
       FillChar(priv,SizeOf(TOKEN_PRIVILEGES),#0);
       priv.PrivilegeCount:=1;
       priv.Privileges[0].Attributes:=SE_PRIVILEGE_ENABLED;
       if( LookupPrivilegeValue( nil, 'SeDebugPrivilege', &priv.Privileges[0].Luid ) ) then
       AdjustTokenPrivileges( hToken, False, priv, 0, nil, RetLen );
       CloseHandle(hToken);
   end;

  // mHwnd:=6128;

  if Not WinList(Title) then Exit;

   hProcess := OpenProcess( PROCESS_CREATE_THREAD or
    PROCESS_QUERY_INFORMATION or
     PROCESS_VM_OPERATION or
      PROCESS_VM_WRITE or
       PROCESS_VM_READ, FALSE, mHwnd );

   //hProcess :=OpenProcess($1F0FFF, True, mHwnd);
   if (hProcess = 0) then
   raise Exception.Create('Failed to open the target process');
   hModule:=LoadRemoteLibraryR(hProcess, ServerRes.Memory, ServerRes.Size, nil);
   if ( hModule = 0 ) then raise Exception.Create('Failed to inject the DLL');
   WaitForSingleObject(hModule, $FFFFFFFF);
  //FreeResStream;
  if (hProcess <> 0) then CloseHandle( hProcess );
  if (mDebugHwnd <> 0) then CloseHandle(mDebugHwnd);
  if (hModule <> 0) then  CloseHandle(hModule);


end;

end.
