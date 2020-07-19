unit LoadLibraryR;

interface

uses
Windows,Logger;

function GetReflectiveLoaderOffset(lpReflectiveDllBuffer:Pointer):DWORD;

function LoadLibraryR_(lpBuffer:Pointer;dwLength:DWORD ):HMODULE;stdcall;

function LoadRemoteLibraryR(hProcess:THandle;lpBuffer:Pointer;dwLength:DWORD;lpParameter:Pointer):THandle;stdcall;

implementation
uses
SysUtils;
type
REFLECTIVELOADER = function:Cardinal;stdcall;
LPTHREAD_START_ROUTINE = function(lpThreadParameter:Pointer):DWORD;stdcall;
DLLMAIN = function(HINSTANCE:Cardinal;D:DWORD;P:Pointer):BOOL;stdcall;
const DLL_QUERY_HMODULE = 6;
function DEREF_32(name:Cardinal):DWORD;
begin
  Result:=PDWORD(name)^;
end;

function DEREF_16(name:Cardinal):Word;
begin
    Result:=PWORD(name)^;
end;

function Rva2Offset(dwRva:DWORD;uiBaseAddress:DWORD):DWORD;
var
wIndex:Word;
pSectionHeader:PImageSectionHeader;
pNtHeaders:PImageNtHeaders;
begin
  wIndex:=0;
  pSectionHeader:=nil;
  pNtHeaders:=nil;
	pNtHeaders := PImageNtHeaders((uiBaseAddress + PImageDosHeader(uiBaseAddress)._lfanew));

	pSectionHeader := PImageSectionHeader(Cardinal(@(pNtHeaders.OptionalHeader)) + pNtHeaders.FileHeader.SizeOfOptionalHeader);

    if( dwRva < pSectionHeader.PointerToRawData ) then
        Exit(dwRva);

        for wIndex:=0 to pNtHeaders.FileHeader.NumberOfSections -1 do
          begin
             if wIndex > 0 then  Inc(pSectionHeader);
             if( (dwRva >= pSectionHeader.VirtualAddress) and (dwRva < (pSectionHeader.VirtualAddress + pSectionHeader.SizeOfRawData) )) then
             Exit(dwRva - pSectionHeader.VirtualAddress + pSectionHeader.PointerToRawData);
          end;
Result:=0;
end;

function  GetReflectiveLoaderOffset(lpReflectiveDllBuffer:Pointer):DWORD;
var
uiBaseAddress:Cardinal;
uiExportDir:Cardinal;
uiNameArray:Cardinal;
uiAddressArray:Cardinal;
uiNameOrdinals:Cardinal;
dwCounter:DWORD;
dwCompiledArch:DWORD;
cpExportedFunctionName:PAnsiChar;
I:Cardinal;
s:AnsiString;
begin
  Result:=0;
{$IFDEF WIN_X64}
	dwCompiledArch := 2;
{$ELSE}
	// This will catch Win32 and WinRT.
	dwCompiledArch := 1;
{$ENDIF}
	uiBaseAddress := Cardinal(lpReflectiveDllBuffer);
	// get the File Offset of the modules NT Header
	uiExportDir := uiBaseAddress + (PImageDosHeader(uiBaseAddress)._lfanew);
	// currenlty we can only process a PE file which is the same type as the one this fuction has
	// been compiled as, due to various offset in the PE structures being defined at compile time.
	if( PImageNtHeaders(uiExportDir).OptionalHeader.Magic = $010B ) then // PE32
	begin
		if( dwCompiledArch <> 1 )  then Exit(0);
	end
	else if( PImageNtHeaders(uiExportDir).OptionalHeader.Magic = $020B ) then // PE64
	begin
		if( dwCompiledArch <> 2 ) then Exit(0);
	end
	else Exit;

	// uiNameArray = the address of the modules export directory entry

	//uiNameArray = (UINT_PTR)&((PIMAGE_NT_HEADERS)uiExportDir)->OptionalHeader.DataDirectory[ IMAGE_DIRECTORY_ENTRY_EXPORT ];

 uiNameArray:=Cardinal(@(PImageNtHeaders(uiExportDir).OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT]));
  //SaveLog('uiNameArray',uiNameArray,uiBaseAddress);
	// get the File Offset of the export directory
 //	uiExportDir = uiBaseAddress + Rva2Offset( ((PIMAGE_DATA_DIRECTORY)uiNameArray)->VirtualAddress, uiBaseAddress );
  uiExportDir:= uiBaseAddress + Rva2Offset(PImageDataDirectory(uiNameArray).VirtualAddress,uiBaseAddress);
  //SaveLog('uiExportDir',uiExportDir,uiBaseAddress);
	// get the File Offset for the array of name pointers
 //	uiNameArray = uiBaseAddress + Rva2Offset( ((PIMAGE_EXPORT_DIRECTORY )uiExportDir)->AddressOfNames, uiBaseAddress );
  uiNameArray:= uiBaseAddress + Rva2Offset(Cardinal((PImageExportDirectory(uiExportDir).AddressOfNames)),uiBaseAddress);

  //SaveLog('uiNameArray',uiNameArray,uiBaseAddress);
	// get the File Offset for the array of addresses
	//uiAddressArray = uiBaseAddress + Rva2Offset( ((PIMAGE_EXPORT_DIRECTORY )uiExportDir)->AddressOfFunctions, uiBaseAddress );
   uiAddressArray := uiBaseAddress + Rva2Offset(Cardinal(PImageExportDirectory(uiExportDir).AddressOfFunctions),uiBaseAddress);

   //SaveLog('uiAddressArray',uiAddressArray,uiBaseAddress);
	// get the File Offset for the array of name ordinals
	//uiNameOrdinals = uiBaseAddress + Rva2Offset( ((PIMAGE_EXPORT_DIRECTORY )uiExportDir)->AddressOfNameOrdinals, uiBaseAddress );
    uiNameOrdinals := uiBaseAddress + Rva2Offset(Cardinal((PImageExportDirectory(uiExportDir).AddressOfNameOrdinals)),uiBaseAddress );
   //SaveLog('uiNameOrdinals',uiNameOrdinals,uiBaseAddress);
	// get a counter for the number of exported functions...
 //	dwCounter = ((PIMAGE_EXPORT_DIRECTORY )uiExportDir)->NumberOfNames;
    dwCounter := PImageExportDirectory(uiExportDir).NumberOfNames;
	// loop through all the exported functions to find the ReflectiveLoader
