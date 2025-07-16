unit MyAlignEditor;

interface

uses
  System.SysUtils, System.Classes, DesignIntf, DesignEditors, Vcl.Controls, CustomStatusBar; // Assicurati di includere CustomStatusBar

type
  // Dichiara la classe dell'editor di proprietà personalizzato
  TMyAlignPropertyEditor = class(TEnumPropertyEditor)
  public
    // Sovrascrive il metodo GetValues per definire le opzioni disponibili
    function GetValues: TPropertyValues; override;
  end;

// Procedura per registrare l'editor nell'IDE di Delphi
procedure Register;

implementation

procedure Register;
begin
  // Registra l'editor personalizzato per la proprietà 'Align'
  // associandolo al tuo componente TMyCustomStatusBar e al tipo TAlign
  RegisterPropertyEditor(TypeInfo(TAlign), TMyCustomStatusBar, 'Align', TMyAlignPropertyEditor);
end;

{ TMyAlignPropertyEditor }

function TMyAlignPropertyEditor.GetValues: TPropertyValues;
begin
  // Inizialmente, ottieni i valori predefiniti dell'enumerazione TAlign
  Result := inherited GetValues;

  // Cancella tutti i valori esistenti per avere un controllo totale
  Result.Clear;

  // Aggiungi solo i valori che vuoi rendere disponibili
  Result.Add('alTop');
  Result.Add('alBottom');
  Result.Add('alNone'); // È buona pratica includere alNone, per permettere di disabilitare l'allineamento
end;

end.
