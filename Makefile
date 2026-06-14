PACKAGE = sysinfo
VERSION = 1.0

prefix = /usr
bindir = $(prefix)/bin
datadir = $(prefix)/share
localedir = $(datadir)/locale

INSTALL = install -c
INSTALL_DATA = $(INSTALL) -m 644
INSTALL_PROGRAM = $(INSTALL) -m 755
MKDIR_P = mkdir -p

INTLTOOL_MERGE = intltool-merge
INTLTOOL_EXTRACT = intltool-extract

PO_FILES = $(wildcard po/*.po)
MO_FILES = $(PO_FILES:.po=.mo)

all: sysinfo.desktop

# DESKTOP FILE (intltool)

data/sysinfo.desktop.in.h: data/sysinfo.desktop.in
	$(INTLTOOL_EXTRACT) --type=gettext/ini $<

sysinfo.desktop: data/sysinfo.desktop.in data/sysinfo.desktop.in.h $(PO_FILES)
	$(INTLTOOL_MERGE) -d po data/sysinfo.desktop.in $@

# MO FILES

po/%.mo: po/%.po
	$(MKDIR_P) po
	msgfmt -c -o $@ $<

# POT GENERATION

update-po:
	@echo "Extracting shell strings..."
	xgettext \
		--language=Shell \
		--keyword=_ \
		--package-name=$(PACKAGE) \
		--package-version=$(VERSION) \
		-o po/script.pot \
		src/sysinfo.sh

	@echo "Extracting desktop strings..."
	$(INTLTOOL_EXTRACT) --type=gettext/ini data/sysinfo.desktop.in

	xgettext \
		--language=C \
		--keyword=N_ \
		--package-name=$(PACKAGE) \
		--package-version=$(VERSION) \
		-o po/desktop.pot \
		data/sysinfo.desktop.in.h

	@echo "Merging POT..."
	msgcat --use-first \
		po/script.pot \
		po/desktop.pot \
		-o po/$(PACKAGE).pot

	rm -f po/script.pot po/desktop.pot data/sysinfo.desktop.in.h

# INSTALL

install: all $(MO_FILES)
	$(MKDIR_P) $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) src/sysinfo.sh $(DESTDIR)$(bindir)/sysinfo

	$(MKDIR_P) $(DESTDIR)$(datadir)/applications
	$(INSTALL_DATA) sysinfo.desktop $(DESTDIR)$(datadir)/applications/

	$(MKDIR_P) $(DESTDIR)$(datadir)/icons/hicolor/256x256/apps
	$(INSTALL_DATA) data/icon.png $(DESTDIR)$(datadir)/icons/hicolor/256x256/apps/sysinfo.png

	for po in $(PO_FILES); do \
		lang=$$(basename $$po .po); \
		$(MKDIR_P) $(DESTDIR)$(localedir)/$$lang/LC_MESSAGES; \
		$(INSTALL_DATA) po/$$lang.mo $(DESTDIR)$(localedir)/$$lang/LC_MESSAGES/$(PACKAGE).mo; \
	done
	
# UNINSTALL

uninstall: 
	rm -f $(DESTDIR)$(bindir)/sysinfo 
	rm -f $(DESTDIR)$(datadir)/applications/sysinfo.desktop 
	rm -f $(DESTDIR)$(datadir)/icons/hicolor/256x256/apps/sysinfo.png 
	rm -rf $(DESTDIR)$(localedir)/*/LC_MESSAGES/$(PACKAGE).mo

# CLEAN

clean:
	rm -f sysinfo.desktop
	rm -f data/sysinfo.desktop.in.h
	rm -f po/*.mo po/*.pot

distclean: clean

.PHONY: all update-po install clean distclean
