unit CustomStatusBar;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.ComCtrls;


  const
  szCompName        = 'TMyCustomStatusBar';
  szVersion         = 'MyCustomStatusBar v. 2.0 by Enzo Scozzaro';


type
  // Enumerazione per l'allineamento del testo nei pannelli
  TStatusPanelAlignment = (taLeftJustify, taRightJustify, taCenter);

  // Enumerazione per lo stile del bordo smussato dei pannelli
  TBevelCut = (bvNone, bvLowered, bvRaised);

  // Tipo di evento per il click sul componente principale TMyCustomStatusBar
  // Passa l'indice del pannello cliccato
  TPanelClickEvent = procedure(Sender: TObject; PanelIndex: Integer) of object;

  // Dichiarazione della classe TMyCustomStatusBarPanel, che rappresenta un singolo pannello
  TMyCustomStatusBarPanel = class(TCollectionItem)
  private
    FText: string;
    FWidth: Integer;
    FPanelAlignment: TStatusPanelAlignment; // *** MODIFICATO: Rinominato da FAlignment a FPanelAlignment ***
    FFont: TFont;
    FBevelOuter: TBevelCut;
    FTag: TObject;
    FOnClick: TNotifyEvent;          // Evento OnClick specifico per questo pannello
    FImageIndex: Integer;            // Indice dell'immagine nella ImageList
    FBackgroundColor: TColor;      // Colore di sfondo del pannello
    procedure SetText(const Value: string);
    procedure SetWidth(const Value: Integer);
    procedure SetPanelAlignment(const Value: TStatusPanelAlignment); // *** MODIFICATO: Rinominato da SetAlignment a SetPanelAlignment ***
    procedure SetFont(const Value: TFont);
    procedure SetBevelOuter(const Value: TBevelCut);
    procedure FontChanged(Sender: TObject);
    procedure SetImageIndex(const Value: Integer);
    procedure SetBackgroundColor(const Value: TColor);
  protected
    procedure Changed;               // Metodo chiamato quando una proprietà del pannello cambia
    procedure DoClick;               // Metodo per scatenare l'evento OnClick del pannello
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
  published
    property Text: string read FText write SetText;
    property Width: Integer read FWidth write SetWidth;
    property PanelAlignment: TStatusPanelAlignment read FPanelAlignment write SetPanelAlignment; // *** MODIFICATO: Rinominato da Alignment a PanelAlignment ***
    property Font: TFont read FFont write SetFont;
    property BevelOuter: TBevelCut read FBevelOuter write SetBevelOuter default bvNone;
    property Tag: TObject read FTag write FTag;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor default clBtnFace;
  end;

  // Dichiarazione della classe TMyCustomStatusBarPanels, la collezione di pannelli
  TMyCustomStatusBarPanels = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TMyCustomStatusBarPanel;
    procedure SetItem(Index: Integer; const Value: TMyCustomStatusBarPanel);
  protected
    procedure Update(Item: TCollectionItem); override; // Chiamato quando un item nella collezione cambia
    procedure InvalidateOwner; // Invalida il proprietario (StatusBar) per il ridisegno
  public
    constructor Create(AOwner: TPersistent);
    property Items[Index: Integer]: TMyCustomStatusBarPanel read GetItem write SetItem; default;
  end;

  // Dichiarazione della classe TMyCustomStatusBar, il componente principale
  TMyCustomStatusBar = class(TCustomControl)
  private
    FPanels: TMyCustomStatusBarPanels;
    FOnPanelClick: TPanelClickEvent; // Evento di click generale per la StatusBar
    FImages: TImageList;             // Collezione di immagini per i pannelli
    FSizeGrip: Boolean;              // Nuova proprietà: abilita/disabilita la size grip
    FColor: TColor;                  // Colore di sfondo della StatusBar principale
    FAbout:         string;
    procedure SetPanels(const Value: TMyCustomStatusBarPanels);
    procedure SetImages(const Value: TImageList);
    procedure SetSizeGrip(const Value: Boolean);
    procedure SetColor(const Value: TColor);
  protected
    procedure Paint; override;     // Metodo di disegno del componente
    procedure Resize; override;    // Metodo chiamato al ridimensionamento
    procedure         SetAbout(Value: string); virtual;
    procedure DoPanelClick(Panel: TMyCustomStatusBarPanel; PanelIndex: Integer); // Metodo per scatenare entrambi gli eventi di click
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override; // Gestione del click del mouse
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Align default alBottom; // Questa è la proprietà Align del componente StatusBar stesso
    property Panels: TMyCustomStatusBarPanels read FPanels write SetPanels;
    property OnPanelClick: TPanelClickEvent read FOnPanelClick write FOnPanelClick;
    property Images: TImageList read FImages write SetImages;
    property SizeGrip: Boolean read FSizeGrip write SetSizeGrip default True; // Proprietà pubblica con default True
    property Color: TColor read FColor write SetColor default clBtnFace; // Proprietà pubblica per il colore della barra
    property          About: string read FAbout write SetAbout;
  end;

