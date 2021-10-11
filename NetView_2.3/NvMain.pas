
{*******************************************************}
{                                                       }
{                 NetView Version 2.3                   }
{                                                       }
{                                                       }
{         Copyright (c) 1999-2004 Vadim Crits           }
{                                                       }
{*******************************************************}

unit NvMain;

{$WARN SYMBOL_DEPRECATED OFF}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, ToolWin, Menus, ImgList, ActnList, ExtCtrls, StdCtrls, Registry;

type
  TResourceType = (rtComputer, rtSharedFolder, rtSharedPrinter);

  TMainForm = class(TForm)
    StatusBar: TStatusBar;
    ListView: TListView;
    ImageList: TImageList;
    CoolBar: TCoolBar;
    Animate: TAnimate;
    ActionList: TActionList;
    actSave: TAction;
    actSaveAs: TAction;
    actExit: TAction;
    actToolBar: TAction;
    actStatusBar: TAction;
    actRefresh: TAction;
    actFind: TAction;
    actPing: TAction;
    actAbout: TAction;
    Splitter: TSplitter;
    psMenuBar: TPageScroller;
    MenuBar: TToolBar;
    btnFile: TToolButton;
    btnView: TToolButton;
    btnResource: TToolButton;
    btnHelp: TToolButton;
    PopupMenu: TPopupMenu;
    actGridLines: TAction;
    actHotTrack: TAction;
    actRowSelect: TAction;
    piGridLines: TMenuItem;
    piHotTrack: TMenuItem;
    piRowSelect: TMenuItem;
    psToolBar: TPageScroller;
    ToolBar: TToolBar;
    btnSave: TToolButton;
    ToolButton1: TToolButton;
    btnStop: TToolButton;
    btnRefresh: TToolButton;
    ToolButton2: TToolButton;
    btnFind: TToolButton;
    btnPing: TToolButton;
    actStop: TAction;
    ResourceBar: TToolBar;
    cboResource: TComboBox;
    btnGo: TToolButton;
    actGo: TAction;
    actResourceBar: TAction;
    TbrImages: TImageList;
    TbrHotImages: TImageList;
    MainMenu: TMainMenu;
    miFile: TMenuItem;
    miView: TMenuItem;
    miResource: TMenuItem;
    miHelp: TMenuItem;
    miSave: TMenuItem;
    miSaveAs: TMenuItem;
    N1: TMenuItem;
    miExit: TMenuItem;
    miToolbars: TMenuItem;
    miStatusBar: TMenuItem;
    N2: TMenuItem;
    miGridLines: TMenuItem;
    miHotTrack: TMenuItem;
    miRowSelect: TMenuItem;
    N3: TMenuItem;
    miGo: TMenuItem;
    miStop: TMenuItem;
    miRefresh: TMenuItem;
    miStandardButtons: TMenuItem;
    miResourceBar: TMenuItem;
    miFind: TMenuItem;
    miPing: TMenuItem;
    miAbout: TMenuItem;
    actOpen: TAction;
    btnOpen: TToolButton;
    ProgressBar: TProgressBar;
    miOpen: TMenuItem;
    actMessage: TAction;
    btnMessage: TToolButton;
    miMessage: TMenuItem;
    piOpen: TMenuItem;
    piPing: TMenuItem;
    piMessage: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListViewColumnClick(Sender: TObject; Column: TListColumn);
    procedure ListViewCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure ListViewDblClick(Sender: TObject);
    procedure ListViewKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure StatusBarResize(Sender: TObject);
    procedure StatusBarDrawPanel(StatusBar: TStatusBar;
      Panel: TStatusPanel; const Rect: TRect);
    procedure cboResourceKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cboResourceDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure SplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure ResourceBarResize(Sender: TObject);
    procedure actSaveExecute(Sender: TObject);
    procedure actSaveAsExecute(Sender: TObject);
    procedure actExitExecute(Sender: TObject);
    procedure actToolBarExecute(Sender: TObject);
    procedure actResourceBarExecute(Sender: TObject);
    procedure actStatusBarExecute(Sender: TObject);
    procedure actGoExecute(Sender: TObject);
    procedure actStopExecute(Sender: TObject);
    procedure actRefreshExecute(Sender: TObject);
    procedure actFindExecute(Sender: TObject);
    procedure actOpenExecute(Sender: TObject);
    procedure actPingExecute(Sender: TObject);
    procedure actMessageExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
    procedure actGridLinesExecute(Sender: TObject);
    procedure actHotTrackExecute(Sender: TObject);
    procedure actRowSelectExecute(Sender: TObject);
    procedure ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure PopupMenuPopup(Sender: TObject);
  private
    { Private declarations }
    FRegistry: TRegistry;
    FResType: TResourceType;
    FSortCol: Integer;
    FAscending: Boolean;
    FFileName: string;
    procedure ThreadDone(Sender: TObject);
    procedure MkFile(const FileName: string; CreationFlag: Boolean);
  public
    { Public declarations }
    property Registry: TRegistry read FRegistry;
  end;

  TItemData = packed record
    ImageIndex: Integer;
    Caption : string;
    SubItem0: string;
    SubItem1: string;
    SubItem2: string;
    SubItem3: string;
  end;

  TChildThread = class(TThread)
  private
    FResType: TResourceType;
    FValue: Integer;
    FCurItem: TItemData;
    procedure SetMax;
    procedure SetPosition;
    procedure AddItem;
  protected
    procedure Execute; override;
  public
    constructor Create(ResType: TResourceType);
  end;

