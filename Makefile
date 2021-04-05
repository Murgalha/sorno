comp=clang
src=src/*.c
incl=-Iinclude
out=sorno
libs=-lm -lsqlite3
std=-std=c99

all:
	@$(comp) -o $(out) $(src) $(incl) $(libs) $(std)

debug:
	@$(comp) -o $(out) $(src) $(incl) $(libs) $(std) -g

run:
	@./$(out)

debug-run:
	@gdb ./$(out)
