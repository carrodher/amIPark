.PHONY = all clean

all: gui

gui:
	gcc `pkg-config --cflags gtk+-3.0` gui.c -o gui.out `pkg-config --libs gtk+-3.0`

clean:
	rm gui.out
