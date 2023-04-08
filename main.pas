unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Math, TypInfo;

type
  reg8T = (AL = 0, CL, DL, BL, AH, CH, DH, BH);
  reg16T =(AX = 0, CX, DX, BX, SP, BP, SI, DI);
  sRegT = (ES = 0, CS, SS, DS);

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

procedure ClearStr(var operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2: string);
begin
  operation := '';
  operand1 := '';
  operand2 := '';
  setlength(bytestr1, 2);
  setlength(bytestr2, 2);
  setlength(bytestr3, 2);
  setlength(bytestr4, 2);
  prefix1 := '';
  prefix2 := '';
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
    '0':  resstr := '[BX + SI]';
    '1':  resstr := '[BX + DI]';
    '2':  resstr := '[BP + SI]';
    '3':  resstr := '[BP + DI]';
    '4':  resstr := '[SI]';
    '5':  resstr := '[DI]';
    '6':  resstr := 'disp16';
    '7':  resstr := '[BX]';
    '40': resstr := '[BX + SI] + disp8';
    '41': resstr := '[BX + DI] + disp8';
    '42': resstr := '[BP + SI] + disp8';
    '43': resstr := '[BP + DI] + disp8';
    '44': resstr := '[SI] + disp8';
    '45': resstr := '[DI] + disp8';
    '46': resstr := '[BP] + disp8';
    '47': resstr := '[BX] + disp8';
    '80': resstr := '[BX + SI] + disp16';
    '81': resstr := '[BX + DI] + disp16';
    '82': resstr := '[BP + SI] + disp16';
    '83': resstr := '[BP + DI] + disp16';
    '84': resstr := '[SI] + disp16';
    '85': resstr := '[DI] + disp16';
    '86': resstr := '[BP] + disp16';
    '87': resstr := '[BX] + disp16';
    //'C0': resstr := 'AX';
    //'C1': resstr := 'CX';
    //'C2': resstr := 'DX';
    //'C3': resstr := 'BX';
    //'C4': resstr := 'SP';
    //'C5': resstr := 'BP';
    //'C6': resstr := 'SI';
    //'C7': resstr := 'DI';
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

function GetStrSReg(e: sRegT): string;
begin
  case e of
    ES: GetStrSReg := 'ES';
    CS: GetStrSReg := 'CS';
    SS: GetStrSReg := 'SS';
    DS: GetStrSReg := 'DS';
  end;
end;

function Contains(str, str2: string; var position: integer): boolean;
begin
  position := Pos(str, str2);
  if position > 0 then contains := true
  else contains := false;
end;

function Insert(str, str2: string; pos: integer): string;
var
  i: integer;
  resstr: string;
begin
  resstr := str;
  if (pos > 0) then
  begin
    resstr := '';
    for i := 1 to pos - 1 do resstr += str[i];
    resstr += str2;
    for i := pos to length(str) do resstr += str[i];
  end;
  Insert := resstr;
end;

procedure ReadByte(str: string; var i: integer; var str2: string);
begin
  setlength(str2, 2);
  str2[1] := str[i];
  str2[2] := str[i + 1];
  i += 2;
end;

function GetOutputStr(numberLine: integer; operation, operand1, operand2, bytestr1, prefix1, prefix2: string): string;
var
  temp: string;
  position: integer;
begin
  if (operand2 <> '') then
    temp := DecToHex(numberLine, 4) + #9 + prefix1 + ' ' + operation + #9 + operand1 + ', ' + operand2 + #9 + bytestr1 + #10
  else
    temp := DecToHex(numberLine, 4) + #9 + prefix1 + ' ' + operation + #9 + operand1 + ' ' + operand2 + #9 + bytestr1 + #10;
  if (prefix2 <> '') then
  begin
    position := pos('[', temp);
    temp := Insert(temp, prefix2+':', position);
  end;
  GetOutputStr := temp;
end;

function GetWordPtrDisp16Str(pos: integer; operand, bytestr1, bytestr2: string): string;
begin
  operand := copy(operand, 1, pos-1);
  operand := 'word ptr ' + operand + '[0x'+bytestr2+bytestr1+']';
  GetWordPtrDisp16Str := operand;
