unit SchemaDefinitionUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, GenericCollectionUnit, CollectionUnit;

type
  { TCollectionWithToXML }

  { TObjectCollectionWithToXML }

  generic TObjectCollectionWithToXML<TData> = class(specialize TObjectCollection<TData>)
  protected
    function MyClassName: AnsiString; virtual; abstract;
  public
    function ToXML: AnsiString;

  end;

  { TSchema }

  TSchema = class(TObject)
  public type

    { TBaseSchemaObject }

    TBaseSchemaObject = class(TObject)
    public
      function ToXML: AnsiString; virtual;

    end;

    TMetadata = class(TBaseSchemaObject)
    public

    end;

    { TImports }

    TIncludes = class(TAnsiStrings)
    public
      function ToXML: AnsiString;

    end;

    TIdentifier = AnsiString;

    TBaseType = class(TBaseSchemaObject)
      FTypeName: AnsiString;

    end;

    { TBaiscType }

    TBaiscType = class(TBaseType)
    public
      constructor Create(ATypeName: AnsiString);

      function ToXML: AnsiString; override;

    end;

    { TIdentType }

    TIdentType = class(TBaseType)
      FIdentName: AnsiString;

    public
      constructor Create(AIdenName: AnsiString);
      function ToXML: AnsiString; override;

    end;

    { TArrayType }

    TArrayType = class(TBaseType)
    private
      FSubType: TBaseType;

    public
      constructor Create(aSubType: TBaseType);
      destructor Destroy; override;

      function ToXML: AnsiString; override;

    end;

    { TEnumField }

    TEnumField = class(TBaseSchemaObject)
    private
      FName: AnsiString;
      FValue: Integer;
      FHasValue: Boolean;

    public
      constructor Create(aName: TIdentifier);
      constructor Create(aName: TIdentifier; aValue: Integer);
    end;

    { TEnumFields }

    TEnumFields = class(specialize TObjectCollectionWithToXML<TEnumField>)
    protected
      function MyClassName: AnsiString; override;

    end;

    TEnum = class(TBaseSchemaObject)
    public type

      { TValue }

      TValue = class(TBaseSchemaObject)
      private
        HasIntValue: Boolean;
        FIntValue: Integer;
        FName: TIdentifier;

      public
        property Name: TIdentifier read FName;
        property IntValue: Integer read FIntValue;

        constructor Create(aName: TIdentifier; aIntValue: Integer);
        constructor Create(aName: TIdentifier);
      end;

      { TValues }

      TValues = class(specialize TObjectCollectionWithToXML<TValue>)
      protected
        function MyClassName: AnsiString; override;

      end;

    private
      FName: TIdentifier;
      FType: TBaseType;
      FValues: TValues;

    public
      constructor Create(constref aName: TIdentifier; aType: TBaseType; aValues: TValues);
      procedure AddAField(AField: TEnumField);

    end;

    { TEnums }

    TEnums = class(specialize TObjectCollectionWithToXML<TEnum>)
    protected
      function MyClassName: AnsiString; override;

    end;

    { TField }

    TField = class(TBaseSchemaObject)
    private
      FName: TIdentifier;
      FType: TSchema.TBaseType;
      FScaler: Integer;
      FMetaData: TMetadata;
      FIsDeprecated: Boolean;

    public
      property Name: TIdentifier read FName;
      property TheType: TSchema.TBaseType read FType;
      property Sclaer: Integer read FScaler;
      property MetaData: TMetadata read FMetaData;
      property IsDeprecated: Boolean read FIsDeprecated;

      constructor Create(constref aName: TIdentifier; aType: TBaseType; aScaler: Integer; aMetadata: TMetadata);
      destructor Destroy; override;

      function ToXML: AnsiString; override;
    end;

    { TFields }

    TFields = class(specialize TObjectCollectionWithToXML<TField>)
    protected
      function MyClassName: AnsiString; override;

    end;

    { TTable }

    TTable = class(TBaseSchemaObject)
    private
      FName: TIdentifier;
      FFields: TFields;
      function GetField(Index: Integer): TField;

    public
      property Fields: TFields read FFields;
      property Field[Index: Integer]: TField read GetField;

      constructor Create(constref aName: TIdentifier);
      destructor Destroy; override;

      function ToXML: AnsiString; override;

    end;

    { TTables }

    TTables = class(specialize TObjectCollectionWithToXML<TTable>)
    protected
      function MyClassName: AnsiString; override;

    end;

    { TStruct }

    TStruct = class(TBaseSchemaObject)
    private
      FName: TIdentifier;
      FFields: TFields;
      function GetField(Index: Integer): TField;

    public
      property Fields: TFields read FFields;
      property Field[Index: Integer]: TField read GetField;

      constructor Create(constref aName: TIdentifier);
      destructor Destroy; override;

      function ToXML: AnsiString; override;

    end;

    { TStructs }

    TStructs = class(specialize TObjectCollectionWithToXML<TStruct>)
    protected
      function MyClassName: AnsiString; override;

    end;

    TAttributes = specialize TCollection<TIdentifier>;

  private
    FIncludes: TIncludes;
    FOtherParams: TAnsiStrings;
    FNamespace: TIdentifier;
    FEnums: TEnums;
    FTables: TTables;
    FStructs: TStructs;
    FRootType: TIdentifier;
    FAttributes: TAttributes;

    function GetInputSchemaFilename: AnsiString;
    function GetValueFromOtherParams(ParamName: AnsiString): AnsiString;

  public
    property InputSchemaFilename: AnsiString read GetInputSchemaFilename;
    property Includes: TIncludes read FIncludes;


    constructor Create(AIncludes: TIncludes;
                       AOtherParams: TAnsiStrings;
                       ANamespace: TIdentifier;
                       AEnums: TEnums;
                       ATables: TTables;
                       AStructs: TStructs;
                       ARootType: TIdentifier;
                       AAttributes: TAttributes);
    destructor Destroy; override;

    function ToXML: AnsiString;
  end;

  TSchemaMap = specialize TMapSimpleKeyObjectValue<AnsiString, TSchema>;

