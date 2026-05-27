Uses GTIA2RGB;

Var
  KEYB:byte absolute 764;

begin
  fgcolor:=15; // white
  bgcolor:=0; // black
  init_screen;

  bgcolor:=1;
  print(' GTIA2RGB 80-column demo ');

  repeat until KEYB<>255;

  GTIA2RGB_SET:=COLS40_MODE;
end.