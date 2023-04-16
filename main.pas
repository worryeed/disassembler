unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, Math, LCLType;

type
  reg8T = (AL = 0, CL, DL, BL, AH, CH, DH, BH);
  reg16T =(AX = 0, CX, DX, BX, SP, BP, SI, DI);
  sRegT = (ES = 0, CS, SS, DS, FS, GS);

  { TMainForm }

  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    MemoAssembler: TMemo;
    MemoByteCode: TMemo;
    MenuItemSaveFile: TMenuItem;
    MenuItemCloseFile: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuItemFile: TMenuItem;
    MenuItemTakeFile: TMenuItem;
    MenuItemView: TMenuItem;
    MenuItemZoomIn: TMenuItem;
    MenuItemZoomOut: TMenuItem;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    Separator: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure MenuItemCloseFileClick(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure MenuItemSaveFileClick(Sender: TObject);
    procedure MenuItemTakeFileClick(Sender: TObject);
    procedure MenuItemZoomInClick(Sender: TObject);
    procedure MenuItemZoomOutClick(Sender: TObject);
    function TryReadFile(var f: file; var resstr, errorstr: string): boolean;
    function TrySaveFile(var f: file; str: string; var errorstr: string): boolean;
    function GetFormateLines(str: string): string;
    function GetAssemblerCode(str: string): string;
  private

  public

  end;

var
  f: file;
  MainForm: TMainForm;

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
    if length(resstr) = i then
      for j := i+1 to bitDepth do
        resstr := '0' + resstr;
  DecToHex := copy(resstr, length(resstr)-bitDepth+1, bitDepth);
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
  resstr := '';
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
  resstr := '';
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
  resstr := '';
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
  resstr := '';
  bytetempstr := '00000000';
  tempstr := DecToBin(HexToDec(str));
  for i := 1 to 8 - length(tempstr) do resstr += '0';
  resstr += tempstr;
  bytetempstr := resstr;
  bytetempstr[3] := '0';
  bytetempstr[4] := '0';
  bytetempstr[5] := '0';
  i := BinToDec(bytetempstr);
  case dectohex(i, 2) of
    '00':  resstr := '[BX + SI]';
    '01':  resstr := '[BX + DI]';
    '02':  resstr := '[BP + SI]';
    '03':  resstr := '[BP + DI]';
    '04':  resstr := '[SI]';
    '05':  resstr := '[DI]';
    '06':  resstr := 'disp16';
    '07':  resstr := '[BX]';
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

function GetAdditionalCode(str: string): string;
var
  i: integer;
begin
  for i := 1 to length(str) do
    if (str[i] = '0') then str[i] := '1'
    else str[i] := '0';
  GetAdditionalCode := dectobin(bintodec(str)+1);
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
    FS: GetStrSReg := 'FS';
    GS: GetStrSReg := 'GS';
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
  if (prefix1 <> '') then numberLine -= 1;
  if (prefix2 <> '') then numberLine -= 1;

  if (operand2 <> '') then
    temp := DecToHex(numberLine, 4) + #9 + prefix1 + ' ' + operation + #9 + operand1 + ', ' + operand2 + #10
  else if (operation = 'db') then
    temp := DecToHex(numberLine, 4) + #9 + prefix1 + ' ' + operation + #9 + operand1 + ' ' + operand2 + ' ; ' + chr(hextodec(bytestr1)) + #10
  else
    temp := DecToHex(numberLine, 4) + #9 + prefix1 + ' ' + operation + #9 + operand1 + ' ' + operand2 + #10;
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
  bytestr3, bytestr4, operand, temp: string;
  p, p2: integer;

begin
  operand := GetModRM(bytestr);
  if (length(operand) = 8) then
  begin
    operand := '';
  end
  else
  begin
    if (Contains('disp16', operand, p) and ('disp16' <> operand)) then
    begin
      setlength(bytestr3, 2);
      setlength(bytestr4, 2);
      ReadByte(str, i, bytestr3);
      ReadByte(str, i, bytestr4);
      temp := bytestr4 + bytestr3;
      if (temp >= '7F80') then
      begin
        temp := GetAdditionalCode(temp);
        p2 := 0;
        p2 := pos('+', operand, 8);
        if (p2 = 0) then p2 := pos('+', operand);
        operand[p2] := '-';
      end;
      operand := GetWordPtrDisp16Str(p, operand, temp, '');
    end
    else if (Contains('disp8', operand, p)) then
    begin
      setlength(bytestr3, 2);
      bytestr4 := '';
      ReadByte(str, i, bytestr3);
      if (bytestr3 >= '80') then
      begin
        bytestr3 := GetAdditionalCode(bytestr3);
        p2 := 0;
        p2 := pos('+', operand, 8);
        if (p2 = 0) then p2 := pos('+', operand);
        operand[p2] := '-';
      end;
      operand := GetWordPtrDisp16Str(p, operand, bytestr3, bytestr4);
    end
    else if ('disp16' = operand) then
    begin
      setlength(bytestr3, 2);
      setlength(bytestr4, 2);
      ReadByte(str, i, bytestr3);
      ReadByte(str, i, bytestr4);
      operand := GetWordPtrDisp16Str(p, operand, bytestr3, bytestr4);
    end
    else
    begin
      operand := 'word ptr ' + operand;
    end;
  end;
  GetMemo8 := operand;
end;

function GetMemo16(str, bytestr: string; var i: integer): string;
var
  bytestr3, bytestr4, operand, temp: string;
  p, p2: integer;

begin
  operand := GetModRM(bytestr);
  if (length(operand) = 8) then
  begin
    operand := '';
  end
  else
  begin
    if (Contains('disp16', operand, p) and ('disp16' <> operand)) then
    begin
      setlength(bytestr3, 2);
      setlength(bytestr4, 2);
      ReadByte(str, i, bytestr3);
      ReadByte(str, i, bytestr4);
      temp := bytestr4 + bytestr3;
      if (temp >= '7F80') then
      begin
        temp := GetAdditionalCode(temp);
        p2 := 0;
        p2 := pos('+', operand, 8);
        if (p2 = 0) then p2 := pos('+', operand);
        operand[p2] := '-';
      end;
      operand := GetWordPtrDisp16Str(p, operand, temp, '');
    end
    else if (Contains('disp8', operand, p)) then
    begin
      setlength(bytestr3, 2);
      bytestr4 := '';
      ReadByte(str, i, bytestr3);
      if (bytestr3 >= '80') then
      begin
        bytestr3 := GetAdditionalCode(bytestr3);
        p2 := 0;
        p2 := pos('+', operand, 8);
        if (p2 = 0) then p2 := pos('+', operand);
        operand[p2] := '-';
      end;
      operand := GetWordPtrDisp16Str(p, operand, bytestr3, bytestr4);
    end
    else if ('disp16' = operand) then
    begin
      setlength(bytestr3, 2);
      setlength(bytestr4, 2);
      ReadByte(str, i, bytestr3);
      ReadByte(str, i, bytestr4);
      operand := GetWordPtrDisp16Str(p, operand, bytestr3, bytestr4);
    end
    else
    begin
      operand := 'word ptr ' + operand;
    end;
  end;
  GetMemo16 := operand;
end;

function GetFarAddres(str, bytestr: string; var i: integer): string;
var
  bytestr2, bytestr3, bytestr4: string;
begin
  readbyte(str, i, bytestr2);
  readbyte(str, i, bytestr3);
  readbyte(str, i, bytestr4);
  GetFarAddres := '0x'+bytestr4+bytestr3+':'+'0x'+bytestr2+bytestr;
end;

function Get8BitRelative(str, bytestr: string; var i: integer): string;
begin
  Get8BitRelative := '0x'+dectohex(hextodec('FF'+bytestr)+i div 2, 4);
end;

function Get16BitRelative(str, bytestr: string; var i: integer): string;
var
  bytestr2: string;
begin
  readbyte(str, i, bytestr2);
  Get16BitRelative := '0x'+dectohex(hextodec(bytestr2+bytestr)+i div 2, 4);
end;

{$R *.lfm}

{ TMainForm }

function TMainForm.GetFormateLines(str: string): string;

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

function TMainForm.GetAssemblerCode(str: string): string;
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
  while (i <= length(str)) do
  begin
    numberLine := i div 2;
    ReadByte(str, i, bytestr1);
    case bytestr1 of
      '00'..'05': //ADD
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
      '08'..'0D': //OR
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
      '10'..'15': //ADC
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
      '18'..'1D': //SBB
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
      '20'..'25': //AND
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
      '28'..'2D': //SUB
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
      '30'..'35': //XOR
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
      '38'..'3D': //CMP
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
      '06', '0E', '16', '1E': //PUSH
      begin
        operation := 'push';
        byteSReg := sRegT(getReg(bytestr1));
        operand1 := GetStrSReg(byteSReg);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '07', '17', '1F': //POP   0F not used
      begin
        operation := 'pop';
        byteSReg := sRegT(getReg(bytestr1));
        operand1 := GetStrSReg(byteSReg);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '27': //DAA
      begin
        operation := 'daa';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '2F': //DAS
      begin
        operation := 'das';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '37': //AAA
      begin
        operation := 'aaa';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '3F': //AAS
      begin
        operation := 'aas';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '70'..'7F': //JCC
      begin
        readbyte(str, i, bytestr2);
        case bytestr1 of
          '70': //JO
          begin
            operation := 'jo';
          end;
          '71': //JNO
          begin
            operation := 'jno';
          end;
          '72': //JB
          begin
            operation := 'jb';
          end;
          '73': //JNB
          begin
            operation := 'jnb';
          end;
          '74': //JE
          begin
            operation := 'je';
          end;
          '75': //JNE
          begin
            operation := 'jne';
          end;
          '76': //JBE
          begin
            operation := 'jbe';
          end;
          '77': //JNBE
          begin
            operation := 'jnbe';
          end;
          '78': //JS
          begin
            operation := 'js';
          end;
          '79': //JNS
          begin
            operation := 'jns';
          end;
          '7A': //JP
          begin
            operation := 'jp';
          end;
          '7B': //JNP
          begin
            operation := 'jnp';
          end;
          '7C': //JL
          begin
            operation := 'jl';
          end;
          '7D': //JNL
          begin
            operation := 'jnl';
          end;
          '7E': //JLE
          begin
            operation := 'jle';
          end;
          '7F': //JNLE
          begin
            operation := 'jnle';
          end;
        end;
        operand1 := Get8BitRelative(str, bytestr2, i);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '80'..'83': //ADD, OR, ADC, SBB, AND, SUB, XOR, CMP
      begin
        readbyte(str, i, bytestr2);
        reg := GetReg(bytestr2);
        case reg of
          0:  //ADD
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
              '82': //ADD r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '83': //ADD r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
          1:  //OR
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
              '82', '83': //DB
              begin
                operation := 'db';
                operand1 := bytestr1;
                i -=2;
              end;
            end;
          end;
          2:  //ADC
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
              '82': //ADC r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '83': //ADC r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
          3:  //SBB
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
              '82': //SBB r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '83': //SBB r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
          4:  //AND
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
              '82', '83': //DB
              begin
                operation := 'db';
                operand1 := bytestr1;
                i -=2;
              end;
            end;
          end;
          5:  //SUB
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
              '82': //SUB r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
              '83': //SUB r/m16, imm8
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
              end;
            end;
          end;
          6:  //XOR
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
              '82', '83': //DB
              begin
                operation := 'db';
                operand1 := bytestr1;
                i -=2;
              end;
            end;
          end;
          7:  //CMP
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
              '82': //CMP r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr2);
                operand2 := GetImm8(str, bytestr2, i);
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
      '84', '85': //TEST r/m8/r/m16, reg8/reg16
      begin
        operation := 'test';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          '84': // TEST r/m8, reg8
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            byteReg8 := reg8T(getReg(bytestr2));
            operand2 := GetStrReg8(byteReg8);
          end;
          '85': // TEST r/m16, reg16
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            byteReg16 := reg16T(getReg(bytestr2));
            operand2 := GetStrReg16(byteReg16);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '86', '87': //XCHG reg8/reg16, r/m8/r/m16
      begin
        operation := 'xchg';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          '86': // XCHG reg8, r/m8
          begin
            byteReg8 := reg8T(getReg(bytestr2));
            operand1 := GetStrReg8(byteReg8);
            operand2 := GetROrMem8(str, bytestr2, i);
          end;
          '87': // XCHG reg16, r/m16
          begin
            byteReg16 := reg16T(getReg(bytestr2));
            operand1 := GetStrReg16(byteReg16);
            operand2 := GetROrMem16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '88'..'8C': //MOV
      begin
        operation := 'mov';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          '88':  //MOV  r/m8, reg8
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            byteReg8 := reg8T(getReg(bytestr2));
            operand2 := GetStrReg8(byteReg8);
          end;
          '89':  //MOV  r/m16, reg16
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            byteReg16 := reg16T(getReg(bytestr2));
            operand2 := GetStrReg16(byteReg16);
          end;
          '8A':  //MOV  reg8, r/m8
          begin
            byteReg8 := reg8T(getReg(bytestr2));
            operand1 := GetStrReg8(byteReg8);
            operand2 := GetROrMem8(str, bytestr2, i);
          end;
          '8B':  //MOV  reg16, r/m16
          begin
            byteReg16 := reg16T(getReg(bytestr2));
            operand1 := GetStrReg16(byteReg16);
            operand2 := GetROrMem16(str, bytestr2, i);
          end;
          '8C':  //MOV r/m16, sreg
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            byteSReg := sRegT(getReg(bytestr2));
            operand2 := GetStrSReg(byteSReg);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '8D': //LEA
      begin
        operation := 'lea';
        readbyte(str, i, bytestr2);
        byteReg16 := reg16T(GetReg(bytestr2));
        operand1 := GetStrReg16(byteReg16);
        operand2 := GetROrMem16(str, bytestr2, i);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '8E': //MOV sreg, r/m16
      begin
        operation := 'mov';
        readbyte(str, i, bytestr2);
        byteSReg := sRegT(getReg(bytestr2));
        operand1 := GetStrSReg(byteSReg);
        operand2 := GetROrMem16(str, bytestr2, i);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '8F': //POP
      begin
        readbyte(str, i, bytestr2);
        reg := GetReg(bytestr2);
        case reg of
          0: //POP
          begin
            operation := 'pop';
            operand1 := GetROrMem16(str, bytestr2, i);
          end;
          else //DB
          begin
            operation := 'db';
            operand1 := bytestr1;
            i -=2;
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '90': //NOP
      begin
        operation := 'nop';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '91'..'97': //XCHG
      begin
        operation := 'xchg';
        operand1 := 'AX';
        byteReg16 := reg16T(getRM(bytestr1));
        operand2 := GetStrReg16(byteReg16);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '98': //CBW
      begin
        operation := 'cbw';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '99': //CWD
      begin
        operation := 'cwd';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '9A': //CALL
      begin
        operation := 'call';
        readbyte(str, i, bytestr2);
        operand1 := GetFarAddres(str, bytestr2, i);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '9B': //WAIT
      begin
        operation := 'wait';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '9C': //PUSHF
      begin
        operation := 'pushf';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '9D': //POPF
      begin
        operation := 'popf';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '9E': //SAHF
      begin
        operation := 'sahf';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      '9F': //LAHF
      begin
        operation := 'lahf';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'A0'..'A3': //MOV
      begin
        operation := 'mov';
        readbyte(str, i, bytestr2);
        readbyte(str, i, bytestr3);
        case bytestr1 of
          'A0': //MOV AL, MEMO8
          begin
            operand1 := 'AL';
            operand2 := GetBytePtrDisp8Str(pos, operand1, bytestr2, bytestr3);
          end;
          'A1': //MOV AX, MEMO16
          begin
            operand1 := 'AX';
            operand2 := GetWordPtrDisp16Str(pos, operand1, bytestr2, bytestr3);
          end;
          'A2': //MOV MEMO8, AL
          begin
            operand1 := GetBytePtrDisp8Str(pos, operand1, bytestr2, bytestr3);
            operand2 := 'AL';
          end;
          'A3': //MOV MEMO16, AX
          begin
            operand1 := GetWordPtrDisp16Str(pos, operand1, bytestr2, bytestr3);
            operand2 := 'AX';
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'A4': //MOVSB
      begin
        operation := 'movsb';
        operand1 := 'byte ptr es:[di]';
        operand2 := 'byte ptr ds:[si]';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'A5': //MOVSW
      begin
        operation := 'movsw';
        operand1 := 'word ptr es:[di]';
        operand2 := 'word ptr ds:[si]';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'A6': //CMPSB
      begin
        operation := 'cmpsb';
        operand1 := 'byte ptr ds:[si]';
        operand2 := 'byte ptr es:[di]';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'A7': //CMPSW
      begin
        operation := 'cmpsw';
        operand1 := 'word ptr ds:[si]';
        operand2 := 'word ptr es:[di]';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'A8', 'A9': //TEST AL/AX, IMM8/IMM16
      begin
        operation := 'test';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          'A8': //TEST AL, IMM8
          begin
            operand1 := 'AL';
            operand2 := GetImm8(str, bytestr2, i);
          end;
          'A9': //TEST AX, IMM16
          begin
            operand1 := 'AX';
            operand2 := GetImm16(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'AA', 'AB': //STOSB, STOSW
      begin
        case bytestr1 of
          'AA': //STOSB
          begin
            operation := 'stosb';
            operand1 := 'byte ptr es:[di]';
            operand2 := 'AL';
          end;
          'AB': //STOSW
          begin
            operation := 'stosw';
            operand1 := 'word ptr es:[di]';
            operand2 := 'AX';
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'AC', 'AD': //LODSB, LODSW
      begin
        case bytestr1 of
          'AC':  //LODSB AL = DS:[SI]
          begin
            operation := 'lodsb';
            operand1 := 'AL';
            operand2 := 'byte ptr [SI]';
          end;
          'AD':  //LODSW AX = DS:[SI]
          begin
            operation := 'lodsw';
            operand1 := 'AX';
            operand2 := 'word ptr [SI]';
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'AE', 'AF': //SCASB, SCASW
      begin
        case bytestr1 of
          'AE':  //SCASB
          begin
            operation := 'scasb';
            operand1 := 'AL';
            operand2 := 'byte ptr es:[di]';
          end;
          'AF':  //SCASW
          begin
            operation := 'scasw';
            operand1 := 'AX';
            operand2 := 'word ptr es:[di]';
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
      'C2', 'C3': //RET
      begin
        operation := 'ret';
        case bytestr1 of
          'C2': //RET IMM16
          begin
            readbyte(str, i, bytestr2);
            operand1 := getimm16(str, bytestr2, i);
          end;
          'C3': //RET
          begin
          // Nothing :)
        end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'C4', 'C5': //LDS, LES  reg16, mem16
      begin
        case bytestr1 of
          'C4':  //LES reg16, mem16
          begin
            operation := 'les';
          end;
          'C5':  //LDS reg16, mem16
          begin
            operation := 'lds';
          end;
        end;
        readbyte(str, i, bytestr1);
        byteReg16 := reg16T(GetReg(bytestr1));
        operand1 := GetStrReg16(byteReg16);
        operand2 := GetMemo16(str, bytestr1, i);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'C6', 'C7': //MOV  r/m8/16, imm8/16
      begin
        operation := 'mov';
        readbyte(str, i, bytestr2);
        reg := getReg(bytestr2);
        case reg of
          0:
          begin
            case bytestr1 of
              'C6': //MOV  r/m8, imm8
              begin
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr3);
                operand2 := GetImm8(str, bytestr3, i);
              end;
              'C7': //MOV  r/m16, imm16
              begin
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr3);
                operand2 := GetImm16(str, bytestr3, i);
              end;
            end;
          end
          else //DB
          begin
            operation := 'db';
            operand1 := bytestr1;
            i -=2;
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2,
          bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2,
          bytestr3, bytestr4, prefix1, prefix2);
      end;
      'CA', ' CB': //RET
      begin
        operation := 'ret';
        case bytestr1 of
          'CA': //RET IMM16
          begin
            readbyte(str, i, bytestr2);
            operand1 := getimm16(str, bytestr2, i);
          end;
          'CB': //RET
          begin
            // Nothing :)
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'CC'..'CE': //INT INT3 INTO
      begin
        case bytestr1 of
          'CC':  //INT3
          begin
            operation := 'int3';
          end;
          'CD':  //INT
          begin
            operation := 'int';
            readbyte(str, i, bytestr2);
            operand1 := getimm8(str, bytestr2, i);
          end;
          'CE':  //INTO
          begin
            operation := 'into'
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'CF': //IRET
      begin
        operation := 'iret';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'D0'..'D3': //ROL, ROR, RCL, RCR, SHL, SHR, SAR
      begin
        readbyte(str, i, bytestr2);
        reg := getReg(bytestr2);
        case bytestr1 of
          'D0': // r/m8, 1
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            operand2 := '1';
            case reg of
              0: //ROL
              begin
                operation := 'rol';
              end;
              1: //ROR
              begin
                operation := 'ror';
              end;
              2: //RCL
              begin
                operation := 'rcl';
              end;
              3: //RCR
              begin
                operation := 'rcr';
              end;
              4: //SHL
              begin
                operation := 'shl';
              end;
              5: //SHR
              begin
                operation := 'shr';
              end;
              6: //DB
              begin
                operation := 'db';
                operand1 := bytestr1;
                i -=2;
              end;
              7: //SAR
              begin
                operation := 'sar';
              end;
            end;
          end;
          'D1': // r/m16, 1
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            operand2 := '1';
            case reg of
              0: //ROL
              begin
                operation := 'rol';
              end;
              1: //ROR
              begin
                operation := 'ror';
              end;
              2: //RCL
              begin
                operation := 'rcl';
              end;
              3: //RCR
              begin
                operation := 'rcr';
              end;
              4: //SHL
              begin
                operation := 'shl';
              end;
              5: //SHR
              begin
                operation := 'shr';
              end;
              6: //DB
              begin
                operation := 'db';
                operand1 := bytestr1;
                i -=2;
              end;
              7: //SAR
              begin
                operation := 'sar';
              end;
            end;
          end;
          'D2': // r/m8, cl
          begin
            operand1 := GetROrMem8(str, bytestr2, i);
            operand2 := 'CL';
            case reg of
              0: //ROL
              begin
                operation := 'rol';
              end;
              1: //ROR
              begin
                operation := 'ror';
              end;
              2: //RCL
              begin
                operation := 'rcl';
              end;
              3: //RCR
              begin
                operation := 'rcr';
              end;
              4: //SHL
              begin
                operation := 'shl';
              end;
              5: //SHR
              begin
                operation := 'shr';
              end;
              6: //DB
              begin
                operation := 'db';
                operand1 := bytestr1;
                i -=2;
              end;
              7: //SAR
              begin
                operation := 'sar';
              end;
            end;
          end;
          'D3': // r/m16, cl
          begin
            operand1 := GetROrMem16(str, bytestr2, i);
            operand2 := 'CL';
            case reg of
              0: //ROL
              begin
                operation := 'rol';
              end;
              1: //ROR
              begin
                operation := 'ror';
              end;
              2: //RCL
              begin
                operation := 'rcl';
              end;
              3: //RCR
              begin
                operation := 'rcr';
              end;
              4: //SHL
              begin
                operation := 'shl';
              end;
              5: //SHR
              begin
                operation := 'shr';
              end;
              6: //DB
              begin
                operation := 'db';
                operand1 := bytestr1;
                i -=2;
              end;
              7: //SAR
              begin
                operation := 'sar';
              end;
            end;
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'D4': //AMM
      begin
        operation := 'aam';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'D5': //AAD
      begin
        operation := 'add';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'D7': //XLAT
      begin
        operation := 'xlatb';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'E0'..'E3': //LOOPNE, LOOPE, LOOP, JCXZ 8-bit relative
      begin
        readbyte(str, i, bytestr2);
        operand1 := Get8BitRelative(str, bytestr2, i);
        case bytestr1 of
          'E0': //LOOPNE 8-bit relative
          begin
            operation := 'loopne';
          end;
          'E1': //LOOPE 8-bit relative
          begin
            operation := 'loope';
          end;
          'E2': //LOOP 8-bit relative
          begin
            operation := 'loop';
          end;
          'E3': //JCXZ 8-bit relative
          begin
            operation := 'jcxz';
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'E4', 'E5': //IN  AL/AX, imm8
      begin
        operation := 'in';
        case bytestr1 of
          'E4':  //IN AL, addr8
          begin
            operand1 := 'AL';
            readbyte(str, i, bytestr2);
            operand2 := getimm8(str, bytestr2, i);
          end;
          'E5':  //IN AX, addr8
          begin
            operand1 := 'AX';
            readbyte(str, i, bytestr2);
            operand2 := getimm8(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'E6', 'E7': //OUT imm8, AL/AX
      begin
        operation := 'out';
        case bytestr1 of
          'E6':  //OUT AL, addr8
          begin
            readbyte(str, i, bytestr2);
            operand1 := getimm8(str, bytestr2, i);
            operand2 := 'AL';
          end;
          'E7':  //OUT AX, addr8
          begin
            readbyte(str, i, bytestr2);
            operand1 := getimm8(str, bytestr2, i);
            operand2 := 'AX';
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'E8': //CALL
      begin
        operation := 'call';
        readbyte(str, i, bytestr2);
        operand1 := Get16BitRelative(str, bytestr2, i);
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'E9'..'EB': //JMP
      begin
        operation := 'jmp';
        readbyte(str, i, bytestr2);
        case bytestr1 of
          'E9': //JMP NEAR-LABEL
          begin
            operand1 := Get16BitRelative(str, bytestr2, i);
          end;
          'EA': //JMP FAR-LABEL
          begin
            operand1 := GetFarAddres(str, bytestr2, i);
          end;
          'EB': //JMP SHORT-LABEL
          begin
            operand1 := Get8BitRelative(str, bytestr2, i);
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'EC', 'ED': //IN  AL/AX, port[DX]
      begin
        operation := 'in';
        case bytestr1 of
          'EC': //IN  AL, port[DX]
          begin
            operand1 := 'AL';
            operand2 := 'DX';
          end;
          'ED': //IN  AX, port[DX]
          begin
            operand1 := 'AX';
            operand2 := 'DX';
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'EE', 'EF': //OUT  AL/AX, port[DX]
      begin
        operation := 'out';
        case bytestr1 of
          'EE': //OUT  AL, port[DX]
          begin
            operand1 := 'DX';
            operand2 := 'AL';
          end;
          'EF': //OUT  AX, port[DX]
          begin
            operand1 := 'DX';
            operand2 := 'AX';
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
      'F5': //CMC
      begin
        operation := 'cmc';
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'F6', 'F7': //TEST, NOT, NEG, MUL, IMUL, DIV, IDIV
      begin
        readbyte(str, i, bytestr2);
        reg := GetReg(bytestr2);
        case bytestr1 of
          'F6': //TEST, NOT, NEG, MUL, IMUL, DIV, IDIV
          begin
            case reg of
              0: //TEST
              begin
                operation := 'test';
                operand1 := GetROrMem8(str, bytestr2, i);
                readbyte(str, i, bytestr3);
                operand2 := GetImm8(str, bytestr3, i);
              end;
              1: //DB
              begin
                operation := 'db';
                operand1 := bytestr1;
                i -=2;
              end;
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
          'F7': //TEST, NOT, NEG, MUL, IMUL, DIV, IDIV
          begin
            case reg of
              0: //TEST
              begin
                operation := 'test';
                operand1 := GetROrMem16(str, bytestr2, i);
                readbyte(str, i, bytestr3);
                operand2 := GetImm16(str, bytestr3, i);
              end;
              1: //DB
              begin
                operation := 'db';
                operand1 := bytestr1;
                i -=2;
              end;
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
      'F8'..'FD': //CLC, STC, CLI, STI, CLD, STD
      begin
        case bytestr1 of
          'F8': //CLC
          begin
            operation := 'clc';
          end;
          'F9': //STC
          begin
            operation := 'stc';
          end;
          'FA': //CLI
          begin
            operation := 'cli';
          end;
          'FB': //STI
          begin
            operation := 'sti';
          end;
          'FC': //CLD
          begin
            operation := 'cld';
          end;
          'FD': //STD
          begin
            operation := 'std';
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'FE'..'FF': //INC, DEC, CALL, JMP, PUSH
      begin
        readbyte(str, i, bytestr2);
        reg := GetReg(bytestr2);
        case bytestr1 of
          'FE': //INC, DEC
          begin
            case reg of
              0: //INC
              begin
                operation := 'inc';
                operand1 := GetROrMem8(str, bytestr2, i);
              end;
              1: //DEC
              begin
                operation := 'dec';
                operand1 := GetROrMem8(str, bytestr2, i);
              end;
              else //DB
              begin
                operation := 'db';
                operand1 := bytestr1;
                i -=2;
              end;
            end;
          end;
          'FF': //INC, DEC, CALL, JMP, PUSH
          begin
            case reg of
              0: //INC mem16
              begin
                operation := 'inc';
                operand1 := GetMemo16(str, bytestr2, i);
              end;
              1: //DEC mem16
              begin
                operation := 'dec';
                operand1 := GetMemo16(str, bytestr2, i);
              end;
              2: //CALL r/m16
              begin
                operation := 'call';
                operand1 := GetROrMem16(str, bytestr2, i);
              end;
              3: //CALL mem16
              begin
                operation := 'call';
                operand1 := GetMemo16(str, bytestr2, i);
              end;
              4: //JMP r/m16
              begin
                operation := 'jmp';
                operand1 := GetROrMem16(str, bytestr2, i);
              end;
              5: //JMP mem16
              begin
                operation := 'jmp';
                operand1 := GetMemo16(str, bytestr2, i);
              end;
              6: //PUSH mem16
              begin
                operation := 'push';
                operand1 := GetMemo16(str, bytestr2, i);
              end;
              7: //DB
              begin
                operation := 'db';
                operand1 := bytestr1;
                i -= 2;
              end;
            end;
          end;
        end;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
      'F0': prefix1 := 'LOCK';
      'F2': prefix1 := 'REPNZ';
      'F3': prefix1 := 'REP';
      '26': prefix2 := 'ES';
      '2E': prefix2 := 'CS';
      '36': prefix2 := 'SS';
      '3E': prefix2 := 'DS';
      else // DB
      begin
        operation := 'db';
        operand1 := bytestr1;
        resstr += GetOutputStr(numberLine, operation, operand1, operand2, bytestr1, prefix1, prefix2);
        clearstr(operation, operand1, operand2, bytestr1, bytestr2, bytestr3, bytestr4, prefix1, prefix2);
      end;
    end; // case
  end;   // while
  GetAssemblerCode := resstr;
end;

function TMainForm.TryReadFile(var f: file; var resstr, errorstr: string): boolean;
var
  str: string;
  b: byte;
  run: boolean;

begin
  run := true;
  str := '';
  {$I-}
  reset(f, 1);
  {$I+}
  if (ioresult <> 0) then
  begin
    errorstr := 'Ошибка открытия файла №' + IntToStr(ioresult);
    run := False;
  end
  else
  begin
    while ((run) and (not EOF(f))) do
    begin
      {$I-}
      blockread(f, b, sizeof(b));
      {$I+}
      if (ioresult <> 0) then
      begin
        errorstr := 'Ошибка чтения файла №' + IntToStr(ioresult);
        run := False;
      end
      else
        str += DecToHex(b, 2);
    end;
    {$I-}
    closefile(f);
    {$I+}
    if (ioresult <> 0) then
    begin
      errorstr := 'Ошибка закрытия файла №' + IntToStr(ioresult);
      run := False;
    end;
  end;
  resstr := str;
  TryReadFile := run;
end;

function TMainForm.TrySaveFile(var f: file; str: string; var errorstr: string): boolean;
var
  ch: char;
  run: boolean;
  i: integer;

begin
  i := 1;
  run := true;
  {$I-}
  rewrite(f, 1);
  {$I+}
  if (ioresult <> 0) then
  begin
    errorstr := 'Ошибка открытия файла №' + IntToStr(ioresult);
    run := False;
  end
  else
  begin
    while ((run) and (i <= length(str))) do
    begin
      ch := str[i];
      {$I-}
      blockwrite(f, ch, sizeof(ch));
      {$I+}
      i += 1;
      if (ioresult <> 0) then
      begin
        errorstr := 'Ошибка записи в файл №' + IntToStr(ioresult);
        run := False;
      end;
    end;
    {$I-}
    closefile(f);
    {$I+}
    if (ioresult <> 0) then
    begin
      errorstr := 'Ошибка закрытия файла №' + IntToStr(ioresult);
      run := False;
    end;
  end;
  TrySaveFile := run;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MemoByteCode.Text := '';
  MemoAssembler.Text := '';
end;

procedure TMainForm.MenuItemCloseFileClick(Sender: TObject);
begin
  MemoByteCode.Text := '';
  MemoAssembler.Text := '';
  MemoByteCode.Font.Size := 9;
  MemoAssembler.Font.Size := 9;
  MenuItemSaveFile.Enabled := False;
  MenuItemCloseFile.Enabled := False;
end;

procedure TMainForm.MenuItemExitClick(Sender: TObject);
begin
  MainForm.Close;
end;

procedure TMainForm.MenuItemSaveFileClick(Sender: TObject);
var
  errorstr: string;

begin
  if (SaveDialog.Execute) then
  begin
    assignfile(f, SaveDialog.FileName);
    if (not TrySaveFile(f, MemoAssembler.Text, errorstr)) then
    begin
       Application.MessageBox(PChar(errorstr), 'Ошибка', MB_ICONERROR);
    end;
  end;
end;

procedure TMainForm.MenuItemTakeFileClick(Sender: TObject);
var
  resread, hex, assemblerCode, errorstr: string;

begin
  if (OpenDialog.Execute) then
  begin
    assignfile(f, OpenDialog.FileName);
    if (TryReadFile(f, resread, errorstr)) then
    begin
      hex := GetFormateLines(resread);
      assemblerCode := GetAssemblerCode(resread);
      MemoByteCode.Text := hex;
      MemoAssembler.Text := assemblerCode;
      MenuItemSaveFile.Enabled := True;
      MenuItemCloseFile.Enabled := True;
    end
    else
    begin
       Application.MessageBox(PChar(errorstr), 'Ошибка', MB_ICONERROR);
    end;
  end;
end;

procedure TMainForm.MenuItemZoomInClick(Sender: TObject);
var
  size: integer;
begin
  if (MemoByteCode.Font.Size < 20) then
  begin
      size := MemoByteCode.Font.Size + 1;
      MemoByteCode.Font.Size := size;
      MemoAssembler.Font.Size := size;
  end;
end;

procedure TMainForm.MenuItemZoomOutClick(Sender: TObject);
var
  size: integer;
begin
  if (MemoByteCode.Font.Size > 5) then
  begin
      size := MemoByteCode.Font.Size - 1;
      MemoByteCode.Font.Size := size;
      MemoAssembler.Font.Size := size;
  end;
end;

end.