for I := dwCounter -1 downto 0 do
  begin
		cpExportedFunctionName := PAnsiChar(uiBaseAddress + Rva2Offset( DEREF_32( uiNameArray ), uiBaseAddress ));
    s:=cpExportedFunctionName;
    OutputDebugStringa(PAnsiChar(s));
		if( StrPos(cpExportedFunctionName, PAnsiChar('ReflectiveLoader')) <> '' ) then
		begin
			// get the File Offset for the array of addresses
			uiAddressArray := uiBaseAddress + Rva2Offset(Cardinal((PImageExportDirectory(uiExportDir).AddressOfFunctions)), uiBaseAddress );

			// use the functions name ordinal as an index into the array of name pointers
			uiAddressArray :=uiAddressArray + ( DEREF_16( uiNameOrdinals ) * sizeof(DWORD) );

			// return the File Offset to the ReflectiveLoader() functions code...
			Exit(Rva2Offset( DEREF_32( uiAddressArray ), uiBaseAddress ));
		end;
		// get the next exported function name
		uiNameArray :=uiNameArray + sizeof(DWORD);

		// get the next exported function name ordinal
		uiNameOrdinals :=uiNameOrdinals + sizeof(WORD);
	end;

end;

function LoadLibraryR_(lpBuffer:Pointer;dwLength:DWORD ):HMODULE;stdcall;
var
  hResult:HMODULE;
	dwReflectiveLoaderOffset:DWORD;
  dwOldProtect1:DWORD;
  dwOldProtect2:DWORD;
  pReflectiveLoader:REFLECTIVELOADER;
  pDllMain:DLLMAIN;
begin
   hResult:=0;
   dwReflectiveLoaderOffset:=0;
   dwOldProtect1:=0;
   dwOldProtect2:=0;
   pReflectiveLoader:=nil;
   pDllMain:=nil;
   Result:=0;
   if ((lpBuffer = nil) or (dwLength = 0)) then  Exit;
   try
    dwReflectiveLoaderOffset := GetReflectiveLoaderOffset( lpBuffer );
    if( dwReflectiveLoaderOffset <> 0 ) then
    begin
       pReflectiveLoader:=REFLECTIVELOADER(Cardinal(@lpBuffer) + dwReflectiveLoaderOffset);
       if(VirtualProtect(lpBuffer,dwLength,PAGE_EXECUTE_READWRITE,@dwOldProtect1)) then
       begin
            pDllMain := DLLMAIN(pReflectiveLoader);
            if ( pReflectiveLoader <> 0 )  then
            begin
              if ( not pDllMain( 0, DLL_QUERY_HMODULE, @hResult )) then begin
                 hResult:=0;
              end;
            end;
            VirtualProtect( lpBuffer, dwLength, dwOldProtect1, @dwOldProtect2 );
       end;
    end;
   except

   end;

end;

function LoadRemoteLibraryR(hProcess:THandle;lpBuffer:Pointer;dwLength:DWORD;lpParameter:Pointer):THandle;stdcall;
var
	lpRemoteLibraryBuffer:Pointer;
  //lpReflectiveLoader:LPTHREAD_START_ROUTINE;
  lpReflectiveLoader:Cardinal;
	dwReflectiveLoaderOffset:DWORD;
	dwThreadId:DWORD;
  NumOfByte:DWORD;
begin


try
    Result:=0;
    if( (hProcess = 0)  or  (lpBuffer = nil) or  (dwLength = 0) ) then Exit;
    dwReflectiveLoaderOffset := GetReflectiveLoaderOffset( lpBuffer );
    if( dwReflectiveLoaderOffset = 0 ) then Exit;
    lpRemoteLibraryBuffer := VirtualAllocEx( hProcess, nil, dwLength, MEM_RESERVE Or MEM_COMMIT, PAGE_EXECUTE_READWRITE );
    if(  lpRemoteLibraryBuffer  = nil) then Exit;
    NumOfByte :=0;
    if( Not WriteProcessMemory( hProcess, lpRemoteLibraryBuffer, lpBuffer, dwLength, NumOfByte ) ) then Exit;
    lpReflectiveLoader := Cardinal(lpRemoteLibraryBuffer) + dwReflectiveLoaderOffset;
    Result :=CreateRemoteThread(hProcess,nil,1024*1024,Pointer(lpReflectiveLoader),lpParameter,0,dwThreadId)
except

end;

end;


end.
