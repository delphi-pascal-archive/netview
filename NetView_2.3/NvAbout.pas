unit NvAbout;

interface

uses
  Windows, Classes, Graphics, Forms, Controls, StdCtrls, ExtCtrls;

type
  TAboutBox = class(TForm)
    btnOk: TButton;
    imgProgram: TImage;
    lblVersion: TLabel;
    lblAuthor: TLabel;
    lblCopyright: TLabel;
    Bevel: TBevel;
    lblName: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

procedure ShowAboutBox(AOwner: TComponent);

var
  AboutBox: TAboutBox;

implementation

uses ShellAPI;

{$R *.dfm}

procedure ShowAboutBox(AOwner: TComponent);
begin
  with TAboutBox.Create(AOwner) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

procedure TAboutBox.FormCreate(Sender: TObject);
begin
  imgProgram.Picture.Icon.Handle := ExtractIcon(HInstance, PChar(Application.ExeName), 0);
end;

end.