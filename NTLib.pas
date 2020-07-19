unit NTLib;

interface

//function MessageBox(HWnd: Integer; Text, Caption: PChar; Flags: Integer): Integer; stdcall; external 'user32.dll' name 'MessageBoxA';
type
NTSTATUS =LongInt;
var
MsgBin:PByte;
MsgLen:PCardinal;

function ConnectToServer(const ServerName:WideString):NTSTATUS;
function ReceiveMsgFromServer:NTSTATUS;
function ClientDisconnect(Flag:Cardinal = 0):NTSTATUS;
function ServerCreatePort(const ServerName:WideString):NTSTATUS;
function ServerListenAndPeekMessage:NTSTATUS;
function SendMsgToServer:NTSTATUS;

procedure test();

implementation
uses
Windows,Logger,SysUtils,Generics.Collections;

{$REGION 'Type'}

type
ULONG = DWORD;
SIZE_T = Cardinal;
PSIZE_T =^SIZE_T;
PULONG =^ULONG;
HANDLE = THandle;
PHANDLE =^HANDLE;
PVOID = Pointer;

PUNICODE_STRING = ^UNICODE_STRING;
UNICODE_STRING = record
Length:Word;
MaximumLength:Word;
Buffer:PWideChar;
end;
_OBJECT_ATTRIBUTES = record
Length:ULONG;
RootDirectory:THandle;
ObjectName:PUNICODE_STRING;
Attributes:ULONG;
SecurityDescriptor:PSecurityDescriptor;
SecurityQualityOfService:PSecurityQualityOfService;
end;
OBJECT_ATTRIBUTES = _OBJECT_ATTRIBUTES;
POBJECT_ATTRIBUTES =  ^OBJECT_ATTRIBUTES;

_ALPC_PORT_ATTRIBUTES = record
Flags:ULONG;
SecurityQos:SECURITY_QUALITY_OF_SERVICE;
MaxMessageLength:SIZE_T;
MemoryBandwidth:SIZE_T;
MaxPoolUsage:SIZE_T;
MaxSectionSize:SIZE_T;
MaxViewSize:SIZE_T;
MaxTotalSectionSize:SIZE_T;
DupObjectTypes:ULONG
end;

ALPC_PORT_ATTRIBUTES = _ALPC_PORT_ATTRIBUTES;
PALPC_PORT_ATTRIBUTES = ^ALPC_PORT_ATTRIBUTES;

_CLIENT_ID = record
UniqueProcess:THandle;
UniqueThread:THandle;
end;

CLIENT_ID = _CLIENT_ID;

PCLIENT_ID = ^CLIENT_ID;

Ts1 = record
    DataLength:Word;
    TotalLength:Word
end;

Ts2 = record
     _Type:Word;
     DataInfoOffset:Word
end;

Tu1 = record
    case Integer of
    0:(s1:Ts1);
    1:(Length:ULONG);
end;

Tu2 = record
     case Integer of
     0:(s2:Ts2);
     1:(ZeroInit:ULONG);
end;

Tu3 = record
     case Integer of
     0:(ClientId:CLIENT_ID);
     1:(DoNotUseThisField:Double);
end;

Tu4 = record
     case Integer of
     0:(ClientViewSize:SIZE_T);
     1:(CallbackId:ULONG);
end;

_PORT_MESSAGE =  record
  u1:Tu1;
  u2:Tu2;
  u3:Tu3;
  MessageId:ULONG;
  u4:Tu4
end;

PORT_MESSAGE = _PORT_MESSAGE;
PPORT_MESSAGE =^PORT_MESSAGE;

_ALPC_MESSAGE_ATTRIBUTES = record
AllocatedAttributes:ULONG;
ValidAttributes:ULONG
end;

ALPC_MESSAGE_ATTRIBUTES = _ALPC_MESSAGE_ATTRIBUTES;
PALPC_MESSAGE_ATTRIBUTES = ^ALPC_MESSAGE_ATTRIBUTES;

TDUMMYSTRUCTNAME =record
    LowPart:DWORD;
    HighPart:Integer;