end;

function GetBytePtrDisp8Str(pos: integer; operand, bytestr1, bytestr2: string): string;
begin
  operand := copy(operand, 1, pos-1);
  operand := 'byte ptr ' + operand + '[0x'+bytestr2+bytestr1+']';
  GetBytePtrDisp8Str := operand;
end;

function GetROrMem8(str, bytestr: string; var i: integer): string;
var
  bytestr3, bytestr4, operand: string;
  byteReg8: reg8T;
  pos: integer;

begin
  operand := GetModRM(bytestr);
  if (length(operand) = 8) then
  begin
    byteReg8 := reg8T(getrm(bytestr));
    operand := GetStrReg8(byteReg8);
  end
  else
  begin
    if (Contains('disp16', operand, pos)) then
    begin
      setlength(bytestr3, 2);
      setlength(bytestr4, 2);
      ReadByte(str, i, bytestr3);
      ReadByte(str, i, bytestr4);
      operand := GetBytePtrDisp8Str(pos, operand, bytestr3, bytestr4);
    end
    else if (Contains('disp8', operand, pos)) then
    begin
      setlength(bytestr3, 2);
      bytestr4 := '00';
      ReadByte(str, i, bytestr3);
      operand := GetBytePtrDisp8Str(pos, operand, bytestr3, bytestr4);
    end
    else
    begin
      operand := 'byte ptr ' + operand;
    end;
  end;
  GetROrMem8 := operand;
end;

function GetROrMem16(str, bytestr: string; var i: integer): string;
var
  bytestr3, bytestr4, operand: string;
  byteReg16: reg16T;
  pos: integer;

begin
  operand := GetModRM(bytestr);
  if (length(operand) = 8) then
  begin
    byteReg16 := reg16T(getrm(bytestr));
    operand := GetStrReg16(byteReg16);
  end
  else
  begin
    if (Contains('disp16', operand, pos)) then
    begin
      setlength(bytestr3, 2);
      setlength(bytestr4, 2);
      ReadByte(str, i, bytestr3);
      ReadByte(str, i, bytestr4);
      operand := GetWordPtrDisp16Str(pos, operand, bytestr3, bytestr4);
    end
    else if (Contains('disp8', operand, pos)) then
    begin
      setlength(bytestr3, 2);
      bytestr4 := '00';
      ReadByte(str, i, bytestr3);
      operand := GetWordPtrDisp16Str(pos, operand, bytestr3, bytestr4);
    end
    else
    begin
      operand := 'word ptr ' + operand;
    end;
  end;
  GetROrMem16 := operand;
end;

function GetImm8(str, bytestr: string; var i: integer): string;
begin
  GetImm8 := '0x'+bytestr;
end;

function GetImm16(str, bytestr: string; var i: integer): string;
var
  bytestr2: string;
begin
  readbyte(str, i, bytestr2);
  GetImm16 := '0x'+bytestr2+bytestr;
end;

function GetMemo8(str, bytestr: string; var i: integer): string;
var
  bytestr2: string;
begin
  readbyte(str, i, bytestr2);
  GetMemo8 := 'byte ptr [0x'+bytestr2+bytestr+']';
end;

function GetMemo16(str, bytestr: string; var i: integer): string;
var
  bytestr2: string;
begin
  readbyte(str, i, bytestr2);
  GetMemo16 := 'word ptr [0x'+bytestr2+bytestr+']';
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
  resstr, bytestr1, bytestr2, bytestr3, bytestr4, operation, operand1, operand2, bytetempstr, prefix1, prefix2: string;
  numberLine, i, j, modd, reg, rm, byte2int, pos: integer;
  run: boolean;
  byteReg8: reg8T;
  byteReg16: reg16T;
  byteSReg: sRegT;

