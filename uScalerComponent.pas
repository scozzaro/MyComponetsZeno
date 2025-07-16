unit uScalerComponent;

interface

uses
  TypInfo, System.Generics.Collections, Math, gaeDBGrid, DBCtrls, Vcl.ComCtrls,
  CustomStatusBar, Vcl.Grids,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms;

type
  TControlOriginalProps = record
    Control: TControl;
    OriginalLeft: Integer;
    OriginalTop: Integer;
    OriginalWidth: Integer;
    OriginalHeight: Integer;
    OriginalFontHeight: Integer;
    OriginalDBGridColumnWidths: array of Integer;
    OriginalDbGridTitleFontHeights: array of Integer;
    OriginalStatusBarProPanelFontHeights: array of Integer;
    OriginalStatusBarProPanelWidths: array of Integer;
    OriginalDBComboBoxDropDownWidth: Integer;

    // Queste proprietà sono specifiche per Vcl.ComCtrls.TStatusBar
    OriginalStatusBarPanelsFontHeights: array of Integer; // Renamed for clarity
    OriginalStatusBarPanelsWidths: array of Integer; // Renamed for clarity

    // Nuove proprietà per TMyCustomStatusBar (la tua CustomStatusBar)
    OriginalMyCustomStatusBarPanelFontHeights: array of Integer;
    OriginalMyCustomStatusBarPanelWidths: array of Integer;

    // NUOVA PROPRIETÀ PER TStringGrid
    OriginalStringGridColumnWidths: array of Integer;

  end;

  TScalerComponent = class(TComponent)
  private
    FOriginalFormWidth: Integer;
    FOriginalFormHeight: Integer;
    FControlProps: TList<TControlOriginalProps>;
    FZoomScales: Double;
    FOriginalOnShow: TNotifyEvent;

    FInitialized: Boolean;
    // Nuovo flag per indicare se le proprietà sono state salvate

    procedure InternalFormOnShow(Sender: TObject);
    procedure SetZoomScales(const Value: Double);
    function GetZoomScales: Double;
    procedure FormOwnerOnShow(Sender: TObject);
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SaveOriginalFormSize(Form: TForm);
    procedure StoreOriginalControlProperties(ParentControl: TWinControl);
    procedure ScaleControls(ParentControl: TWinControl; ScaleFactor: Double);
    procedure ApplyScale(ParentForm: TForm);
    procedure InitializeScale(Form: TForm);
    // Nuovo metodo per l'inizializzazione

  published
    property ZoomScales: Double read GetZoomScales write SetZoomScales;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TScalerComponent]);
end;

{ TScalerComponent }

// Nuovo metodo per l'inizializzazione della scalatura
procedure TScalerComponent.InitializeScale(Form: TForm);
begin
  if not FInitialized then
  begin
    SaveOriginalFormSize(Form);
    StoreOriginalControlProperties(Form);
    ApplyScale(Form);
    FInitialized := True; // Imposta il flag a True dopo l'inizializzazione
  end;
end;

procedure TScalerComponent.InternalFormOnShow(Sender: TObject);
var
  Form: TForm;
begin
  Form := Sender as TForm;

  // Chiama l'handler OnShow originale del form utente PRIMA di fare la nostra scalatura.
  // Questo permette all'utente di impostare ZoomScales o altre proprietà prima del calcolo iniziale.
  if Assigned(FOriginalOnShow) then
  begin
    FOriginalOnShow(Sender);
    // IMPORTANTE: Resetta FOriginalOnShow a nil dopo la prima esecuzione per evitare doppie chiamate.
    // L'evento OnShow del form è un "one-shot" per l'inizializzazione.
    FOriginalOnShow := nil;
  end;

  // Inizializza la scalatura solo una volta
  if not FInitialized then
    InitializeScale(Form);
end;

constructor TScalerComponent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FControlProps := TList<TControlOriginalProps>.Create;
  FZoomScales := 1.0;
  FInitialized := False; // Inizializza il flag a False
end;

destructor TScalerComponent.Destroy;
begin
  FControlProps.Free;
  inherited Destroy;
end;