end;

Tu = TDUMMYSTRUCTNAME;

_LARGE_INTEGER =record
case Integer of
 0:(DUMMYSTRUCTNAME:TDUMMYSTRUCTNAME);
 1:(u:Tu);
 2:(QuadPart:Int64)
end;

LARGE_INTEGER = _LARGE_INTEGER;

PLARGE_INTEGER =^LARGE_INTEGER;

_argument = record
funcid:Cardinal;
do_return:BOOL
end;

_result = record
error:BOOL
end;

_info = record
case Integer of
0:(argumen:_argument);
1:(result:_result);
end;

_DataHeader = record
totalsize:Cardinal;
info:_info;
end;

PDataHeader = ^DataHeader;
DataHeader = _DataHeader;

_DataCache =record
header:DataHeader;
buff:array [0..0] of Byte;
end;

PDataCache = ^DataCache;
DataCache = _DataCache;




TALPC_PORT_ATTRIBUTES_VALUES =  record
	kAlpcPortAttributesNone:ULONG;
	kAlpcPortAttributesLpcPort :ULONG;
	kAlpcPortAttributesAllowImpersonation :ULONG;
	kAlpcPortAttributesAllowLpcRequests :ULONG;
	kAlpcPortAttributesWaitablePort :ULONG;
	kAlpcPortAttributesAllowDupObject :ULONG;
	kAlpcPortAttributesSystemProcess :ULONG;// Not accessible outside the kernel.
	kAlpcPortAttributesLrpcWakePolicy1 :ULONG;
	kAlpcPortAttributesLrpcWakePolicy2 :ULONG;
	kAlpcPortAttributesLrpcWakePolicy3 :ULONG;
	kAlpcPortAttributesDirectMessage :ULONG;
	kAlpcPortAttributesAllowMultiHandleAttribute :ULONG
end;

_ALPC_CUSTOM_MESSAGE = packed record
  Header:PORT_MESSAGE;
  Buffer:array[0..0] of Byte
end;

ALPC_CUSTOM_MESSAGE = _ALPC_CUSTOM_MESSAGE;

PALPC_CUSTOM_MESSAGE = ^ALPC_CUSTOM_MESSAGE;


TBinCache = array[0..MAXWORD -1] of Byte;


TALPC_MESSAGE_FLAGS = record
  kAlpcMessageFlagNone:ULONG;
	kAlpcMessageFlagReplyMessage:ULONG;
	kAlpcMessageFlagLpcMode:ULONG;
	kAlpcMessageFlagReleaseMessage:ULONG;
	kAlpcMessageFlagSyncRequest:ULONG;
	kAlpcMessageFlagTrackPortReferences:ULONG;
	kAlpcMessageFlagWaitUserMode:ULONG;
	kAlpcMessageFlagWaitAlertable:ULONG;
	kAlpcMessageFlagWaitChargePolicy:ULONG;
	kAlpcMessageFlagUnknown1000000:ULONG;
	kAlpcMessageFlagWow64Call:ULONG
end;

TALPC_MESSAGE_ATTRIBUTES_VALUES = record
	kAlpcMessageAttributesNone:ULONG;
	kAlpcMessageAttributesWorkOnBehalfOf:ULONG;
	kAlpcMessageAttributesDirect:ULONG;
	kAlpcMessageAttributesToken:ULONG;
	kAlpcMessageAttributesHandle:ULONG;
	kAlpcMessageAttributesContext:ULONG;
	kAlpcMessageAttributesView:ULONG;
	kAlpcMessageAttributesSecurity:ULONG
end;

{$IFDEF DynLib}
TCreatePort =function(
PortHandle:PHANDLE;
PortName:PUNICODE_STRING;
ObjectAttributes:POBJECT_ATTRIBUTES;
PortAttributes:PALPC_PORT_ATTRIBUTES;
Flags:ULONG;
RequiredServerSid:PSID;
ConnectionMessage:PPORT_MESSAGE;
BufferLength:PULONG;
OutMessageAttributes:PALPC_MESSAGE_ATTRIBUTES;
InMessageAttributes:PALPC_MESSAGE_ATTRIBUTES;
Timeout:PLARGE_INTEGER
):NTSTATUS;

