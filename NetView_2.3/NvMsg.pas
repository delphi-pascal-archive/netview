unit NvMsg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TMessageDialog = class(TForm)
    lblTo: TLabel;
    edtTo: TEdit;
    memText: TMemo;
    btnSend: TButton;
    btnCancel: TButton;
    lblText: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

procedure ShowMessageDialog(AOwner: TComponent; const AToName: string);

var
  MessageDialog: TMessageDialog;

implementation

uses NvConst;

{$R *.dfm}

var
  hLib: THandle = 0;
  NetMessageBufferSend: function(servername: LPCWSTR; msgname: LPCWSTR;
    fromname: LPCWSTR; buf: PBYTE; buflen: DWORD): DWORD; stdcall = nil;

procedure ShowMessageDialog(AOwner: TComponent; const AToName: string);
begin
  with TMessageDialog.Create(AOwner) do
  try
    edtTo.Text := AToName;
    ShowModal;
  finally
    Free;
  end;
end;

procedure TMessageDialog.FormCreate(Sender: TObject);
var
  ComputerName: array[0..MAX_COMPUTERNAME_LENGTH] of Char;
  nSize: DWORD;
begin
  nSize := SizeOf(ComputerName);
  if GetComputerName(ComputerName, nSize) then
    Caption := Format(SMsgDlgCaption, [ComputerName]);
end;

procedure TMessageDialog.btnSendClick(Sender: TObject);
var
  ToNameBuffer, TextBuffer: PWideChar;
  ToNameLen, TextLen, RetVal: DWORD;
begin
  if (hLib > 0) and Assigned(NetMessageBufferSend) then
  begin
    ToNameLen := Length(edtTo.Text);
    ToNameBuffer := AllocMem((ToNameLen + 1) * SizeOf(WideChar));
    try
      StringToWideChar(edtTo.Text, ToNameBuffer, ToNameLen + 1);
      TextLen := Length(memText.Text);
      TextBuffer := AllocMem((TextLen + 1) * SizeOf(WideChar));
      try
        StringToWideChar(memText.Text, TextBuffer, TextLen + 1);
        RetVal := NetMessageBufferSend(nil, ToNameBuffer, nil,
                                       PByte(TextBuffer),
                                       (TextLen + 1) * SizeOf(WideChar));
        if RetVal > 0 then
          raise Exception.Create(SysErrorMessage(RetVal))
        else
          Close;  
      finally
        FreeMem(TextBuffer);
      end;
    finally
      FreeMem(ToNameBuffer);
    end;
  end;
end;

initialization
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    hLib := LoadLibrary('netapi32.dll');
    if hLib > 0 then
      @NetMessageBufferSend := GetProcAddress(hLib, 'NetMessageBufferSend');
  end;
finalization
  if hlib > 0 then
    FreeLibrary(hLib);
end.