// Procedura per registrare il componente nella palette di Delphi
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TMyCustomStatusBar]);
end;

{ TMyCustomStatusBarPanel }




constructor TMyCustomStatusBarPanel.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FWidth := 100;
  FFont := TFont.Create;
  FFont.OnChange := FontChanged;
  FPanelAlignment := taLeftJustify; // *** MODIFICATO ***
  FText := '';
  FBevelOuter := bvLowered;

  FTag := nil;
  FOnClick := nil;
  FImageIndex := -1;
  FBackgroundColor := clBtnFace; // Inizializza il colore di sfondo di default
end;

destructor TMyCustomStatusBarPanel.Destroy;
begin
  FFont.Free;
  inherited;
end;

procedure TMyCustomStatusBarPanel.Changed;
begin
  if Collection is TMyCustomStatusBarPanels then
    TMyCustomStatusBarPanels(Collection).InvalidateOwner;
end;

procedure TMyCustomStatusBarPanel.FontChanged(Sender: TObject);
begin
  Changed;
end;

procedure TMyCustomStatusBarPanel.DoClick;
begin
  if Assigned(FOnClick) then
    FOnClick(Self);
end;

procedure TMyCustomStatusBarPanel.SetPanelAlignment(const Value: TStatusPanelAlignment); // *** MODIFICATO ***
begin
  if FPanelAlignment <> Value then // *** MODIFICATO ***
  begin
    FPanelAlignment := Value; // *** MODIFICATO ***
    Changed;
  end;
end;

procedure TMyCustomStatusBarPanel.SetBevelOuter(const Value: TBevelCut);
begin
  if FBevelOuter <> Value then
  begin
    FBevelOuter := Value;
    Changed;
  end;
end;

procedure TMyCustomStatusBarPanel.SetFont(const Value: TFont);
begin
  FFont.Assign(Value);
end;

procedure TMyCustomStatusBarPanel.SetImageIndex(const Value: Integer);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Changed;
  end;
end;

procedure TMyCustomStatusBarPanel.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    Changed;
  end;
end;

procedure TMyCustomStatusBarPanel.SetWidth(const Value: Integer);
begin
  if FWidth <> Value then
  begin
    FWidth := Value;
    Changed;
  end;
end;

procedure TMyCustomStatusBarPanel.SetBackgroundColor(const Value: TColor);
begin
  if FBackgroundColor <> Value then
  begin
    FBackgroundColor := Value;
    Changed; // Forza il ridisegno del pannello quando il colore cambia
  end;
end;


{ TMyCustomStatusBarPanels }

constructor TMyCustomStatusBarPanels.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TMyCustomStatusBarPanel);
end;

function TMyCustomStatusBarPanels.GetItem(Index: Integer): TMyCustomStatusBarPanel;
begin
  Result := TMyCustomStatusBarPanel(inherited GetItem(Index));
end;

procedure TMyCustomStatusBarPanels.SetItem(Index: Integer; const Value: TMyCustomStatusBarPanel);
begin
  inherited SetItem(Index, Value);
end;

procedure TMyCustomStatusBarPanels.Update(Item: TCollectionItem);
begin
  inherited;
  InvalidateOwner;
end;

procedure TMyCustomStatusBarPanels.InvalidateOwner;
begin
  if Owner is TMyCustomStatusBar then
    TMyCustomStatusBar(Owner).Invalidate;