procedure TScalerComponent.Loaded;
begin
  inherited Loaded;

  if (Owner is TForm) and not(csDesigning in ComponentState) then
  begin
    with TForm(Owner) do
    begin
      if Assigned(OnShow) then
      begin
        if not Assigned(FOriginalOnShow) then
          FOriginalOnShow := OnShow;
      end;

      OnShow := InternalFormOnShow;
    end;
  end;
end;

procedure TScalerComponent.FormOwnerOnShow(Sender: TObject);
var
  Form: TForm;
begin
  Form := Sender as TForm;

  // Questa riga chiama l'OnShow originale del form.
  // Se l'utente imposta ZoomScales qui, il setter di ZoomScales
  // attiverà la scalatura.
  if Assigned(FOriginalOnShow) then
    FOriginalOnShow(Sender);

  // Questo blocco esegue la scalatura una seconda volta (o la prima se ZoomScales
  // non è stata impostata nel FOriginalOnShow)
  if FControlProps.Count = 0 then
  begin
    SaveOriginalFormSize(Form);
    StoreOriginalControlProperties(Form);
    ApplyScale(Form);
    // <--- Questa è la seconda chiamata o la prima "problematic"
  end;
end;

procedure TScalerComponent.SetZoomScales(const Value: Double);
begin
  if Value <= 0 then
    raise Exception.Create('ZoomScales must be greater than 0');

  if FZoomScales <> Value then
  begin
    FZoomScales := Value;

    if (csDesigning in ComponentState) then
      Exit; // Non applicare in design-time

    // Se il form è già stato inizializzato e l'handle è valido, applica la scala
    // Questo gestisce i cambiamenti di ZoomScales A RUNTME DOPO LA PRIMA INIZIALIZZAZIONE.
    if FInitialized and (Owner is TForm) and TForm(Owner).HandleAllocated then
    begin
      // Usa TThread.Queue per assicurarti che l'aggiornamento dell'UI avvenga nel thread principale
      TThread.Queue(nil,
        procedure
        begin
          if (Owner is TForm) and TForm(Owner).HandleAllocated then
            ApplyScale(TForm(Owner));
        end);
    end;
  end;
end;

function TScalerComponent.GetZoomScales: Double;
begin
  Result := FZoomScales;
end;

procedure TScalerComponent.SaveOriginalFormSize(Form: TForm);
begin
  FOriginalFormWidth := Form.Width;
  FOriginalFormHeight := Form.Height;
end;

procedure TScalerComponent.StoreOriginalControlProperties
  (ParentControl: TWinControl);
var
  I, J, idx: Integer;
  ControlProp: TControlOriginalProps;
  Control: TControl;
  FontPropInfo: PPropInfo;
  FontObj: TObject;
  DBGrid: TgaeDBGrid;
  DBComboBox: TDBComboBox;
  MyCustomStatusBar: TMyCustomStatusBar; // La tua CustomStatusBar
  StatusBar: TStatusBar;
  StringGrid: TStringGrid; // DICHIARAZIONE AGGIUNTA

