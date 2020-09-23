# build and install rules for endurance tools and scripts

CFLAGS ?= -O2 -Wall -g

# add some extra warnings
CFLAGS += -Wmissing-prototypes -Wstrict-prototypes -Wsign-compare\
 -Wbad-function-cast -Wcast-qual -Wpointer-arith -Wshadow\
 -Wwrite-strings -Wcast-align -W

BIN = measure/proc2csv measure/sp-noncached
SRC = Makefile src/proc2csv.c src/sp_noncached.c
MAN = endurance-mem-overview.1 \
    endurance-plot.1 \
    endurance-report.1 \
    endurance-extract-process-smaps.1 \
    endurance-parse-snapshots.1 \
    endurance-recompress-snapshots.1 \
    endurance-extract-process-cgroups.1 \
    endurance-snapshot.1 \
    endurance-split-snapshots.1 \
    proc2csv.1 \
    syslog_parse.py.1 \
    sp-noncached.1

DOC = README

ALL = $(SRC) $(BIN) $(DOC) postproc-lib

.PHONY: all
all: $(ALL)

.PHONY: measure
measure: $(BIN)

postproc-lib/Makefile: postproc-lib/Makefile.PL
	cd postproc-lib && perl Makefile.PL

.PHONY: postproc-lib
postproc-lib: postproc-lib/Makefile
	$(MAKE) -C postproc-lib

measure/proc2csv: src/proc2csv.c
	$(CC) $(CFLAGS) -o $@ $<

measure/sp-noncached: src/sp_noncached.c
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: clean
clean: 
	$(RM) measure/proc2csv
	$(RM) measure/xmeminfo
	$(RM) measure/sp-noncached
	[ ! -f postproc-lib/Makefile ] || $(MAKE) -C postproc-lib clean
	$(RM) postproc-lib/Makefile.old
	$(RM) man/endurance-recompress-snapshots.1
	$(RM) man/endurance-extract-process-cgroups.1
	$(RM) postproc/syslog_parse.pyc

.PHONY: test
test:
	[ ! -f postproc-lib/Makefile ] || $(MAKE) -C postproc-lib test

endurance-recompress-snapshots.1: postproc/endurance-recompress-snapshots
	pod2man postproc/endurance-recompress-snapshots > man/$@
	install -D -m 644 man/$@ $(DESTDIR)/usr/share/man/man1/$@

endurance-extract-process-cgroups.1: postproc/endurance-extract-process-cgroups
	pod2man postproc/endurance-extract-process-cgroups > man/$@
	install -D -m 644 man/$@ $(DESTDIR)/usr/share/man/man1/$@

%.1: man/$@
	install -D -m 644 man/$@ $(DESTDIR)/usr/share/man/man1/$@

DOCDIR ?= /usr/share/doc

.PHONY: install-measure
install-measure: measure
	install -D measure/endurance-mem-overview $(DESTDIR)/usr/bin/endurance-mem-overview
	install -D measure/endurance-snapshot $(DESTDIR)/usr/bin/endurance-snapshot
	install -D measure/proc2csv $(DESTDIR)/usr/bin/proc2csv
	install -D measure/sp-noncached $(DESTDIR)/usr/bin/sp-noncached
	[ ! -x measure/xmeminfo ] || install -D measure/xmeminfo $(DESTDIR)/usr/bin/xmeminfo

.PHONY: install-postproc-lib
install-postproc-lib:
	$(MAKE) -C postproc-lib install DESTDIR=$(DESTDIR)

.PHONY: install-postproc
install-postproc:
	install -d $(DESTDIR)/usr/bin/
	cp postproc/* $(DESTDIR)/usr/bin/
	install -d $(DESTDIR)/$(DOCDIR)/sp-endurance-postproc/
	cp README $(DESTDIR)/$(DOCDIR)/sp-endurance-postproc/
	cp doc/endurance.pdf $(DESTDIR)/$(DOCDIR)/sp-endurance-postproc/
	install -d $(DESTDIR)/usr/share/sp-endurance-postproc/
	cp -a syslog-parser-configurations/* $(DESTDIR)/usr/share/sp-endurance-postproc/

.PHONY: install-tests
install-tests:
	install -d $(DESTDIR)/usr/share/sp-endurance-tests/
	cp -a tests/* $(DESTDIR)/usr/share/sp-endurance-tests/

.PHONY: install-compat-symlinks
install-compat-symlinks:
	install -d $(DESTDIR)/usr/bin/
	ln -s -f endurance-extract-process-smaps   $(DESTDIR)/usr/bin/extract-endurance-process-smaps
	ln -s -f endurance-extract-process-cgroups $(DESTDIR)/usr/bin/extract-endurance-process-cgroups
	ln -s -f endurance-parse-snapshots         $(DESTDIR)/usr/bin/parse-endurance-measurements
	ln -s -f endurance-plot                    $(DESTDIR)/usr/bin/endurance_plot
	ln -s -f endurance-recompress-snapshots    $(DESTDIR)/usr/bin/recompress-endurance-measurements
	ln -s -f endurance-report                  $(DESTDIR)/usr/bin/endurance_report.py
	ln -s -f endurance-snapshot                $(DESTDIR)/usr/bin/save-incremental-endurance-stats
	ln -s -f endurance-split-snapshots         $(DESTDIR)/usr/bin/split-endurance-measurements

.PHONY: install
install: $(MAN) install-measure install-postproc-lib install-postproc install-tests
