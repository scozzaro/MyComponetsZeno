unit CustomStatusBarReg;

interface

uses
  System.SysUtils, System.Classes,
  DesignEditors, DesignIntf,
  Vcl.Controls, Vcl.ImgList,
  CustomStatusBar; // la tua unit con TMyCustomStatusBar e TMyCustomStatusBarPanel

type
  TImageIndexPropertyEditor = class(TIntegerProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

procedure Register;

implementation

{ TImageIndexPropertyEditor }

function TImageIndexPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList];
end;

procedure TImageIndexPropertyEditor.GetValues(Proc: TGetStrProc);
var
  Panel: TMyCustomStatusBarPanel;
  Comp: TMyCustomStatusBar;
  ImgList: TImageList;
  i: Integer;
begin
  if GetComponent(0) is TMyCustomStatusBarPanel then
  begin
    Panel := TMyCustomStatusBarPanel(GetComponent(0));
    if Assigned(Panel.Collection) and (Panel.Collection.Owner is TMyCustomStatusBar) then
    begin
      Comp := TMyCustomStatusBar(Panel.Collection.Owner);
      ImgList := Comp.Images;
      if Assigned(ImgList) then
      begin
        Proc('-1'); // valore speciale per "nessuna immagine"
        for i := 0 to ImgList.Count - 1 do
          Proc(IntToStr(i));
      end;
    end;
  end;
end;

procedure Register;
begin
  RegisterPropertyEditor(TypeInfo(Integer), TMyCustomStatusBarPanel, 'ImageIndex', TImageIndexPropertyEditor);
end;

end.

