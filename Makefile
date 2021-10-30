comp=gcc
src=src/*.c src/**/*.c
incl=-Iinclude
out=sorno
libs=-lm -lsqlite3 -lglfw -lGL -lX11 -lpthread -lXrandr -ldl
std=-std=c99

all:
	@$(comp) -o $(out) $(src) $(incl) $(libs) $(std)

debug:
	@$(comp) -o $(out) $(src) $(incl) $(libs) $(std) -g

run:
	@./$(out)

debug-run:
	@gdb ./$(out)
