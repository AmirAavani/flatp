unit SchemaParserUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SchemaDefinitionUnit;

type

  { TBaseSchemaParser }

  TBaseSchemaParser = class(TObject)
  private
    InputFilename: AnsiString;

  public
    class function GetParser(_InputFilename: AnsiString): TBaseSchemaParser;
    class function Parse(_InputFilename: AnsiString): TSchema;
    class function ParseAll(_InputFilename: AnsiString): TSchemaMap;

    function ParseSchema: TSchema; virtual; abstract;
    destructor Destroy; override;
  end;

implementation
uses
  Generics.Collections, ALoggerUnit, PathHelperUnit, StringUnit, CollectionUnit;

type
  TIntList = specialize TList<Integer>;

type
  TTokenKind = (ttkStart, ttkDot, ttkOpenBrace, ttkCloseBrace, ttkOpenPar,
    ttkClosePar, ttkSemiColon, ttkEqualSign, ttkStar,
    ttkColon, ttkComma, ttkDoubleQuote, ttkSingleQuote,
    ttkMinus, ttkPlus, ttkQuestionMark, ttkLessThan, ttkGreaterThan, ttkOpenBracket,
      ttkCloseBracket, ttkAtSgin,
    ttkIdentifier, ttkComment, ttkNumber, ttkSpace, ttkSlash,
    ttkEndLine, ttkEOF);
  TCharKind = (tckStart, tckDot, tckOpenBrace, tckCloseBrace, tckOpenPar,
    tckClosePar, tckSemiColon, tckEqualSign, tckStar,
      tckColon, tckComma, tckDoubleQuote, tckSingleQuote,
      tckMinus, tckPlus, tckQuestionMark, tckLessThan, tckGreaterThan, tckOpenBracket,
      tckCloseBracket, tckAtSgin,

      tckLetter, tckDigit,  tckUnderline, tckSpace, tckSlash, tckBackSlash, tckNumberSign,
      tckExclamationMark,
      tckEndLine, tckEoF);
  { TToken }
  TToken = record
    Kind: TTokenKind;
    TokenString: AnsiString;
         // class operator +(a,b : TToken) : TToken;
  end;

type

  { ENotImplementedYet }

  ENotImplementedYet = class(Exception)
  public
    constructor Create;

  end;

  { EInvalidCharacter }

  EInvalidCharacter = class(Exception)
  public
    constructor Create(Ch: Char; Code: Integer);

  end;

  { EInvalidToken }

  EInvalidToken = class(Exception)
  public
    constructor Create(Actual: TToken; Expected: AnsiString);
    constructor Create(Actual: TToken; Expected: TTokenKind);

  end;

  EParseIntFailed = class(Exception)

  end;

  { EExpectFailed }

  EExpectFailed = class(Exception)
  public
    constructor Create(constref S: AnsiString);
    constructor Create(constref Expected, Actual: AnsiString);
    constructor Create(Expected, Actual: TTokenKind);

  end;

  { TTokenizer }

  TTokenizer = class(TObject)
  private
    Current: Integer;
    Currents: TIntList;
    FileSize: Integer;
    WholeFile: AnsiString;
    Stream: TStream;

    procedure ExpectAll(const TokenStrs: array of AnsiString);
    procedure Expect(const TokenStr: AnsiString);
    procedure ExpectAll(Ts: array of TTokenKind);
    procedure ExpectOne(Ts: array of TTokenKind);
    procedure Expect(const TokenKind: TTokenKind);
    procedure Expect(const Token: TToken; TokenKind: TTokenKind);

    function NextTokenIsIn(Ts: array of TTokenKind): Boolean;
    function NextTokenIsIn(Ts: array of AnsiString): Boolean;
  public
    constructor Create(_Stream: TStream);
    destructor Destroy; override;

    function GetNextToken: TToken;
    procedure Rewind(Count: Integer = 1);

  end;


  { TTokenArray }

  TTokenArray = class(specialize TList<TToken>)
  public
    procedure AddToken(aToken: TToken);

  end;

  { TSchemaParser }

  TSchemaParser = class(TBaseSchemaParser)
  private
    function ParseInclude: AnsiString;
    function ParseNamespace: AnsiString;
    function ParseTable: TSchema.TTable;
    function ParseStruct: TSchema.TStruct;
    function ParseTableField: TSchema.TField;
    function ParseStructField: TSchema.TField;
    function ParseType: TSchema.TBaseType;
    function ParseMetadata: TSchema.TMetadata;
    function ParseIdentifier: TSchema.TIdentifier;
    function ParseInteger: Integer;

  protected
    FTokenizer: TTokenizer;

    function CollectUntil(EndTokenKind: TTokenKind): TTokenArray;

    property Tokenizer: TTokenizer read FTokenizer;

  public
    constructor Create(_Tokenizer: TTokenizer);
    destructor Destroy; override;

    function ParseSchema: TSchema; override;
    function ParseEnum: TSchema.TEnum;

  end;

