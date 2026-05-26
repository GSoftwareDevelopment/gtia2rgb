Uses Atari;

const
{$I memory.inc}

procedure init_screen;
var
  adr,_scr,_atr:Word;
  i:byte;

  procedure dlb(a:byte);
  begin
    poke(adr,a); inc(adr);
  end;

  procedure dlw(a:word);
  begin
    dpoke(adr,a); inc(adr,2);
  end;

begin
  poke(559,0);

  // prepare display list
  adr:=DLIST_ADR; _scr:=SCR_ADR; _atr:=ATR_ADR;
  dlb($70); dlb($70);
  for i:=0 to 23 do
  begin
    dlb($4F); dlw(_scr); dlb($0f); inc(_scr,80);
    dlb($4F); dlw(_atr); dlb($0f); inc(_atr,80);
    dlb(0); dlb(0); dlb(0); dlb(0);
  end;
  dlb($41); dlw(DLIST_ADR);

  // clear screen & set attributes
  fillchar(pointer(SCR_ADR),80*24,$00);
  fillchar(pointer(ATR_ADR),80*24,$1f);
  poke(559,34);

  // set display list
  dpoke(560,DLIST_ADR);

  // enable 80cols CGA mode
  poke($d01d,$60);
end;

var
  i:word;
  KEYB:byte absolute 764;

begin
  init_screen;
  for i:=0 to 80*24 do
  begin
    poke(scr_adr+i,byte(i));
  end;
  repeat until KEYB<>255;
  poke($d01d,0);
end.