begin
  for I := 0 to ParentControl.ControlCount - 1 do
  begin
    Control := ParentControl.Controls[I];
    FillChar(ControlProp, SizeOf(ControlProp), 0);

    ControlProp.Control := Control;
    ControlProp.OriginalLeft := Control.Left;
    ControlProp.OriginalTop := Control.Top;
    ControlProp.OriginalWidth := Control.Width;
    ControlProp.OriginalHeight := Control.Height;
    ControlProp.OriginalFontHeight := 0;
    SetLength(ControlProp.OriginalDBGridColumnWidths, 0);
    SetLength(ControlProp.OriginalDbGridTitleFontHeights, 0);
    SetLength(ControlProp.OriginalStatusBarProPanelFontHeights, 0);
    SetLength(ControlProp.OriginalStatusBarProPanelWidths, 0);
    ControlProp.OriginalDBComboBoxDropDownWidth := 0;

    FontPropInfo := GetPropInfo(Control.ClassInfo, 'Font');
    if Assigned(FontPropInfo) and (FontPropInfo^.PropType^^.Kind = tkClass) then
    begin
      FontObj := GetObjectProp(Control, FontPropInfo);
      if FontObj is TFont then
        ControlProp.OriginalFontHeight := TFont(FontObj).Height;
    end;

    // Handling VCL TStatusBar
    if Control is TStatusBar then
    begin
      StatusBar := TStatusBar(Control);
      SetLength(ControlProp.OriginalStatusBarPanelsFontHeights,
        StatusBar.Panels.Count);
      SetLength(ControlProp.OriginalStatusBarPanelsWidths,
        StatusBar.Panels.Count);
      for idx := 0 to StatusBar.Panels.Count - 1 do
      begin
        // TStatusBar panels font is usually the StatusBar's own font
        ControlProp.OriginalStatusBarPanelsFontHeights[idx] :=
          StatusBar.Font.Height;
        ControlProp.OriginalStatusBarPanelsWidths[idx] :=
          StatusBar.Panels[idx].Width;
      end;
    end;

    if Control is TMyCustomStatusBar then
    // Check if it's your custom status bar
    begin
      MyCustomStatusBar := TMyCustomStatusBar(Control);
      SetLength(ControlProp.OriginalMyCustomStatusBarPanelFontHeights,
        MyCustomStatusBar.Panels.Count);
      SetLength(ControlProp.OriginalMyCustomStatusBarPanelWidths,
        MyCustomStatusBar.Panels.Count);
      for idx := 0 to MyCustomStatusBar.Panels.Count - 1 do
      begin
        // Store font height and width for each panel of your custom status bar
        ControlProp.OriginalMyCustomStatusBarPanelFontHeights[idx] :=
          MyCustomStatusBar.Panels[idx].Font.Height;
        ControlProp.OriginalMyCustomStatusBarPanelWidths[idx] :=
          MyCustomStatusBar.Panels[idx].Width;
      end;
    end;

    // NUOVA SEZIONE PER TStringGrid
    if Control is TStringGrid then
    begin
      StringGrid := TStringGrid(Control);
      SetLength(ControlProp.OriginalStringGridColumnWidths,
        StringGrid.ColCount);
      for J := 0 to StringGrid.ColCount - 1 do
        ControlProp.OriginalStringGridColumnWidths[J] :=
          StringGrid.ColWidths[J];
    end;

    if Control is TgaeDBGrid then
    begin
      DBGrid := TgaeDBGrid(Control);
      SetLength(ControlProp.OriginalDBGridColumnWidths, DBGrid.Columns.Count);
      for J := 0 to DBGrid.Columns.Count - 1 do
        ControlProp.OriginalDBGridColumnWidths[J] := DBGrid.Columns[J].Width;

      SetLength(ControlProp.OriginalDbGridTitleFontHeights,
        DBGrid.Columns.Count);
      for J := 0 to DBGrid.Columns.Count - 1 do
        ControlProp.OriginalDbGridTitleFontHeights[J] :=
          DBGrid.Columns[J].Title.Font.Height;
    end;

    if Control is TDBComboBox then
    begin
      DBComboBox := TDBComboBox(Control);
      ControlProp.OriginalDBComboBoxDropDownWidth := DBComboBox.DropDownWidth;
    end;

    FControlProps.Add(ControlProp);

    if Control is TWinControl then
      StoreOriginalControlProperties(TWinControl(Control));
  end;
end;

procedure TScalerComponent.ScaleControls(ParentControl: TWinControl;
ScaleFactor: Double);
var
  ControlProp: TControlOriginalProps;
  FontPropInfo: PPropInfo;
  FontObj: TObject;
  DBGrid: TgaeDBGrid;
  DBComboBox: TDBComboBox;
  J, OrigFontSize, NewFontHeight, idx: Integer;
  StatusBar: TStatusBar;
  MyCustomStatusBar: TMyCustomStatusBar; // La tua CustomStatusBar
  StringGrid: TStringGrid; // DICHIARAZIONE AGGIUNTA