end;

{ TMyCustomStatusBar }

procedure TMyCustomStatusBar.SetAbout(Value: string);
begin
  // do nothing!

end;





constructor TMyCustomStatusBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alBottom; // Questo si riferisce all'Align del componente StatusBar sul Form
  Height := 22;
  AutoSize := False;
  FPanels := TMyCustomStatusBarPanels.Create(Self);
  ControlStyle := ControlStyle + [csOpaque];
  FOnPanelClick := nil;
  FImages := nil;
  FSizeGrip := True; // Default true
    FAbout         :=  szVersion;
  FColor := clBtnFace; // Inizializza il colore di sfondo della barra di default
end;

destructor TMyCustomStatusBar.Destroy;
begin
  FPanels.Free;
  inherited;
end;

procedure TMyCustomStatusBar.SetPanels(const Value: TMyCustomStatusBarPanels);
begin
  FPanels.Assign(Value);
end;

procedure TMyCustomStatusBar.SetImages(const Value: TImageList);
begin
  FImages := Value;
  Invalidate;
end;

procedure TMyCustomStatusBar.SetSizeGrip(const Value: Boolean);
begin
  if FSizeGrip <> Value then
  begin
    FSizeGrip := Value;
    Invalidate;  // Ridisegna per mostrare/nascondere la grip
  end;
end;

procedure TMyCustomStatusBar.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Invalidate; // Forza il ridisegno della StatusBar quando il colore cambia
  end;
end;


procedure TMyCustomStatusBar.Paint;
var
  i, x, ImgLeft, ImgTop, TargetSize :Integer;
  R, ImageRect, TextRect: TRect;
  Panel: TMyCustomStatusBarPanel;
  Flags: Cardinal;
  GripSize: Integer;
  StretchWidth: Integer;
  EffectivePanelColor: TColor;

  // Variabili per i cerchi della grip
// Variabili per i cerchi della grip
  CircleSize: Integer;
  CircleColor: TColor;
  Cx, Cy: Integer; // Coordinate centrali del cerchio
  Spacing: Integer;
  Step: Integer;
  row_idx: Integer; // Indice della riga
  col_idx: Integer; // Indice della colonna
begin
  // Riempi lo sfondo generale della status bar con il colore specificato o clBtnFace
  if Self.Color = clNone then
    Canvas.Brush.Color := clBtnFace
  else
    Canvas.Brush.Color := Self.Color;
  Canvas.FillRect(ClientRect);

  x := 0;
  GripSize := 16; // dimensione standard della size grip (es. 16x16 pixel)

  for i := 0 to FPanels.Count - 1 do
  begin
    Panel := FPanels[i];

    if i = FPanels.Count - 1 then
    begin
      // Ultimo pannello si estende fino al bordo destro dell'area client, ignorando la grip
      StretchWidth := ClientWidth - x;
      if StretchWidth < 0 then
        StretchWidth := 0;
      R := Rect(x, 0, x + StretchWidth, Height);
    end
    else
      R := Rect(x, 0, x + Panel.Width, Height);

    // Determina il colore effettivo del pannello
    if Panel.BackgroundColor = clNone then
    begin
      // Se il pannello ha clNone, usa il colore della StatusBar principale
      if Self.Color = clNone then
        EffectivePanelColor := clBtnFace // Se anche la barra è clNone, usa clBtnFace come fallback finale
      else
        EffectivePanelColor := Self.Color; // Altrimenti usa il colore della barra
    end
    else
      EffectivePanelColor := Panel.BackgroundColor; // Altrimenti usa il colore specifico del pannello

    Canvas.Brush.Color := EffectivePanelColor;
    Canvas.FillRect(R);

    // Disegna bordo
    case Panel.BevelOuter of
      bvLowered: DrawEdge(Canvas.Handle, R, BDR_SUNKENOUTER, BF_RECT);
      bvRaised:  DrawEdge(Canvas.Handle, R, BDR_RAISEDOUTER, BF_RECT);
    end;

    // Immagine se presente
    if Assigned(FImages) and (Panel.ImageIndex >= 0) and (Panel.ImageIndex < FImages.Count) then
    begin
      var ImgBmp := TBitmap.Create;
      try
        ImgBmp.PixelFormat := pf32bit;
        FImages.GetBitmap(Panel.ImageIndex, ImgBmp);

        // Riduci dimensione immagine e margini per distanziarla
        TargetSize := Height - 2;
        if TargetSize > 19 then
          TargetSize := R.Bottom - R.Top - 4;

        var ScaledBmp := TBitmap.Create;
        try
          ScaledBmp.PixelFormat := pf32bit;
          ScaledBmp.SetSize(TargetSize, TargetSize);
          ScaledBmp.Canvas.StretchDraw(Rect(0, 0, TargetSize, TargetSize), ImgBmp);

          ImgLeft := R.Left + 4; // margine interno sinistro più grande
          ImgTop := R.Top + 2;   // margine interno superiore per far sembrare dentro

          Canvas.Draw(ImgLeft, ImgTop, ScaledBmp);

          TextRect := Rect(ImgLeft + TargetSize + 6, R.Top, R.Right - 4, R.Bottom);
        finally
          ScaledBmp.Free;
        end;
      finally
        ImgBmp.Free;
      end;
    end
    else
    begin
      TextRect := Rect(R.Left + 4, R.Top, R.Right - 4, R.Bottom);
    end;

    Canvas.Font := Panel.Font;
    case Panel.PanelAlignment of
      taLeftJustify:  Flags := DT_LEFT or DT_VCENTER or DT_SINGLELINE;
      taRightJustify: Flags := DT_RIGHT or DT_VCENTER or DT_SINGLELINE;
      taCenter:       Flags := DT_CENTER or DT_VCENTER or DT_SINGLELINE;
    else
      Flags := DT_LEFT or DT_VCENTER or DT_SINGLELINE;
    end;

    DrawText(Canvas.Handle, PChar(Panel.Text), Length(Panel.Text), TextRect, Flags);

    x := R.Right;
  end;

  // *** Disegna la grip con piccoli cerchi a forma di triangolo ***
