CC      = cobc
CFLAGS  = -x -free -I copybooks/
SRCDIR  = src
BINDIR  = bin

PROGRAMS = DAILY-CLOSING INTEREST-CALC CNAB240-GEN RECONCILIATION FEE-CALC

.PHONY: all clean

all: $(BINDIR) $(PROGRAMS)

$(BINDIR):
	mkdir -p $(BINDIR)

$(PROGRAMS):
	$(CC) $(CFLAGS) -o $(BINDIR)/$@ $(SRCDIR)/$@.cbl

clean:
	rm -rf $(BINDIR)/*
