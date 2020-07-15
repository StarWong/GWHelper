unit GetProcAddressR;

interface
type
FARPROC = function:Integer;
function GetProcAddressR_(hModule:THandle;const lpProcName:PAnsiChar ):FARPROC;stdcall;

implementation
uses
Windows,SysUtils;
function DEREF_32(name:Cardinal):DWORD;
begin
  Result:=PDWORD(name)^;
end;

function DEREF_16(name:Cardinal):Word;
begin
    Result:=PWORD(name)^;
end;

function GetProcAddressR_(hModule:THandle;const lpProcName:PAnsiChar ):FARPROC;stdcall;
var
uiLibraryAddress:Cardinal;
fpResult:FARPROC;
pNtHeaders:PIMAGENTHEADERS;
pDataDirectory:PIMAGEDATADIRECTORY;
pExportDirectory:PIMAGEEXPORTDIRECTORY;
uiAddressArray:Cardinal;
uiNameArray:Cardinal;
uiNameOrdinals:Cardinal;
dwCounter:DWORD;
I:Cardinal;
cpExportedFunctionName:PAnsiChar;
begin
    Result:= nil;
     if hModule = 0 then  Exit;
     uiLibraryAddress:=hModule;
     try
       pNtHeaders := PIMAGENTHEADERS(uiLibraryAddress + PIMAGEDOSHEADER(uiLibraryAddress)._lfanew);
       pDataDirectory := PIMAGEDATADIRECTORY(Cardinal(@pNtHeaders.OptionalHeader.DataDirectory[ IMAGE_DIRECTORY_ENTRY_EXPORT ]));
       pExportDirectory := PIMAGEEXPORTDIRECTORY( uiLibraryAddress + pDataDirectory.VirtualAddress );
       uiAddressArray := ( uiLibraryAddress + Cardinal(pExportDirectory.AddressOfFunctions) );
       uiNameArray:=(uiLibraryAddress + Cardinal(pExportDirectory.AddressOfNames) );
       uiNameOrdinals := ( uiLibraryAddress + Cardinal(pExportDirectory.AddressOfNameOrdinals) );
       if ((Cardinal(lpProcName) and $FFFF0000 ) = $0)then
       begin
        uiAddressArray :=uiAddressArray + ( ( ( Cardinal(lpProcName) - pExportDirectory.Base ) * SizeOf(DWORD) ));
        fpResult := FARPROC( uiLibraryAddress + DEREF_32(uiAddressArray) );
       end
       else
       begin
           dwCounter:=pExportDirectory.NumberOfNames;
           if dwCounter = 0 then Exit;
           for I := dwCounter - 1 downto 0 do
           begin
                 cpExportedFunctionName:=PAnsiChar(uiLibraryAddress + DEREF_32( uiNameArray ));
                 if (StrComp(cpExportedFunctionName,lpProcName) = 0) then
                 begin
                  uiAddressArray :=uiAddressArray + ( DEREF_16( uiNameOrdinals ) * sizeof(DWORD) );
                  fpResult := FARPROC((uiLibraryAddress + DEREF_32( uiAddressArray )));
                  Break;
                 end;
                 uiNameArray :=uiNameArray + sizeof(DWORD);
                 uiNameOrdinals :=uiNameOrdinals + sizeof(WORD);
           end;

       end;

     except

     end;

end;

end.
