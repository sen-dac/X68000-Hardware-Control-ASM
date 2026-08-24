main.x: main.o dma.o draw.o input.o itoa.o s_title.o s_play.o s_end.o
	lk -o main.x main.o dma.o draw.o input.o itoa.o s_title.o s_play.o s_end.o

main.o: main.s
	as main.s

dma.o: ./dma/dma.s
	as ./dma/dma.s

draw.o: ./draw/draw.s
	as ./draw/draw.s

input.o: ./input/input.s
	as ./input/input.s

itoa.o: ./itoa/itoa.s
	as ./itoa/itoa.s

s_title.o: ./scene/s_title.s
	as ./scene/s_title.s

s_play.o: ./scene/s_play.s
	as ./scene/s_play.s

s_end.o: ./scene/s_end.s
	as ./scene/s_end.s