var
  MainForm: TMainForm;
  ChildThread: TChildThread;

implementation

uses NvFind, NvPing, NvMsg, NvAbout, NvConst, WinSock, Nb30, MMSystem, ShellAPI;

{$R *.dfm}

var
  ProviderName: array[0..255] of Char;
  LanaEnum: TLanaEnum;

function GetLana(var LanaEnum: TLanaEnum): Boolean;
var
  NCB: TNCB;
begin
  FillChar(LanaEnum, SizeOf(LanaEnum), 0);
  FillChar(NCB, SizeOf(NCB), 0);
  with NCB do
  begin
    ncb_command := Char(NCBENUM);
    ncb_buffer := PChar(@LanaEnum);
    ncb_length := SizeOf(TLanaEnum);
    Netbios(@NCB);
    Result := (ncb_retcode = Char(NRC_GOODRET)) and (Byte(LanaEnum.length) > 0);
  end;
end;

function NBReset(const LanaNum: Char): Boolean;
var
  NCB: TNCB;
begin
  FillChar(NCB, SizeOf(NCB), 0);
  with NCB do
  begin
    ncb_command := Char(NCBRESET);
    ncb_lana_num := LanaNum;
    Netbios(@NCB);
    Result := (ncb_retcode = Char(NRC_GOODRET));
  end;
end;

function GetMacAddress(const LanaNum: Char; Name: PChar): string;
var
  NCB: TNCB;
  AdapterStatus: PAdapterStatus;
begin
  Result := '';
  FillChar(NCB, SizeOf(TNCB), 0);
  FillChar(AdapterStatus, SizeOf(AdapterStatus), 0);
  NCB.ncb_length := SizeOf(TAdapterStatus) + 255 * SizeOf(TNameBuffer);
  GetMem(AdapterStatus, NCB.ncb_length);
  try
    with NCB do
    begin
      ncb_command := Char(NCBASTAT);
      ncb_buffer := PChar(AdapterStatus);
      StrCopy(ncb_callname, Name);
      ncb_lana_num := LanaNum;
      Netbios(@NCB);
      if ncb_retcode = Char(NRC_GOODRET) then
        Result := Format('%2.2x-%2.2x-%2.2x-%2.2x-%2.2x-%2.2x', [
                         Byte(AdapterStatus^.adapter_address[0]),
                         Byte(AdapterStatus^.adapter_address[1]),
                         Byte(AdapterStatus^.adapter_address[2]),
                         Byte(AdapterStatus^.adapter_address[3]),
                         Byte(AdapterStatus^.adapter_address[4]),
                         Byte(AdapterStatus^.adapter_address[5])]);
    end;
  finally
    FreeMem(AdapterStatus);
  end;