begin
  if ParentControl is TForm then
  begin
    TForm(ParentControl).Width := Round(FOriginalFormWidth * ScaleFactor);
    TForm(ParentControl).Height := Round(FOriginalFormHeight * ScaleFactor);
  end;

  for ControlProp in FControlProps do
  begin
    with ControlProp do
    begin
      Control.Left := Round(OriginalLeft * ScaleFactor);
      Control.Top := Round(OriginalTop * ScaleFactor);
      Control.Width := Round(OriginalWidth * ScaleFactor);
      Control.Height := Round(OriginalHeight * ScaleFactor);

      if OriginalFontHeight <> 0 then
      begin
        FontPropInfo := GetPropInfo(Control.ClassInfo, 'Font');
        if Assigned(FontPropInfo) and (FontPropInfo^.PropType^^.Kind = tkClass)
        then
        begin
          try
            FontObj := GetObjectProp(Control, FontPropInfo);
            if FontObj is TFont then
            begin
              OrigFontSize := -MulDiv(OriginalFontHeight, 72,
                Screen.PixelsPerInch);
              OrigFontSize := Max(1, Round(OrigFontSize * ScaleFactor));
              NewFontHeight := -MulDiv(OrigFontSize, Screen.PixelsPerInch, 72);
              TFont(FontObj).Height := NewFontHeight;
            end;
          except
          end;
        end;
      end;

      // Scaling for VCL TStatusBar panels
      if Control is TStatusBar then
      begin
        StatusBar := TStatusBar(Control);
        for idx := 0 to StatusBar.Panels.Count - 1 do
        begin
          // Scale panel width
          if idx < Length(OriginalStatusBarPanelsWidths) then
            StatusBar.Panels[idx].Width :=
              Round(OriginalStatusBarPanelsWidths[idx] * ScaleFactor);

          // Scale StatusBar's overall font (which affects panels)
          if idx < Length(OriginalStatusBarPanelsFontHeights) then
          // Check array bounds
          begin
            OrigFontSize := -MulDiv(OriginalStatusBarPanelsFontHeights[idx], 72,
              Screen.PixelsPerInch);
            OrigFontSize := Max(1, Round(OrigFontSize * ScaleFactor));
            NewFontHeight := -MulDiv(OrigFontSize, Screen.PixelsPerInch, 72);
            StatusBar.Font.Height := NewFontHeight;
            // Apply to the StatusBar's main font
          end;
        end;
      end;

      // Scaling for your CustomStatusBar (TMyCustomStatusBar) panels and their fonts
      if Control is TMyCustomStatusBar then
      begin
        MyCustomStatusBar := TMyCustomStatusBar(Control);
        for idx := 0 to MyCustomStatusBar.Panels.Count - 1 do
        begin
          // Scale panel width
          if idx < Length(OriginalMyCustomStatusBarPanelWidths) then
            MyCustomStatusBar.Panels[idx].Width :=
              Round(OriginalMyCustomStatusBarPanelWidths[idx] * ScaleFactor);

          // Scale panel font individually
          if idx < Length(OriginalMyCustomStatusBarPanelFontHeights) then
          begin
            OrigFontSize := -MulDiv(OriginalMyCustomStatusBarPanelFontHeights
              [idx], 72, Screen.PixelsPerInch);
            OrigFontSize := Max(1, Round(OrigFontSize * ScaleFactor));
            NewFontHeight := -MulDiv(OrigFontSize, Screen.PixelsPerInch, 72);
            MyCustomStatusBar.Panels[idx].Font.Height := NewFontHeight;
          end;
        end;
      end;

      // NUOVA SEZIONE PER TStringGrid
      if Control is TStringGrid then
      begin
        StringGrid := TStringGrid(Control);
        if Length(ControlProp.OriginalStringGridColumnWidths) = StringGrid.ColCount
        then
        begin
          for J := 0 to StringGrid.ColCount - 1 do
          begin
            StringGrid.ColWidths[J] :=
              Round(ControlProp.OriginalStringGridColumnWidths[J] *
              ScaleFactor);
          end;
        end;
      end;

      if Control is TgaeDBGrid then
      begin
        DBGrid := TgaeDBGrid(Control);
        for J := 0 to DBGrid.Columns.Count - 1 do
        begin
          DBGrid.Columns[J].Width :=
            Round(OriginalDBGridColumnWidths[J] * ScaleFactor);
          DBGrid.Columns[J].Title.Font.Height :=
            Round(OriginalDbGridTitleFontHeights[J] * ScaleFactor);
        end;
      end;

      if Control is TDBComboBox then
      begin
        DBComboBox := TDBComboBox(Control);
        DBComboBox.DropDownWidth :=
          Round(OriginalDBComboBoxDropDownWidth * ScaleFactor);
      end;
    end;
  end;
end;

procedure TScalerComponent.ApplyScale(ParentForm: TForm);
begin
  ScaleControls(ParentForm, FZoomScales);
end;

end.
