unit PulScripts;

interface

const
  gdi32 = 'gdi32.dll';
  user32 = 'user32.dll';
{$IF Defined(NEXTGEN) and Declared(System.Embedded)}
  kernelbase = 'kernelbase.dll';
{$ELSE}
  kernelbase = 'kernel32.dll';
{$ENDIF}
  kernel32 = 'kernel32.dll';

type
  IInt = type Integer;
  HDC = type NativeUInt;
  HBITMAP = type NativeUInt;
  HGDIOBJ = type NativeUInt;

  _RECT = record
    left, top, right, bottom: Longint;
  end;

  _Point = record
    X, Y: Longint;
  end;

  TBitmapInfoHeader = packed record
    biSize: LongWord;
    biWidth: Longint;
    biHeight: Longint;
    biPlanes: WORD;
    biBitCount: WORD;
    biCompression: LongWord;
    biSizeImage: LongWord;
    biXPelsPerMeter: Longint;
    biYPelsPerMeter: Longint;
    biClrUsed: LongWord;
    biClrImportant: LongWord;
  end;

  TBmpHeader = packed record
    bfType: WORD;
    bfSize: Longint;
    bfReserved: Longint;
    bfOffBits: Longint;
    biSize: LongWord;
    biWidth: Longint;
    biHeight: Longint;
    biPlanes: WORD;
    biBitCount: WORD;
    biCompression: LongWord;
    biSizeImage: LongWord;
    biXPelsPerMeter: Longint;
    biYPelsPerMeter: Longint;
    biClrUsed: LongWord;
    biClrImportant: LongWord;
  end;

  tagBITMAPINFO = record
    bmiHeader: TBitmapInfoHeader;
    bmiColors: array [0 .. 0] of record rgbBlue: Byte;
    rgbGreen: Byte;
    rgbRed: Byte;
    rgbReserved: Byte;
  end;

end;

function ScrWindows(FileName: string; X, Y, Width, Height: Integer;
  wint: Boolean = false; ABpp: Integer = 32; Wnd: IInt = 0): Boolean;
  function PixelSearch(out OutRes: _Point; left, top, right, bottom,
    color: Integer; nVar: Byte = 0; hwnd: IInt = 0): Boolean;

implementation

function CreateDIBSection(DC: HDC; const p2: tagBITMAPINFO; p3: LongWord;
  var p4: Pointer; p5: NativeUInt; p6: LongWord): HBITMAP; stdcall;
  external gdi32 name 'CreateDIBSection';

function GetSystemMetrics(nIndex: Integer): Integer; stdcall;
  external 'user32.dll' name 'GetSystemMetrics';
function GetSysColor(nIndex: Integer): LongWord; stdcall;
  external 'user32.dll' name 'GetSysColor';
function IsWindow(hwnd: IInt): Boolean; stdcall;
  external 'user32.dll' name 'IsWindow';
function GetClientRect(hwnd: IInt; var lpRect: _RECT): Boolean; stdcall;
  external 'user32.dll' name 'GetClientRect';

function ScreenToClient(hwnd: IInt; var lpPoint: _Point): Boolean; stdcall;
  external 'user32.dll' name 'ScreenToClient';

function GetWindowRect(hwnd: IInt; var lpRect: _RECT): Boolean; stdcall;
  external user32 name 'GetWindowRect';

function GetDC(hwnd: IInt): IInt; stdcall; external 'user32.dll' name 'GetDC';
function BitBlt(DestDC: IInt; X, Y, Width, Height: Integer; SrcDC: IInt;
  XSrc, YSrc: Integer; Rop: LongWord): Boolean; stdcall;
  external 'gdi32.dll' name 'BitBlt';
function ReleaseDC(hwnd: IInt; HDC: IInt): Integer; stdcall;
  external 'user32.dll' name 'ReleaseDC';
function CharUpperBuff(lpsz: PWideChar; cchLength: LongWord): LongWord; stdcall;
  external 'user32.dll' name 'CharUpperBuffW';
function CloseHandle(hObject: NativeUInt): Boolean; stdcall;
  external 'kernel32.dll' name 'CloseHandle';
function DeleteDC(DC: HDC): Boolean; stdcall; external gdi32 name 'DeleteDC';
function DeleteObject(p1: HGDIOBJ): Boolean; stdcall;
  external gdi32 name 'DeleteObject';
function SystemParametersInfo(uiAction, uiParam: LongWord; pvParam: Pointer;
  fWinIni: LongWord): Boolean; external user32 name 'SystemParametersInfoW';
function CreateCompatibleDC(DC: HDC): HDC; stdcall;
  external gdi32 name 'CreateCompatibleDC';
