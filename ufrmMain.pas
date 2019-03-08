unit ufrmMain;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses

  Windows,
{$IFDEF FPC}
  LCLIntf, LCLType, LMessages,
{$ENDIF}
  ImageHlp,JwaTlHelp32, SysUtils,  Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ListBox1: TListBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
_IMAGE_IMPORT_DESCRIPTOR = packed record
case Integer of
0:(Characteristics: DWORD);
1:(OriginalFirstThunk:DWORD;TimeDateStamp:DWORD;ForwarderChain: DWORD;Name: DWORD;FirstThunk: DWORD);
end;
IMAGE_IMPORT_DESCRIPTOR=_IMAGE_IMPORT_DESCRIPTOR;
PIMAGE_IMPORT_DESCRIPTOR=^IMAGE_IMPORT_DESCRIPTOR;

type PFARPROC=^FARPROC;   //FARPROC = pointer;

var
  Form1: TForm1;
  //addr_NtQuerySystemInformation: Pointer;
  _messageboxa:function(hWnd: HWND; lpText, lpCaption: PAnsiChar; uType: UINT):integer;stdcall;

  {$IFnDEF FPC}
  type ptruint=dword;
  {$ENDIF}

implementation

{$R *.dfm}

function RedirectIAT(pszCallerModName: Pchar; pfnCurrent: FarProc; pfnNew: FARPROC; hmodCaller: hModule):boolean;
var     ulSize: ULONG;
   pImportDesc: PIMAGE_IMPORT_DESCRIPTOR;
    pszModName: PChar;
        pThunk: PDWORD;
        ppfn:PFARPROC;
        ffound: LongBool;
       //written: DWORD;
       written:ptruint;
begin
result:=false;
{$IFDEF FPC}
 pImportDesc:= ImageDirectoryEntryToData(Pointer(hmodCaller), TRUE,IMAGE_DIRECTORY_ENTRY_IMPORT, @ulSize);
{$ELSE}
pImportDesc:= ImageDirectoryEntryToData(Pointer(hmodCaller), TRUE,IMAGE_DIRECTORY_ENTRY_IMPORT, ulSize);
{$ENDIF}
  if pImportDesc = nil then exit;
  while pImportDesc.Name<>0 do
   begin
    pszModName := PChar(hmodCaller + pImportDesc.Name);
    //is this the library we are looking for?
     if (lstrcmpiA(pszModName, pszCallerModName) = 0) then break;  //The comparison is not case-sensitive
    Inc(pImportDesc);
   end;
  if (pImportDesc.Name = 0) then exit;
 pThunk := PDWORD(hmodCaller + pImportDesc.FirstThunk);
  while pThunk^<>0 do
   begin
    ppfn := PFARPROC(pThunk);
    fFound := (ppfn^ = pfnCurrent);
     if (fFound) then
      begin
       //lets overwrite the original pointer to the function with our pointer to our function
       {$IFDEF FPC}
       VirtualProtectEx(GetCurrentProcess,ppfn,4,PAGE_EXECUTE_READWRITE,@written);
       {$ELSE}
       VirtualProtectEx(GetCurrentProcess,ppfn,4,PAGE_EXECUTE_READWRITE,written);
       {$ENDIF}
       written:=0;
       WriteProcessMemory(GetCurrentProcess, ppfn, @pfnNew, sizeof(pfnNew), Written);
       //the below would probably work if we are in the same exe ... thus avoiding VirtualProtectEx+WriteProcessMemory
       //ppfn^ :=  Cardinal(pfnNew);
       if written<>0 then result:=true;
       exit;
      end;
    Inc(pThunk);
   end;
end;

procedure myexitprocess(dwexitcode:dword);
begin
messageboxw(0,'hook:exit','hook:exit',0);
//exitprocess(dwexitcode);
end;

function MyMessageBoxA(hWnd: HWND; lpText, lpCaption: PAnsiChar; uType: UINT): Integer; stdcall;
begin
//we should call the original pointer or else we will enter a deadly loop...
result:=_messageboxa(hwnd,'hook:messageboxa','hook:messageboxa',utype);
//result:=messageboxw(hwnd,'hook:messageboxa','hook:messageboxa',utype);
end;

function FuncIncept(dll,api:string;new:pointer):boolean;
var hSnapShot: THandle;
         me32: MODULEENTRY32;
          hfunc:farproc;
begin
result:=false;
hfunc:=nil;
 hfunc:=GetProcAddress(getModuleHandle(pchar(dll)),pchar(api));
 if hfunc=nil then exit;
hSnapShot:=CreateToolHelp32SnapShot(TH32CS_SNAPMODULE,GetCurrentProcessId);
if hSnapshot=INVALID_HANDLE_VALUE then raise exception.create('hSnapshot=INVALID_HANDLE_VALUE');

try
 ZeroMemory(@me32,sizeof(MODULEENTRY32));
 me32.dwSize:=sizeof(MODULEENTRY32);
 Module32First(hSnapShot,me32);
 //we are going thru all loaded modules although the main module might be enough
 //i.e GetModuleHandle(nil)
repeat
  if RedirectIAT(pchar(dll),hfunc,new,me32.hModule)
    then Form1.ListBox1.Items.Add(strpas(me32.szmodule)+':'+inttohex(integer(me32.modBaseAddr),4)+ ' TRUE')
    else Form1.ListBox1.Items.Add(strpas(me32.szmodule)+':'+inttohex(integer(me32.modBaseAddr),4)+ ' FALSE');

until not Module32Next(hSnapShot,me32);
   finally
    FileClose(hSnapShot); { *Converted from CloseHandle* }
   end;
result:=true;   
end;

function FreeFunc(dll,api:string;current:pointer):boolean;
var hSnapShot: THandle;
         me32: MODULEENTRY32;
         hfunc:farproc;

begin
result:=false;
hfunc:=nil;
 hfunc:=GetProcAddress(getModuleHandle(pchar(dll)),pchar(api));
if hfunc=nil then exit;
 hSnapShot:=CreateToolHelp32SnapShot(TH32CS_SNAPMODULE,GetCurrentProcessId);
  if hSnapshot=INVALID_HANDLE_VALUE then exit;
  try
   ZeroMemory(@me32,sizeof(MODULEENTRY32));
   me32.dwSize:=sizeof(MODULEENTRY32);

   Module32First(hSnapShot,me32);
    repeat
     RedirectIAT(pchar(dll),current,hfunc,me32.hModule);
    until not Module32Next(hSnapShot,me32);
  finally
   FileClose(hSnapShot); { *Converted from CloseHandle* }
  end;
result:=true;  
end;

procedure TForm1.Button1Click(Sender: TObject);
var ret:boolean;
begin
ListBox1.Clear ;
@_messageboxa:=GetProcAddress(getModuleHandle('user32.dll'),'MessageBoxA');
ret:=FuncIncept('user32.dll','MessageBoxA',@mymessageboxa);
if ret=false then showmessage('false...');
//ret:=FuncIncept('kernel32.dll','ExitProcess',@myexitprocess);
//if ret=false then showmessage('false...');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
//exitprocess(0);
//delphi may bind some api differently but the below will definitely be intercepted with lazarus/fpc
MessageBoxA (0 ,'test','test',0);
end;

procedure TForm1.Button3Click(Sender: TObject);
var ret:boolean;
begin
//eventually, we can restore the original pointer
ret:=freefunc('user32.dll','MessageBoxA',@mymessageboxa);
//ret:=freefunc('kernel32.dll','ExitProcess',@myexitprocess);
//if ret=false then showmessage('freefunc:false...');
end;

end.