end;

{ TChildThread }

constructor TChildThread.Create(ResType: TResourceType);
begin
  inherited Create(False);
  FResType := ResType;
end;

procedure TChildThread.AddItem;
begin
  with MainForm do
  begin
    with ListView.Items.Add do
    begin
      ImageIndex := FCurItem.ImageIndex;
      Caption := FCurItem.Caption;
      SubItems.Add(FCurItem.SubItem0);
      SubItems.Add(FCurItem.SubItem1);
      if FResType = rtComputer then
      begin
        SubItems.Add(FCurItem.SubItem2);
        SubItems.Add(FCurItem.SubItem3);
      end;
    end;
    if FSortCol <> -1 then
      ListView.CustomSort(nil, FSortCol - 1);
  end;
  Application.ProcessMessages;
end;

procedure TChildThread.SetMax;
begin
  MainForm.ProgressBar.Max := FValue;
end;

procedure TChildThread.SetPosition;
begin
  MainForm.ProgressBar.Position := FValue;
end;

procedure TChildThread.Execute;
const
  ENUM_COUNT = 512;
  MAX_ENTRIES = DWORD(-1);
var
  hEnum: THandle;
  NetGroups, NetComps, NetShares: array[0..ENUM_COUNT - 1] of TNetResource;
  BufferSize, GroupCount, CompCount, ShareCount: DWORD;
  i, j, k: Integer;
  ComputerName: string;
  HostEnt: PHostEnt;
  NBBuffer: array[0..NCBNAMSZ - 1] of Char;
begin
  BufferSize := SizeOf(TNetResource) * ENUM_COUNT;
  NetGroups[0].lpProvider := ProviderName;
  if WNetOpenEnum(RESOURCE_GLOBALNET, RESOURCETYPE_DISK,
                  RESOURCEUSAGE_CONTAINER, @NetGroups[0], hEnum) <> NO_ERROR then
  begin
    ReturnValue := -1;
    RaiseLastWin32Error;
  end;
  GroupCount := MAX_ENTRIES;
  FillChar(NetGroups, BufferSize, 0);
  try
    if WNetEnumResource(hEnum, GroupCount, @NetGroups, BufferSize) <> NO_ERROR then
    begin
      ReturnValue := -1;
      RaiseLastWin32Error;
    end;
  finally
    WNetCloseEnum(hEnum);
  end;
  FValue := GroupCount - 1;
  Synchronize(SetMax);
  for i := 0 to GroupCount - 1 do
  begin
    FValue := i;
    Synchronize(SetPosition);
    if Terminated then
    begin
      ReturnValue := -1;
      Exit;
    end;
    if WNetOpenEnum(RESOURCE_GLOBALNET, RESOURCETYPE_DISK,
                    RESOURCEUSAGE_CONTAINER, @NetGroups[i], hEnum) <> NO_ERROR then
      Continue;
    CompCount := MAX_ENTRIES;
    FillChar(NetComps, BufferSize, 0);
    try
      if WNetEnumResource(hEnum, CompCount, @NetComps, BufferSize) <> NO_ERROR then
        Continue;
    finally
      WNetCloseEnum(hEnum);
    end;
    for j := 0 to CompCount - 1 do
    begin
      if Terminated then
      begin
        ReturnValue := -1;
        Exit;
      end;
      case FResType of
        rtComputer:
          with FCurItem do
          begin
            ImageIndex := Ord(FResType);
            Caption := NetComps[j].lpRemoteName;
            SubItem0 := NetGroups[i].lpRemoteName;
            SubItem1 := NetComps[j].lpComment;
            ComputerName := Copy(Caption, 3, MaxInt);
            HostEnt := gethostbyname(PChar(ComputerName));
            if Assigned(HostEnt) then
              SubItem2 := inet_ntoa(TInAddr(PLongint(HostEnt^.h_addr_list^)^))
            else
              SubItem2 := '?.?.?.?';
            for k := 0 to Byte(LanaEnum.length) - 1 do
            begin
              if Terminated then
              begin
                ReturnValue := -1;
                Exit;
              end;
              FillChar(NBBuffer, NCBNAMSZ, ' ');
              CopyMemory(@NBBuffer, PChar(ComputerName), Length(ComputerName));
              SubItem3 := GetMacAddress(LanaEnum.lana[k], NBBuffer);
              if SubItem3 <> '' then
                Break;
            end;
            if SubItem3 = '' then
              SubItem3 := '?-?-?-?-?-?';
            if (Pos('?', SubItem2) > 0) or (Pos('?', SubItem3) > 0) then
              ImageIndex := 3;
            Synchronize(AddItem);
          end;
        rtSharedFolder, rtSharedPrinter:
          begin
            if WNetOpenEnum(RESOURCE_GLOBALNET, Ord(FResType),
                            RESOURCEUSAGE_CONNECTABLE, @NetComps[j], hEnum) <> NO_ERROR then
              Continue;
            ShareCount := MAX_ENTRIES;
            FillChar(NetShares, BufferSize, 0);
            try
              if WNetEnumResource(hEnum, ShareCount, @NetShares, BufferSize) <> NO_ERROR then
                Continue;
            finally
              WNetCloseEnum(hEnum);
            end;
            for k := 0 to ShareCount - 1 do
            begin
              if Terminated then
              begin
                ReturnValue := -1;
                Exit;
              end;
              with FCurItem do
              begin
                ImageIndex := Ord(FResType);
                Caption := NetShares[k].lpRemoteName;
                SubItem0 := NetGroups[i].lpRemoteName;
                SubItem1 := NetShares[k].lpComment;
              end;
              Synchronize(AddItem);
            end;
          end;
      end;
    end;
  end;