begin
  numberLine := 0;
  i := 1;
  run := true;
  operation := '';
  operand1 := '';
  operand2 := '';
  prefix1 := '';
  prefix2 := '';
  resstr := '';
  setlength(bytestr1, 2);
  setlength(bytestr2, 2);
  setlength(bytestr3, 2);
  setlength(bytestr4, 2);
  while (i <= length(str)) and (run) do
  begin
    numberLine := i div 2;
    ReadByte(str, i, bytestr1);
    case bytestr1 of
      '00'..'05': // ADD
      begin
        operation := 'add';
        case bytestr1 of
          '00': //ADD r/m8, reg8
          begin
            readbyte(str, i, bytestr2);
            operand1 := GetROrMem8(str, bytestr2, i);
            byteReg8 := reg8T(getReg(bytestr2));
            operand2 := GetStrReg8(byteReg8);
          end;
          '01': //ADD r/m16, reg16
          begin
            readbyte(str, i, bytestr2);
            operand1 := GetROrMem16(str, bytestr2, i);
            byteReg16 := reg16T(getReg(bytestr2));
            operand2 := GetStrReg16(byteReg16);
          end;
          '02': //ADD reg8, r/m8
          begin
            readbyte(str, i, bytestr2);
            byteReg8 := reg8T(getReg(bytestr2));
            operand1 := GetStrReg8(byteReg8);
            operand2 := GetROrMem8(str, bytestr2, i);
          end;
          '03': //ADD reg16, r/m16
          begin
            readbyte(str, i, bytestr2);
            byteReg16 := reg16T(getReg(bytestr2));
            operand1 := GetStrReg16(byteReg16);
            operand2 := GetROrMem16(str, bytestr2, i);
          end;
          '04': //ADD AL, imm8
          begin
            readbyte(str, i, bytestr2);
            operand1 := 'AL';
            operand2 := GetImm8(str, bytestr2, i);
          end;
          '05': //ADD AX, imm16
          begin
            readbyte(str, i, bytestr2);
            operand1 := 'AX';
            operand2 := GetImm16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '08'..'0D': // OR
      begin
        readbyte(str, i, bytestr2);
        operation := 'or';
        case bytestr1 of
          '08': //OR r/m8, reg8
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            byteReg8 := reg8T(getReg(bytestr2));
            operand2 := GetStrReg8(byteReg8);
          end;
          '09': //OR r/m16, reg16
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            byteReg16 := reg16T(getReg(bytestr2));
            operand2 := GetStrReg16(byteReg16);
          end;
          '0A': //OR reg8, r/m8
          begin
            byteReg8 := reg8T(getReg(bytestr2));
            operand1 := GetStrReg8(byteReg8);
            operand2 := GetROrMem8(str, bytestr2, i);
          end;
          '0B': //OR reg16, r/m16
          begin
            byteReg16 := reg16T(getReg(bytestr2));
            operand1 := GetStrReg16(byteReg16);
            operand2 := GetROrMem16(str, bytestr2, i);
          end;
          '0C': //OR AL, imm8
          begin
            operand1 := 'AL';
            operand2 := GetImm8(str, bytestr2, i);
          end;
          '0D': //OR AX, imm16
          begin
            operand1 := 'AX';
            operand2 := GetImm16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '10'..'15': // ADC
      begin
        operation := 'adc';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          '10': //ADC r/m8, reg8
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            byteReg8 := reg8T(getReg(bytestr2));
            operand2 := GetStrReg8(byteReg8);
          end;
          '11': //ADC r/m16, reg16
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            byteReg16 := reg16T(getReg(bytestr2));
            operand2 := GetStrReg16(byteReg16);
          end;
          '12': //ADC reg8, r/m8
          begin
            byteReg8 := reg8T(getReg(bytestr2));
            operand1 := GetStrReg8(byteReg8);
            operand2 := GetROrMem8(str, bytestr2, i);
          end;
          '13': //ADC reg16, r/m16
          begin
            byteReg16 := reg16T(getReg(bytestr2));
            operand1 := GetStrReg16(byteReg16);
            operand2 := GetROrMem16(str, bytestr2, i);
          end;
          '14': //ADC AL, imm8
          begin
            operand1 := 'AL';
            operand2 := GetImm8(str, bytestr2, i);
          end;
          '15': //ADC AX, imm16
          begin
            operand1 := 'AX';
            operand2 := GetImm16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '18'..'1D': // SBB
      begin
        operation := 'sbb';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          '18': //SBB r/m8, reg8
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            byteReg8 := reg8T(getReg(bytestr2));
            operand2 := GetStrReg8(byteReg8);
          end;
          '19': //SBB r/m16, reg16
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            byteReg16 := reg16T(getReg(bytestr2));
            operand2 := GetStrReg16(byteReg16);
          end;
          '1A': //SBB reg8, r/m8
          begin
            byteReg8 := reg8T(getReg(bytestr2));
            operand1 := GetStrReg8(byteReg8);
            operand2 := GetROrMem8(str, bytestr2, i);
          end;
          '1B': //SBB reg16, r/m16
          begin
            byteReg16 := reg16T(getReg(bytestr2));
            operand1 := GetStrReg16(byteReg16);
            operand2 := GetROrMem16(str, bytestr2, i);
          end;
          '1C': //SBB AL, imm8
          begin
            operand1 := 'AL';
            operand2 := GetImm8(str, bytestr2, i);
          end;
          '1D': //SBB AX, imm16
          begin
            operand1 := 'AX';
            operand2 := GetImm16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '20'..'25': // AND
      begin
        operation := 'and';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          '20': //AND r/m8, reg8
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            byteReg8 := reg8T(getReg(bytestr2));
            operand2 := GetStrReg8(byteReg8);
          end;
          '21': //AND r/m16, reg16
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            byteReg16 := reg16T(getReg(bytestr2));
            operand2 := GetStrReg16(byteReg16);
          end;
          '22': //AND reg8, r/m8
          begin
            byteReg8 := reg8T(getReg(bytestr2));
            operand1 := GetStrReg8(byteReg8);
            operand2 := GetROrMem8(str, bytestr2, i);
          end;
          '23': //AND reg16, r/m16
          begin
            byteReg16 := reg16T(getReg(bytestr2));
            operand1 := GetStrReg16(byteReg16);
            operand2 := GetROrMem16(str, bytestr2, i);
          end;
          '24': //AND AL, imm8
          begin
            operand1 := 'AL';
            operand2 := GetImm8(str, bytestr2, i);
          end;
          '25': //AND AX, imm16
          begin
            operand1 := 'AX';
            operand2 := GetImm16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '28'..'2D': // SUB
      begin
        operation := 'sub';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          '28': //SUB r/m8, reg8
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            byteReg8 := reg8T(getReg(bytestr2));
            operand2 := GetStrReg8(byteReg8);
          end;
          '29': //SUB r/m16, reg16
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            byteReg16 := reg16T(getReg(bytestr2));
            operand2 := GetStrReg16(byteReg16);
          end;
          '2A': //SUB reg8, r/m8
          begin
            byteReg8 := reg8T(getReg(bytestr2));
            operand1 := GetStrReg8(byteReg8);
            operand2 := GetROrMem8(str, bytestr2, i);
          end;
          '2B': //SUB reg16, r/m16
          begin
            byteReg16 := reg16T(getReg(bytestr2));
            operand1 := GetStrReg16(byteReg16);
            operand2 := GetROrMem16(str, bytestr2, i);
          end;
          '2C': //SUB AL, imm8
          begin
            operand1 := 'AL';
            operand2 := GetImm8(str, bytestr2, i);
          end;
          '2D': //SUB AX, imm16
          begin
            operand1 := 'AX';
            operand2 := GetImm16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '30'..'35': // XOR
      begin
        operation := 'xor';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          '30': //XOR r/m8, reg8
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            byteReg8 := reg8T(getReg(bytestr2));
            operand2 := GetStrReg8(byteReg8);
          end;
          '31': //XOR r/m16, reg16
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            byteReg16 := reg16T(getReg(bytestr2));
            operand2 := GetStrReg16(byteReg16);
          end;
          '32': //XOR reg8, r/m8
          begin
            byteReg8 := reg8T(getReg(bytestr2));
            operand1 := GetStrReg8(byteReg8);
            operand2 := GetROrMem8(str, bytestr2, i);
          end;
          '33': //XOR reg16, r/m16
          begin
            byteReg16 := reg16T(getReg(bytestr2));
            operand1 := GetStrReg16(byteReg16);
            operand2 := GetROrMem16(str, bytestr2, i);
          end;
          '34': //XOR AL, imm8
          begin
            operand1 := 'AL';
            operand2 := GetImm8(str, bytestr2, i);
          end;
          '35': //XOR AX, imm16
          begin
            operand1 := 'AX';
            operand2 := GetImm16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '38'..'3D': // CMP
      begin
        operation := 'cmp';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          '38': //CMP r/m8, reg8
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            byteReg8 := reg8T(getReg(bytestr2));
            operand2 := GetStrReg8(byteReg8);
          end;
          '39': //CMP r/m16, reg16
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            byteReg16 := reg16T(getReg(bytestr2));
            operand2 := GetStrReg16(byteReg16);
          end;
          '3A': //CMP reg8, r/m8
          begin
            byteReg8 := reg8T(getReg(bytestr2));
            operand1 := GetStrReg8(byteReg8);
            operand2 := GetROrMem8(str, bytestr2, i);
          end;
          '3B': //CMP reg16, r/m16
          begin
            byteReg16 := reg16T(getReg(bytestr2));
            operand1 := GetStrReg16(byteReg16);
            operand2 := GetROrMem16(str, bytestr2, i);
          end;
          '3C': //CMP AL, imm8
          begin
            operand1 := 'AL';
            operand2 := GetImm8(str, bytestr2, i);
          end;
          '3D': //CMP AX, imm16
          begin
            operand1 := 'AX';
            operand2 := GetImm16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;


      '06', '0E', '16', '1E': //PUSH
      begin
        operation := 'push';
        byteSReg := sRegT(getReg(bytestr1));
        operand1 := GetStrSReg(byteSReg);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '07', '17', '1F': //POP   0F(вроде есть, а вроде и нет)
      begin
        operation := 'pop';
        byteSReg := sRegT(getReg(bytestr1));
        operand1 := GetStrSReg(byteSReg);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;


      'FE'..'FF': //DEC INC PUSH
      begin
        readbyte(str, i, bytestr2);
        reg := GetReg(bytestr2);
        case bytestr1 of
          'FE':
          begin  //reg8 или адрес 1 байт
            case reg of
              0:
              begin
                operation := 'inc';
                operand1 := GetROrMem8(str, bytestr2, i);
              end;
              1:
              begin
                operation := 'dec';
                operand1 := GetROrMem8(str, bytestr2, i);
              end;
            end;
          end;
          'FF':
          begin  //reg16 или адрес 2 байта
            case reg of
              0:
              begin  // INC
                operation := 'inc';
                operand1 := GetROrMem16(str, bytestr2, i);
              end;
              1:
              begin  // DEC
                operation := 'dec';
                operand1 := GetROrMem16(str, bytestr2, i);
              end;
              6:
              begin  // PUSH
                operation := 'push';
                operand1 := GetROrMem16(str, bytestr2, i);
              end;
            end;
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '40'..'47': //INC
      begin
        operation := 'inc';
        byteReg16 := reg16T(getRM(bytestr1));
        operand1 := GetStrReg16(byteReg16);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '48'..'4F': //DEC
      begin
        operation := 'dec';
        byteReg16 := reg16T(getrm(bytestr1));
        operand1 := GetStrReg16(byteReg16);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '50'..'57': //PUSH
      begin
        operation := 'push';
        byteReg16 := reg16T(getRm(bytestr1));
        operand1 := GetStrReg16(byteReg16);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '58'..'5F': //POP
      begin
        operation := 'pop';
        byteReg16 := reg16T(getRm(bytestr1));
        operand1 := GetStrReg16(byteReg16);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;

      '80', '81', '83': // ADD, OR, ADC, SBB, AND, SUB, XOR, CMP  r/m8/16, imm8/16
      begin
        readbyte(str, i, bytestr2);
        reg := GetReg(bytestr2);
        case reg of
          0:
          begin
            operation := 'add';
            case bytestr1 of
              '80': //ADD r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '81': //ADD r/m16, imm16
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm16(str, bytestr2, i);
              end;
              '83': //ADD r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
          1:
          begin
            operation := 'or';
            case bytestr1 of
              '80': //OR r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '81': //OR r/m16, imm16
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm16(str, bytestr2, i);
              end;
              '83': //OR r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
          2:
          begin
            operation := 'abc';
            case bytestr1 of
              '80': //ADC r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '81': //ADC r/m16, imm16
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm16(str, bytestr2, i);
              end;
              '83': //ADC r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
          3:
          begin
            operation := 'sbb';
            case bytestr1 of
              '80': //SBB r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '81': //SBB r/m16, imm16
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm16(str, bytestr2, i);
              end;
              '83': //SBB r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
          4:
          begin
            operation := 'and';
            case bytestr1 of
              '80': //AND r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '81': //AND r/m16, imm16
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm16(str, bytestr2, i);
              end;
              '83': //AND r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
          5:
          begin
            operation := 'sub';
            case bytestr1 of
              '80': //SUB r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '81': //SUB r/m16, imm16
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm16(str, bytestr2, i);
              end;
              '83': //SUB r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
          6:
          begin
            operation := 'xor';
            case bytestr1 of
              '80': //XOR r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '81': //XOR r/m16, imm16
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm16(str, bytestr2, i);
              end;
              '83': //XOR r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
          7:
          begin
            operation := 'cmp';
            case bytestr1 of
              '80': //CMP r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '81': //CMP r/m16, imm16
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm16(str, bytestr2, i);
              end;
              '83': //CMP r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;

      '88', '89': //MOV  r/m8/16, reg8/16
      begin
        operation := 'mov';
        case bytestr1 of
          '88':  //MOV  r/m8, reg8
          begin
            readbyte(str, i, bytestr2);
            operand1 := GetROrMem8(str, bytestr2, i);
            byteReg8 := reg8T(getReg(bytestr2));
            operand2 := GetStrReg8(byteReg8);
          end;
          '89':  //MOV  r/m16, reg16
          begin
            readbyte(str, i, bytestr2);
            operand1 := GetROrMem16(str, bytestr2, i);
            byteReg16 := reg16T(getReg(bytestr2));
            operand2 := GetStrReg16(byteReg16);
          end;
        end;
      end;


      '8C', '8E':  //MOV r/m16/sreg, sreg/r/m16
      begin
        operation := 'mov';
        case bytestr1 of
          '8C':  //MOV r/m16, sreg
          begin
            readbyte(str, i, bytestr2);
            operand1 := GetROrMem16(str, bytestr2, i);
            byteSReg := sRegT(getReg(bytestr2));
            operand2 := GetStrSReg(byteSReg);
          end;
          '8E':  //MOV sreg, r/m16
          begin
            readbyte(str, i, bytestr2);
            byteSReg := sRegT(getReg(bytestr2));
            operand1 := GetStrSReg(byteSReg);
            operand2 := GetROrMem16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;


      '8F': //POP
      begin
        operation := 'pop';
        readbyte(str, i, bytestr2);
        operand1 := GetROrMem16(str, bytestr2, i);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;

      'A0'..'A3': //MOV
      begin
        operation := 'mov';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          'A0':
          begin
            operand1 := 'AL';
            operand2 := GetMemo8(str, bytestr2, i);
          end;
          'A1':
          begin
            operand1 := 'AX';
            operand2 := GetMemo16(str, bytestr2, i);
          end;
          'A2':
          begin
            operand1 := GetMemo8(str, bytestr2, i);
            operand2 := 'AL';
          end;
          'A3':
          begin
            operand1 := GetMemo16(str, bytestr2, i);
            operand2 := 'AX';
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;

      'B0'..'B7': //MOV  reg8, imm8
      begin
        operation := 'mov';
        byteReg8 := reg8T(GetRM(bytestr1));
        operand1 := GetStrReg8(byteReg8);
        readbyte(str, i, bytestr2);
        operand2 := GetImm8(str, bytestr2, i);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'B8'..'BF': //MOV  reg16,imm16
      begin
        operation := 'mov';
        byteReg16 := reg16T(GetRM(bytestr1));
        operand1 := GetStrReg16(byteReg16);
        readbyte(str, i, bytestr2);
        operand2 := GetImm16(str, bytestr2, i);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;

      'C6', 'C7': //MOV  r/m8/16, imm8/16
      begin
        operation := 'mov';
        case bytestr1 of
          'C6': //MOV  r/m8, imm8
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            readbyte(str, i, bytestr2);
            operand2 := GetImm8(str, bytestr2, i);
          end;
          'C7': //MOV  r/m16, imm16
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            readbyte(str, i, bytestr2);
            operand2 := GetImm16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;

      'CC'..'CE':
      begin
        case bytestr1 of
          'CC':
          begin
            operation := 'int 3';
          end;
          'CD':
          begin
            operation := 'int';
            readbyte(str, i, bytestr2);
            operand1 := getimm8(str, bytestr2, i);
          end;
          'CE':
          begin
            operation := 'into'
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;

      'F4': //HLT
      begin
        operation := 'hlt';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;

      'F6', 'F7': //NOT, NEG, MUL, IMUL, DIV, IDIV
      begin
        readbyte(str, i, bytestr2);
        reg := GetReg(bytestr2);
        case bytestr1 of
          'F6': //NOT, NEG, MUL, IMUL, DIV, IDIV
          begin
            case reg of
              2: //NOT
              begin
                operation := 'not';
                operand1 := GetROrMem8(str, bytestr2, i);
              end;
              3: //NEG
              begin
                operation := 'neg';
                operand1 := GetROrMem8(str, bytestr2, i);
              end;
              4: //MUL
              begin
                operation := 'mul';
                operand1 := GetROrMem8(str, bytestr2, i);
              end;
              5: //IMUL
              begin
                operation := 'imul';
                operand1 := GetROrMem8(str, bytestr2, i);
              end;
              6: //DIV
              begin
                operation := 'div';
                operand1 := GetROrMem8(str, bytestr2, i);
              end;
              7: //IDIV
              begin
                operation := 'idiv';
                operand1 := GetROrMem8(str, bytestr2, i);
              end;
            end;
          end;
          'F7': //NOT, NEG, MUL, IMUL, DIV, IDIV
          begin
            case reg of
              2: //NOT
              begin
                operation := 'not';
                operand1 := GetROrMem16(str, bytestr2, i);
              end;
              3: //NEG
              begin
                operation := 'neg';
                operand1 := GetROrMem16(str, bytestr2, i);
              end;
              4: //MUL
              begin
                operation := 'mul';
                operand1 := GetROrMem16(str, bytestr2, i);
              end;
              5: //IMUL
              begin
                operation := 'imul';
                operand1 := GetROrMem16(str, bytestr2, i);
              end;
              6: //DIV
              begin
                operation := 'div';
                operand1 := GetROrMem16(str, bytestr2, i);
              end;
              7: //IDIV
              begin
                operation := 'idiv';
                operand1 := GetROrMem16(str, bytestr2, i);
              end;
            end;
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;

      'FC': //CLD
      begin
        operation := 'cld';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;

      'F0': prefix1 := 'LOCK';
      'F2': prefix1 := 'REPNZ';
      'F3': prefix1 := 'REP';
      '2E': prefix2 := 'CS';
      '36': prefix2 := 'SS';
      '3E': prefix2 := 'DS';
      '26': prefix2 := 'ES';
      '64': prefix2 := 'FS';
      '65': prefix2 := 'GS';
      else
      begin
        operation := 'db';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
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
  //resread := 'B800702EA300002EFF0E0102FECCFF0DB802008ED8B409BA0400CD21B8004CCD210048656C6C6F2C20576F726C642124';
  //resread := 'FEC8FEC9FECAFECBFECCFECDFECEFECFFE0E1200FE0F';
  //resread := 'FF4812FE0FFF4021FE07';
  //resread := '8F4422';
  resread := 'B800702EA300002EFF0E0102FECCFF0DB802008ED8B409BA0400CD21B8004CCD210048656C6C6F2C20576F726C642124';
  //hex := GetFormateLines(resread);
  assemblerCode := GetAssemblerCode(resread);
  //MemoByteCode.Text := hex;
  MemoByteCode.Text := resread;
  MemoAssembler.Text := assemblerCode;
end;

end.