function SelectObject(DC: HDC; p2: HGDIOBJ): HGDIOBJ; stdcall;
  external gdi32 name 'SelectObject';
function CreateFile(lpFileName: PWideChar;
  dwDesiredAccess, dwShareMode: LongWord; lpSecurityAttributes: Pointer;
  dwCreationDisposition, dwFlagsAndAttributes: LongWord;
  hTemplateFile: NativeUInt): NativeUInt; stdcall;
  external kernelbase name 'CreateFileW';

function WriteFile(hFile: THandle; const Buffer;
  nNumberOfBytesToWrite: LongWord; var lpNumberOfBytesWritten: LongWord;
  lpOverlapped: Pointer): Boolean; stdcall; external kernel32 name 'WriteFile';
function GetModuleFileName(hModule: HINST; lpFileName: PWideChar;
  nSize: LongWord): LongWord; stdcall;
  external kernel32 name 'GetModuleFileNameW';


function GetHandleTRect(GHandle: IInt; out rect: _RECT): Boolean;
begin
  rect.left := 0;
  rect.right := 0;
  rect.bottom := 0;
  rect.right := 0;

  if IsWindow(GHandle) then
    Result := GetClientRect(GHandle, rect)
  else
    Result := GetWindowRect(GHandle, rect);
end;

function ScrWindowsEx(Wnd: IInt; SrcDC: IInt; X, Y, Width, Height, XSrc,
  YSrc: Integer; Rop: LongWord = $00CC0020): Boolean;
Var
  DC: IInt;
begin
  Result := false;

  DC := GetDC(Wnd);
  if DC <> 0 then
  begin
    Result := BitBlt(SrcDC, X, Y, Width, Height, DC, XSrc, YSrc, Rop);
    ReleaseDC(Wnd, DC);
  end;
end;

function Create_DIB(out Bmi: tagBITMAPINFO; var Bits: Pointer;
  var Handle: HBITMAP; Width, Height: Longint; bit: WORD = 24): Boolean;
var
  BitmapSize: Integer;
begin
  Result := true;
  FillChar(Bmi, SizeOf(Bmi), 0);
  BitmapSize := Width * Height shl 2;
  with Bmi.bmiHeader do
  begin
    biSizeImage := BitmapSize + SizeOf(TBmpHeader);
    biSize := $28;
    biWidth := Width;
    biHeight := Height;
    biPlanes := 1;
    biBitCount := bit;
    biCompression := 0;
    biXPelsPerMeter := 0;
    biYPelsPerMeter := 0;
    biClrUsed := 0;
    biClrImportant := 0;
  end;

  Handle := CreateDIBSection(0, Bmi, 0, Bits, 0, 0);
  if Handle = 0 then
  begin
    Result := false;
    FillChar(Bmi, SizeOf(Bmi), 0);
  end;
end;

procedure FreeVars__(out DC: HDC; out Handle: HBITMAP; out Bmi: tagBITMAPINFO);
begin
  if DC <> 0 then
    DeleteDC(DC);
  if Handle <> 0 then
    DeleteObject(Handle);
  FillChar(Bmi, SizeOf(Bmi), 0);
  DC := 0;
  Handle := 0;
end;

function ScrWindows(FileName: string; X, Y, Width, Height: Integer;
  wint: Boolean = false; ABpp: Integer = 32; Wnd: IInt = 0): Boolean;
var
  rect, panel: _RECT;
  hDC1: HDC;
  Bmi: tagBITMAPINFO;
  Bits: ^Byte;
  Handle: HBITMAP;
   i: LongWord;
  hFile: LongWord;
  Header: TBmpHeader;