{ ENotImplementedYet }

constructor ENotImplementedYet.Create;
begin
  inherited Create('Not Implemented Yet!');

end;

{ EExpectFailed }

constructor EExpectFailed.Create(constref S: AnsiString);
begin
  inherited Create(S);

end;

constructor EExpectFailed.Create(constref Expected, Actual: AnsiString);
begin
  inherited Create(Format('Expected "%s" Visited "%s".',
      [Expected, Actual]));

end;

constructor EExpectFailed.Create(Expected, Actual: TTokenKind);
begin
  inherited Create(Format('Expected "%d" Visited "%d".',
      [Ord(Expected), Ord(Actual)]));

end;

{ TSchemaParser }

function TSchemaParser.ParseInclude: AnsiString;
// include = include string_constant ;
var
  Token: TToken;

begin
  Tokenizer.Expect(ttkDoubleQuote);
  Token := Tokenizer.GetNextToken;

  Result := '';
  while Token.Kind <> ttkDoubleQuote do
  begin
    Result += Token.TokenString;

  end;

end;

function TSchemaParser.ParseNamespace: AnsiString;
// namespace_decl = namespace ident ( . ident )* ;
var
  Token: TToken;

begin
  Token := Tokenizer.GetNextToken;
  if Token.Kind <> ttkIdentifier then
    raise EExpectFailed.Create(ttkIdentifier, Token.Kind);

  Result := Token.TokenString;
  Token := Tokenizer.GetNextToken;
  while Token.Kind = ttkDot do
  begin
    Result += '.';
    Token := Tokenizer.GetNextToken;
    if Token.Kind <> ttkIdentifier then
      raise EExpectFailed.Create(ttkIdentifier, Token.Kind);
    Result += Token.TokenString;
    Token := Tokenizer.GetNextToken;

  end;
  Tokenizer.Rewind;
  Tokenizer.Expect(ttkSemiColon);

end;

function TSchemaParser.ParseTable: TSchema.TTable;
var
  Token: TToken;

begin
  Token := Tokenizer.GetNextToken;
  if Token.Kind <> ttkIdentifier then
    raise EInvalidToken.Create(Token, ttkIdentifier);

  Result := TSchema.TTable.Create(Token.TokenString);

  Tokenizer.Expect(ttkOpenBrace);

  Token := Tokenizer.GetNextToken;
  while Token.Kind <> ttkCloseBrace do
  begin
    Tokenizer.Rewind;

    Result.Fields.Add(ParseTableField);

    Token := Tokenizer.GetNextToken;

  end;

  Tokenizer.Rewind;
  Tokenizer.Expect(ttkCloseBrace);

end;

function TSchemaParser.ParseStruct: TSchema.TStruct;
var
  Token: TToken;

begin
  Token := Tokenizer.GetNextToken;
  if Token.Kind <> ttkIdentifier then
    raise EInvalidToken.Create(Token, ttkIdentifier);

  Result := TSchema.TStruct.Create(Token.TokenString);

  Tokenizer.Expect(ttkOpenBrace);

  Token := Tokenizer.GetNextToken;
  while Token.Kind <> ttkCloseBrace do
  begin
    Tokenizer.Rewind;

    Result.Fields.Add(ParseStructField);

    Token := Tokenizer.GetNextToken;

  end;

  Tokenizer.Rewind;
  Tokenizer.Expect(ttkCloseBrace);

end;

function TSchemaParser.ParseTableField: TSchema.TField;
var
  aName: TSchema.TIdentifier;
  aType: TSchema.TBaseType;
  aScaler: Integer;
  aMetadata: TSchema.TMetadata;
  Token: TToken;