TDoPeekMessage =function(
PortHandle:HANDLE;
Flags:ULONG;
SendMessage:PPORT_MESSAGE;
SendMessageAttributes:PALPC_MESSAGE_ATTRIBUTES;
ReceiveMessage:PPORT_MESSAGE;
BufferLength:PSIZE_T;
ReceiveMessageAttributes:PALPC_MESSAGE_ATTRIBUTES;
Timeout:PLARGE_INTEGER
):NTSTATUS;

TAlpcInitializeMessageAttribute =function(
AttributeFlags:ULONG;
var Buffer:ALPC_MESSAGE_ATTRIBUTES;
BufferSize:ULONG;
var RequiredBufferSize:ULONG
):NTSTATUS;

TCreateServer =function(
PortHandle:PHANDLE;
ObjectAttributes:POBJECT_ATTRIBUTES;
PortAttributes:PALPC_PORT_ATTRIBUTES
):NTSTATUS;

TAcceptClients =function(
    PortHandle:PHANDLE;
    ConnectionPortHandle:HANDLE;
    Flags:ULONG;
    ObjectAttributes:POBJECT_ATTRIBUTES;
    PortAttributes:PALPC_PORT_ATTRIBUTES;
    PortContext:PVOID;
    ConnectionRequest:PPORT_MESSAGE;
    ConnectionMessageAttributes:PALPC_MESSAGE_ATTRIBUTES;
    AcceptConnection:Boolean
):NTSTATUS;

TDisconnectFromServer =function(
    PortHandle:HANDLE;
    Flags:ULONG
):NTSTATUS;






{$ENDIF}


{$ENDREGION}

{$REGION 'Const'}
const
ALPC_PORT_ATTRIBUTES_VALUES:TALPC_PORT_ATTRIBUTES_VALUES =
(
kAlpcPortAttributesNone:$0;
kAlpcPortAttributesLpcPort:$1000;
kAlpcPortAttributesAllowImpersonation:$10000;
kAlpcPortAttributesAllowLpcRequests:$20000;
kAlpcPortAttributesWaitablePort:$40000;
kAlpcPortAttributesAllowDupObject:$80000;
kAlpcPortAttributesSystemProcess:$100000;
kAlpcPortAttributesLrpcWakePolicy1:$200000;
kAlpcPortAttributesLrpcWakePolicy2:$400000;
kAlpcPortAttributesLrpcWakePolicy3:$800000;
kAlpcPortAttributesDirectMessage:$1000000;
kAlpcPortAttributesAllowMultiHandleAttribute:$2000000
);

m_MaxMessageLength =Word($1000);
m_MemoryBandwith:SIZE_T = $1000;
m_MaxPoolUsage:SIZE_T = $1000;
m_MaxSectionSize:SIZE_T = $1000;
m_MaxViewSize:SIZE_T = $1000;
m_MaxTotalSectionSize:SIZE_T = $1000;
m_DupObjectTypes:ULONG = $0;

STATUS_INSUFFICIENT_RESOURCES = $C000009A;
STATUS_SUCCESS = ULONG($0);
STATUS_INFO_LENGTH_MISMATCH = ULONG($C0000004);

ALPC_MESSAGE_FLAGS :TALPC_MESSAGE_FLAGS  =
(
	kAlpcMessageFlagNone:ULONG($0);
	kAlpcMessageFlagReplyMessage:$1;
	kAlpcMessageFlagLpcMode:$2;
	kAlpcMessageFlagReleaseMessage:$10000;
	kAlpcMessageFlagSyncRequest:$20000;
	kAlpcMessageFlagTrackPortReferences:$40000;
	kAlpcMessageFlagWaitUserMode:$100000;
	kAlpcMessageFlagWaitAlertable:$200000;
	kAlpcMessageFlagWaitChargePolicy:$400000;
	kAlpcMessageFlagUnknown1000000:$1000000;
	kAlpcMessageFlagWow64Call:$40000000
);

