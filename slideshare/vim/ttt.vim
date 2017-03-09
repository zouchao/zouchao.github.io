"  TicTacToe macro set III, written by Kevin Earls (kevin@ti.com) 12/13/96.
"  Permission to use, copy, learn and fix is hereby granted to anyone who can.
"  Please leave my name in any copies made, your cooperation is appreciated.
"  If you would like an explanation of the macros, email me I`ll do my best.
"  Also, Please send any comments to the above address. 
"
"  #### TO RUN, VIM AN EMPTY FILE AND SOURCE THE MACRO SET (:so ttt.mac<ENTER>)
"  #### AND TYPE "g" TO START. THE jklh KEYS MOVE, THE x KEY MAKES A MARK.
"
"  This is the third revision of macros that will play the universial TicTacToe
"  game against the user. This algorithm picks out the best move by sorting
"  the lines of available moves. Although it isn't foolproof, it 
"  will amaze people who have never seen [vi|vim] do anything but edit text 
"  before. I wanted to add something of mine to the very popular list of 
"  macro sets like "the towers of hanoi", "Conway's game of life", and
"  "the maze solving macros".
"
"  ####  ****    WORKS BEST WITH AN EMPTY .EXRC FILE.  ********          ####
"  ####  Due to vi's bugs of not being able to yank or put inside        ####
"  ####  of macros this will not work with the real vi.                  ####
"  ####  (Does anyone besides me still use the real vi all the time? =)  ####
"  ####  I have tried this on lemmy with no luck. Someone else?          ####
"  ####  I don't have access to vile, elvis, nvi or other vi clones.     ####
"  ####  Works with vim on SparkStation(SunOS)s, PCs, and HP Worksations.####
"
"                    EACH PLACE IS MARKED.
"      N I T I E     NORTH    TOP     EAST
"    +---+---+---+
"      L I C I R     LEFT    CENTER   RIGHT
"    +---+---+---+
"      W I B I S     WEST    BOTTOM   SOUTH
"                 
"
set remap
set noautoindent
set nonumber
" CONTROL MAPS.
map!  qq      :q!
map  qq      :q!
map!  x      Xlx;RR
map!  j      2ja
map!  k      2ka
map!  l      4la
map!  h      4ha
map   g      ;Ii
map   T      1GdGg
map!  T      1GdGg
map   t      `ci
map!  t      `ci
"  WHAT A MESS!! A WHOLE LOT OF TROUBLE JUST TO PRINT A MESSAGE. =)
map   ;H1    1GA   t   -   To Reset Position.;H2
map   ;H2    jA   T   -   To Play Again.;H3
map   ;H3    jA   qq  -   To Quit.;H4
map   ;H4    jA   x   -   To Place your X.;H5
map   ;H5    jA   The usual jklh keys To Move.`c
"
" ;I DRAW THE BOARD. ;M MARK EACH PLACE.
" ;1R REMAP ;N TO THE NEXT LINE AND START SEARCHING LINES AND EXECUTE THE LINE.
map   ;L     O +---+---+---+ 
map   ;D     O     I   I     
map   ;I     ;D;L;D;L;Do;M;H1
map   ;M     1Ghhmn2jml2jmw4lmb4lms2kmr2kme4hmt2jmc
"
" YANK IN ALL LINES AND PRINT AT BOTTOM.
map   ;RR    ;1R;2R;3R;4R;5R;6R;7R;8R;SS
map   ;1R    `nmm"ny `t"ty `e"ey Go"np"tp"epa ;1Rz"qx
map   ;2R    `lmm"ly `c"cy `r"ry G"lP"cp"rpa ;2Rz"qx
map   ;3R    `wmm"wy `b"by `s"sy G"wP"bp"spa ;3Rz"qx
map   ;4R    `nmm"ny `l"ly `w"wy G"nP"lp"wpa ;4Rv"qx
map   ;5R    `tmm"ty `c"cy `b"by G"tP"cp"bpa ;5Rv"qx
map   ;6R    `emm"ey `r"ry `s"sy G"eP"rp"spa ;6Rv"qx
map   ;7R    `nmm"ny `c"cy `s"sy G"nP"cp"spa ;7Rd"qx
map   ;8R    `emm"ey `c"cy `w"wy G"eP"cp"wpa ;8Rf"qx
"
" SEARCH FOR BEST MOVE. LAST ONE DELETED IS BEST.
map   ;SS    :8,$s/ //g;1S
map   ;1S    :8,$g/^\([XO]\)\1\1;/s//YYY;/g;2S
map   ;2S    :8,$g/^[XO][XO][XO];/s//ZZZ;/g:8,$g/^ZZZ/d a;3S
map   ;3S    :8,$g/^X;/d a:8,$g/^OX;/d a:8,$g/^XO;/d a;4S
map   ;4S    :8,$g/^O;/d a:8,$g/^XX;/d a:8,$g/^OO;/d a;5S
map   ;5S    :8,$g/^XXX;/d a:8,$g/^YYY/;d a;6S
map   ;6S    Gpdw"x3x@xk;7S
map   ;7S    :s/ /+/g:g/^XXX/s//ZXX/:g/^[XO][XO][XO]/s//ZZZ/;8S
map   ;8S    0"x3x:8,$d@x
"
" THESE GET EXECUTED WHEN YOU CAN WIN OR NEED TO BLOCK.
" `m HOLDS THE CURRENT LINE. "q HOLDS THE CURRENT DIRECTION.
" "q = z = horizontal
" "q = v = vertical
" "q = d = diagonal falling to the right
" "q = f = diagonal rising to the right
map   ;z1    `mrOi
map   ;z2    `m4lrOi
map   ;z3    `m8lrOi
map   ;v1    `mrOi
map   ;v2    `m2jrOi
map   ;v3    `m4jrOi
map   ;d1    `nrOi
map   ;d2    `crOi
map   ;d3    `srOi
map   ;f1    `erOi
map   ;f2    `crOi
map   ;f3    `wrOi
"
" THESE ARE WHAT GETS EXECUTED AT THE END OF ;*S.
map  ;#x    0"qp0"x3x@x
map  ++O    Go;1;#x
map  ++X    Go;1;#x
map  +O+    Go;1;#x
map  +OX    Go;1;#x
map  +X+    Go;1;#x
map  +XO    Go;1;#x
map  O++    Go;2;#x
map  O+X    Go;2;#x
map  OX+    Go;3;#x
map  X++    Go;2;#x
map  X+O    Go;2;#x
map  XO+    Go;3;#x
map  +OO    Go;1;#xZYY
map  O+O    Go;2;#xZYY
map  OO+    Go;3;#xZYY
map  +XX    Go;1;#x
map  X+X    Go;2;#x
map  XX+    Go;3;#x
map  ZXX    7GdGo   YOU WIN!!!`c
map  ZYY    7GdGo   I WON!!!`c
map  ZZZ    7GdGo   GAME OVER!!!`c
