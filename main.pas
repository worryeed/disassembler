unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Math, TypInfo;

type
  reg8T = (AL = 0, CL, DL, BL, AH, CH, DH, BH);
  reg16T = (AX = 0, CX, DX, BX, SP, BP, SI, DI);
  Segments = (DS= 0, ES, FS, GS, SS, CS, IP);

  { TForm1 }

  TForm1 = class(TForm)
    MemoAssembler: TMemo;
    MemoByteCode: TMemo;
    procedure FormCreate(Sender: TObject);
    function ReadFile(var f: file): string;
    function GetFormateLines(str: string): string;
    function GetAssemblerCode(str: string): string;
  private

  public

  end;

const
  PATH = 'C:\Users\KISTO\Desktop\HELLO.EXE';

var
  f: file;
  Form1: TForm1;

implementation

function DecToHex(decimal, bitDepth: integer): string;
var
  digit: byte;
  i, j: integer;
  ch: char;
  resstr: string;

begin
  resstr := '';
  while decimal > 0 do
  begin
    digit := decimal mod 16;
    if digit in [10..15] then
      case digit of
        10: ch := 'A';
        11: ch := 'B';
        12: ch := 'C';
        13: ch := 'D';
        14: ch := 'E';
        15: ch := 'F';
      end
    else
    ch := chr(Ord('0') + digit);
    resstr := ch + resstr;
    decimal := decimal div 16;
  end;
  for i := 0 to bitDepth do
    if length(resstr) = i then for j := i+1 to bitDepth do resstr := '0' + resstr;
  DecToHex := resstr;
end;

function HexToDec(hex: string): integer;
const
  s: string = '0123456789ABCDEF';
var
  n, k: integer;
  i, j: byte;

begin
  n := 0;
  k := 1;
  for i := length(hex) downto 1 do
    for j := 0 to 15 do
      if hex[i] = s[j + 1] then
      begin
        n += j * k;
        k *= 16;
      end;
  HexToDec := n;
end;

function DecToBin(n: integer): string;
var
  binaryString: string;
begin
  binaryString := '';
  while n > 0 do
  begin
    if n mod 2 = 0 then
      binaryString := '0' + binaryString
    else
      binaryString := '1' + binaryString;
    n := n div 2;
  end;
  DecToBin := binaryString;
end;

function BinToDec(str: string): integer;
var
  i, n, len: integer;
begin
  n := 0;
  len := length(str);
  for i := 1 to len do
  begin
    if str[i] = '1' then
      n := n + round(power(2, len - i));
  end;
  BinToDec := n;
end;

procedure clearstr(var str1, str2, str3: string);
begin
  str1 := '';
  str2 := '';
  str3 := '';
end;

function GetMod(str: string): integer;
var
  bytetempstr, tempstr, resstr: string;
  i: integer;

begin
  bytetempstr := '00000000';
  tempstr := DecToBin(HexToDec(str));
  for i := 1 to 8 - length(tempstr) do resstr += '0';
  resstr += tempstr;
  bytetempstr[7] := resstr[1];
  bytetempstr[8] := resstr[2];
  GetMod := BinToDec(bytetempstr);
end;

function GetReg(str: string): integer;
var
  bytetempstr, tempstr, resstr: string;
  i: integer;

begin
  bytetempstr := '00000000';
  tempstr := DecToBin(HexToDec(str));
  for i := 1 to 8 - length(tempstr) do resstr += '0';
  resstr += tempstr;
  bytetempstr[6] := resstr[3];
  bytetempstr[7] := resstr[4];
  bytetempstr[8] := resstr[5];
  GetReg := BinToDec(bytetempstr);
end;

function GetRM(str: string): integer;
var
  bytetempstr, tempstr, resstr: string;
  i: integer;

begin
  bytetempstr := '00000000';
  tempstr := DecToBin(HexToDec(str));
  for i := 1 to 8 - length(tempstr) do resstr += '0';
  resstr += tempstr;
  bytetempstr[6] := resstr[6];
  bytetempstr[7] := resstr[7];
  bytetempstr[8] := resstr[8];
  GetRM := BinToDec(bytetempstr);
end;

function GetModRM(str: string): string;
var
  bytetempstr, tempstr, resstr: string;
  i: integer;

