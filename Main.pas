unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    StaticText1: TStaticText;
    Button2: TButton;
    Memo1: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
uses
Inject,NTLib;
{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  InjectDll(PAnsiChar('Guild wars'));
  Sleep(1000);
 if  ConnectToServer('\RPC Control\MyCoolDummyAlpcPort') = 0 then
 begin
 Self.Button1.Enabled:=False;
 Self.Button1.Caption:='��ʼ���ɹ�';
 end
 else
 begin
   Self.Button1.Enabled:=False;
   ShowMessage('���ʹ��������´򿪿ͻ��ˣ�����ϵ����Ա');
 end;
  //PWideChar(MsgBin):= 'Ana are mere';
  //MsgLen^:=SizeOf(char)*StrLen(PWideChar(MsgBin));
  //SendMsgToServer;
  //ReceiveMsgFromServer;
  //ShowMessage(PWideChar(MsgBin));
end;

procedure TForm1.Button2Click(Sender: TObject);
var
s:RawByteString;
begin
if Edit1.Text = '' then  ShowMessage('���ݲ���Ϊ��')
else
begin
    s:='���';
     MsgLen^:=Length(s);
     MoveMemory(MsgBin,@s[1],MsgLen^);
     if SendMsgToServer = 0 then
     begin
      Memo1.Lines.Add('������Ϣ�ɹ�');
      if  ReceiveMsgFromServer = 0 then
      begin
           Memo1.Lines.Add('�յ���Ϣ:' + PAnsiChar(MsgBin) + ',��Ϣ����:' + IntToStr(strlen(PWideChar(MsgBin))));
      end
      else
      begin
          Memo1.Lines.Add('������Ϣ���ʹ���');
      end;
     end
     else
     begin
          Memo1.Lines.Add('������Ϣ���ʹ���');
     end;

end;

end;

end.
