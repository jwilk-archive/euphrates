library Hooker;

uses Windows, Messages, Special;

function HookProc(code:longint; wParam:longint; lParam:integer):longint; export; stdcall;
var
   FDataHandle:THandle;
   FDataPtr:^TSharedData;
begin
  FDataHandle:=OpenFileMapping(FILE_MAP_WRITE,true,cMapName);
  FDataPtr:=MapViewOfFile(FDataHandle,FILE_MAP_ALL_ACCESS,0,0,0);
  PostMessage(FDataPtr^.HWnd,WM_USER+7,wParam,integer(lParam));
  CallNextHookEx(FDataPtr^.NextH,code,wParam,integer(lParam));
  UnmapViewOfFile(FDataPtr);
  CloseHandle(FDataHandle);
  Result:=0;
end;

exports
  HookProc index 1;

end.