begin
  bytetempstr := '00000000';
  tempstr := DecToBin(HexToDec(str));
  for i := 1 to 8 - length(tempstr) do resstr += '0';
  resstr += tempstr;
  bytetempstr := resstr;
  bytetempstr[3] := '0';
  bytetempstr[4] := '0';
  bytetempstr[5] := '0';
  i := BinToDec(bytetempstr);
  case dectohex(i, 1) of
    '0':  resstr := 'DS: [BX + SI]';
    '1':  resstr := 'DS: [BX + DI]';
    '2':  resstr := 'SS: [BP + SI]';
    '3':  resstr := 'SS: [BP + DI]';
    '4':  resstr := 'DS: [SI]';
    '5':  resstr := 'DS: [DI]';
    '6':  resstr := 'DS: disp16';
    '7':  resstr := 'DS: [BX]';
    '40': resstr := 'DS: [BX + SI] + disp8';
    '41': resstr := 'DS: [BX + DI] + disp8';
    '42': resstr := 'SS: [BP + SI] + disp8';
    '43': resstr := 'SS: [BP + DI] + disp8';
    '44': resstr := 'DS: [SI] + disp8';
    '45': resstr := 'DS: [DI] + disp8';
    '46': resstr := 'SS: [BP] + disp8';
    '47': resstr := 'DS: [BX] + disp8';
    '80': resstr := 'DS: [BX + SI] + disp16';
    '81': resstr := 'DS: [BX + DI] + disp16';
    '82': resstr := 'SS: [BP + SI] + disp16';
    '83': resstr := 'SS: [BP + DI] + disp16';
    '84': resstr := 'DS: [SI] + disp16';
    '85': resstr := 'DS: [DI] + disp16';
    '86': resstr := 'SS: [BP] + disp16';
    '87': resstr := 'DS: [BX] + disp16';
    'C0': resstr := 'AX';
    'C1': resstr := 'CX';
    'C2': resstr := 'DX';
    'C3': resstr := 'BX';
    'C4': resstr := 'SP';
    'C5': resstr := 'BP';
    'C6': resstr := 'SI';
    'C7': resstr := 'DI';
  end;
  GetModRM := resstr;
end;

function GetStrReg8(e: reg8T): string;
begin
  case e of
    AL: GetStrReg8 := 'AL';
    CL: GetStrReg8 := 'CL';
    DL: GetStrReg8 := 'DL';
    BL: GetStrReg8 := 'BL';
    AH: GetStrReg8 := 'AH';
    CH: GetStrReg8 := 'CH';
    DH: GetStrReg8 := 'DH';
    BH: GetStrReg8 := 'BH';
  end;
end;

function GetStrReg16(e: reg16T): string;
begin
  case e of
    AX: GetStrReg16 := 'AX';
    CX: GetStrReg16 := 'CX';
    DX: GetStrReg16 := 'DX';
    BX: GetStrReg16 := 'BX';
    SP: GetStrReg16 := 'SP';
    BP: GetStrReg16 := 'BP';
    SI: GetStrReg16 := 'SI';
    DI: GetStrReg16 := 'DI';
  end;
end;

function Contains(str, str2: string): boolean;
var
  p: integer;
begin
  p := Pos(str, str2);
  if p > 0 then contains := true
  else contains := false;
end;

{$R *.lfm}

{ TForm1 }

function TForm1.GetFormateLines(str: string): string;

var
  resstr: string;
  numberLine, i, j: integer;

begin
  numberLine := 0;
  resstr := '';
  for i := 1 to Length(str) div 32 + 1 do
  begin
    resstr += DecToHex(numberLine, 4);
    resstr += #9;
    for j := 1 to 32 do
    begin
      resstr += str[j + (32 * (i - 1))];
      if (j mod 2 = 0) and (j <> 32) and (j <> 16) then resstr += #32;
      if (j = 16) then resstr += #9;
    end;
    resstr += #13;
    numberLine += 16;
  end;
  GetFormateLines := resstr;
end;

function TForm1.GetAssemblerCode(str: string): string;
var
  resstr, bytestr1, bytestr2, bytestr3, bytestr4, operation, operand1, operand2, bytetempstr: string;
  numberLine, i, j, modd, reg, rm, byte2int: integer;
  run: boolean;
  byteReg8: reg8T;
  byteReg16: reg16T;