end;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);

  procedure FatalError(const ErrMsg: string);
  begin
    with Application do
    begin
      MessageBox(PChar(ErrMsg), PChar(Title), MB_OK or MB_ICONERROR);
      ShowMainForm := False;
      Terminate;
    end;
  end;

var
  BufferSize: Cardinal;
  WSAData: TWSAData;
  i: Integer;
  Position: TRect;
begin
  BufferSize := SizeOf(ProviderName);
  if WNetGetProviderName(WNNC_NET_LANMAN, @ProviderName, BufferSize) <> NO_ERROR then
    FatalError(SysErrorMessage(GetLastError));
  if WSAStartup($0101, WSAData) <> 0 then
    FatalError(SWinSockErr);
  if not GetLana(LanaEnum) then
    FatalError(SProblemWithNA);
  if Win32Platform = VER_PLATFORM_WIN32_NT then
    for i := 0 to Byte(LanaEnum.length) - 1 do
      if not NBReset(LanaEnum.lana[i]) then
        FatalError(SResetLanaErr);
  Animate.ResName := 'FINDCOMP';
  with cboResource do
  begin
    for i := 0 to High(NetResNames) do
      Items.Add(NetResNames[i]);
    ItemIndex := 0;
  end;
  with ProgressBar do
  begin
    Parent := StatusBar;
    Top := 2;
    Height := StatusBar.Height - 2;
  end;
  FRegistry := TRegistry.Create;
  with FRegistry do
    if OpenKey(INIT_KEY, False) then
    try
      if ValueExists(SPosition) then
      begin
        ReadBinaryData(SPosition, Position, SizeOf(Position));
        BoundsRect := Position;
      end;
      if ValueExists(SWindowState) then
        if ReadInteger(SWindowState) = Ord(wsMaximized) then
          WindowState := wsMaximized;
      if ValueExists(SResourceType) then
        cboResource.ItemIndex := ReadInteger(SResourceType);
      if ValueExists(SShowToolBar) then
        psToolBar.Visible := ReadBool(SShowToolBar);
      if ValueExists(SShowResourceBar) then
        ResourceBar.Visible := ReadBool(SShowResourceBar);
      if ValueExists(SShowStatusBar) then
        StatusBar.Visible := ReadBool(SShowStatusBar);
      with ListView do
      begin
        if ValueExists(SShowGridLines) then
          GridLines := ReadBool(SShowGridLines);
        if ValueExists(SShowHotTrack) then
          if ReadBool(SShowHotTrack) then
            actHotTrack.Execute;
        if ValueExists(SShowRowSelect) then
          RowSelect := ReadBool(SShowRowSelect);
      end;
    finally
      CloseKey;
    end;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  actGo.Execute;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  Position: TRect;