begin
  aScaler := -1;
  Token := Tokenizer.GetNextToken;
  if Token.Kind <> ttkIdentifier then
    raise EInvalidToken.Create(Token, ttkIdentifier);
  aName := Token.TokenString;

  Tokenizer.Expect(ttkColon);
  aType := ParseType;
  Token := Tokenizer.GetNextToken;
  if Token.Kind = ttkOpenPar then
  begin
    while Token.Kind <> ttkClosePar do
    begin
      Token := Tokenizer.GetNextToken;

    end;
    aMetadata := ParseMetadata;
    Tokenizer.Expect(ttkSemiColon);
  end
  else if Token.Kind = ttkEqualSign then
  begin
    raise ENotImplementedYet.Create;

  end
  else if Token.Kind = ttkSemiColon then
  else
    EInvalidToken.Create(Token, '( or =');


  Result := TSchema.TField.Create(aName, aType, aScaler, aMetadata);

end;

function TSchemaParser.ParseStructField: TSchema.TField;
var
  aName: TSchema.TIdentifier;
  aType: TSchema.TBaseType;
  aScaler: Integer;
  aMetadata: TSchema.TMetadata;
  Token: TToken;

begin
  Token := Tokenizer.GetNextToken;
  Tokenizer.Expect(Token, ttkIdentifier);

  aName := Token.TokenString;

  Tokenizer.Expect(ttkColon);
  aType := ParseType;
  aMetadata := ParseMetadata;
  Tokenizer.Expect(ttkSemiColon);

  Result := TSchema.TField.Create(aName, aType, aScaler, aMetadata);

end;

function TSchemaParser.ParseType: TSchema.TBaseType;
// type = bool | byte | ubyte | short | ushort | int | uint | float | long | ulong | double | int8 | uint8 | int16 | uint16 | int32 | uint32| int64 | uint64 | float32 | float64 | string | [ type ] | ident
var
  Token: TToken;

begin
  Result := nil;
  Token := Tokenizer.GetNextToken;
  if Token.Kind = ttkOpenBracket then
  begin
    Token := Tokenizer.GetNextToken;
    if Token.Kind <> ttkCloseBracket then
    begin
      Tokenizer.Rewind;
      Result := TSchema.TArrayType.Create(Self.ParseType);
      Tokenizer.Expect(ttkCloseBracket);

    end;

  end
  else
  begin
    if (Token.TokenString = 'bool') or (Token.TokenString = 'byte') or (Token.TokenString =  'ubyte')
    or (Token.TokenString =  'short') or (Token.TokenString =  'ushort') or (Token.TokenString =  'int') or (Token.TokenString =
    'uint') or (Token.TokenString =  'float') or (Token.TokenString =  'long') or (Token.TokenString =  'ulong')
    or (Token.TokenString =  'double') or (Token.TokenString =  'int8') or (Token.TokenString =  'uint8')
    or (Token.TokenString =  'int16') or (Token.TokenString =  'uint16') or
    (Token.TokenString = 'int32') or (Token.TokenString =  'uint32') or (Token.TokenString =  'int64')
    or (Token.TokenString =  'uint64') or (Token.TokenString =  'float32') or
    (Token.TokenString =  'float64') or (Token.TokenString =  'string') then
      Result := TSchema.TBaiscType.Create(Token.TokenString)
    else if Token.Kind = ttkIdentifier then
      Result := TSchema.TIdentType.Create(Token.TokenString)
    else
      raise EInvalidToken.Create(Token, ttkIdentifier);

  end;
end;

function TSchemaParser.ParseMetadata: TSchema.TMetadata;
begin
  Result := nil;
end;

function TSchemaParser.ParseIdentifier: TSchema.TIdentifier;
var
  Token: TToken;

begin
  Token := Tokenizer.GetNextToken;

  Tokenizer.Expect(Token, ttkIdentifier);
  Result := Token.TokenString;

end;

function TSchemaParser.ParseInteger: Integer;
var
  Token: TToken;

begin
  Token := Tokenizer.GetNextToken;
  if Token.Kind <> ttkNumber then
    raise EInvalidToken.Create(Token, ttkNumber);

  Result := StrToInt(token.TokenString);

end;

