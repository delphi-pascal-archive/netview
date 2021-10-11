unit NvFind;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, Dialogs, StdCtrls,
  ComCtrls;

type
  TFindDialog = class(TForm)
    PageControl: TPageControl;
    Page1: TTabSheet;
    cboName: TComboBox;
    btnOk: TButton;
    btnCancel: TButton;
    lblNamed: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
  private
    { Private declarations }
    FMRUList: string;
  public
    { Public declarations }
  end;

procedure ShowFindDialog(AOwner: TComponent);

var
  FindDialog: TFindDialog;

implementation

uses NvMain, NvConst;

{$R *.dfm}

const
  A: array[0..9] of Char = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j');

procedure ShowFindDialog(AOwner: TComponent);
begin
  with TFindDialog.Create(AOwner) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

procedure TFindDialog.FormCreate(Sender: TObject);
var
  s: string;
  i: Integer;
begin
  with MainForm.Registry do
  begin
    OpenKey(INIT_KEY + MRU_KEY, True);
    if ValueExists(SMRUList) then
    begin
      FMRUList := ReadString(SMRUList);
      s := FMRUList;
      for i := 1 to Length(FMRUList) do
        if ValueExists(FMRUList[i]) then
          cboName.Items.Add(ReadString(FMRUList[i]))
        else
          Delete(s, Pos(FMRUList[i], s), 1);
      FMRUList := s;
    end;
  end;
end;

procedure TFindDialog.FormDestroy(Sender: TObject);
begin
  with MainForm.Registry do
  begin
    WriteString(SMRUList, FMRUList);
    CloseKey;
  end;
end;

procedure TFindDialog.btnOkClick(Sender: TObject);
var
  FindItem: TListItem;
  i: Integer;
begin
  Hide;
  with MainForm do
    with ListView, Registry do
    begin
      FindItem := FindCaption(0, AnsiUpperCase(cboName.Text), False, True, True);
      if Assigned(FindItem) then
      begin
        SetFocus;
        ItemFocused := FindItem;
        Selected := FindItem;
        FindItem.MakeVisible(True);
      end
      else
        Application.MessageBox(PChar(Format(SResNotFound, [cboName.Text])),
                               PChar(Application.Title),
                               MB_OK or MB_ICONINFORMATION);
      if Trim(cboName.Text) = '' then Exit;
      for i := 0 to cboName.Items.Count - 1 do
        if AnsiLowerCase(cboName.Items[i]) = AnsiLowerCase(cboName.Text) then
        begin
          cboName.ItemIndex := i;
          Break;
        end;
      if cboName.ItemIndex = -1 then
      begin
        if cboName.Items.Count < 10 then
        begin
          for i := 0 to High(A) do if Pos(A[i], FMRUList) = 0 then Break;
          Insert(A[i], FMRUList, 1);
          WriteString(A[i], cboName.Text);
        end
        else
        begin
          Insert(FMRUList[Length(FMRUList)], FMRUList, 1);
          Delete(FMRUList, Length(FMRUList), 1);
          WriteString(FMRUList[1], cboName.Text);
        end;
      end
      else
      begin
        Insert(Copy(FMRUList, cboName.ItemIndex + 1, 1), FMRUList, 1);
        Delete(FMRUList, cboName.ItemIndex + 2, 1);
      end;
    end;
end;

end.