implementation

uses
  StringUnit, ALoggerUnit;

{ TSchema.TStructs }

function TSchema.TStructs.MyClassName: AnsiString;
begin
  Result := 'TStructs';

end;

{ TSchema.TTables }

function TSchema.TTables.MyClassName: AnsiString;
begin
  Result := 'TTables';

end;

{ TSchema.TFields }

function TSchema.TFields.MyClassName: AnsiString;
begin
  Result := 'TFields';

end;

{ TSchema.TEnums }

function TSchema.TEnums.MyClassName: AnsiString;
begin
  Result := 'TEnums';

end;

{ TSchema.TEnum.TValues }

function TSchema.TEnum.TValues.MyClassName: AnsiString;
begin
  Result := 'TEnumValues';
end;

{ TSchema.TEnumFields }

function TSchema.TEnumFields.MyClassName: AnsiString;
begin
  Result := 'TEnumFields';
end;

{ TSchema.TBaseSchemaObject }

function TSchema.TBaseSchemaObject.ToXML: AnsiString;
begin
  FmtFatalLn('Not Implement Yet for %s', [Self.ClassName]);
  Result := Format('<%s></%s>', [Self.ClassName, Self.ClassName]);

end;

{ TObjectCollectionWithToXML }

function TObjectCollectionWithToXML.ToXML: AnsiString;
var
  i: Integer;
  Str: TStringList;

begin
  Str := TStringList.Create;
  Str.Add(Format('<%s>', [MyClassName]));

  for i := 0 to Self.Count - 1 do
    Str.Add(Self[i].ToXML);
  Str.Add(Format('</%s>', [MyClassName]));

  Result := Str.Text;
  Str.Free;

end;

{ TSchema.TEnum.TValue }

constructor TSchema.TEnum.TValue.Create(aName: TIdentifier; aIntValue: Integer);
begin
  inherited Create;

  FName := aName;
  FIntValue := aIntValue;

end;

constructor TSchema.TEnum.TValue.Create(aName: TIdentifier);
begin
  inherited Create;

  HasIntValue := False;
  FName := aName;

end;

{ TSchema.TStruct }

function TSchema.TStruct.GetField(Index: Integer): TField;
begin
  Result := FFields[Index];

end;

constructor TSchema.TStruct.Create(constref aName: TIdentifier);
begin
  inherited Create;

  FName := aName;
  FFields := TFields.Create;

end;

destructor TSchema.TStruct.Destroy;
begin
  FFields.Free;

  inherited Destroy;
end;

function TSchema.TStruct.ToXML: AnsiString;
var
  Str: TStringList;
  aField: TField;

begin
  Str := TStringList.Create;

  Str.Add(Format('<Struct name = "%s" >', [FName]));

  for aField in FFields do
    Str.Add(aField.ToXML);

  Str.Add('</Struct>');

  Result := Str.Text;

  Str.Free;

end;

{ TSchema.TBaiscType }

constructor TSchema.TBaiscType.Create(ATypeName: AnsiString);
begin
  inherited Create;

  FTypeName := ATypeName;

end;

function TSchema.TBaiscType.ToXML: AnsiString;
begin
  Result:= Format('<BaiscType name= "%s" />', [FTypeName]);

end;

{ TSchema.TIdentType }

constructor TSchema.TIdentType.Create(AIdenName: AnsiString);
begin
  inherited Create;

  FIdentName := AIdenName;

end;

function TSchema.TIdentType.ToXML: AnsiString;
begin
  Result:= Format('<IdentType name= "%s" />', [FTypeName]);

end;

{ TSchema.TField }

