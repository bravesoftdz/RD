unit unCampo;

interface

uses
  unClasseBasica, ZDataset, DB, DBClient;

  type TCampo = class(TBasica)
    private
      FsNome: String;
      FoQryTiposCampos: TZQuery;
      FoCdsTiposCampos: TClientDataSet;
      FoFieldCodigoUsuario: TField;
      FoFieldCodigoTipoCampo: TField;
      FoFieldNome: TField;
      FoFieldDescTipoCampo: TField;
      FoFieldCdsTiposCamposDescricao: TField;

      function GetNome: String;
      procedure SetNome(const psNome: String);
    protected
      function Atualizar: Boolean; override;
      function Inserir: Boolean; override;
      procedure DefinirComponentesAcessoDados; override;
      procedure DefinirFieldsAcessoDados; override;
      procedure DefinirComponentesDadosParaNil; override;
      function ValidarFieldsAtivos: Boolean; override;
    public
      property prpNome: String read GetNome write SetNome;

      constructor Create;
      destructor Destroy; override;
      procedure Limpar; override;
      function Editar: Boolean; override;
      function Novo: Boolean; override;
      function Salvar: Boolean; override;
      function Deletar(const piCodigo: Integer): Boolean; override;
      procedure DeletarCdsDados; override;
      procedure Cancelar; override;
      procedure CarregarCamposParaCadastro;
      procedure DefinirDescricaoTipoCampo;
  end;

implementation

uses
  unConstantes, unDM, unUsuarioSingleton;

{ TCampo }

constructor TCampo.Create;
begin
  inherited;
end;

destructor TCampo.Destroy;
begin
  inherited;
end;

function TCampo.GetNome: String;
begin
  Result := FsNome;
end;

procedure TCampo.SetNome(const psNome: String);
begin
  FsNome := psNome;
end;

procedure TCampo.Limpar;
begin
  inherited;
  prpNome := sSTRING_INDEFINIDO;
end;

function TCampo.Editar: Boolean;
begin
  Result := False;
  if not(ValidarCdsDadosEstahAtivo) then
    Exit;

  FoCdsDados.Edit;
  Result := True;
end;

function TCampo.Novo: Boolean;
begin
  Result := False;
  if not(ValidarCdsDadosEstahAtivo) then
    Exit;

  FoCdsDados.Append;
  Result := True;
end;

function TCampo.Salvar: Boolean;
begin
  Result := inherited Salvar;

  if not(Result) then
    Exit;

  IniciarTransacao;
  try
    try
      FoCdsDados.First;
      while not(FoCdsDados.Eof) do
      begin
        if (FoFieldCodigo.AsInteger = nNUMERO_INDEFINIDO) then
          Result := Inserir
        else
          Result := Atualizar;

        if not(Result) then
        begin
          prpMensagem := sMSG_OCORREU_ERRO_SALVAR_CAMPOS_DO_USUARIO;
          Exit;
        end;

        FoCdsDados.Next;
      end;
    finally
      if not(Result) then
        RollbackTransacao
      else
        ComitarTransacao;
    end;
  except
    prpMensagem := sMSG_OCORREU_ERRO_SALVAR_CAMPOS_DO_USUARIO;
    RollbackTransacao;
  end;

  Result := True;
end;

function TCampo.Deletar(const piCodigo: Integer): Boolean;
begin
  Result := False;
  try
    IniciarTransacao;

    //xxxxx - deletar todos os contatos campos

    FoQryExecutar.Close;
    FoQryExecutar.SQL.Clear;
    FoQryExecutar.SQL.Add('DELETE FROM campos ');
    FoQryExecutar.SQL.Add('WHERE codigo = :pCodigo');
    FoQryExecutar.ParamByName('pCodigo').AsInteger := piCodigo;
    FoQryExecutar.ExecSQL;

    ComitarTransacao;
    Result := True;
  except
    prpMensagem := sMSG_OCORREU_ERRO_DELETAR_CAMPO_DO_USUARIO;
    RollbackTransacao;
  end;
end;

procedure TCampo.DeletarCdsDados;
begin
  if not(ValidarCdsDadosEstahAtivo) then
    Exit;

  FoCdsDados.Delete;
end;

procedure TCampo.Cancelar;
begin
  FoCdsDados.Cancel;
end;

function TCampo.Atualizar: Boolean;
begin
  Result := False;
  FoQryExecutar.Close;
  FoQryExecutar.SQL.Clear;
  FoQryExecutar.SQL.Add('UPDATE campos ');
  FoQryExecutar.SQL.Add('SET codigo_tipo_campo = :pCodigoTipoCampo, nome = :pNome ');
  FoQryExecutar.SQL.Add('WHERE codigo = :pCodigo');
  FoQryExecutar.ParamByName('pCodigoTipoCampo').AsInteger := FoFieldCodigoTipoCampo.AsInteger;
  FoQryExecutar.ParamByName('pNome').AsString := FoFieldNome.AsString;
  FoQryExecutar.ParamByName('pCodigo').AsInteger := FoFieldCodigo.AsInteger;
  FoQryExecutar.ExecSQL;
  Result := True;
end;