function TSchemaParser.CollectUntil(EndTokenKind: TTokenKind): TTokenArray;
var
  CurToken: TToken;

begin
  CurToken := Tokenizer.GetNextToken;

  Result := TTokenArray.Create;
  while CurToken.Kind <> EndTokenKind do
  begin
    Result.AddToken(CurToken);

    CurToken := Tokenizer.GetNextToken;
  end;
end;

constructor TSchemaParser.Create(_Tokenizer: TTokenizer);
begin
  inherited Create;

  FTokenizer := _Tokenizer;

end;

destructor TSchemaParser.Destroy;
begin
  FTokenizer.Free;

  inherited Destroy;
end;

function TSchemaParser.ParseSchema: TSchema;
// schema = include* ( namespace_decl | type_decl | enum_decl | root_decl | file_extension_decl | file_identifier_decl | attribute_decl | rpc_decl | object )*
var
  Token: TToken;
  Includes: TSchema.TIncludes;
  OtherParams: TAnsiStrings;
  Namespace: TSchema.TIdentifier;
  Enums: TSchema.TEnums;
  Tables: TSchema.TTables;
  Structs: TSchema.TStructs;
  RootType: TSchema.TIdentifier;
  Attributes: TSchema.TAttributes;

begin
  Includes := TSchema.TIncludes.Create;
  OtherParams := TAnsiStrings.Create;
  Enums := TSchema.TEnums.Create;
  Tables := TSchema.TTables.Create;
  Structs := TSchema.TStructs.Create;
  Attributes := TSchema.TAttributes.Create;

  OtherParams.Add('InputSchemaFilename:' + InputFilename);
  Token := Tokenizer.GetNextToken;
  while Token.TokenString = 'include' do
  begin
    Includes.Add(ParseInclude);
    Token := Tokenizer.GetNextToken;

  end;

  while Token.Kind <> ttkEOF do
  begin
    if Token.TokenString = 'namespace' then
      Namespace := ParseNamespace
    else if Token.TokenString = 'enum' then
      Enums.Add(ParseEnum)
    else if Token.TokenString = 'table' then
      Tables.Add(ParseTable)
    else if Token.TokenString = 'struct' then
      Structs.Add(ParseStruct)
    else if Token.TokenString = 'root_type' then
    begin
      Token := Tokenizer.GetNextToken;
      if Token.Kind <> ttkIdentifier then
        raise EInvalidToken.Create(token, ttkIdentifier);
      RootType := Token.TokenString;
      Tokenizer.Expect(ttkSemiColon);

    end
    else if Token.TokenString = 'attribute' then
    begin
      Token := Tokenizer.GetNextToken;
      if Token.Kind = ttkDoubleQuote then
      begin
        Attributes.Add(ParseIdentifier);
        Tokenizer.Expect(ttkDoubleQuote);

      end
      else
      begin
        Tokenizer.Rewind;
        Attributes.Add(ParseIdentifier);

      end;
      Tokenizer.Expect(ttkSemiColon);

    end
    else
      raise Exception.Create(Format('Invalid token: %s', [Token.TokenString]));
    Token := Tokenizer.GetNextToken;

  end;

  Result := TSchema.Create(
    Includes,
    OtherParams,
    Namespace,
    Enums,
    Tables,
    Structs,
    RootType,
    Attributes
  );

end;

function TSchemaParser.ParseEnum: TSchema.TEnum;
var
  Name, vName: TSchema.TIdentifier;
  EnumType: TSchema.TBaseType;
  Metadata: TSchema.TMetadata;
  Token: TToken;
  Values: TSchema.TEnum.TValues;
  vIntValue: Integer;

begin
  Name := ParseIdentifier;
  Tokenizer.Expect(ttkColon);
  EnumType := ParseType;
  Metadata := ParseMetadata;
  Values := TSchema.TEnum.TValues.Create;

  Tokenizer.Expect(ttkOpenBrace);

  Token := Tokenizer.GetNextToken;
  while Token.Kind <> ttkCloseBrace do
  begin
    if token.Kind <> ttkIdentifier then
      raise EInvalidToken.Create(Token, ttkIdentifier);

    vName := Token.TokenString;
    Token := Tokenizer.GetNextToken;
    if Token.Kind = ttkEqualSign then
    begin
      vIntValue := ParseInteger;
      Values.Add(TSchema.TEnum.TValue.Create(vName, vIntValue));
      Token := Tokenizer.GetNextToken;

    end
    else
    begin
      Values.Add(TSchema.TEnum.TValue.Create(vName));

    end;
    if Token.Kind = ttkComma then
      Token := Tokenizer.GetNextToken;

  end;

  Result := TSchema.TEnum.Create(Name, EnumType, Values);

