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
  Vcl.Grids, Vcl.DBGrids, DateUtils, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent;

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
    NetHTTPClient1: TNetHTTPClient;
    Lista_TempENVIADO: TSmallintField;
    Memo_log: TMemo;
    Label3: TLabel;
    DB_Banco: TFDQuery;
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
    function StripChars(const Text: string; const InValidChars: System.SysUtils.TSysCharSet): string;
    function EnviarSms(var numero, mensagem: string): string;
    function EnviarEmail(var nome_cliente, email_cliente, nome_banco, id_email : string): string;
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

function TFormPrincipal.EnviarEmail(var nome_cliente, email_cliente, nome_banco,
  id_email : string): string;
var
  url: string;
  ss : TStringStream;
begin
  URL := 'https://www.grupovoz.net.br/email/send/'+nome_cliente+'/'+email_cliente+'/'+nome_banco+'/'+id_email;
  // URL para Pipedream - Teste
  //URL := 'https://endofdg5rkj3qrw.m.pipedream.net/'+nome_cliente+'/'+email_cliente+'/'+nome_banco+'/'+id_email;

  ss := TStringStream.Create('', tencoding.UTF8);
  ss.WriteString(URL);
  self.NetHTTPClient1.Accept :='application/x-www-form-urlencoded';
  self.NetHTTPClient1.ContentType := 'UTF-8';
  self.NetHTTPClient1.AcceptEncoding := 'UTF-8';
  ss.Position := 0;
  Result := self.NetHTTPClient1.Get(URL, ss).ContentAsString(tencoding.UTF8);
  ss.Free;
end;

function TFormPrincipal.EnviarSms(var numero, mensagem: string): string;
var
  url: string;
  ss : TStringStream;
begin
  URL := 'http://www.zenvia360.com.br/GatewayIntegration/msgSms.do?account=grupo.voz.corp&code=if8LznpC0L&dispatch=send&to=55'+numero+'&msg='+mensagem;
  ss := TStringStream.Create('', tencoding.UTF8);
  ss.WriteString(URL);
  self.NetHTTPClient1.Accept :='application/x-www-form-urlencoded';
  self.NetHTTPClient1.ContentType := 'application/x-www-form-urlencoded';
  self.NetHTTPClient1.AcceptEncoding := 'UTF-8';
  Result := self.NetHTTPClient1.Get(URL, ss).ContentAsString(tencoding.UTF8);
  ss.Free;
end;

// IN�CIO DO PROGRAMA
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
    Lista_Temp.FieldByName('ENVIADO').Value := 0;
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

function TFormPrincipal.StripChars(const Text: string;
  const InValidChars: System.SysUtils.TSysCharSet): string;
  var
  i,j,zbsAdj : Integer;
begin
  SetLength(Result,Length(Text));  // Preallocate result maximum length
  j := 0; // Resulting string length counter
  zbsAdj := 1-Low(String); // Handles zero based string offset
  for i := Low(Text) to High(Text) do begin
    if not CharInSet(Text[i],InValidChars) then begin
      Inc(j);
      Result[j-zbsAdj] := Text[i];
    end;
  end;
  SetLength(Result,j); // Set result actual length
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
  numeroCliente: string;
  response    : string;
  enviado     : integer;
  email_cliente: string;
  id_email    : string;
  nome_banco  : string;