begin
  numberLine := 0;
  i := 1;
  run := true;
  operation := '';
  operand1 := '';
  operand2 := '';
  resstr := '';
  setlength(bytestr1, 2);
  setlength(bytestr2, 2);
  setlength(bytestr3, 2);
  setlength(bytestr4, 2);

  while (i <= length(str)) and (run) do
  begin
    bytestr1[1] := str[i];
    bytestr1[2] := str[i + 1];
    i += 2;
    case bytestr1 of

      'FE'..'FF': begin
        bytestr2[1] := str[i];
        bytestr2[2] := str[i + 1];
        reg := GetReg(bytestr2);
        i += 2;
        case bytestr1 of
          'FE': begin
            case reg of
              0: begin
                operation := 'inc';
              end;
              1: begin  //reg8 или адрес 1 байт
                operation := 'dec';
                byteReg8 := reg8T(getrm(bytestr2));
                operand1 := GetStrReg8(byteReg8);
                i += 2; // 1 байт
              end;
            end;
          end;
          'FF': begin
            case reg of
              0: begin
                operation := 'inc';
              end;                     //                               1   2   3  4    5   6  7
              1: begin  //reg16 или адрес 2 байта    reg16T = (AX = 0, CX, DX, BX, SP, BP, SI, DI);
                operation := 'dec';
                operand1 :=  GetModRM(bytestr2);
                if (Contains('disp16', operand1)) then
                begin
                  bytestr3[1] := str[i];
                  bytestr3[2] := str[i + 1];
                  bytestr4[1] := str[i + 2];
                  bytestr4[2] := str[i + 3];
                  operand1 := 'word ptr [' + inttostr(hextodec(bytestr3+bytestr4)) + ']';
                  i += 4; // байта
                end
                else if (Contains('disp8', operand1)) then
                begin
                  i += 2; // байта
                end
                else
                begin

                end;

              end;
              6: begin
                operation := 'push';
              end;
            end;
          end;
        end;
        resstr += DecToHex(numberLine, 4) + #9 + operation + ' ' + operand1 + ' ' + operand2 + #9 + bytestr1 + #10;
        clearstr(operation, operand1, operand2);
        numberLine += 2;
      end;

      '48'..'4F': begin
        operation := 'dec';
        byteReg16 := reg16T(getrm(bytestr1));
        operand1 := GetStrReg16(byteReg16);
        resstr += DecToHex(numberLine, 4) + #9 + operation + ' ' + operand1 + ' ' + operand2 + #9 + bytestr1 + #10;
        clearstr(operation, operand1, operand2);
        numberLine += 1;
      end;
      else
      begin
        resstr += DecToHex(numberLine, 4) + #9 + operation + ' ' + operand1 + ' ' + operand2 + #9 + bytestr1 + #10;
        numberLine += 1;
      end;


    end; // case


  end;   // while
  GetAssemblerCode := resstr;
end;

function TForm1.ReadFile(var f: file): string;
var
  str: string;
  b: byte;

begin
  str := '';
  reset(f, 1);
  while (not eof(f)) do
  begin
    blockread(f, b, sizeof(b));
    str += DecToHex(b, 2);
  end;
  closefile(f);
  ReadFile := str;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  resread, hex, assemblerCode: string;

begin
  assignfile(f, PATH);
  //resread := readfile(f);
  //resread := 'B800702EA300002EFF0E0000B802008ED8B409BA0000CD21B8004CCD210048656C6C6F2C20576F726C642124';
  //resread := 'B800702EA300002EFF0E0000FECCB802008ED8B409BA0200CD21B8004CCD210048656C6C6F2C20576F726C642124';
  resread := 'B800702EA300002EFF0E0000FECCFF0DB802008ED8B409BA0400CD21B8004CCD210048656C6C6F2C20576F726C642124';
  //hex := GetFormateLines(resread);
  assemblerCode := GetAssemblerCode(resread);
  //MemoByteCode.Text := hex;
  MemoByteCode.Text := resread;
  MemoAssembler.Text := assemblerCode;
end;

end.