end;

{ TTokenArray }

procedure TTokenArray.AddToken(aToken: TToken);
begin
  Self.Add(aToken);

end;

constructor EInvalidToken.Create(Actual: TToken; Expected: AnsiString);
begin
  inherited Create(Format('Unexpected Token Visited [Actual: %s, Expected: %s]', [Actual.TokenString, Expected]))

end;

constructor EInvalidToken.Create(Actual: TToken; Expected: TTokenKind);
begin
  inherited Create(Format('Unexpected Token Visited [Actual: %d, Expected: %d]', [Ord(Actual.Kind), Ord(Expected)]))

end;

procedure TTokenizer.ExpectAll(const TokenStrs: array of AnsiString);
var
  TokenStr: AnsiString;

begin
  for TokenStr in TokenStrs do
    Self.Expect(TokenStr)

end;

procedure TTokenizer.Expect(const TokenStr: AnsiString);
var
  Token: TToken;

begin
  Token := GetNextToken;

  if Token.TokenString <> TokenStr then
    raise EExpectFailed.Create(Format('Expected "%s" Visited "%s".',
      [Token.TokenString, TokenStr]));

end;

procedure TTokenizer.ExpectAll(Ts: array of TTokenKind);
var
  TokenKind: TTokenKind;

begin
  for TokenKind in Ts do
    Self.Expect(TokenKind);

end;

procedure TTokenizer.ExpectOne(Ts: array of TTokenKind);
var
  Token: TToken;
  Kind: TTokenKind;
  Found: Boolean;

begin
  Token := GetNextToken;
  Found := False;
  for Kind in Ts do
    Found := Found or (Token.Kind = Kind);

  if not Found then
    raise EExpectFailed.Create(Format('Expected "%d" Visited "%d".',
              [Ord(Token.Kind), Ord(Ts[0])]));
end;

procedure TTokenizer.Expect(const TokenKind: TTokenKind);
var
  Token: TToken;

begin
  Token := GetNextToken;
  if Token.Kind <> TokenKind then
    raise EExpectFailed.Create(Format('Expected "%d" Visited "%d".',
      [Token.Kind, TokenKind]));
end;

procedure TTokenizer.Expect(const Token: TToken; TokenKind: TTokenKind);
begin
  if Token.Kind <> TokenKind then
    raise EInvalidToken.Create(Token, ttkIdentifier);

end;

function TTokenizer.NextTokenIsIn(Ts: array of TTokenKind): Boolean;
var
  Next: TToken;
  Kind: TTokenKind;

begin
  Next := GetNextToken;
  Rewind;

  for Kind in Ts do
    if Next.Kind = Kind then
      Exit(True);

  Result := False;
end;

function TTokenizer.NextTokenIsIn(Ts: array of AnsiString): Boolean;
var
  Next: TToken;
  S: AnsiString;

begin
  Next := GetNextToken;

  for S in Ts do
    if Next.TokenString = S then
    begin
      Rewind(1);
      Exit(True);

    end;

  Rewind(1);
  Result := False;
end;

constructor TTokenizer.Create(_Stream: TStream);
begin
  inherited Create;

  Stream := _Stream;
  Stream.Position := 0;
  SetLength(WholeFile, Stream.Size);
  Stream.ReadBuffer(WholeFile[1], Stream.Size);
  FileSize := Stream.Size;
  Currents := TIntList.Create;
  Current := 1;
  Currents.Add(Current);

end;

destructor TTokenizer.Destroy;
begin
  Currents.Free;
  Stream.Free;

  inherited Destroy;
end;

type
  TChar = record
    Kind: TCharKind;
    Ch: Char;
  end;

