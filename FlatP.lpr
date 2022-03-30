program FlatP;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, ParameterManagerUnit, ALoggerUnit, WideStringUnit, SyncUnit,
SchemaParserUnit, SchemaDefinitionUnit
  { you can add units after this };

var
  SchemaMap: TSchemaMap;
  it: TSchemaMap.TPairEnumerator;

begin
  WriteLn('<A>');

  SchemaMap := TBaseSchemaParser.ParseAll(
    GetRunTimeParameterManager.ValueByName['--InputFile'].AsAnsiString);

  it := SchemaMap.GetEnumerator;
  while it.MoveNext do
    WriteLn(it.Current.Value.ToXML);
  it.Free;

  //TBaseSchemaParser.GenerateCode(ProtoMap);

  WriteLn('</A>');

  SchemaMap.Free;
end.

