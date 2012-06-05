PREFIX=benchmark
LINKER=ld
CC=gcc

all: build link

build:
	$(CC) -g -c $(PREFIX).s

link:
	$(LINKER) -o $(PREFIX) $(PREFIX).o

clean:
	rm -f $(PREFIX)
	rm -f $(PREFIX).o
