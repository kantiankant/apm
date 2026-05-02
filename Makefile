# apm - aur package manager
# a makefile for a shell script, because apparently this is fine now

PREFIX    ?= /usr/local
BINDIR    ?= $(PREFIX)/bin
MANDIR    ?= $(PREFIX)/share/man/man1
STATEDIR  ?= $(HOME)/.local/state/apm

NAME      = apm
VERSION   = 1.0.1
MAN       = $(NAME).1

.PHONY: all install uninstall clean dist help

all:
	@printf 'nothing to build. it is a shell script.\n'
	@printf 'run "make install" to install, or sit here, either is fine.\n'

install:
	@printf 'installing %s %s...\n' "$(NAME)" "$(VERSION)"
	install -Dm755 $(NAME)        $(DESTDIR)$(BINDIR)/$(NAME)
	install -Dm644 $(MAN)         $(DESTDIR)$(MANDIR)/$(MAN)
	gzip -f                       $(DESTDIR)$(MANDIR)/$(MAN)
	install -dm755                $(DESTDIR)$(STATEDIR)
	@printf 'installed successfully. welcome to the AUR. mind the PKGBUILDs.\n'

uninstall:
	@printf 'uninstalling %s...\n' "$(NAME)"
	rm -f  $(DESTDIR)$(BINDIR)/$(NAME)
	rm -f  $(DESTDIR)$(MANDIR)/$(MAN).gz
	rmdir --ignore-fail-on-non-empty $(DESTDIR)$(STATEDIR) 2>/dev/null || true
	@printf 'uninstalled. it was good while it lasted. unlike most things.\n'

clean:
	@printf 'nothing to clean. again: shell script.\n'
	@printf 'if your shell script has build artefacts, you have larger problems.\n'

dist:
	@printf 'creating dist tarball %s-%s.tar.gz...\n' "$(NAME)" "$(VERSION)"
	mkdir -p dist/$(NAME)-$(VERSION)
	cp $(NAME) $(MAN) Makefile README dist/$(NAME)-$(VERSION)/
	tar -czf dist/$(NAME)-$(VERSION).tar.gz -C dist $(NAME)-$(VERSION)
	rm -rf dist/$(NAME)-$(VERSION)
	@printf 'created dist/%s-%s.tar.gz\n' "$(NAME)" "$(VERSION)"
	@printf 'ready to distribute. unlike my CV, which remains stubbornly unfinished.\n'

help:
	@printf 'apm %s - aur package manager\n\n' "$(VERSION)"
	@printf 'targets:\n'
	@printf '  all        does nothing, correctly\n'
	@printf '  install    install apm, man page, and state directory\n'
	@printf '  uninstall  remove everything apm put on your system\n'
	@printf '  clean      also does nothing, but with purpose\n'
	@printf '  dist       create a release tarball\n'
	@printf '  help       print this message, which you clearly already found\n'
	@printf '\nvariables:\n'
	@printf '  PREFIX     installation prefix (default: /usr/local)\n'
	@printf '  DESTDIR    staging root for packagers (default: empty)\n'
