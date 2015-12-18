type
   TBankObject = record
     id: String;
     color, tol: Int32;
     setting: TColorSettings;
     splitDist: Int32;
     minArea, maxArea: Int32;
     minLen, maxLen: Int32;
   end;

var
  BANK_VARROCK_WEST,
  BANK_VARROCK_EAST,
  BANK_ALKHARID,
  BANK_FALADOR_WEST,
  BANK_FALADOR_EAST,
  BANK_CAMELOT: TBankObject;


{$ifndef CodeInsight}
begin
  with BANK_VARROCK_WEST do
  begin
    id := 'BANK_VARROCK_WEST';
    color := 5191231;
    tol := 20;
    setting := ColorSetting(2, 0.2, 0.8);
    splitDist := 2;
    minArea := 20*20;
    maxArea := 40*40;
  end;

  with BANK_VARROCK_EAST do
  begin
    id := 'BANK_VARROCK_EAST';
    color := 5191231;
    tol := 20;
    setting := ColorSetting(2, 0.2, 0.8);
    splitDist := 2;
    minArea := 20*20;
    maxArea := 40*40;
  end;

  with BANK_ALKHARID do
  begin
    id := 'BANK_ALKHARID';
    color := 7171703;
    tol := 20;
    setting := ColorSetting(2,0.2,0.2);
    splitDist := 2;
    minArea := 20*20;
    maxArea := 40*40;
  end;

  with BANK_FALADOR_WEST do
  begin
    id := 'BANK_FALADOR_WEST';
    color := 7171703;
    tol := 20;
    setting := ColorSetting(2,0.2,0.2);
    splitDist := 2;
    minArea := 20*20;
    maxArea := 40*40;
  end;

  with BANK_FALADOR_EAST do
  begin
    id := 'BANK_FALADOR_EAST';
    color := 4415608;
    tol := 16;
    setting := ColorSetting(2,0.15,0.2);
    splitDist := 2;
    minArea := 10*10;
    maxArea := 30*30;
    minLen := 26*10;
    maxLen := 38*18;
  end;

  with BANK_CAMELOT do
  begin
    id := 'BANK_CAMELOT';
    color := 3691619;
    tol := 16;
    setting := ColorSetting(2,0.15,0.2);
    splitDist := 2;
    minArea := 7*7;
    maxArea := 30*30;
    minLen := 25*8;
    maxLen := 42*25;
  end;
end;
{$endif}


function BankIsOpen(): Boolean;
const
  FONT_SETTING:TCompareRules = [2070783,1];
var txt:String;
begin
  txt := ocr.Recognize(Box(181,16,341,34), FONT_SETTING, UpFont);
  Result := Pos('Bank of RuneScape', txt) > 0;
  if not Result then
  begin
    txt := ocr.Recognize(Box(54,295,154,314), FONT_SETTING, SmallFont);
    Result := Pos('Rearrange mode', txt) > 0;
  end;
end;


function OpenBank(bank:TBankObject): Boolean;
var
  i,j:Int32;
  TPA:TPointArray;
  ATPA:T2DPointArray;
  B:TBox;
  TBA:TBoxArray;
begin
  if BankIsOpen() then Exit(True);
  FindColorsTolerance(TPA, bank.color, mainScreen.FBounds, bank.tol, bank.setting);

  ATPA := ClusterTPA(TPA,bank.splitDist);
  SortATPAFromMidPoint(ATPA,Point(260,170));
  for i:=0 to High(ATPA) do
  begin
    B := GetTPABounds(ATPA[i]);
    if not InRange(B.Area(), bank.minArea, bank.maxArea) then
      Continue;
    if (bank.maxLen > 0) and not(InRange(Length(ATPA[i]), bank.minLen, bank.maxLen)) then
      Continue;
    TBA += B;
  end;
  {$IFDEF SMART_DEBUG}Smart.Image.drawBoxes(TBA,False,255);{$ENDIF}
  for i:=0 to High(TBA) do
  begin
    Mouse.Move(TBA[i]);
    if mainscreen.IsUpText(['Banker','Bank Bank']) then
    begin
      wait(Random(130,260));
      if not mainscreen.IsUpText(['Banker','Bank Bank']) then
        Continue();
      ChooseOption.Open();
      ChooseOption.Select(['Bank Bank']);
      for j:=0 to 300 do
      begin
        Result := BankIsOpen();
        if Result then
          Break(2)
        else
          Wait(50);
      end;
    end;
  end;
  {$IFDEF SMART_DEBUG}Smart.Image.drawBoxes(TBA,False,0);{$ENDIF}
end;


function CloseBank(): Boolean;
var
  i:Int32;
  B:TBox = [477,14,495,32];
begin
  if not(BankIsOpen()) then Exit(True);
  mouse.Click(B,mouse_left);
  for i:=0 to 100 do
    if not(BankIsOpen()) then Exit(True) else Wait(50);
end;


function DepositAll(): Boolean;
var
  i:Int32;
  B:TBox = [428,298,458,326];
begin
  if not(BankIsOpen()) then Exit(False);
  if length(inventory.GetUsedSlots) = 0 then Exit(True);
  mouse.Click(B,mouse_left);
  for i:=0 to 10 do
    if length(inventory.GetUsedSlots) = 0 then Exit(True) else Wait(50);
end;


function WithdrawItems(slot:Int32; Option:String='1'; X:Int32=0): Boolean;
var
  i:Int32;
  txt:String;
  B:TBox = [66,82,448,296];
  Slots:TBoxArray;
begin
  Slots := B.PartitionEx(6,8,-7,-2);
  {$IFDEF SMART_DEBUG}Smart.Image.drawBoxes(Slots,False,255);{$ENDIF}
  Mouse.Move(Slots[slot]);
  ChooseOption.Open();
  if not ChooseOption.Select(['Withdraw-'+Option]) then Exit(False);
  Result := True;
  if Pos('X',Option) = 1 then
  begin
    for i:=0 to 200 do
    begin
      txt := GetTextAtEx(Box(212,393,307,410),0,3,4,0,10,'UpChars07');
      if Pos('Enter amount',txt) <> 0 then
        Break;
      Wait(10);
    end;
    Keyboard.Send(IntToStr(X), VK_RETURN);
  end;
end;


{$IFDEF SMART}
function DebugBankSlots(): Boolean;
var
  i:Int32;
  B:TBox = [66,82,448,296];
  Slots:TBoxArray;
begin
  Slots := B.PartitionEx(6,8,-7,-2);
  Smart.Image.drawBoxes(Slots,False,255);
  for i:=0 to High(Slots) do
  begin
    Smart.Image.DrawText(ToString(i), Point(Slots[i].x1+2,Slots[i].y1+17), 1252386);
    Smart.Image.DrawText(ToString(i), Point(Slots[i].x1+2,Slots[i].y1+18), $FFFF00);
  end;
end;
{$ENDIF}
