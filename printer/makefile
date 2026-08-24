chkprn.x: chkprn.o input.o
	lk -o chkprn.x chkprn.o input.o

chkprn.o: chkprn.s
	as chkprn.s

input.o: ./input/input.s
	as ./input/input.s