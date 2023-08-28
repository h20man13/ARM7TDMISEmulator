LABEL begin_0
a := 0
GOTO begin_1
LABEL WriteLn
IASM "SWI 4"
RETURN
LABEL WriteInt
IPARAM c
IASM "LDR R0, %a"
IASM "SWI 1"
RETURN
LABEL WriteReal
IPARAM e
IASM "LDR R0, %a"
IASM "SWI 2"
RETURN
LABEL ReadInt
h := 0
IASM "SWI 3"
IPARAM h
IASM "STR R0, %a"
g := h
RETURN
LABEL begin_1
i := 10
j := i
GOTO begin_2
LABEL begin_2
PROC WriteInt ( j -> c )
END
