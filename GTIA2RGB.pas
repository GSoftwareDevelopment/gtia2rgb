unit GTIA2RGB;

interface
const
{$I GTIA2RGB.inc}

  COLS40_MODE        = $00; // Off - normal 40 column mode
  COLS80_SIMPLE_MODE = $40; // Simple - no attributes, no color, just 80 columns
  COLS80_CGA_MODE    = $60; // CGA palette attributes
  COLS80_ACL_MODE    = $48; // Atari Chroma+Luma
  COLS80_RGB_MODE    = $68; // Full RGB

var
  GTIA2RGB_VER_MAJOR:byte absolute $d01c; // Readonly
  GTIA2RGB_VER_MINOR:byte absolute $d01d; // Readonly
  GTIA2RGB_ID:byte absolute $d01e;        // Readonly, always $0a
  GTIA2RGB_SET:byte absolute $d01d;       // Write-only

  fgcolor:byte;
  bgcolor:byte;
  curX,curY:byte;

function check_gtia2rgb:boolean; inline;
function gtia2rgb_version:word; inline;
procedure init_screen;
procedure gotoXY(x,y:byte);
procedure print(s:string);

implementation

var
  i:byte;
  _scr,_atr:Word;

  SDMCTL:byte absolute 559;
  SDLST:word absolute 560;

function check_gtia2rgb:boolean; inline;
begin
  result:=(GTIA2RGB_ID=$0a);
end;

function gtia2rgb_version:word; inline;
begin
  result:=(GTIA2RGB_VER_MAJOR shl 8) or GTIA2RGB_VER_MINOR;
end;

procedure upload_rom_font; assembler;
asm
FONT_ADDR_HI  = $D010 ; addr[10:3] (writing clears addr[2:0])
FONT_ADDR_LO  = $D011 ; addr[2:0] (row within current character)
FONT_DATA     = $D01E ; data byte + auto-increment (needs COL80=1)
ZPTR          = $FE   ; zero page pointer for source data

LOAD_FONT:
  lda #0
  sta FONT_ADDR_HI  ; start at char 0 (addr = 0)
  sta ZPTR          ; source page low byte = 0
  ldx #0
LF_BLOCK:
  lda LF_SRC_HI,x
  sta ZPTR+1        ; source page high byte
  lda LF_EOR,x
  sta LF_EOR_OP+1   ; self-modify: $00 or $FF
  ldy #0
LF_BYTE:
  lda (ZPTR),y
LF_EOR_OP:
  eor #0            ; $00 = normal, $FF = inverse
  sta FONT_DATA     ; write + auto-increment
  iny
  bne LF_BYTE       ; 256 bytes per page
  inx
  cpx #8            ; 8 pages = 2048 bytes
  bne LF_BLOCK
  rts

; Source pages (ROM $E000) remapped to ATASCII destination order.
; Pages 0-3: normal characters. Pages 4-7: inverse (EOR $FF).
LF_SRC_HI: .byte $E2,$E0,$E1,$E3,$E2,$E0,$E1,$E3
LF_EOR: .byte 0, 0, 0, 0,$FF,$FF,$FF,$FF
end;

procedure gotoXY(x,y:byte);
begin
  curX:=x; curY:=y;
  _scr:=SCR_ADR+y*80+x;
  _atr:=ATR_ADR+y*80+x;
end;

procedure print(s:string);
var
  atr:byte;

begin
  atr:=(bgcolor shl 4) or fgcolor;
  for i:=1 to length(s) do
  begin
    poke(_scr,byte(s[i]));
    poke(_atr,atr);
    inc(_scr);
    inc(_atr);
  end;
end;

procedure init_screen;
var
  adr:word;

  procedure dlb(a:byte);
  begin
    poke(adr,a); inc(adr);
  end;

  procedure dlw(a:word);
  begin
    dpoke(adr,a); inc(adr,2);
  end;

begin
  if not check_gtia2rgb then 
  begin
    writeln('GTIA2RGB not detected!');
    halt(1);
  end;
  writeln('GTIA2RGB detected, version ',GTIA2RGB_VER_MAJOR,'.',GTIA2RGB_VER_MINOR);
  pause(50);

  // turn off ANTIC
  SDMCTL:=0;

  // enable 80cols CGA mode
  GTIA2RGB_SET:=COLS80_CGA_MODE;

  upload_rom_font;

  // set display list
  SDLST:=DLIST_ADR;

  // prepare display list
  adr:=DLIST_ADR; _scr:=SCR_ADR; _atr:=ATR_ADR;
  dlb($70); dlb($40);
  for i:=0 to 24 do
  begin
    dlb($4F); dlw(_scr); dlb($0f); inc(_scr,80);
    dlb($4F); dlw(_atr); dlb($0f); inc(_atr,80);
    dlb(0); dlb(0); dlb(0); dlb(0);
  end;
  dlb($41); dlw(DLIST_ADR);

  // clear screen & set attributes
  fillchar(pointer(SCR_ADR),80*25,$20);
  fillchar(pointer(ATR_ADR),80*25,bgcolor shl 4 or fgcolor);

  // turn on ANTIC
  SDMCTL:=$22;
  gotoXY(0,0);
end;

end.