function TCampo.Inserir: Boolean;
begin
  Result := False;
  FoQryExecutar.Close;
  FoQryExecutar.SQL.Clear;
  FoQryExecutar.SQL.Add('INSERT INTO campos (codigo_usuario, codigo_tipo_campo, nome) ');
  FoQryExecutar.SQL.Add('VALUES (:pCodigoUsuario, :pCodigoTipoCampo, :pNome)');
  FoQryExecutar.ParamByName('pCodigoUsuario').AsInteger := FoFieldCodigoUsuario.AsInteger;
  FoQryExecutar.ParamByName('pCodigoTipoCampo').AsInteger := FoFieldCodigoTipoCampo.AsInteger;
  FoQryExecutar.ParamByName('pNome').AsString := FoFieldNome.AsString;
  FoQryExecutar.ExecSQL;
  Result := True;
end;

procedure TCampo.DefinirComponentesAcessoDados;
begin
  inherited;
  FoQryDados := DM.qryCampos;
  FoDspDados := DM.dspCampos;
  FoCdsDados := DM.cdsCampos;
  FoQryTiposCampos := DM.qryTiposCampos;
  FoCdsTiposCampos := DM.cdsTiposCampos;
end;

procedure TCampo.DefinirFieldsAcessoDados;
begin
  inherited;

  if not(ValidarCdsDadosEstahAtivo) then
    Exit;

  if (FoCdsDados.FindField(sFIELD_CAMPO_CODIGO_USUARIO) <> nil) then
    FoFieldCodigoUsuario := FoCdsDados.FindField(sFIELD_CAMPO_CODIGO_USUARIO);

  if (FoCdsDados.FindField(sFIELD_CAMPO_CODIGO_TIPO_CAMPO) <> nil)  then
    FoFieldCodigoTipoCampo := FoCdsDados.FindField(sFIELD_CAMPO_CODIGO_TIPO_CAMPO);

  if (FoCdsDados.FindField(sFIELD_CAMPO_NOME) <> nil)  then
    FoFieldNome := FoCdsDados.FindField(sFIELD_CAMPO_NOME);

  if (FoCdsDados.FindField(sFIELD_CAMPO_TIPO_CAMPO) <> nil)  then
    FoFieldDescTipoCampo := FoCdsDados.FindField(sFIELD_CAMPO_TIPO_CAMPO);

  if (FoCdsTiposCampos.FindField(sFIELD_TIPOS_CAMPOS_DESCRICAO) <> nil)  then
    FoFieldCdsTiposCamposDescricao := FoCdsTiposCampos.FindField(sFIELD_TIPOS_CAMPOS_DESCRICAO);
end;

procedure TCampo.DefinirComponentesDadosParaNil;
begin
  inherited;
  FoQryTiposCampos := nil;
  FoCdsTiposCampos := nil;
  FoFieldCodigoUsuario := nil;
  FoFieldCodigoTipoCampo := nil;
  FoFieldNome := nil;
end;

function TCampo.ValidarFieldsAtivos: Boolean;
begin
  Result := inherited ValidarFieldsAtivos;
  if not(Result) then
    Exit;

  Result := (Assigned(FoFieldCodigoUsuario)) and (Assigned(FoFieldCodigoTipoCampo))
    and (Assigned(FoFieldNome));
end;

procedure TCampo.CarregarCamposParaCadastro;
begin
  //carrega os campos
  FoCdsDados.Close;
  FoQryDados.Close;
  FoQryDados.SQL.Clear;
  FoQryDados.SQL.Add('SELECT C.codigo, C.codigo_usuario, C.codigo_tipo_campo, ');
  FoQryDados.SQL.Add('C.nome, TC.descricao AS "desc_tipo_campo", C.data_cadastro ');
  FoQryDados.SQL.Add('FROM campos C ');
  FoQryDados.SQL.Add('JOIN "TIPOS_ CAMPOS" TC ON C.codigo_tipo_campo = TC.codigo ');
  FoQryDados.SQL.Add('WHERE C.codigo_usuario = :pCodigoUsuario');
  FoQryDados.ParamByName('pCodigoUsuario').AsInteger := TUsuarioSingleton.ObterInstancia.prpCodigoUsuario;
  FoQryDados.Open;
  FoCdsDados.Open;

  //carrega os tipos de campos
  FoCdsTiposCampos.Close;
  FoQryTiposCampos.Close;
  FoQryTiposCampos.SQL.Clear;
  FoQryTiposCampos.SQL.Add('SELECT T.codigo, T.descricao ');
  FoQryTiposCampos.SQL.Add('FROM "TIPOS_ CAMPOS" T');
  FoQryTiposCampos.Open;
  FoCdsTiposCampos.Open;
end;

procedure TCampo.DefinirDescricaoTipoCampo;
begin
  if (not(Assigned(FoFieldDescTipoCampo))) or (not(Assigned(FoFieldCdsTiposCamposDescricao))) then
    Exit;

  if not (FoCdsDados.State in [dsEdit, dsInsert]) then
    Exit;

  FoFieldDescTipoCampo.AsString := FoFieldCdsTiposCamposDescricao.AsString;
end;

end.