begin
  with FRegistry do
  begin
    RootKey := HKEY_CLASSES_ROOT;
    if not KeyExists(NN_KEY) then
      if OpenKey(NN_KEY, True) then
      try
        WriteString('', SScanWithNetView);
        CloseKey;
        OpenKey(NN_KEY + 'command', True);
        WriteString('', Application.ExeName + ' "%1"');
      finally
        CloseKey;
      end;
    RootKey := HKEY_CURRENT_USER;
    if OpenKey(INIT_KEY, True) then
    try
      if WindowState = wsNormal then
      begin
        Position := BoundsRect;
        WriteBinaryData(SPosition, Position, SizeOf(Position));
      end;
      WriteInteger(SWindowState, Ord(WindowState));
      WriteInteger(SResourceType, Ord(FResType));
      WriteBool(SShowToolBar, psToolBar.Visible);
      WriteBool(SShowResourceBar, ResourceBar.Visible);
      WriteBool(SShowStatusBar, StatusBar.Visible);
      WriteBool(SShowGridLines, actGridLines.Checked);
      WriteBool(SShowHotTrack, actHotTrack.Checked);
      WriteBool(SShowRowSelect, actRowSelect.Checked);
    finally
      CloseKey;
    end;
    Free;
  end;
  actStop.Execute;
  WSACleanup;
end;

procedure TMainForm.ListViewColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  FAscending := not FAscending;
  if (FSortCol <> -1) and (FSortCol <> Column.Index) then
  begin
    FAscending := True;
    ListView.Columns[FSortCol].ImageIndex := -1;
  end;
  if FAscending then
    Column.ImageIndex := 4
  else
    Column.ImageIndex := 5;
  FSortCol := Column.Index;
  ListView.CustomSort(nil, FSortCol - 1);
end;