begin
  // Richard @ Tempo de permissividade entre a hora da lista e a hora atual em minutos.
  permTempo := 5;

  // Richard @ Percorre a tabela tempor�ria de listas em mem�ria,
  //         @ Checando se est� na hora de enviar alguma lista,
  //         @ Tamb�m se a lista j� foi enviada neste ciclo.
  Lista_Temp.First;
  horaAgora := Now;

  Memo_log.Lines.Add('Ciclo de 10 minutos...');
  while not Lista_Temp.Eof do
  begin
  enviado     := Lista_Temp.FieldByName('enviado').AsInteger;
  horaDisparo := Lista_Temp.FieldByName('HORADISPARO').Value;
    if (CompareTime(horaDisparo,IncMinute(horaAgora, -permTempo)) > 0) AND (CompareTime(horaDisparo,IncMinute(horaAgora, permTempo)) < 0) AND (enviado = 0) then
    begin
      // Richard @ Evitar a duplica��o
      Try
        Lista_Temp.Edit;
        Lista_Temp.FieldByName('enviado').AsInteger := 1;
        Lista_Temp.Post;
      Except on E : Exception do
        Memo_log.Lines.Add(E.Message);
      End;
      //         @ Se estiver na hora de enviar a lista, busca todas opera��es
      //         @ onde a data de vencimento condiz com a regra da lista.
      diaVenc     := IncDay(horaAgora, Lista_Temp.FieldByName('DIASVENC').AsInteger);
      diaVencStr  := StringReplace(DateToStr(diaVenc), '/', '.', [rfReplaceAll, rfIgnoreCase]);
      SQL_Query := 'SELECT DISTINCT c.nome, o.tipooperacao, o.datavencto, o.valornominal, o.condnegociais, o.nroperacao, c.fone, c.fone_1, c.e_mail FROM operacoes o ' +
                   'INNER JOIN clientes c ON c.codigo = o.cliente ' +
                   'INNER JOIN listas l ON l.id_banco = o.banco ' +
                   'WHERE o.datavencto = '''+diaVencStr+'''';

      Try
        DB_Ops.Active := false;
        DB_Ops.SQL.Text := SQL_Query;
        DB_Ops.Open;
        DB_Ops.First;
        // Richard   @ Busca todas as opera��es com a data condizente
        while not DB_Ops.Eof do
        begin
          //         @ Informa��o de Cliente e Opera��o recuperada, agora enviamos o SMS/EMAIL
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

            //       @ Contato para o envio de SMS
            if DB_Ops.FieldByName('FONE').AsString <> '' then
            numeroCliente := StripChars(DB_Ops.FieldByName('FONE').AsString, [' ','-','(',')'])
            else
            numeroCliente := StripChars(DB_Ops.FieldByName('FONE_1').AsString, [' ','-','(',')']);

            //       @ Envia o SMS
            Try
              response := EnviarSms(numeroCliente, mensagemSubs);
              Memo_log.Lines.Add('Mensagem enviada para: '+numeroCliente+' Response: '+response);
            Except on E : Exception do
              Memo_log.Lines.Add(E.Message);
            End;

          end
          //         @ Campanha � EMAIL
          else
          begin
            pnomeCliente  := DB_Ops.FieldByName('nome').AsString;
            email_cliente := DB_Ops.FieldByName('e_mail').AsString;
            id_email      := Lista_Temp.FieldByName('TIPOEMAIL').AsString;
            nome_banco    := Lista_Temp.FieldByName('ID_BANCO').AsString;

            //       @ Recuperar o nome do Banco pelo ID
            DB_Banco.Active := false;
            DB_Banco.SQL.Text := 'SELECT nome FROM bancos WHERE id = '+Lista_Temp.FieldByName('ID_BANCO').AsString;
            Try
              DB_Banco.Open;
              nome_banco := DB_Banco.FieldByName('nome').AsString;
              DB_Banco.Close;
            Except on E: Exception do
              Memo_log.Lines.Add(E.Message);
            End;

            Try
              response := EnviarEmail(pnomeCliente, email_cliente, nome_banco, id_email);
              Memo_log.Lines.Add('Email enviado para: '+email_cliente+' Response: '+response);
            Except on E: Exception do
              Memo_log.Lines.Add(E.Message);
            End;
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
    //         @ Inicia buscando as listas do banco de dados
    DB_Listas.Active := false;
    DB_Listas.SQL.Text := _SELECT;
    DB_Listas.Open;

    DB_Listas.First;
    Lista_Temp.Close;
    Lista_Temp.CreateDataSet;
    Lista_Temp.Open;

    Memo_log.Lines.Add('Ciclo de 12h...');
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
      Lista_Temp.FieldByName('ENVIADO').Value := 0;
      Lista_Temp.Post;

      DB_Listas.Next;
    end;
  Except on E: Exception do
    ShowMessage('Houve um erro: '+E.Message);
  End;
end;



end.