if FSizeGrip then
  begin
    R := Rect(Width - GripSize, Height - GripSize, Width, Height); // Area della grip
    CircleSize := 2; // *** NUOVA DIMENSIONE: Diametro dei cerchi impostato a 2 pixel ***
    CircleColor := clGray; // Colore dei cerchi
    Spacing := 1; // *** NUOVO SPAZIO: Spazio tra i cerchi impostato a 1 pixel ***
    Step := CircleSize + Spacing; // Passo per spostarsi tra i centri dei cerchi (2+1 = 3 pixel)

    Canvas.Pen.Color := CircleColor;
    Canvas.Brush.Color := CircleColor; // Riempi i cerchi con lo stesso colore del bordo

    // Definiamo un margine dal bordo della grip per il posizionamento del primo cerchio.
    var Start_X_Offset := (GripSize mod Step) div 2; // Offset per centrare i cerchi
    var Start_Y_Offset := (GripSize mod Step) div 2;

    // Punto di partenza per il cerchio più in basso a destra
    var Initial_Cx := R.Right - (CircleSize div 2) - Start_X_Offset - 1;
    var Initial_Cy := R.Bottom - (CircleSize div 2) - Start_Y_Offset - 1;

    // Calcoliamo la massima quantità di cerchi per lato con la nuova dimensione e spaziatura.
    // Per una GripSize di 16 e uno Step di 3: 16 / 3 = 5.33 -> possiamo avere fino a 5 cerchi
    var MaxCirclesPerSide := Trunc(GripSize / Step) + 1; // Aggiungiamo 1 per includere più cerchi e riempire meglio

    // Poiché 16/3 = 5.33, possiamo avere una riga/colonna di 5 cerchi (5*2px + 4*1px = 10+4 = 14px),
    // che sta benissimo nei 16px della grip. Potresti anche fissare a 5 se preferisci un numero specifico.
    // MaxCirclesPerSide := 5; // Puoi fissare a 5 se vuoi essere preciso per GripSize 16, CircleSize 2, Spacing 1

    for row_idx := 0 to MaxCirclesPerSide - 1 do // Dal basso verso l'alto
    begin
      for col_idx := 0 to MaxCirclesPerSide - 1 do // Da destra a sinistra
      begin
        // Condizione per disegnare solo la parte triangolare
        // Il triangolo ha l'angolo a 90 gradi in basso a destra
        // Questo significa che disegniamo cerchi solo se la loro posizione
        // rientra nell'area del triangolo, dove la somma di riga e colonna
        // non supera un certo limite (MaxCirclesPerSide - 1).
        if (row_idx + col_idx) < MaxCirclesPerSide then
        begin
          // Calcola il centro del cerchio
          // I cerchi si muovono verso l'alto (diminuendo Y) e verso sinistra (diminuendo X)
          // partendo dall'angolo in basso a destra.
          Cx := Initial_Cx - col_idx * Step;
          Cy := Initial_Cy - row_idx * Step;

          // Disegna il cerchio
          Canvas.Ellipse(Cx - CircleSize div 2, Cy - CircleSize div 2,
                         Cx + CircleSize div 2, Cy + CircleSize div 2);
        end;
      end;
    end;
  end;
