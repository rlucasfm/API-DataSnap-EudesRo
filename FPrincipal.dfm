object FormPrincipal: TFormPrincipal
  Left = 271
  Top = 114
  Caption = 'EudesRo API RESTFul'
  ClientHeight = 353
  ClientWidth = 691
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 24
    Top = 48
    Width = 20
    Height = 13
    Caption = 'Port'
  end
  object Label2: TLabel
    Left = 8
    Top = 224
    Width = 84
    Height = 13
    Caption = 'Listas carregadas'
  end
  object Label3: TLabel
    Left = 416
    Top = 5
    Width = 17
    Height = 13
    Caption = 'Log'
  end
  object ButtonStart: TButton
    Left = 24
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Iniciar'
    TabOrder = 0
    OnClick = ButtonStartClick
  end
  object ButtonStop: TButton
    Left = 105
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Parar'
    TabOrder = 1
    OnClick = ButtonStopClick
  end
  object EditPort: TEdit
    Left = 24
    Top = 67
    Width = 121
    Height = 21
    TabOrder = 2
    Text = '8077'
  end
  object ButtonOpenBrowser: TButton
    Left = 24
    Top = 112
    Width = 107
    Height = 25
    Caption = 'Open Browser'
    TabOrder = 3
    OnClick = ButtonOpenBrowserClick
  end
  object DBGrid1: TDBGrid
    Left = 8
    Top = 243
    Width = 395
    Height = 102
    DataSource = Lista_Source
    TabOrder = 4
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object Memo_log: TMemo
    Left = 416
    Top = 24
    Width = 267
    Height = 321
    TabOrder = 5
  end
  object ApplicationEvents1: TApplicationEvents
    OnIdle = ApplicationEvents1Idle
    Left = 256
    Top = 24
  end
  object DB_Connection: TFDConnection
    Params.Strings = (
      
        'Database=C:\Users\richard\Documents\Embarcadero\Studio\Projects\' +
        'API-EudesRoCI\database\APIDATABASE.FDB'
      'User_Name=SYSDBA'
      'Password=masterkey'
      'DriverID=FB')
    Left = 256
    Top = 176
  end
  object DB_Query: TFDQuery
    Connection = DB_Connection
    Left = 336
    Top = 176
  end
  object DB_IDGen: TFDQuery
    Connection = DB_Connection
    Left = 336
    Top = 120
  end
  object DB_Check: TFDQuery
    Connection = DB_Connection
    SQL.Strings = (
      'SELECT * FROM clientes WHERE cpf = '#39'4877897410'#39)
    Left = 256
    Top = 120
  end
  object DB_Check2: TFDQuery
    Connection = DB_Connection
    SQL.Strings = (
      'SELECT * FROM clientes WHERE cpf = '#39'4877897410'#39)
    Left = 256
    Top = 104
  end
  object DB_Check3: TFDQuery
    Connection = DB_Connection
    SQL.Strings = (
      'SELECT * FROM clientes WHERE cpf = '#39'4877897410'#39)
    Left = 256
    Top = 88
  end
  object Timer_12h: TTimer
    Interval = 21600000
    OnTimer = Timer_12hTimer
    Left = 72
    Top = 144
  end
  object DB_Listas: TFDQuery
    Connection = DB_Connection
    SQL.Strings = (
      'SELECT * FROM clientes WHERE cpf = '#39'4877897410'#39)
    Left = 16
    Top = 144
  end
  object Lista_Temp: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 16
    Top = 160
    object Lista_TempID: TIntegerField
      FieldName = 'ID'
    end
    object Lista_TempID_BANCO: TIntegerField
      FieldName = 'ID_BANCO'
    end
    object Lista_TempNOME: TStringField
      FieldName = 'NOME'
      Size = 128
    end
    object Lista_TempTIPOEMAIL: TIntegerField
      FieldName = 'TIPOEMAIL'
    end
    object Lista_TempDIASVENC: TIntegerField
      FieldName = 'DIASVENC'
    end
    object Lista_TempHORADISPARO: TTimeField
      FieldName = 'HORADISPARO'
    end
    object Lista_TempMENSAGEM: TBlobField
      FieldName = 'MENSAGEM'
      Size = 512
    end
    object Lista_TempTIPOCAMPANHA: TStringField
      FieldName = 'TIPOCAMPANHA'
      Size = 8
    end
    object Lista_TempENVIADO: TSmallintField
      FieldName = 'ENVIADO'
    end
  end
  object Lista_Source: TDataSource
    DataSet = Lista_Temp
    Left = 16
    Top = 176
  end
  object Timer_10m: TTimer
    Interval = 600000
    OnTimer = Timer_10mTimer
    Left = 128
    Top = 136
  end
  object DB_Ops: TFDQuery
    Connection = DB_Connection
    SQL.Strings = (
      'SELECT * FROM clientes WHERE cpf = '#39'4877897410'#39)
    Left = 128
    Top = 152
  end
  object NetHTTPClient1: TNetHTTPClient
    AllowCookies = True
    HandleRedirects = True
    UserAgent = 'Embarcadero URI Client/1.0'
    Left = 344
    Top = 24
  end
  object DB_Banco: TFDQuery
    Connection = DB_Connection
    SQL.Strings = (
      'SELECT * FROM clientes WHERE cpf = '#39'4877897410'#39)
    Left = 128
    Top = 168
  end
end
