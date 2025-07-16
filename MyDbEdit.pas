unit MyDbEdit;

interface

uses
  Winapi.Messages, Vcl.DBCtrls, Vcl.Controls, System.Classes;

type
  TMyDBEdit = class(TDBEdit)
  private
    FOnPaste: TNotifyEvent;
  protected
    procedure WMPaste(var Message: TMessage); message WM_PASTE;
published
    property Text;
    property DataSource;
    property DataField;
    property ReadOnly;
    property EditMask;

    property Field;
    property Font;
    property Color;

    property Anchors;
    property BiDiMode;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ImeMode;
    property ImeName;
    property MaxLength;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnChange;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
    property OnPaste: TNotifyEvent read FOnPaste write FOnPaste;
  end;

procedure Register;

implementation

{ TMyDBEdit }

procedure TMyDBEdit.WMPaste(var Message: TMessage);
begin
  // Chiamiamo la gestione predefinita del messaggio WM_PASTE
  inherited;

  // Se è stato assegnato un gestore per l'evento OnPaste, lo chiamiamo
  if Assigned(FOnPaste) then
    FOnPaste(Self);
end;

procedure Register;
begin
  RegisterComponents('Data Controls', [TMyDBEdit]);
end;

end.


end.