function TTokenizer.GetNextToken: TToken;

  function GetNextChar: TChar;
  begin
    if Length(WholeFile) < Current then
    begin
      Result.Kind := tckEoF;
      Exit;
    end;
    Result.Ch := WholeFile[Current];
    Inc(Current);

    case Result.Ch of
    '0'..'9': Result.Kind := tckDigit;
    'a'..'z': Result.Kind := tckLetter;
    'A'..'Z': Result.Kind := tckLetter;
    ' ': Result.Kind := tckSpace;
     #10, #13: Result.Kind := tckEndLine;
    '(': Result.Kind := tckOpenPar;
    ')': Result.Kind := tckClosePar;
    '{': Result.Kind := tckOpenBrace;
    '}': Result.Kind := tckCloseBrace;
    '=': Result.Kind := tckEqualSign;
    '*': Result.Kind := tckStar;
    ':': Result.Kind := tckColon;
    ',': Result.Kind := tckComma;
    '"': Result.Kind := tckDoubleQuote;
    ';': Result.Kind := tckSemiColon;
    '.': Result.Kind := tckDot;
    '_': Result.Kind := tckUnderline;
    '-': Result.Kind := tckMinus;
    '/': Result.Kind := tckSlash;
    '?': Result.Kind := tckQuestionMark;
    Chr(39): Result.Kind := tckSingleQuote;
    '<': Result.Kind := tckLessThan;
    '>': Result.Kind := tckGreaterThan;
    '[': Result.Kind := tckOpenBracket;
    ']': Result.Kind := tckCloseBracket;
    '#': Result.Kind := tckNumberSign;
    '!': Result.Kind := tckExclamationMark;
    '@': Result.Kind := tckAtSgin;
    '+': Result.Kind := tckPlus
    else
      FatalLn(Result.ch + ' ' + IntToStr(Ord(Result.Ch)));
      raise EInvalidCharacter.Create(Result.ch, Ord(Result.Ch));
    end;

  end;

  type
    TCharKindSet = set of TCharKind;

    function NextCharIs(ChSet: TCharKindSet): Boolean;
    var
      StartPos: Integer;
      Ch: TCharKind;
      NextChar: TChar;

    begin
      StartPos := Current;

      for Ch in ChSet do
      begin
        NextChar := GetNextChar;
        if (NextChar.Kind = tckEoF) or (NextChar.Kind <> Ch) then
        begin
          Current := StartPos;
          Exit(False);
        end;

      end;

      Current := StartPos;
      Result := True;
    end;

var
  CurrentChar: TChar;

