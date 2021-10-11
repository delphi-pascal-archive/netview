unit NvPing;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask;

type
  TPingDialog = class(TForm)
    btnStart: TButton;
    btnCancel: TButton;
    GroupBox: TGroupBox;
    lblBytes: TLabel;
    lblNumber: TLabel;
    lblTimeOut: TLabel;
    edtBytes: TMaskEdit;
    edtNumber: TMaskEdit;
    edtTimeOut: TMaskEdit;
    chkFragment: TCheckBox;
    lblResults: TLabel;
    Memo: TMemo;
    procedure FormShow(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    { Private declarations }
    FComputerName: string;
    FIpAddress: string;
    FCancel: Boolean;
  public
    { Public declarations }
    property ComputerName: string read FComputerName write FComputerName;
    property IpAddress: string read FIpAddress write FIpAddress;
  end;

procedure ShowPingDialog(AOwner: TComponent; const AComputerName, AIpAddress: string);

var
  PingDialog: TPingDialog;

implementation

uses NvConst, Icmp, WinSock;

{$R *.dfm}

var
  IcmpHandle: THandle;
  
procedure ShowPingDialog(AOwner: TComponent; const AComputerName, AIpAddress: string);
begin
  with TPingDialog.Create(AOwner) do
  try
    FComputerName := AComputerName;
    FIpAddress := AIpAddress;
    ShowModal;
  finally
    Free;
  end;
end;

procedure TPingDialog.FormShow(Sender: TObject);
begin
  Caption := Format(SPingDlgCaption, [FComputerName]);
end;

procedure TPingDialog.btnStartClick(Sender: TObject);
var
  BufferSize, TimeOut, EchoCount, RetVal, i: Integer;
  IpOpt: TIPOptionInformation;
  PingBuffer: Pointer;
  pIpe: PIcmpEchoReply;
  TimeStr: string;
begin
  if IcmpHandle = INVALID_HANDLE_VALUE then
  begin
    Memo.Lines.Add(SInitErr);
    Exit;
  end;
  BufferSize := StrToInt(Trim(edtBytes.Text));
  if (BufferSize < 1) or (BufferSize > 65500) then
  begin
    BufferSize := 32;
    edtBytes.Text := IntToStr(BufferSize);
  end;
  EchoCount := StrToInt(Trim(edtNumber.Text));
  if EchoCount < 1 then
  begin
    EchoCount := 4;
    edtNumber.Text := IntToStr(EchoCount);
  end;
  TimeOut := StrToInt(Trim(edtTimeOut.Text));
  if TimeOut < 1 then
  begin
    TimeOut := 1000;
    edtTimeout.Text := IntToStr(TimeOut);
  end;
  with IpOpt do
  begin
    Ttl := 32;
    Tos := 0;
    if chkFragment.Checked then
      Flags := IP_FLAG_DF
    else
      Flags := 0;
    OptionsSize := 0;
    OptionsData := nil;
  end;
  GetMem(pIpe, SizeOf(TICMPEchoReply) + BufferSize);
  GetMem(PingBuffer, BufferSize);
  try
    FillChar(PingBuffer^, BufferSize, $AA);
    pIpe^.Data := PingBuffer;
    if Memo.Lines.Count > 100 then
    begin
      Memo.Lines.BeginUpdate;
      Memo.Lines.Delete(0);
      Memo.Lines.EndUpdate;
    end;
    Memo.Lines.Add(Format(SPinging, [FComputerName, FIpAddress, BufferSize]));
    for i := 0 to EchoCount - 1 do
    begin
      Application.ProcessMessages;
      if FCancel then Break;
      RetVal := IcmpSendEcho(IcmpHandle, inet_addr(PChar(FIpAddress)), PingBuffer,
                             BufferSize, @IpOpt, pIpe,
                             SizeOf(TICMPEchoReply) + BufferSize, TimeOut);
      if RetVal = 0 then
      begin
        RetVal := GetLastError;
        case RetVal of
          IP_REQ_TIMED_OUT: Memo.Lines.Add(SReqTimedOut);
          IP_PACKET_TOO_BIG: Memo.Lines.Add(SPacketTooBig);
        else
          Memo.Lines.Add(Format(SErrorCode, [RetVal]));
        end;
        Sleep(1000);
        Continue;
      end;
      if pIpe^.RoundTripTime < 1 then
        TimeStr := '<10'
      else
        TimeStr := '=' + IntToStr(pIpe^.RoundTripTime);
      Memo.Lines.Add(Format(SReply, [inet_ntoa(TInAddr(pIpe^.Address)),
                                     pIpe^.DataSize, TimeStr, pIpe^.Options.Ttl]));
      Sleep(1000);
    end;
    Memo.Lines.Add('');
  finally
    FreeMem(pIpe);
    FreeMem(PingBuffer);
  end;
end;

procedure TPingDialog.btnCancelClick(Sender: TObject);
begin
  FCancel := True;
end;

initialization
  IcmpHandle := IcmpCreateFile;
finalization
 if IcmpHandle <> INVALID_HANDLE_VALUE then
   IcmpCloseHandle(IcmpHandle);
end.
