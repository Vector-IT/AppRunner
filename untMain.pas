unit untMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, IniFiles, DateUtils, ExtCtrls, ShellAPI,
  FileCtrl, cxControls, cxContainer, cxEdit, cxTextEdit, cxMaskEdit,
  cxButtonEdit, Buttons;

type
  TfrmMain = class(TForm)
    lblTitulo: TLabel;
    lblArchivo: TLabel;
    PB1: TProgressBar;
    Timer1: TTimer;
    Image1: TImage;
    Label1: TLabel;
    Label3: TLabel;
    btnIniciar: TButton;
    btnDesde: TcxButtonEdit;
    btnHacia: TcxButtonEdit;
    btnSwitch: TBitBtn;
    btnConfig: TBitBtn;
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnIniciarClick(Sender: TObject);
    procedure btnDesdePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnHaciaPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnSwitchClick(Sender: TObject);
    procedure btnConfigClick(Sender: TObject);
  private
    { Private declarations }
    function LeerIni(Archivo, Seccion, Clave, Default: String): String;
    procedure GrabarIni(Archivo, Seccion, Clave, Valor: String);
    function ControlarVersion(strFileLocal, strFileRemoto: String): Boolean;
    procedure CopiarArchivo(strFileOrigen, strFileDestino: String);
    procedure CopiarVariosArchivos(strFileOrigen, strFileDestino: String);
    procedure CopyFileDate(const Source, Dest: String);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

function TfrmMain.LeerIni(Archivo, Seccion, Clave, Default: String): String;
var
  IFile: TIniFile;
begin
  IFile:= TIniFile.Create(Archivo);
  try
    if IFile.ValueExists(Seccion, Clave) then
      Result:= IFile.ReadString(Seccion, Clave, Default)
    else
    begin
      //IFile.WriteString(Seccion, Clave, Default);
      Result:= Default;
    end;
  finally
    IFile.Free;
  end;
end;

procedure TfrmMain.GrabarIni(Archivo, Seccion, Clave, Valor: String);
var
  IFile: TIniFile;
begin
  IFile:= TIniFile.Create(Archivo);
  try
    IFile.WriteString(Seccion, Clave, Valor)
  finally
    IFile.Free;
  end;
end;


procedure TfrmMain.Timer1Timer(Sender: TObject);
var
  strRutaLocal, strRutaServer, strArchivo: String;
  I, CantFiles: Integer;
  blnEjecutar: Boolean;
