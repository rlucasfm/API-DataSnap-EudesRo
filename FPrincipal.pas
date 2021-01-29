unit FPrincipal;

interface

uses
  Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.AppEvnts, Vcl.StdCtrls, IdHTTPWebBrokerBridge, Web.HTTPApp,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.ExtCtrls, Datasnap.DBClient,
  Vcl.Grids, Vcl.DBGrids, DateUtils;

type
  TFormPrincipal = class(TForm)
    ButtonStart: TButton;
    ButtonStop: TButton;
    EditPort: TEdit;
    Label1: TLabel;
    ApplicationEvents1: TApplicationEvents;
    ButtonOpenBrowser: TButton;
    DB_Connection: TFDConnection;
    DB_Query: TFDQuery;
    DB_IDGen: TFDQuery;
    DB_Check: TFDQuery;
    DB_Check2: TFDQuery;
    DB_Check3: TFDQuery;
    Timer_12h: TTimer;
    DB_Listas: TFDQuery;
    Lista_Temp: TClientDataSet;
    Lista_TempID: TIntegerField;
    Lista_TempID_BANCO: TIntegerField;
    Lista_TempNOME: TStringField;
    Lista_TempTIPOEMAIL: TIntegerField;
    Lista_TempDIASVENC: TIntegerField;
    Lista_TempHORADISPARO: TTimeField;
    Lista_TempMENSAGEM: TBlobField;
    Lista_TempTIPOCAMPANHA: TStringField;
    Lista_Source: TDataSource;
    DBGrid1: TDBGrid;
    Label2: TLabel;
    Timer_10m: TTimer;
    DB_Ops: TFDQuery;
    procedure FormCreate(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure ButtonStartClick(Sender: TObject);
    procedure ButtonStopClick(Sender: TObject);
    procedure ButtonOpenBrowserClick(Sender: TObject);
    procedure Timer_12hTimer(Sender: TObject);
    procedure Timer_10mTimer(Sender: TObject);
  private
    FServer: TIdHTTPWebBrokerBridge;
    procedure StartServer;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormPrincipal: TFormPrincipal;
  index : integer;

implementation

{$R *.dfm}

uses
  WinApi.Windows, Winapi.ShellApi, Datasnap.DSSession;

procedure TFormPrincipal.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
begin
  ButtonStart.Enabled := not FServer.Active;
  ButtonStop.Enabled := FServer.Active;
  EditPort.Enabled := not FServer.Active;
end;

procedure TFormPrincipal.ButtonOpenBrowserClick(Sender: TObject);
var
  LURL: string;
begin
  StartServer;
  LURL := Format('http://localhost:%s', [EditPort.Text]);
  ShellExecute(0,
        nil,
        PChar(LURL), nil, nil, SW_SHOWNOACTIVATE);
end;

procedure TFormPrincipal.ButtonStartClick(Sender: TObject);
begin
  StartServer;
end;

procedure TerminateThreads;
begin
  if TDSSessionManager.Instance <> nil then
    TDSSessionManager.Instance.TerminateAllSessions;
end;

procedure TFormPrincipal.ButtonStopClick(Sender: TObject);
begin
  TerminateThreads;
  FServer.Active := False;
  FServer.Bindings.Clear;
end;

procedure TFormPrincipal.FormCreate(Sender: TObject);
const
  _SELECT = 'SELECT * FROM listas';
begin
  FServer := TIdHTTPWebBrokerBridge.Create(Self);

  DB_Listas.Active := false;
  DB_Listas.SQL.Text := _SELECT;
  DB_Listas.Open;

  DB_Listas.First;
  Lista_Temp.Close;
  Lista_Temp.CreateDataSet;
  Lista_Temp.Open;
  while not DB_Listas.Eof do
  begin
    Lista_Temp.Append;
    Lista_Temp.FieldByName('ID').Value := DB_Listas.FieldByName('id').Value;
    Lista_Temp.FieldByName('ID_BANCO').Value := DB_Listas.FieldByName('id_banco').Value;
    Lista_Temp.FieldByName('NOME').Value := DB_Listas.FieldByName('nome').Value;
    Lista_Temp.FieldByName('TIPOEMAIL').Value := DB_Listas.FieldByName('tipoemail').Value;
    Lista_Temp.FieldByName('DIASVENC').Value := DB_Listas.FieldByName('diasvenc').Value;
    Lista_Temp.FieldByName('HORADISPARO').Value := DB_Listas.FieldByName('horadisparo').Value;
    Lista_Temp.FieldByName('MENSAGEM').Value := DB_Listas.FieldByName('mensagem').Value;
    Lista_Temp.FieldByName('TIPOCAMPANHA').Value := DB_Listas.FieldByName('tipocampanha').Value;
    Lista_Temp.Post;

    DB_Listas.Next;
  end;
end;

procedure TFormPrincipal.StartServer;
begin
  if not FServer.Active then
  begin
    FServer.Bindings.Clear;
    FServer.DefaultPort := StrToInt(EditPort.Text);
    FServer.Active := True;
  end;
end;

procedure TFormPrincipal.Timer_10mTimer(Sender: TObject);
var
  SQL_Query   : string;
  horaAgora   : TDateTime;
  horaDisparo : TDateTime;
  diaVenc     : TDateTime;
  diaVencStr  : string;
  permTempo   : integer;
  tipoCampanha: string;
  mensagemSubs: string;
  Splitted    : TArray<string>;
  pnomeCliente: string;
  pnomeAluno  : string;
begin
  // Richard @ Tempo de permissividade entre a hora da lista e a hora atual.
  permTempo := 5;

  // Richard @ Percorre a tabela tempor�ria de listas em mem�ria,
  //         @ Checando se est� na hora de enviar alguma lista
  Lista_Temp.First;
  horaAgora := Now;

  while not Lista_Temp.Eof do
  begin
  horaDisparo := Lista_Temp.FieldByName('HORADISPARO').Value;
    if (CompareTime(horaDisparo,IncMinute(horaAgora, -permTempo)) > 0) AND (CompareTime(horaDisparo,IncMinute(horaAgora, permTempo)) < 0) then
    begin
      // Richard @ Se estiver na hora de enviar a lista, busca todas opera��es
      //         @ onde a data de vencimento condiz com a regra da lista.
      diaVenc     := IncDay(horaAgora, Lista_Temp.FieldByName('DIASVENC').AsInteger);
      diaVencStr  := StringReplace(DateToStr(diaVenc), '/', '.', [rfReplaceAll, rfIgnoreCase]);
      SQL_Query := 'SELECT DISTINCT c.nome, o.tipooperacao, o.datavencto, o.valornominal, o.condnegociais, o.nroperacao FROM operacoes o ' +
                   'INNER JOIN clientes c ON c.codigo = o.cliente ' +
                   'INNER JOIN listas l ON l.id_banco = o.banco ' +
                   'WHERE o.datavencto = '''+diaVencStr+'''';

      Try
        DB_Ops.Active := false;
        DB_Ops.SQL.Text := SQL_Query;
        DB_Ops.Open;
        DB_Ops.First;
        while not DB_Ops.Eof do
        begin
          // Richard @ Informa��o de Cliente e Opera��o recuperada, agora enviamos o SMS/EMAIL
          //         @ Verificando se a campanha � SMS ou EMAIL...
          tipoCampanha := Lista_Temp.FieldByName('TIPOCAMPANHA').AsString;

          if tipoCampanha = 'sms' then
          //         @ Campanha � SMS
          begin
            //       @ Substitui os identificadores
            mensagemSubs := StringReplace(Lista_Temp.FieldByName('MENSAGEM').AsString, '$nomeop$', DB_Ops.FieldByName('tipooperacao').AsString, [rfReplaceAll, rfIgnoreCase]);
            mensagemSubs := StringReplace(mensagemSubs, '$datavenc$', DB_Ops.FieldByName('datavencto').AsString, [rfReplaceAll, rfIgnoreCase]);
            mensagemSubs := StringReplace(mensagemSubs, '$valorop$', DB_Ops.FieldByName('valornominal').AsString, [rfReplaceAll, rfIgnoreCase]);
            mensagemSubs  := StringReplace(mensagemSubs, '$nomecliente$', DB_Ops.FieldByName('nome').AsString, [rfReplaceAll, rfIgnoreCase]);
            mensagemSubs  := StringReplace(mensagemSubs, '$nomealuno$', DB_Ops.FieldByName('condnegociais').AsString, [rfReplaceAll, rfIgnoreCase]);
            //       @ Conseguir apenas os primeiros nomes de cliente e aluno
            pnomeCliente  := DB_Ops.FieldByName('nome').AsString;
            pnomeAluno    := DB_Ops.FieldByName('condnegociais').AsString;
            Splitted      := pnomeCliente.Split([' ']);
            mensagemSubs  := StringReplace(mensagemSubs, '$pnomecliente$', Splitted[0], [rfReplaceAll, rfIgnoreCase]);
            Splitted      := pnomeAluno.Split([' ']);
            mensagemSubs  := StringReplace(mensagemSubs, '$pnomealuno$', Splitted[0], [rfReplaceAll, rfIgnoreCase]);
            //       @ Corre��o de UNICODE vindo do DB Firebird
            mensagemSubs  := StringReplace(mensagemSubs, 'u00e1', '�', [rfReplaceAll, rfIgnoreCase]);
            mensagemSubs  := StringReplace(mensagemSubs, 'u00ea', '�', [rfReplaceAll, rfIgnoreCase]);
            mensagemSubs  := StringReplace(mensagemSubs, 'u00e9', '�', [rfReplaceAll, rfIgnoreCase]);
            mensagemSubs  := StringReplace(mensagemSubs, 'u00c1', '�', [rfReplaceAll, rfIgnoreCase]);
            mensagemSubs  := StringReplace(mensagemSubs, 'u00ca', '�', [rfReplaceAll, rfIgnoreCase]);
            mensagemSubs  := StringReplace(mensagemSubs, 'u00c9', '�', [rfReplaceAll, rfIgnoreCase]);
          end
          //         @ Campanha � EMAIL
          else
          begin
          end;

          DB_Ops.Next;
        end;
      Except on E : Exception do
        ShowMessage('Houve um erro: '+E.Message);
      End;


    end;
  Lista_Temp.Next;
  end;
end;

procedure TFormPrincipal.Timer_12hTimer(Sender: TObject);
const
  _SELECT = 'SELECT * FROM listas';
begin
  Try
    // Richard @ Inicia buscando as listas do banco de dados
    DB_Listas.Active := false;
    DB_Listas.SQL.Text := _SELECT;
    DB_Listas.Open;

    DB_Listas.First;
    Lista_Temp.Close;
    Lista_Temp.CreateDataSet;
    Lista_Temp.Open;

    //        @ Salva as listas em uma tabela tempor�ria na mem�ria
    while not DB_Listas.Eof do
    begin
      Lista_Temp.Append;
      Lista_Temp.FieldByName('ID').Value := DB_Listas.FieldByName('id').Value;
      Lista_Temp.FieldByName('ID_BANCO').Value := DB_Listas.FieldByName('id_banco').Value;
      Lista_Temp.FieldByName('NOME').Value := DB_Listas.FieldByName('nome').Value;
      Lista_Temp.FieldByName('TIPOEMAIL').Value := DB_Listas.FieldByName('tipoemail').Value;
      Lista_Temp.FieldByName('DIASVENC').Value := DB_Listas.FieldByName('diasvenc').Value;
      Lista_Temp.FieldByName('HORADISPARO').Value := DB_Listas.FieldByName('horadisparo').Value;
      Lista_Temp.FieldByName('MENSAGEM').Value := DB_Listas.FieldByName('mensagem').Value;
      Lista_Temp.FieldByName('TIPOCAMPANHA').Value := DB_Listas.FieldByName('tipocampanha').Value;
      Lista_Temp.Post;

      DB_Listas.Next;
    end;
  Except on E: Exception do
    ShowMessage('Houve um erro: '+E.Message);
  End;
end;



end.