ALPC_MESSAGE_ATTRIBUTES_VALUES:TALPC_MESSAGE_ATTRIBUTES_VALUES  =
(
 	kAlpcMessageAttributesNone:ULONG($0);
	kAlpcMessageAttributesWorkOnBehalfOf:$2000000;
	kAlpcMessageAttributesDirect:$4000000;
	kAlpcMessageAttributesToken:$8000000;
	kAlpcMessageAttributesHandle:$10000000;
	kAlpcMessageAttributesContext:$20000000;
	kAlpcMessageAttributesView:$40000000;
	kAlpcMessageAttributesSecurity:$80000000
);

 LPC_REQUEST = ULONG(1);
 LPC_REPLY  = ULONG(2);
 LPC_DATAGRAM  = ULONG(3);
 LPC_LOST_REPLY = ULONG(4);
 LPC_PORT_CLOSED = ULONG(5);
 LPC_CLIENT_DIED = ULONG(6);
 LPC_EXCEPTION = ULONG(7);
 LPC_DEBUG_EVENT = ULONG(8);
 LPC_ERROR_EVENT = ULONG(90) ;
 LPC_CONNECTION_REQUEST =(10);
 LPC_KERNELMODE_MESSAGE =Word($8000);
 LPC_NO_IMPERSONATE = Word($4000);

{$ENDREGION}

{$REGION 'Var'}

var
BinCache,MsgCache:TBinCache;
m_AlpcClientPortHandle:HANDLE;
m_AlpcServerPortHandle:HANDLE;
m_ClientList:TDictionary<ULONG,HANDLE>;

{$ENDREGION}

{$REGION 'DllCall'}

function CreatePort(
PortHandle:PHANDLE;
PortName:PUNICODE_STRING;
ObjectAttributes:POBJECT_ATTRIBUTES;
PortAttributes:PALPC_PORT_ATTRIBUTES;
Flags:ULONG;
RequiredServerSid:PSID;
ConnectionMessage:PPORT_MESSAGE;
BufferLength:PULONG;
OutMessageAttributes:PALPC_MESSAGE_ATTRIBUTES;
InMessageAttributes:PALPC_MESSAGE_ATTRIBUTES;
Timeout:PLARGE_INTEGER
):NTSTATUS;stdcall;external 'ntdll.dll' name 'NtAlpcConnectPort';

function DoPeekMessage(
PortHandle:HANDLE;
Flags:ULONG;
SendMessage:PPORT_MESSAGE;
SendMessageAttributes:PALPC_MESSAGE_ATTRIBUTES;
ReceiveMessage:PPORT_MESSAGE;
BufferLength:PSIZE_T;
ReceiveMessageAttributes:PALPC_MESSAGE_ATTRIBUTES;
Timeout:PLARGE_INTEGER
):NTSTATUS;stdcall;external 'ntdll.dll' name 'NtAlpcSendWaitReceivePort';



function AlpcInitializeMessageAttribute
(
AttributeFlags:ULONG;
var Buffer:ALPC_MESSAGE_ATTRIBUTES;
BufferSize:ULONG;
var RequiredBufferSize:ULONG
):NTSTATUS;stdcall;external 'ntdll.dll' name 'AlpcInitializeMessageAttribute';


function CreateServer(
PortHandle:PHANDLE;
ObjectAttributes:POBJECT_ATTRIBUTES;
PortAttributes:PALPC_PORT_ATTRIBUTES
):NTSTATUS;stdcall;external 'ntdll.dll' name 'NtAlpcCreatePort';


function AcceptClients(
    PortHandle:PHANDLE;
    ConnectionPortHandle:HANDLE;
    Flags:ULONG;
    ObjectAttributes:POBJECT_ATTRIBUTES;
    PortAttributes:PALPC_PORT_ATTRIBUTES;
    PortContext:PVOID;
    ConnectionRequest:PPORT_MESSAGE;
    ConnectionMessageAttributes:PALPC_MESSAGE_ATTRIBUTES;
    AcceptConnection:Boolean
):NTSTATUS;stdcall;external 'ntdll.dll' name 'NtAlpcAcceptConnectPort';