end;

procedure TMyCustomStatusBar.Resize;
begin
  inherited;
  Invalidate;
end;

procedure TMyCustomStatusBar.DoPanelClick(Panel: TMyCustomStatusBarPanel; PanelIndex: Integer);
begin
  // Esegue prima l'evento OnClick del singolo pannello
  if Assigned(Panel) then
    Panel.DoClick;

  // Esegue l'evento generale della StatusBar
  if Assigned(FOnPanelClick) then
    FOnPanelClick(Self, PanelIndex);
end;

procedure TMyCustomStatusBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i, PosX: Integer;
  Panel: TMyCustomStatusBarPanel;
  GripSize: Integer;
  GripRect: TRect;
begin
  inherited;

  GripSize := 16;
  GripRect := Rect(Width - GripSize, Height - GripSize, Width, Height);

  // Se clicca sulla grip e SizeGrip è attivo, facciamo gestione ridimensionamento (default)
  // Nota: se la grip è disegnata manualmente e non usi DrawFrameControl,
  // la gestione del resize standard di Windows su quell'area potrebbe non funzionare.
  // In questo caso, potresti dover implementare un controllo manuale del WM_NCHITTEST
  // per la zona della grip.
  if FSizeGrip and PtInRect(GripRect, Point(X, Y)) then
  begin
    // Per un componente personalizzato che disegna la grip manualmente,
    // se vuoi abilitare il resize standard quando si clicca sulla grip,
    // devi inviare un messaggio WM_NCHITTEST con HTBOTTOMRIGHT.
    // Questo è un esempio più avanzato e richiede override di WndProc.
    // Per semplicità, in questo esempio, il click sulla grip non farà nulla
    // se non gestito esplicitamente da Windows o dal tuo codice.
    // L'uscita (Exit) qui significa che il click non verrà propagato ai pannelli sottostanti.
    Exit;
  end;

  PosX := 0;
  for i := 0 to FPanels.Count - 1 do
  begin
    Panel := FPanels[i];
    // Calcolo la larghezza utile per l'ultimo pannello in caso di size grip attivo
    if FSizeGrip and (i = FPanels.Count - 1) then
    begin
      // La logica di click per il pannello deve considerare che l'ultimo pannello si estende
      // su tutta l'area, quindi un click nella zona della grip va gestito prima da PtInRect(GripRect, Point(X, Y))
      // altrimenti il click andrà al pannello.
      // Se il pannello è più largo della grip, la parte cliccabile è fino a prima della grip
      if (X >= PosX) and (X < PosX + Panel.Width) then // L'ultimo pannello prende tutto lo spazio
      begin
        // Ma dobbiamo escludere l'area della grip se cliccabile
        if not (FSizeGrip and PtInRect(GripRect, Point(X, Y))) then // Assicurati di non cliccare sulla grip
        begin
          DoPanelClick(Panel, i);
          Exit;
        end;
      end;
      Inc(PosX, Panel.Width); // Sposta la PosX comunque in base alla larghezza definita del pannello
    end
    else
    begin
      if (X >= PosX) and (X < PosX + Panel.Width) then
      begin
        DoPanelClick(Panel, i);
        Exit;
      end;
      Inc(PosX, Panel.Width);
    end;
  end;
end;

end.