constructor TSchema.TField.Create(constref aName: TIdentifier;
  aType: TBaseType; aScaler: Integer; aMetadata: TMetadata);
begin
  inherited Create;

  FName := aName;
  FType := aType;
  FScaler := aScaler;
  FMetaData := aMetadata;

end;

destructor TSchema.TField.Destroy;
begin
  FType.Free;
  FMetaData.Free;

  inherited Destroy;
end;

function TSchema.TField.ToXML: AnsiString;
var
  Str: TStringList;

begin
  Str := TStringList.Create;

  Str.Add('<TField Name = "%s" Scaler = "%d">', [Self.Name, Self.Sclaer]);
  Str.Add('  <Type>');
  Str.Add(FType.ToXML);
  Str.Add('  </Type>');

  Str.Add('</TField>');

  Result:= Str.Text;
  Str.Free;


end;

{ TSchema.TTable }

function TSchema.TTable.GetField(Index: Integer): TField;
begin
  Result := FFields[Index];

end;

constructor TSchema.TTable.Create(constref aName: TIdentifier);
begin
  inherited Create;

  FName := aName;
  FFields := TFields.Create;

end;

destructor TSchema.TTable.Destroy;
begin
  FFields.Free;

  inherited Destroy;
end;

function TSchema.TTable.ToXML: AnsiString;
var
  Str: TStringList;
  aField: TField;

begin
  Str := TStringList.Create;

  Str.Add(Format('<Table name = "%s" >', [FName]));

  for aField in FFields do
    Str.Add(aField.ToXML);

  Str.Add('</Table>');

  Result := Str.Text;

  Str.Free;

end;

{ TSchema.TEnum }

constructor TSchema.TEnum.Create(constref aName: TIdentifier; aType: TBaseType;
  aValues: TValues);
begin
  inherited Create;

  FName := aName;
  FType := aType;
  FValues := aValues;

end;

procedure TSchema.TEnum.AddAField(AField: TEnumField);
begin
  raise ENotImplemented.Create('');

end;

{ TSchema.TArrayType }

constructor TSchema.TArrayType.Create(aSubType: TBaseType);
begin
  inherited Create;

  FSubType := aSubType;

end;

destructor TSchema.TArrayType.Destroy;
begin
  FSubType.Free;

  inherited Destroy;
end;

function TSchema.TArrayType.ToXML: AnsiString;
begin
  Result:= Format(
    '<TArrayType name="%s">' +
      '%s' +
    '</TArrayType>',
    [FTypeName, FSubType.ToXML]);

end;

{ TSchema.TEnumField }

constructor TSchema.TEnumField.Create(aName: TIdentifier);
begin
  inherited Create;

  FName := aName;
  FHasValue := False;
end;

constructor TSchema.TEnumField.Create(aName: TIdentifier; aValue: Integer);
begin
  inherited Create;

  FName := aName;
  FValue := aValue;
  FHasValue := True;

end;

{ TSchema }

function TSchema.GetValueFromOtherParams(ParamName: AnsiString): AnsiString;
var
  Str: AnsiString;

begin
  Result := '';

  for Str in FOtherParams do
    if IsPrefix(ParamName, Str) then
      Exit(Copy(Str, Length(ParamName) + 1, Length(Str)));

end;

function TSchema.GetInputSchemaFilename: AnsiString;
begin
  Result := GetValueFromOtherParams('InputSchemaFilename:');

end;

constructor TSchema.Create(AIncludes: TIncludes; AOtherParams: TAnsiStrings;
  ANamespace: TIdentifier; AEnums: TEnums; ATables: TTables;
  AStructs: TStructs; ARootType: TIdentifier; AAttributes: TAttributes);
begin
  inherited Create;

  FIncludes := AIncludes;
  FOtherParams := AOtherParams;
  FNamespace := ANamespace;
  FEnums := AEnums;
  FTables := ATables;
  FStructs := AStructs;
  FRootType := ARootType;
  FAttributes := AAttributes;

end;

destructor TSchema.Destroy;
begin
  FIncludes.Free;

  inherited Destroy;
end;

function TSchema.ToXML: AnsiString;
begin
  Result := Format('<TSchema FileName = "%s" Path= "%s" Namespace = "%s" > %s %s %s %s %s </TSchema>',
  [ExtractFileName(InputSchemaFilename),
   ExtractFileDir(InputSchemaFilename),
   FNamespace,
   FIncludes.ToXML,
   FEnums.ToXML,
   FTables.ToXML,
   FStructs.ToXML,
   FRootType
  ]);

end;

{ TSchema.TIncludes }

function TSchema.TIncludes.ToXML: AnsiString;
var
  Str: AnsiString;

begin
  Result := '';

  for Str in Self do
    Result += '<Include Value = "' + Str + '"/>';
  Result :=
    '<Includes>' +
      Result +
  '</Includes>';
end;

end.