begin
  //Cargo variables
  Timer1.Enabled:= False;
  GrabarIni(ChangeFileExt(Application.ExeName, '.ini'), 'CONFIGURACION', 'RUTA_SERVIDOR', btnDesde.Text);
  GrabarIni(ChangeFileExt(Application.ExeName, '.ini'), 'CONFIGURACION', 'RUTA_LOCAL', btnHacia.Text);
    
  strRutaLocal:= LeerIni(ChangeFileExt(Application.ExeName, '.ini'), 'CONFIGURACION', 'RUTA_LOCAL', '') + '\';
  strRutaServer:= LeerIni(ChangeFileExt(Application.ExeName, '.ini'), 'CONFIGURACION', 'RUTA_SERVIDOR', '') + '\';

  blnEjecutar:= StrToBool(LeerIni(ChangeFileExt(Application.ExeName, '.ini'), 'CONFIGURACION', 'EJECUTA_AL_FINAL', '1'));
  CantFiles:= strToInt(LeerIni(ChangeFileExt(Application.ExeName, '.ini'), 'ARCHIVOS', 'CANTIDAD', ''));

  PB1.Max:= CantFiles;

  //Recorro el en busca de los archivos
  for I:= 1 to CantFiles do
  begin
    //Traigo el nombre del archivo
    strArchivo:= LeerIni(ChangeFileExt(Application.ExeName, '.ini'), 'ARCHIVOS', 'ARCHIVO_' + IntToStr(I), '');
    lblArchivo.Caption:= strArchivo;

    PB1.Position:= I;

    Application.ProcessMessages;

    if strArchivo <> '' then
    begin
      //Controlo si existe el directorio
      if not DirectoryExists(strRutaLocal) then
        CreateDir(strRutaLocal);

      //Me fijo si tiene Wildcards para llamar a un metodo diferente
      if Pos('*', strArchivo) <> 0 then
      begin
        ControlarVersion(strRutaLocal + strArchivo, strRutaServer + strArchivo);
        CopiarVariosArchivos(strRutaServer + strArchivo, ExtractFilePath(strRutaLocal + strArchivo));
      end
      else
      //Controlo edad de los archivos
      if not ControlarVersion(strRutaLocal + strArchivo, strRutaServer + strArchivo) then
      begin
        try
          //Borro el local
          DeleteFile(strRutaLocal + strArchivo);
      
          //Copio el nuevo
          if FileExists(strRutaServer + strArchivo) then
          begin
            CopiarArchivo(strRutaServer + strArchivo, strRutaLocal + strArchivo);
            CopyFileDate(strRutaServer + strArchivo, strRutaLocal + strArchivo);
          end;

          Application.ProcessMessages;
        except
          Application.MessageBox(PChar('Error al copiar el archivo '+strArchivo+#10+'Por favor contáctese con Soporte Técnico e informe el problema.'), 'App Runner', MB_OK+MB_ICONEXCLAMATION+MB_DEFBUTTON1+MB_APPLMODAL);
        end;
      end;
    end;
  end;

  if blnEjecutar then
  begin
    strArchivo:= LeerIni(ChangeFileExt(Application.ExeName, '.ini'), 'ARCHIVOS', 'ARCHIVO_1', '');
    ShellExecute(Handle, nil, PChar(strRutaLocal + strArchivo),  nil, nil, SW_SHOW);
  end;
  Close;
end;

procedure TfrmMain.btnIniciarClick(Sender: TObject);
begin
  btnIniciar.Hide;
  Timer1.Enabled:= True;
end;

function TfrmMain.ControlarVersion(strFileLocal, strFileRemoto: String): Boolean;
var
  fecLocal, fecRemoto: TDateTime;
begin
  if FileExists(strFileLocal) then
    fecLocal:= FileDateToDateTime(FileAge(strFileLocal))
  else
  begin
    Result:= False;
    Exit;
  end;

  if FileExists(strFileRemoto) then
    fecRemoto:= FileDateToDateTime(FileAge(strFileRemoto))
  else
  begin
    Result:= False;
    Exit;
  end;

  if MinutesBetween(fecRemoto, fecLocal) <> 0 then
    Result:= False
  else
    Result:= True;
end;

procedure TfrmMain.CopiarArchivo(strFileOrigen, strFileDestino: String);
var
  Origen,
  Destino  :file of byte;
  Buffer   :array[0..4096] of char;
  Leidos   :integer;
  Longitud :longint;
begin
  if (not DirectoryExists(ExtractFilePath(strFileDestino))) then
    CreateDir(ExtractFilePath(strFileDestino));

  {Abrimos fichero Origen y Destino}
  AssignFile(Origen, strFileOrigen);
  FileMode := 0;
  Reset(Origen);
  AssignFile(Destino, strFileDestino);
  Rewrite(Destino);
  {Hallamos la longitud del fichero a copiar}
  Longitud:= FileSize(Origen);
  {Actualizamos limites de la ProgressBar}
  while Longitud >0 do
  begin
    BlockRead(Origen, Buffer[0], SizeOf(Buffer), Leidos);
    Longitud:= Longitud-Leidos;
    BlockWrite(Destino, Buffer[0], Leidos);
  end;
  CloseFile(Origen);
  CloseFile(Destino);
end;

procedure TfrmMain.CopyFileDate(const Source, Dest: String);
var
  SourceHand, DestHand: word;
begin
  SourceHand := FileOpen(Source, fmOpenRead);       { open source file }
  DestHand := FileOpen(Dest, fmOpenWrite);            { open dest file }
  FileSetDate(DestHand, FileGetDate(SourceHand)); { get/set date }
  FileClose(SourceHand);                          { close source file }
  FileClose(DestHand);                            { close dest file }
end;

procedure TfrmMain.CopiarVariosArchivos(strFileOrigen, strFileDestino: String);
var
  F : TShFileOpStruct;
  Result: Integer;
begin
  if (not DirectoryExists(ExtractFilePath(strFileDestino))) then
    CreateDir(ExtractFilePath(strFileDestino));

  F.Wnd := 0;
  F.wFunc := FO_COPY;
  F.pFrom := PCHAR(strFileOrigen + #0);
  F.pTo := PCHAR(strFileDestino + #0);
  F.fFlags := FOF_SILENT OR FOF_NOCONFIRMATION OR FOF_MULTIDESTFILES OR FOF_NOCONFIRMMKDIR;
  Result:= ShFileOperation(F);
  if Result <> 0 then
  begin
    Application.MessageBox(PChar('Error al copiar el archivo '+strFileOrigen+#10+SysErrorMessage(Result)+#10+'Por favor contáctese con Soporte Técnico e informe el problema.'), 'App Runner', MB_OK+MB_ICONEXCLAMATION+MB_DEFBUTTON1+MB_APPLMODAL);
  end;
end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  strRutaLocal, strRutaServer: String;
  blnInicio: Boolean;
begin
  //Cargo variables
  strRutaLocal:= LeerIni(ChangeFileExt(Application.ExeName, '.ini'), 'CONFIGURACION', 'RUTA_LOCAL', '');
  strRutaServer:= LeerIni(ChangeFileExt(Application.ExeName, '.ini'), 'CONFIGURACION', 'RUTA_SERVIDOR', '');

  btnDesde.Text:= strRutaServer;
  btnHacia.Text:= strRutaLocal;

  blnInicio:= StrToBool(LeerIni(ChangeFileExt(Application.ExeName, '.ini'), 'CONFIGURACION', 'AUTOSTART', '0'));
  Timer1.Enabled:= blnInicio;
  btnIniciar.Visible:= not blnInicio;
end;

procedure TfrmMain.btnDesdePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var strDirectorio: String;
begin
  strDirectorio:= btnDesde.Text;

  if SelectDirectory('Seleccione un origen', '', strDirectorio) then
  begin
    GrabarIni(ChangeFileExt(Application.ExeName, '.ini'), 'CONFIGURACION', 'RUTA_SERVIDOR', strDirectorio);
    btnDesde.Text:= strDirectorio;
  end;
end;

procedure TfrmMain.btnHaciaPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var strDirectorio: String;
begin
  strDirectorio:= btnHacia.Text;

  if SelectDirectory('Seleccione un destino', '', strDirectorio) then
  begin
    GrabarIni(ChangeFileExt(Application.ExeName, '.ini'), 'CONFIGURACION', 'RUTA_LOCAL', strDirectorio);
    btnHacia.Text:= strDirectorio;
  end;
end;

procedure TfrmMain.btnSwitchClick(Sender: TObject);
var strAux: String;
begin
  strAux:= btnDesde.Text;
  btnDesde.Text:= btnHacia.Text;
  btnHacia.Text:= strAux;                    
end;

procedure TfrmMain.btnConfigClick(Sender: TObject);
begin
  ShellExecute(Handle, nil, PChar(ChangeFileExt(Application.ExeName, '.ini')),  nil, nil, SW_SHOW);
end;

end.