begin
  Result := false;

  if not GetHandleTRect(Wnd, rect) then
  begin
    SystemParametersInfo($0030, 0, @panel, 0);

    if Width = 0 then
    begin
      if wint then
        rect.right := panel.right
      else
        rect.right := GetSystemMetrics(0);
    end
    else
      rect.right := Width;

    if Height = 0 then
    begin
      if wint then
        rect.bottom := panel.bottom
      else
        rect.bottom := GetSystemMetrics(1);
    end
    else
      rect.bottom := Height;
  end
  else
  begin
    if Width = 0 then
      rect.right := rect.right
    else
      rect.right := Width;

    if Height = 0 then
      rect.bottom := rect.bottom
    else
      rect.bottom := Height;
  end;

  X := abs(X);
  Y := abs(Y);

  if Create_DIB(Bmi, Pointer(Bits), Handle, rect.right - X, rect.bottom - Y,
    ABpp) then
  begin

    hDC1 := CreateCompatibleDC(0);
    if hDC1 <> 0 then
    begin
      SelectObject(hDC1, Handle);
      if ScrWindowsEx(Wnd, hDC1, 0 - X, 0 - Y, rect.right, rect.bottom, 0, 0)
      then
      begin

        Header.bfType := $4D42;
        Header.bfSize := Bmi.bmiHeader.biSizeImage + SizeOf(TBmpHeader);
        Header.bfReserved := 0;
        Header.bfOffBits := SizeOf(TBmpHeader);
        Header.biSize := $28;
        Header.biWidth := rect.right - X;
        Header.biHeight := rect.bottom - Y;
        Header.biPlanes := 1;
        Header.biBitCount := ABpp;
        Header.biCompression := 0;
        Header.biSizeImage := Bmi.bmiHeader.biSizeImage;
        Header.biXPelsPerMeter := 0;
        Header.biYPelsPerMeter := 0;
        Header.biClrUsed := 0;
        Header.biClrImportant := 0;
        hFile := CreateFile(PChar(FileName), $40000000, 0, nil, 2, 0, 0);

        WriteFile(hFile, Header, SizeOf(Header), i, nil);
        WriteFile(hFile, Bmi, Bmi.bmiHeader.biSizeImage, i, nil);
        WriteFile(hFile, Bits^, Bmi.bmiHeader.biSizeImage, i, nil);
        CloseHandle(hFile);
        Result := true;
      end;
    end;
    FreeVars__(hDC1, Handle, Bmi);
  end;
end;

function PixelSearch(out OutRes: _Point; left, top, right, bottom,
  color: Integer; nVar: Byte = 0; hwnd: IInt = 0): Boolean;
var
  Line: NativeInt;
  X, Y: Integer;
  red, green, blue: Byte;
  red_low, green_low, blue_low: Byte;
  red_high, green_high, blue_high: Byte;
  rect: _RECT;
  hDC1: HDC;
  Bmi: tagBITMAPINFO;
  Bits: PByte;
  Handle: HBITMAP;
begin
  Result := false;
  OutRes.X := 0;
  OutRes.Y := 0;

  if (right <= 0) or (bottom <= 0) then
    Exit;

  if not GetHandleTRect(hwnd, rect) then
  begin
    hwnd := 0;
    rect.right := GetSystemMetrics(0);
    rect.bottom := GetSystemMetrics(1);
  end;

  if color < 0 then
    color := GetSysColor(color and $000000FF);

  color := (color and $FF0000) shr 16 or (color and $00FF00) or
    (color and $0000FF) shl 16;

  red := Byte(color);
  green := Byte(color shr 8);
  blue := Byte(color shr 16);

  if nVar = 0 then
  begin
    red_high := red;
    red_low := red_high;
    green_high := green;
    green_low := green_high;
    blue_high := blue;
    blue_low := blue_high;
  end
  else
  begin
    if nVar > red then
      red_low := 0
    else
      red_low := red - nVar;
    if nVar > green then
      green_low := 0
    else
      green_low := green - nVar;
    if nVar > blue then
      blue_low := 0
    else
      blue_low := blue - nVar;
    if nVar > $FF - red then
      red_high := $FF
    else
      red_high := red + nVar;
    if nVar > $FF - green then
      green_high := $FF
    else
      green_high := green + nVar;
    if nVar > $FF - blue then
      blue_high := 0
    else
      blue_high := blue + nVar;
  end;

  if Create_DIB(Bmi, Pointer(Bits), Handle, rect.right, rect.bottom) then
  begin
    hDC1 := CreateCompatibleDC(0);
    if hDC1 <> 0 then
    begin
      SelectObject(hDC1, Handle);
      if ScrWindowsEx(hwnd, hDC1, 0, 0, rect.right, rect.bottom, 0, 0) then
      begin
        for Y := top to bottom do
        begin
          Line := NativeInt(Bits + (Bmi.bmiHeader.biHeight - Y - 1) *
            (((Bmi.bmiHeader.biWidth * Bmi.bmiHeader.biBitCount) + 31) and
            not 31) div 8);
          for X := left to right do
          begin
            { A + B * 3(x) }
            blue := Byte(Pointer(Line + X * 3)^);
            green := Byte(Pointer(Line + (X * 3) + 1)^);
            red := Byte(Pointer(Line + (X * 3) + 2)^);
            if (blue >= blue_low) and (blue <= blue_high) and
              (green >= green_low) and (green <= green_high) and
              (red >= red_low) and (red <= red_high) then
            begin
              OutRes.X := X;
              OutRes.Y := Y;
              FreeVars__(hDC1, Handle, Bmi);
              Result := true;
              Exit;
            end;
          end;
        end;
      end;
      FreeVars__(hDC1, Handle, Bmi);
    end;
  end;
end;

end.