begin
  Result.TokenString := '';
  Result.Kind:= ttkStart;
  CurrentChar := GetNextChar;

  case CurrentChar.Kind of
    tckLetter, tckUnderline:
    begin
      while CurrentChar.Kind in [tckLetter, tckDigit, tckUnderline] do
      begin
        Result.TokenString += CurrentChar.Ch;
        CurrentChar := GetNextChar;
      end;
      Dec(Current);
      Result.Kind:= ttkIdentifier;
    end;
    tckDigit:
    begin
      while CurrentChar.Kind = tckDigit do
      begin
        Result.TokenString += CurrentChar.Ch;
        CurrentChar := GetNextChar;
      end;
      Dec(Current);
      Result.Kind:= ttkNumber;
    end;
    tckDot, tckOpenBrace,
      tckCloseBrace, tckOpenPar, tckClosePar, tckSemiColon, tckEqualSign,
      tckColon, tckComma, tckDoubleQuote, tckSingleQuote,
      tckMinus, tckQuestionMark, tckLessThan, tckGreaterThan, tckOpenBracket,
      tckCloseBracket, tckAtSgin:
    begin
      Result.TokenString += CurrentChar.Ch;
      Result.Kind := TTokenKind(Ord(CurrentChar.Kind));
    end;
    tckSpace:
    begin
      while CurrentChar.Kind in [tckSpace] do
      begin
        Result.TokenString += CurrentChar.Ch;
        CurrentChar := GetNextChar;
      end;
      Dec(Current);
      Result.Kind:= ttkSpace;

      Result := Self.GetNextToken;
      Exit;
    end;
    tckEndLine:
    begin
      Result.TokenString += CurrentChar.Ch;
      Result.Kind := ttkEndLine;
      CurrentChar := GetNextChar;
      while CurrentChar.Kind = tckEndLine do
      begin
        Result.TokenString += CurrentChar.Ch;
        CurrentChar := GetNextChar;
      end;
      Dec(Current);
      if CurrentChar.Kind = tckEoF then
      begin
        Result.Kind:= ttkEOF;
        Exit;
      end;
      Result := Self.GetNextToken;
      Exit;
    end;
    tckEoF:
      Result.Kind := ttkEOF;
    tckSlash:
    begin
      Result.TokenString += CurrentChar.Ch;
      Result.Kind := ttkSlash;

      if NextCharIs([tckSlash]) then
      begin
        CurrentChar := GetNextChar;
        Result.TokenString += CurrentChar.Ch;
        Result.Kind := ttkComment;
        CurrentChar := GetNextChar;
        while not (CurrentChar.Kind in [tckEndLine, tckEoF]) do
        begin
          Result.TokenString += CurrentChar.Ch;
          CurrentChar := GetNextChar;
        end;
        Result := Self.GetNextToken;
        Exit;
      end
      else if NextCharIs([tckStar]) then
      begin
        CurrentChar := GetNextChar;
        Result.TokenString += CurrentChar.Ch;
        Result.Kind := ttkComment;

        while not NextCharIs([tckStar, tckSlash]) do
        begin
          Result.TokenString += CurrentChar.Ch;
          CurrentChar := GetNextChar;
        end;
        Result.TokenString += GetNextChar.Ch;
        Result.TokenString += GetNextChar.Ch;

        Result := Self.GetNextToken;
        Exit;
      end;

    end
    else
    begin
      FatalLn(CurrentChar.ch + ' Ch:' + IntToStr(Ord(CurrentChar.Ch)) +
        ' Kind:' + IntToStr(Ord(CurrentChar.Kind)) +
        ' Result:' + Result.TokenString);
      raise Exception.Create(CurrentChar.ch + ' ' + IntToStr(Ord(CurrentChar.Ch)) +
        ' Result:' + Result.TokenString);
    end;
  end;

  Currents.Add(Current);
 end;

procedure TTokenizer.Rewind(Count: Integer);
begin
  Currents.Count := Currents.Count - Count;
  Current := Currents.Last;

end;

constructor EInvalidCharacter.Create(Ch: Char; Code: Integer);
begin
  inherited Create(Format('Invalid Character %s (%d)', [Ch, Code]));
end;

{ TBaseSchemaParser }

class function TBaseSchemaParser.GetParser(_InputFilename: AnsiString
  ): TBaseSchemaParser;
var
  InputStream: TFileStream;
  Tokenizer: TTokenizer;

begin
  InputStream := TFileStream.Create(_InputFilename, fmOpenRead);
  Tokenizer := TTokenizer.Create(InputStream);

  Result := TSchemaParser.Create(Tokenizer);
  Result.InputFilename := _InputFilename;

end;

class function TBaseSchemaParser.Parse(_InputFilename: AnsiString): TSchema;
var
  Parser: TBaseSchemaParser;

begin
  Parser := TBaseSchemaParser.GetParser(_InputFilename);

  Result := Parser.ParseSchema;

  Parser.Free;

end;

class function TBaseSchemaParser.ParseAll(_InputFilename: AnsiString
  ): TSchemaMap;

  procedure RecParse(FilePath, SchemaFile: AnsiString; SchemaMap: TSchemaMap);
  var
    Schema: TSchema;
    Include: AnsiString;

  begin
    FMTDebugLn('Parsing %s', [JoinPath(FilePath, SchemaFile)]);

    Schema := TBaseSchemaParser.Parse(JoinPath(FilePath, SchemaFile));
    SchemaMap.Add(JoinPath(FilePath, SchemaFile), Schema);

    for Include in Schema.Includes do
      if SchemaMap.Find(JoinPath(FilePath, Include)) = nil then
        RecParse(FilePath, Include, SchemaMap);
  end;

var
  Filename: AnsiString;

begin
  Result := TSchemaMap.Create;
  Filename:= _InputFilename;
  if not IsPrefix('./', _InputFilename) and not IsPrefix('/', _InputFilename) then
    Filename := './' + _InputFilename;

  RecParse(ExtractFilePath(Filename), ExtractFileName(Filename), Result);

end;

destructor TBaseSchemaParser.Destroy;
begin
  inherited Destroy;
end;

end.

