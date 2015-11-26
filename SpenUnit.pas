unit SpenUnit;

interface
               
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, XPMan, Grids;

const Letters=['a'..'z','A'..'Z','_'];
const Digits=['0'..'9'];
const Operators=';';
const TextLine=['"',''''];
const Comments=['/','*'];
const KeyWords: array [1..5] of string=('if','else','while','do','switch');
const InitializationIdentifier='var';
const CycleStatus='for';
const FunctionStatus='function';

type
  TAreaRec=Record
             BracketSum: integer;
             OpenFlag: boolean;
             AreaName: string;
             PreviousArea: string;
            end;
  TSearchRec=Record
              Condition: char;
              CycleNumber: integer;
             end;
  TIdentifier=Record
               IdentifierName: string;
               AreaOfExist: string;
               SpenNumber: integer;
              end;
  TIdentifierList=array[1..200] of TIdentifier;
  TSetOfChar=set of char;
  TForm1 = class(TForm)
    CodeMemo: TMemo;
    DoneButton: TButton;
    XPManifest1: TXPManifest;
    SpenStringGrid: TStringGrid;
    procedure FormShow(Sender: TObject);
    procedure DoneButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  CodeCondition: char;
  ProcessingArea: TAreaRec;
  IdentifierList: TIdentifierList;
  SearchStatus: TSearchRec;
  HeightOfIdentifierList: integer;

implementation

{$R *.dfm}

procedure TForm1.FormShow(Sender: TObject);
var F: TextFile;
    S: string;
    i: integer;

begin
 assignfile(F,'D:\MS\codef.txt');
 Reset(F);
 i:=0;
 while not(EOF(F)) do
 begin
  Readln(F,S);
  CodeMemo.Lines.Strings[i]:=S;
  inc(i);
 end;
 CloseFile(F);
end;

procedure TForm1.DoneButtonClick(Sender: TObject);

 function SeparateFromLine(var CodeLine: string; const SetOfValidSymbols: TSetOfChar):string;
 var i: integer;
 begin
  i:=1;
  while (CodeLine[i] in SetOfValidSymbols) and (i<length(CodeLine)+1) do
   inc(i);
  result:=Copy(CodeLine,1,i-1);
 end;

 function GetLexeme(var CodeLine: string):string;
 begin
  case CodeLine[1] of
   'a'..'z','A'..'Z' : result:=SeparateFromLine(CodeLine,Letters+Digits);
   '0'..'9' : result:=SeparateFromLine(CodeLine,Digits);
   '/','*' : result:=SeparateFromLine(CodeLine,Comments);
  else
   result:=CodeLine[1];
  end;
  Delete(CodeLine,1,length(result));
 end;

 procedure ExecuteLexeme(var Lexeme,CodeLine: string; var TransformedCode: string);
 var ModifiedLexeme: string;

  function DefineTokenClass(var Token,CodeLine: string):string;

   function CompareTokenWithKeyWords(var Token: string):boolean;
   var i: integer;
   begin
    result:=False;
    for i:=1 to 5 do
     if Token=KeyWords[i] then
      result:=True;
   end;

   procedure SetCommentCondition(var Token: string);
   begin
    if length(Token)>1 then
     case Token[2] of
      '*' : CodeCondition:='M';
      '/' : CodeCondition:='L';
     end
    else
     case Token[1] of
      '''' : CodeCondition:='S';
      '"'  : CodeCondition:='D';
     end;
   end;

   function ExecuteAssignment(var CodeLine: string):string;
   var Lexeme: string;
   begin
    repeat
     Lexeme:=GetLexeme(CodeLine);
    until (Lexeme=';') or (length(Codeline)<1);
    if Lexeme=';' then
     result:='S'
    else
     result:='N';
   end;

  begin
   result:='N';
   case Token[1] of
    'a'..'z','A'..'Z','_' : if not(CompareTokenWithKeyWords(Token)) then result:=Token;
    ';' : result:='S';
    '{' : result:='O';
    '}' : result:='C';
    '=' : result:=ExecuteAssignment(Codeline);
    '/','''','"' : SetCommentCondition(Token);
   end;
  end;

 begin
  ModifiedLexeme:=DefineTokenClass(Lexeme,CodeLine);
  if ModifiedLexeme<>'N' then
   TransformedCode:=TransformedCode+ModifiedLexeme+' ';
 end;

 procedure ExecuteUnusebleCode(var CodeLine: string; const EndSymbol: string);
 var Lexeme: string;
     i: integer;
 begin
  i:=0;
  while i<length(CodeLine) do
  begin
   Lexeme:=GetLexeme(CodeLine);
   if (Lexeme=EndSymbol) then
   begin
    CodeCondition:='W';
    i:=length(CodeLine);
   end;
  end;
 end;

 procedure ExecuteTransformedCode(var TransformedCode: string; var IdentifierList: TIdentifierList);
 var Token: string;

  function GetToken(var CodeLine: string):string;
  var CurrentPosition: integer;
  begin
   CurrentPosition:=1;
   while CodeLine[CurrentPosition]<>' ' do
    inc(CurrentPosition);
   result:=Copy(CodeLine,1,CurrentPosition-1);
   Delete(CodeLine,1,CurrentPosition);
  end;

  procedure AddToIdentifierList(var IdentifierList: TIdentifierList; const Token: string; const SearchStatus: TSearchRec);

   procedure CreateNewNodeInIdentifierList(const Identifier: string; var IdentifierList: TIdentifierList);
   begin
    IdentifierList[HeightOfIdentifierList+1].IdentifierName:=Identifier;
    IdentifierList[HeightOfIdentifierList+1].AreaOfExist:=ProcessingArea.AreaName;
    IdentifierList[HeightOfIdentifierList+1].SpenNumber:=0;
    inc(HeightOfIdentifierList);
   end;

   procedure IncreaseSpenNumber(const Identifier: string; var IdentifierList: TIdentifierList);
   var Increased: boolean;
       ListCounter: integer;
   begin
    ListCounter:=1;
    Increased:=False;
    while (ListCounter<HeightOfIdentifierList+1) and not(Increased) do
    begin
     if ((IdentifierList[ListCounter].AreaOfExist=ProcessingArea.AreaName) and (IdentifierList[ListCounter].IdentifierName=Identifier)) or ((pos('Cycle',ProcessingArea.PreviousArea)<>0) and (IdentifierList[ListCounter].AreaOfExist=ProcessingArea.PreviousArea) and (IdentifierList[ListCounter].IdentifierName=Identifier)) then
     begin
      Increased:=True;
      inc(IdentifierList[ListCounter].SpenNumber);
     end;
     inc(ListCounter);
    end;
    ListCounter:=1;
    if not(Increased) then
     while (ListCounter<HeightOfIdentifierList+1) and not(Increased) do
    begin
     if (IdentifierList[ListCounter].AreaOfExist='Global') and (IdentifierList[ListCounter].IdentifierName=Identifier) then
     begin
      Increased:=True;
      inc(IdentifierList[ListCounter].SpenNumber);
     end;
     inc(ListCounter);
    end;
   end;

  begin
   case SearchStatus.Condition of
    'R' : CreateNewNodeInIdentifierList(Token,IdentifierList);
    'W' : IncreaseSpenNumber(Token,IdentifierList);
   end;
  end;

  procedure SetCycleStatus;
  begin
   ProcessingArea.PreviousArea:=ProcessingArea.AreaName;
   ProcessingArea.AreaName:='Cycle'+IntToStr(SearchStatus.CycleNumber);
   inc(SearchStatus.CycleNumber);
  end;

  procedure SetFunctionStatus;
  begin
   ProcessingArea.PreviousArea:=ProcessingArea.AreaName;
   ProcessingArea.AreaName:=GetToken(TransformedCode);
   ProcessingArea.OpenFlag:=True;
   ProcessingArea.BracketSum:=0;
  end;

  procedure SetGlobalStatus;
  begin
   ProcessingArea.PreviousArea:=ProcessingArea.AreaName;
   ProcessingArea.AreaName:='Global';
   ProcessingArea.OpenFlag:=False;
  end;

  procedure SetPreviousStatus;
  var TemporaryAreaName: string;
  begin
   TemporaryAreaName:=ProcessingArea.AreaName;
   ProcessingArea.AreaName:=ProcessingArea.PreviousArea;
   ProcessingArea.PreviousArea:=TemporaryAreaName;
  end;

 begin
  while length(TransformedCode)>1 do
  begin
    Token:=GetToken(TransformedCode);
    case Token[1] of
     'v' : if Token=InitializationIdentifier then SearchStatus.Condition:='R' else AddToIdentifierList(IdentifierList,Token,SearchStatus);
     'f' : begin
            if Token=CycleStatus then
             SetCycleStatus()
            else
             if Token=FunctionStatus then
              SetFunctionStatus()
             else
              AddToIdentifierList(IdentifierList,Token,SearchStatus);
           end;
     'O' : if (ProcessingArea.OpenFlag) then
            inc(ProcessingArea.BracketSum);
     'C' : begin
            if (ProcessingArea.OpenFlag) then
             dec(ProcessingArea.BracketSum);
            if ProcessingArea.BracketSum<1 then
             SetGlobalStatus();
           end;
     'S' : begin
            if SearchStatus.Condition='R' then
             SearchStatus.Condition:='W';
            if pos('Cycle',ProcessingArea.AreaName)<>0 then
             SetPreviousStatus();
           end;
     '/' : begin
            if SearchStatus.Condition='R' then
             SearchStatus.Condition:='W';
           end;
     else
      AddToIdentifierList(IdentifierList,Token,SearchStatus);
    end;
  end;
 end;

 procedure PrintIdentifierList(const IdentifierList: TIdentifierList);
 var i: integer;
 begin
  SpenStringGrid.Cells[0,0]:='Область видимости';
  SpenStringGrid.Cells[1,0]:='Идентификатор';
  SpenStringGrid.Cells[2,0]:='Спен';
  for i:=1 to HeightOfIdentifierList do
  begin
   SpenStringGrid.RowCount:=i+1;
   SpenStringGrid.Cells[0,i]:=IdentifierList[i].AreaOfExist;
   SpenStringGrid.Cells[1,i]:=IdentifierList[i].IdentifierName;
   SpenStringGrid.Cells[2,i]:=IntToStr(IdentifierList[i].SpenNumber);
  end;
 end;

 procedure SpensCounting;
 var i: integer;
     CodeLine,TransformedCode,Lexeme: string;
 begin
  TransformedCode:='';
  CodeCondition:='W';
  for i:=0 to CodeMemo.Lines.Count do
  begin
   CodeLine:=CodeMemo.Lines.Strings[i];
   while length(CodeLine)>0 do
   begin
    case CodeCondition of
     'W' : begin
            Lexeme:=GetLexeme(CodeLine);
            ExecuteLexeme(Lexeme,CodeLine,TransformedCode);
           end;
     'L' : begin
            CodeCondition:='W';
            Delete(CodeLine,1,length(CodeLine));
           end;
     'M' : ExecuteUnusebleCode(CodeLine,'*/');
     'S' : ExecuteUnusebleCode(CodeLine,'''');
     'D' : ExecuteUnusebleCode(CodeLine,'"');
    end;
   end;
   TransformedCode:=TransformedCode+'/n ';
  end;
  SearchStatus.Condition:='W';
  SearchStatus.CycleNumber:=1;
  ProcessingArea.AreaName:='Global';
  ProcessingArea.PreviousArea:='Global';
  HeightOfIdentifierList:=0;
  ExecuteTransformedCode(TransformedCode,IdentifierList);
  PrintIdentifierList(IdentifierList);
 end;

begin
 SpensCounting();
end;

end.
