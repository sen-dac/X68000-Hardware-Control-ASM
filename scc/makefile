scc.x: scc.o input.o
	lk -o scc.x scc.o input.o

scc.o: scc.s
	as scc.s

input.o: ./input/input.s
	as ./input/input.s

itoa.o: ./itoa/itoa.s
	as ./itoa/itoa.s
