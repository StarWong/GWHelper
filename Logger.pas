unit Logger;

interface

procedure SaveLog(const Str: string;Date_lOG:Boolean=False);overload
procedure SaveLog(const Data: Cardinal;Date_lOG:Boolean=False);overload
procedure SaveLog(const Key: string;const Value: Cardinal;Date_lOG:Boolean=False);overload
procedure SaveLog(const Key: string;const Value: Cardinal;BaseData:Cardinal = 0;Date_lOG:Boolean=False);overload
procedure SetLogger(const DirectoryPath_:string;const logFileName_:string;const RetSetLogFile_:Boolean);
implementation
uses
SysUtils;
var
DirectoryPath:string = '';
logFileName:string = 'Logger.log';
RetSetLogFile:Boolean = True;
{$REGION 'Debug & Logs'}
procedure AppendTxt(const filePath, Str: string); // 主进程函数
var
  F: Textfile;
begin
  AssignFile(F, filePath);
  Append(F);
  Writeln(F, Str);
  Closefile(F);
end;

// 新建文件                                                //主进程函数

procedure NewTxt(const filePath: string);
var
  F: Textfile;
begin
  AssignFile(F, filePath);
  ReWrite(F);
  Closefile(F);
end;
procedure SaveLog(const Str: string;Date_lOG:Boolean=False);
begin
    if Date_lOG then
    AppendTxt(DirectoryPath + logFileName, Str)
    else
    AppendTxt(DirectoryPath + logFileName,
    FormatDateTime('YYYY-MM-DD HH:NN:SS ZZZ: ',Now) + Str);
end;

procedure SaveLog(const Data: Cardinal;Date_lOG:Boolean=False);
begin
  SaveLog(IntToStr(Data),Date_lOG);
end;

procedure SaveLog(const Key: string;const Value: Cardinal;Date_lOG:Boolean=False);
begin
  SaveLog(Key + ':' + IntToStr(Value),Date_lOG);
end;

procedure SaveLog(const Key: string;const Value: Cardinal;BaseData:Cardinal = 0;Date_lOG:Boolean=False);
begin
  SaveLog(Key,Value - BaseData,Date_lOG );
end;

procedure SetLogger(const DirectoryPath_:string;const logFileName_:string;const RetSetLogFile_:Boolean);
begin
    DirectoryPath:=DirectoryPath_;
    logFileName:=logFileName_;
    RetSetLogFile:=RetSetLogFile_;
end;


{$ENDREGION}

initialization
DirectoryPath := ExtractFilePath(paramstr(0));
if  not fileExists(DirectoryPath + logFileName) then
    NewTxt(DirectoryPath + logFileName)
    else
    begin
      if RetSetLogFile then
      begin
        DeleteFile(DirectoryPath + logFileName);
        NewTxt(DirectoryPath + logFileName);
      end;
    end;
finalization

end.