procedure TMainForm.ListViewCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);

  function AlignIpAddress(const IpAddress: string): string;
  var
    P, Start: PChar;
    S: string;
  begin
    Result := '';
    P := PChar(IpAddress);
    while P^ <> #0 do
    begin
      Start := P;
      while not (P^ in [#0, '.']) do Inc(P);
      SetString(S, Start, P - Start);
      Result := Result + Format('%3s', [S]);
      if P^ <> #0 then
      begin
        Result := Result + '.';
        Inc(P);
      end;
    end;
  end;
  
var
  SortFlag: Integer;
begin
  if FAscending then SortFlag := 1  else SortFlag := -1;
  case Data of
    -1: Compare := SortFlag * AnsiCompareText(Item1.Caption, Item2.Caption);
 0,1,3: Compare := SortFlag * AnsiCompareText(Item1.SubItems[Data],
                                              Item2.SubItems[Data]);
     2: Compare := SortFlag * AnsiCompareText(AlignIpAddress(Item1.SubItems[Data]),
                                              AlignIpAddress(Item2.SubItems[Data]))
  end;
end;

procedure TMainForm.ListViewDblClick(Sender: TObject);
begin
  if actOpen.Enabled then actOpen.Execute;
end;

procedure TMainForm.ListViewKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then ListViewDblClick(Sender);
end;

procedure TMainForm.StatusBarResize(Sender: TObject);
const
  W = 150;
begin
  with Sender as TStatusBar do
  begin
    if ClientWidth >= Panels[2].Width + W then
    begin
      Panels[0].Width := ClientWidth - Panels[1].Width - Panels[2].Width;
      if Panels[1].Width <= W then Panels[1].Width := W;
    end
    else
    begin
      Panels[0].Width := 1;
      Panels[1].Width := ClientWidth - Panels[2].Width;
      if ClientWidth <= Panels[2].Width then Panels[1].Width := 0;
    end;
    with ProgressBar do
    begin
      Left := Panels[0].Width + 2;
      Width := Panels[1].Width - 2;
    end;
  end;
end;

procedure TMainForm.StatusBarDrawPanel(StatusBar: TStatusBar;
  Panel: TStatusPanel; const Rect: TRect);
begin
  with StatusBar do
    if Panel.Index = 0 then
    begin
      ImageList.Draw(Canvas, Rect.Left + 1, Rect.Top, 6);
      Canvas.TextOut(Rect.Left + 21, Rect.Top + 1, SUpdating);
    end
    else
    begin
      ImageList.Draw(Canvas, Rect.Left + 1, Rect.Top, 7);
      Canvas.TextOut(Rect.Left + 21, Rect.Top + 1, SLocalInet);
    end;
end;

procedure TMainForm.cboResourceKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then actGo.Execute;
end;

procedure TMainForm.cboResourceDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  OldRect: TRect;
  DrawingStyle: TDrawingStyle;
begin
  with Control as TComboBox do
  begin
    OldRect := Rect;
    if odFocused in State then
      DrawingStyle := dsSelected
    else
      DrawingStyle := dsNormal;
    ImageList.Draw(Canvas, Rect.Left, Rect.Top, Index, DrawingStyle, itImage);
    Rect.Right := Rect.Left + Canvas.TextWidth(Items[Index]) + 3;
    OffsetRect(Rect, ImageList.Width + 2, 0);
    Canvas.FillRect(Rect);
    Canvas.TextOut(Rect.Left + 1, Rect.Top + 2, Items[Index]);
    if odFocused in State then
    begin
      Canvas.DrawFocusRect(OldRect);
      Canvas.DrawFocusRect(Rect);
    end;
  end;
end;

procedure TMainForm.SplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
var
  i: Integer;
begin
  with CoolBar do
    if NewSize < Height then
    begin
      for i := Bands.Count - 1 downto 0 do
        if Bands[i].Break = True then
          if NewSize <= Height - Bands[i].Height then
          begin
            Bands[i].Break := False;
            Accept := True;
          end;
    end
    else
    begin
      for i := Bands.Count - 1 downto 0 do
        if (Bands[i].Break = False) and (not Bands[i].FixedSize) then
          if NewSize >= Height + Bands[i].Height then
          begin
            Bands[i].Break := True;
            Accept := True;
          end;
    end;
end;

procedure TMainForm.ResourceBarResize(Sender: TObject);
begin
  cboResource.Width := ResourceBar.Width - ResourceBar.ButtonWidth - 2;
end;

procedure TMainForm.actSaveExecute(Sender: TObject);
begin
  if FFileName = '' then
    actSaveAs.Execute
  else
    MkFile(FFileName, False);
end;

procedure TMainForm.actSaveAsExecute(Sender: TObject);
var
  FileExt: string;
begin
  Application.ProcessMessages;
  with TSaveDialog.Create(Self) do
  try
    Options := [ofHideReadOnly, ofEnableSizing, ofOverwritePrompt];
    if FFileName = '' then FileName := '*' + SDefExt
    else
      FileName := FFileName;
    Filter := SFilter;
    if Execute then
    begin
      FFileName := FileName;
      FileExt := ExtractFileExt(FFileName);
      if AnsiLowerCase(FileExt) <> SDefExt then
      begin
        Delete(FFileName, Pos('.', FFileName), Length(FileExt));
        FFileName := FFileName + SDefExt;
      end;
      MkFile(FFileName, True);
    end;
  finally
    Free;
  end;
end;

procedure TMainForm.actExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.actToolBarExecute(Sender: TObject);
begin
  psToolBar.Visible := not psToolBar.Visible;
end;

procedure TMainForm.actResourceBarExecute(Sender: TObject);
begin
  with CoolBar.Bands.FindBand(ResourceBar) do Visible := not Visible;
end;

procedure TMainForm.actStatusBarExecute(Sender: TObject);
begin
  StatusBar.Visible := not StatusBar.Visible;
end;

procedure TMainForm.actGoExecute(Sender: TObject);
var
  ResType: TResourceType;
  i: Integer;
begin
  actStop.Execute;
  Screen.Cursor := crAppStart;
  Animate.Active := True;
  StatusBar.Panels[0].Style := psOwnerDraw;
  ResType := TResourceType(cboResource.ItemIndex);
  with ListView do
  begin
    Items.BeginUpdate;
    Items.Clear;
    Items.EndUpdate;
    if (ResType <> FResType) or (Columns.Count = 0) then
    begin
      Columns.BeginUpdate;
      Columns.Clear;
      Columns.EndUpdate;
      for i := 0 to High(ColumnNames) do
      begin
        with Columns.Add do
        begin
          Caption := ColumnNames[i];
          Width := 110;
        end;
        if (ResType <> rtComputer) and (Columns.Count > 2) then
          Break;
      end;
      FAscending := False;
      FSortCol := -1;
    end;
  end;
  ChildThread := TChildThread.Create(ResType);
  ChildThread.OnTerminate := ThreadDone;
  FResType := ResType;
end;

procedure TMainForm.actStopExecute(Sender: TObject);
begin
  Application.ProcessMessages;
  if Assigned(ChildThread) then
    with ChildThread do
    begin
      Terminate;
      WaitFor;
      FreeAndNil(ChildThread);
    end;
end;

procedure TMainForm.actRefreshExecute(Sender: TObject);
begin
  actGo.Execute;
end;

procedure TMainForm.actFindExecute(Sender: TObject);
begin
  ShowFindDialog(Self);
end;

procedure TMainForm.actOpenExecute(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar(ListView.Selected.Caption), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.actPingExecute(Sender: TObject);
begin
  with ListView.Selected do
    ShowPingDialog(Self, Copy(Caption, 3, MaxInt), SubItems[2]);
end;

procedure TMainForm.actMessageExecute(Sender: TObject);
begin
  ShowMessageDialog(Self, Copy(ListView.Selected.Caption, 3, MaxInt));
end;

procedure TMainForm.actAboutExecute(Sender: TObject);
begin
  ShowAboutBox(Self);
end;

procedure TMainForm.actGridLinesExecute(Sender: TObject);
begin
  with ListView do
  begin
    GridLines := not GridLines;
    Invalidate;
  end;
end;

procedure TMainForm.actHotTrackExecute(Sender: TObject);
begin
  with ListView do
  begin
    HotTrack := not HotTrack;
    if HotTrack then
    begin
      OnDblClick := nil;
      OnClick := ListViewDblClick;
      HotTrackStyles := [htHandPoint, htUnderlineCold, htUnderlineHot];
    end
    else
    begin
      OnClick := nil;
      OnDblClick := ListViewDblClick;
      HotTrackStyles := [];
    end;
    Invalidate;
  end;
end;

procedure TMainForm.actRowSelectExecute(Sender: TObject);
begin
  with ListView do
  begin
    RowSelect := not RowSelect;
    Invalidate;
  end;
end;

procedure TMainForm.ActionListUpdate(Action: TBasicAction;
  var Handled: Boolean);
begin
  actSave.Enabled := not Animate.Active;
  actSaveAs.Enabled := actSave.Enabled;
  actToolBar.Checked := psToolBar.Visible;
  actResourceBar.Checked := ResourceBar.Visible;
  actStatusBar.Checked := StatusBar.Visible;
  with ListView do
  begin
    actFind.Enabled := Items.Count > 0;
    actMessage.Visible := Win32Platform = VER_PLATFORM_WIN32_NT;
    if Assigned(Selected) then
    begin
      actOpen.Enabled := Selected.ImageIndex in [0, 1];
      actPing.Enabled := Selected.ImageIndex = 0;
      actMessage.Enabled := actMessage.Visible and actPing.Enabled;
    end
    else
    begin
      actOpen.Enabled := False;
      actPing.Enabled := False;
      actMessage.Enabled := False;
    end;
    actGridLines.Checked := GridLines;
    actHotTrack.Checked := HotTrack;
    actRowSelect.Checked := RowSelect;
  end;
end;

procedure TMainForm.PopupMenuPopup(Sender: TObject);
begin
  actOpen.Update;
  piOpen.Visible := actOpen.Enabled;
  piPing.Visible := actPing.Enabled;
  piMessage.Visible := actMessage.Enabled;
  piGridLines.Visible := not Assigned(ListView.Selected);
  piHotTrack.Visible := piGridLines.Visible;
  piRowSelect.Visible := piGridLines.Visible;
end;

procedure TMainForm.ThreadDone(Sender: TObject);
begin
  with ChildThread do
    if Assigned(FatalException) then
      Application.ShowException(Exception(FatalException));
  ProgressBar.Position := 0;
  StatusBar.Panels[0].Style := psText;
  StatusBar.Panels[0].Text := Format(SStatusText, [ListView.Items.Count,
                                                   NetResNames[Ord(FResType)]]);
  if ChildThread.ReturnValue = 0 then
    sndPlaySound(PChar('JP'), SND_RESOURCE);
  Animate.Active := False;
  Screen.Cursor := crDefault;
end;

procedure TMainForm.MkFile(const FileName: string; CreationFlag: Boolean);
var
  F: TextFile;
  SaveCursor: TCursor;
  FmtStr: string;
  i: Integer;
begin
  AssignFile(F, FileName);
  if CreationFlag then Rewrite(F) else Reset(F);
  SaveCursor := Screen.Cursor;
  try
    Screen.Cursor := crAppStart;
    Append(F);
    Writeln(F, Format(#13#10'*** %s (%s) ***'#13#10, [NetResNames[Ord(FResType)],
                                                      FormatDateTime(ShortDateFormat +
                                                      ' ' + LongTimeFormat, Now)]));
    with ListView do
      if FResType = rtComputer then
      begin
        FmtStr := '%-17s %-15s %-48s %-15s %-17s';
        Writeln(F, Format(FmtStr, [Columns[0].Caption,
                                   Columns[1].Caption,
                                   Columns[2].Caption,
                                   Columns[3].Caption,
                                   Columns[4].Caption]));
        Writeln(F, Format('%s %s %s %s %s', ['=================',
                                             '===============',
                                             '================================================',
                                             '===============',
                                             '=================']));
        for i := 0 to Items.Count - 1 do
          Writeln(F, Format(FmtStr, [Items[i].Caption,
                                     Items[i].SubItems[0],
                                     Items[i].SubItems[1],
                                     Items[i].SubItems[2],
                                     Items[i].SubItems[3]]));
      end
      else
      begin
        FmtStr := '%-48s %-15s %-48s';
        Writeln(F, Format(FmtStr, [Columns[0].Caption,
                                   Columns[1].Caption,
                                   Columns[2].Caption]));
        Writeln(F, Format('%s %s %s', ['================================================',
                                       '===============',
                                       '================================================']));
        for i := 0 to Items.Count - 1 do
          Writeln(F, Format(FmtStr, [Items[i].Caption,
                                     Items[i].SubItems[0],
                                     Items[i].SubItems[1]]));
      end;
  finally
    CloseFile(F);
    Screen.Cursor := SaveCursor;
  end;
end;

end.