function DisconnectFromServer(
    PortHandle:HANDLE;
    Flags:ULONG
):NTSTATUS;stdcall;external 'ntdll.dll' name 'NtAlpcDisconnectPort';

{$ENDREGION}

{$REGION 'Functions'}

procedure RTL_CONSTANT_STRING(const ServerName:WideString;var PortName:UNICODE_STRING);
begin
     PortName.Length:= Length(ServerName) * SizeOf(ServerName[1]);
     PortName.MaximumLength:= (Length(ServerName) + 1)*SizeOf(ServerName[1]);
     PortName.Buffer:= Addr(ServerName[1]);
end;

procedure test();
begin
   MessageBox(0,PWideChar(IntToStr(SizeOf(PORT_MESSAGE))),PWideChar('size'),0);
end;


procedure InitializeAlpcPortAttributes(var AlpcPortAttributes:ALPC_PORT_ATTRIBUTES);
begin
    FillChar(AlpcPortAttributes,SizeOf(ALPC_PORT_ATTRIBUTES),#0);

    AlpcPortAttributes.Flags := ALPC_PORT_ATTRIBUTES_VALUES.kAlpcPortAttributesAllowImpersonation;
	  AlpcPortAttributes.MaxMessageLength := m_MaxMessageLength;
	  AlpcPortAttributes.MemoryBandwidth := m_MemoryBandwith;
	  AlpcPortAttributes.MaxMessageLength := m_MaxPoolUsage;
	  AlpcPortAttributes.MaxSectionSize := m_MaxSectionSize;
	  AlpcPortAttributes.MaxViewSize := m_MaxViewSize;
	  AlpcPortAttributes.DupObjectTypes := m_DupObjectTypes;

	  AlpcPortAttributes.SecurityQos.Length := sizeof(AlpcPortAttributes.SecurityQos);
	  AlpcPortAttributes.SecurityQos.ImpersonationLevel := SecurityImpersonation;
	  AlpcPortAttributes.SecurityQos.ContextTrackingMode := SECURITY_DYNAMIC_TRACKING;
	  AlpcPortAttributes.SecurityQos.EffectiveOnly := FALSE;

end;


function AlpcMessageInitialize(Buffer:PByte;BufferSize:Word;var AlpcMessage:TBinCache):NTSTATUS;
var
totalSize:Word;
begin
  Result:=STATUS_SUCCESS;
  totalSize:=BufferSize+sizeof(PORT_MESSAGE);
   if totalSize < SizeOf(PORT_MESSAGE) then  Exit(STATUS_INTEGER_OVERFLOW);
   if totalSize > SizeOf(TBinCache) then Exit(STATUS_INSUFFICIENT_RESOURCES);
   FillChar(AlpcMessage,totalSize,#0);
   PALPC_CUSTOM_MESSAGE(Addr(AlpcMessage)).Header.u1.s1.TotalLength := totalSize;
   if Buffer <> nil then
   begin
     //Move(Buffer^,PALPC_CUSTOM_MESSAGE(Addr(AlpcMessage)).Buffer,BufferSize);
     MoveMemory(Addr(PALPC_CUSTOM_MESSAGE(Addr(AlpcMessage)).Buffer[0]),Buffer,BufferSize);
     PALPC_CUSTOM_MESSAGE(Addr(AlpcMessage)).Header.u1.s1.DataLength := BufferSize;
   end;
end;


function AlpcMessageAttributesInitialize(
MessageAttributesFlags:ULONG;
var AlpcMessageAttrib:ALPC_MESSAGE_ATTRIBUTES   //fixed size, no need cache
):NTSTATUS;inline;
var
requiredSize:ULONG;
Ret:NTSTATUS;
begin
    Ret:=AlpcInitializeMessageAttribute(
    MessageAttributesFlags,
    AlpcMessageAttrib,
    0,
    requiredSize
    );  //Calc the require size for the flag
    if requiredSize = 0 then
    begin
      if Ret = 0 then Exit(STATUS_INFO_LENGTH_MISMATCH)
      else
      Exit(Ret);
    end;
    FillChar(AlpcMessageAttrib,SizeOf(ALPC_MESSAGE_ATTRIBUTES),#0); //zero Msgattribcache
    Ret:=AlpcInitializeMessageAttribute(
    MessageAttributesFlags,
    AlpcMessageAttrib,
    requiredSize,
    requiredSize
    );  //Store attrib to MsgAttribache
    Result:=Ret;
end;

function InitializeMessageAndAttributes(
MessageAttributesFlags:ULONG;
Buffer:PByte;
BufferSize:Word;
var AlpcMessage:TBinCache;  //BinCache
var AlpcMessageAttributes:ALPC_MESSAGE_ATTRIBUTES
):NTSTATUS;
begin
    if BufferSize >  MAXWORD then Exit(STATUS_INSUFFICIENT_RESOURCES);
    Result:=AlpcMessageInitialize(Buffer,BufferSize,AlpcMessage);//Move Buffer to MsgContextCache
    if Result <> 0 then Exit;
     Result := AlpcMessageAttributesInitialize(
     MessageAttributesFlags,
     AlpcMessageAttributes
     ); //Move Attrib to
end;


function ConnectToServer(const ServerName:WideString):NTSTATUS;
const
timeout:LARGE_INTEGER =(QuadPart:0);
var
connectMessage:PALPC_CUSTOM_MESSAGE;
connectMessageLength:ULONG;
alpcPortAttributes:ALPC_PORT_ATTRIBUTES;
PortName:UNICODE_STRING;
begin
     InitializeAlpcPortAttributes(alpcPortAttributes);
     AlpcMessageInitialize(
     nil,
     0,
     BinCache
     );
     connectMessage:=Addr(BinCache);
     connectMessageLength := connectMessage.Header.u1.s1.TotalLength;
     RTL_CONSTANT_STRING(ServerName,PortName);
     m_AlpcClientPortHandle:=0;
     Result:= CreatePort(
     Addr(m_AlpcClientPortHandle),
     Addr(PortName),
     nil,
     Addr(alpcPortAttributes),
     ALPC_MESSAGE_FLAGS.kAlpcMessageFlagSyncRequest,
     nil,
     Addr(connectMessage.Header),
     Addr(connectMessageLength),
     nil,
     nil,
     nil
     );
end;

function SendMsg(
AlpcPortHandle:HANDLE;
MsgID:ULONG = 0;
Flag:ULONG = 0
):NTSTATUS;
var
MsgAttrib:ALPC_MESSAGE_ATTRIBUTES;
begin
      Result := InitializeMessageAndAttributes(
      ALPC_MESSAGE_ATTRIBUTES_VALUES.kAlpcMessageAttributesNone,
      MsgBin,    //In,The Msg should be sended
      MsgLen^,   //In,The Msg Length
      BinCache,  //Out the MsgContextcache
      MsgAttrib //Out the MsgAttribCache
      );
      if Result = 0 then
      begin
      PALPC_CUSTOM_MESSAGE(Addr(BinCache[0])).Header.MessageId:=MsgID;
      Result:=DoPeekMessage(
       AlpcPortHandle,
       Flag,
      Addr(PALPC_CUSTOM_MESSAGE(Addr(BinCache[0])).Header),
      Addr(MsgAttrib),
      nil,
      nil,
      nil,
      nil
      );
      end;
end;

function SendMsgToServer:NTSTATUS;
begin
    Result:=SendMsg(m_AlpcClientPortHandle);
end;

function ClientDisconnect(Flag:Cardinal = 0):NTSTATUS;
begin
Result:=DisconnectFromServer(m_AlpcClientPortHandle,Flag);
end;

function SendMsgToClient(ClientMsgID:ULONG):NTSTATUS;
begin
    Result:=SendMsg(m_AlpcServerPortHandle,ClientMsgID,ALPC_MESSAGE_FLAGS.kAlpcMessageFlagReplyMessage);
end;

function ReceiveMsg(AlpcPortHandle:HANDLE):NTSTATUS;
var
MsgAttrib:ALPC_MESSAGE_ATTRIBUTES;
MsgSize:SIZE_T;
begin
     Result:=InitializeMessageAndAttributes(
     ALPC_MESSAGE_ATTRIBUTES_VALUES.kAlpcMessageAttributesNone,
     nil,
     m_MaxMessageLength,
     MsgCache,
     MsgAttrib
     );

     MsgSize:=PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Header.u1.s1.TotalLength;
     if Result = 0 then
     begin
     Result:= DoPeekMessage(
     AlpcPortHandle,//PortHandle:HANDLE
     ALPC_MESSAGE_FLAGS.kAlpcMessageFlagNone,//Flags:ULONG
     nil, //SendMessage:PPORT_MESSAGE
     nil,//SendMessageAttributes:PALPC_MESSAGE_ATTRIBUTES
     Addr(PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Header), //ReceiveMessage:PPORT_MESSAGE
     @MsgSize,
     Addr(MsgAttrib),  //ReceiveMessageAttributes:PALPC_MESSAGE_ATTRIBUTES
     nil //Timeout:PLARGE_INTEGER
     );
     end;
end;

function ReceiveMsg2(AlpcPortHandle:HANDLE):NTSTATUS;
var
MsgAttrib:ALPC_MESSAGE_ATTRIBUTES;
MsgSize:SIZE_T;
PMSG:PORT_MESSAGE;
begin
     Result:=InitializeMessageAndAttributes(
     ALPC_MESSAGE_ATTRIBUTES_VALUES.kAlpcMessageAttributesNone,
     nil,
     m_MaxMessageLength,
     BinCache,
     MsgAttrib
     );

     MsgSize:=PALPC_CUSTOM_MESSAGE(Addr(BinCache[0])).Header.u1.s1.TotalLength;
     PMSG.u1.s1.TotalLength:=MsgSize;
     if Result = 0 then
     begin
     MsgSize:=0;
     Result:= DoPeekMessage(
     AlpcPortHandle,//PortHandle:HANDLE
     ALPC_MESSAGE_FLAGS.kAlpcMessageFlagNone,//Flags:ULONG
     nil, //SendMessage:PPORT_MESSAGE
     nil,//SendMessageAttributes:PALPC_MESSAGE_ATTRIBUTES
     Addr(PMSG), //ReceiveMessage:PPORT_MESSAGE
     //Addr(PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Header.u1.s1.TotalLength), //BufferLength:PSIZE_T
     @MsgSize,
     Addr(MsgAttrib),  //ReceiveMessageAttributes:PALPC_MESSAGE_ATTRIBUTES
     nil //Timeout:PLARGE_INTEGER
     );
     end;
end;

function ReceiveMsgFromServer:NTSTATUS;
begin
   Result:=ReceiveMsg(m_AlpcClientPortHandle);
end;

function ReceiveMsgFromClient:NTSTATUS;
begin
   Result:=ReceiveMsg(m_AlpcServerPortHandle);
end;

procedure InitializeObjectAttributes(
Len:ULONG;
RootDirectory:Cardinal;
Attributes:ULONG;
ObjectName:PUNICODE_STRING;
SecurityDescriptor:PSECURITY_DESCRIPTOR;
SecurityQualityOfService:PSecurityQualityOfService;
var alpcPortObjectAttributes:OBJECT_ATTRIBUTES
);inline;
begin
 alpcPortObjectAttributes.Length:=Len;
 alpcPortObjectAttributes.RootDirectory:=RootDirectory;
 alpcPortObjectAttributes.Attributes:=Attributes;
 alpcPortObjectAttributes.ObjectName:=ObjectName;
 alpcPortObjectAttributes.SecurityDescriptor:=SecurityDescriptor;
 alpcPortObjectAttributes.SecurityQualityOfService:=SecurityQualityOfService;
end;

function ServerCreatePort(
const ServerName:WideString
):NTSTATUS;
var
alpcPortObjectAttributes:OBJECT_ATTRIBUTES;
alpcPortAttributes:ALPC_PORT_ATTRIBUTES;
PortName:UNICODE_STRING;
begin
InitializeAlpcPortAttributes(alpcPortAttributes);
RTL_CONSTANT_STRING(ServerName,PortName);
InitializeObjectAttributes(SizeOf(OBJECT_ATTRIBUTES),0,0,Addr(PortName),nil,nil,alpcPortObjectAttributes);
Result :=CreateServer(
Addr(m_AlpcServerPortHandle),
Addr(alpcPortObjectAttributes),
Addr(alpcPortAttributes)
);
end;

function ServerAcceptClient(
):NTSTATUS;
var
alpcPortAttributes:ALPC_PORT_ATTRIBUTES;
clientHandle:HANDLE;
//connectionRequest:PPORT_MESSAGE;
begin
	InitializeAlpcPortAttributes(alpcPortAttributes);
  Result:= AcceptClients(
 			Addr(clientHandle),                        // [out] PortHandle : PHANDLE
			m_AlpcServerPortHandle,                    // [in] ConnectionPortHandle : HANDLE
			ALPC_MESSAGE_FLAGS.kAlpcMessageFlagNone,   // [in] Flags : ULONG
			nil,                                       //[in opt] ObjectAttributes : POBJECT_ATTRIBUTES
			Addr(alpcPortAttributes),                  // [in opt] PortAttributes : PALPC_PORT_ATTRIBUTES
			nil,                                       //[in opt] PortContext : PVOID
			Addr(PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Header), // [in] ConnectionRequest : PPORT_MESSAGE
			nil,                                       // [inout opt] ConnectionMessageAttributes : PALPC_MESSAGE_ATTRIBUTES
			True
  );
  if Result = 0 then
  begin
      m_ClientList.Add(PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Header.MessageId,clientHandle);
  end;
end;


function ServerListenAndPeekMessage:NTSTATUS;
var
s:RawByteString;
status:ULONG;
begin
         Result:= ReceiveMsgFromClient;
         if Result = 0 then
         begin
         status:= PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Header.u2.s2._Type and $FFF;
           case status of
           LPC_PORT_CLOSED,
           LPC_LOST_REPLY,
           LPC_CLIENT_DIED:
           begin
               {SaveLog('Delete Client,HANDLE:' + IntToStr(
               Cardinal(m_ClientList[PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Header.MessageId])
               ));
               }
               m_ClientList.Remove(PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Header.MessageId);

           end;
           LPC_REQUEST:
           begin
              {SaveLog(
              'Rec Msg:' + PWideChar(MsgBin) + ',MsgID:' +
               IntToStr(PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Header.MessageId)
              );
               }
              s:='Hello,response from server';
              //SaveLog('Msg Context:' + s);
              MoveMemory(MsgBin,@s[1],Length(s));
              MsgLen^:=Length(s);
              Result:=SendMsgToClient(PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Header.MessageId);
              if Result = 0 then
              begin
               // SaveLog('Send Msg To Client!,True');
              end
              else
              begin
                //SaveLog('Send Msg To Client,False,errcode:' + IntToHex(Result,8));
                Exit;
               end;
           end;
           LPC_CONNECTION_REQUEST:
           begin
              Result:=ServerAcceptClient;
              if Result <> 0 then
              begin
                //SaveLog('Accept Client, Occur a error,errcode:' + IntToHex(Result,8));
                Exit;
              end;

           end
           else
           begin
               //SaveLog('Rec a message ,code:' + IntToHex(Result,8));
           end;

           end;
         end;
end;

{$ENDREGION}

initialization
MsgBin:=Addr(PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Buffer[0]);
MsgLen:=Addr(PALPC_CUSTOM_MESSAGE(Addr(MsgCache[0])).Header.u1.s1.DataLength);
m_ClientList:=TDictionary<ULONG,HANDLE>.Create;

finalization
m_ClientList.Free;
end.
