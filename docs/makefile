# Makefile for MongoDB Sphinx documentation
# MAKEFLAGS += -j
# MAKEFLAGS += -r
MAKEFLAGS += --no-print-directory

# Build directory tweaking.

DOCS_SOURCE ?= source
DOCS_DIR ?= ./
output = build
public-output = $(output)/public
branch-output = $(output)/$(current-branch)
public-branch-output = $(public-output)/$(current-branch)

# change this to reflect the branch that "manual/" will point to
primary-branch = master
# intuit the current branch and commit
current-branch := $(shell git symbolic-ref HEAD 2>/dev/null | cut -d "/" -f "3" )
last-commit := $(shell git rev-parse --verify HEAD)

ifeq ($(current-branch),$(primary-branch))
current-if-not-manual = $(primary-branch)
else
current-if-not-manual = $(current-branch)
endif

# Fixing `sed` for OS X
UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
SED_ARGS_FILE = -i -r
SED_ARGS_REGEX = -r
endif
ifeq ($(UNAME), Darwin)
SED_ARGS_FILE = -i "" -E
SED_ARGS_REGEX = -E
endif

# Sphinx variables.
SPHINXOPTS = -c $(DOCS_DIR)/
SPHINXBUILD = sphinx-build
PAPER = letter
PAPEROPT_a4 = -D latex_paper_size=a4
PAPEROPT_letter = -D latex_paper_size=letter
ALLSPHINXOPTS = -q -d $(branch-output)/doctrees $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) $(DOCS_SOURCE)

.PHONY: publish help clean push-dc1 push-dc2

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "	 html		to make standalone HTML files"
	@echo "	 dirhtml	to make HTML files named index.html in directories"
	@echo "	 singlehtml	to make a single large HTML file"
	@echo "	 epub		to make an epub"
	@echo "	 latex		to make LaTeX files, you can set PAPER=a4 or PAPER=letter"
	@echo "	 man		to make manual pages"
	@echo "	 changes	to make an overview of all changed/added/deprecated items"
	@echo
	@echo "MongoDB Meta Driver Specific Targets."
	@echo "	 publish	runs publication process and then deploys the build to $(public-output)"
	@echo "	 push		runs publication process and pushes to docs site to production."
	@echo "	 pdfs		generates pdfs more efficently than latexpdf."
	@echo

#
# Meta targets that control the build and publication process.
#

.PHONY: push publish-if-up-to-date

push:publish-if-up-to-date
	@echo [build]: copying the new $(current-branch) build to the web servers.
	$(MAKE) MODE='push' push-dc1 push-dc2
	@echo [build]: deployed a new build of the $(current-branch) branch of the Manual.

push-all:publish
	@echo [build]: copying the full docs site to the web servers.
	$(MAKE) MODE='push' push-all-dc1 push-all-dc2
	@echo [build]: deployed a new build of the full Manual.

publish-if-up-to-date:
	@$(DOCS_DIR)/bin/published-build-check $(current-branch) $(last-commit)
	$(MAKE) publish

publish:initial-dependencies
	$(MAKE) sphinx-components
	$(MAKE) static-components
	@echo [build]: $(primary-branch) branch is succeessfully deployed to '$(public-output)'.

#
# Targets for pushing the new build to the web servers.
#

ifeq ($(MODE),push)
push-dc1:
	rsync -arz $(public-output)/$(current-branch)/ www@www-c1.10gen.cc:/data/sites/docs/meta-driver/$(current-branch)
push-dc2:
	rsync -arz $(public-output)/$(current-branch)/ www@www-c1.10gen.cc:/data/sites/docs/meta-driver/$(current-branch)
push-all-dc1:
	rsync -arz $(public-output)/ www@www-c1.10gen.cc:/data/sites/docs/meta-driver/
push-all-dc2:
	rsync -arz $(public-output)/ www@www-c1.10gen.cc:/data/sites/docs/meta-driver/
endif

######################################################################
#
# Targets that should/need only be accessed in publication
#
######################################################################


# Deployment targets to kick off the rest of the build process. Only
# access these targets through the ``publish`` target.
.PHONY: initial-dependencies static-components sphinx-components post-processing

initial-dependencies:$(DOCS_SOURCE)/about.txt
	@echo [build]: completed the pre-publication routine for the $(primary-branch) branch of the Manual.
static-components:$(public-branch-output)/release.txt $(public-output)/osd.xml links
	@echo [build]: completed building and migrating all non-Sphinx components of the build.
sphinx-components:$(public-branch-output)/ $(public-branch-output)/sitemap.xml.gz
	@echo [build]: completed the publication routine for all Sphinx Components of the Manual Build.

#
# Build the HTML components of the build.
#

.PHONY:$(DOCS_SOURCE)/about.txt setup

setup:
	@mkdir -p $(public-branch-output)
	@echo [build]: created $(public-branch-output)

$(branch-output)/singlehtml/contents.html:$(branch-output)/singlehtml
$(DOCS_SOURCE)/about.txt:setup
	@touch $@
	@echo [build]: touched '$@' to ensure a fresh build.
$(branch-output)/dirhtml:dirhtml
	@touch $@
	@echo [build]: touched $@ to ensure proper migration.
$(branch-output)/html:html
	@touch $@
	@echo [build]: touched $@ to ensure proper migration.
$(branch-output)/singlehtml:singlehtml
	@touch $@
	@echo [build]: touched $@ to ensure proper migration.
#
# Migrating and processing the dirhtml and singlehtml as needed.
#

$(public-branch-output)/:$(branch-output)/dirhtml
	@cp -R $</* $@
	@echo [build]: migrated '$</*' to '$@'

# Deployment related work for the non-Sphinx aspects of the build.
$(public-branch-output)/release.txt:$(public-output)/latest
	@echo [build]: generating '$@' with current release hash.
	@git rev-parse --verify HEAD >|$@
$(public-output)/latest:$(public-output)
	@$(DOCS_DIR)/bin/create-link $(primary-branch) latest $@
$(public-output):
	@mkdir -p $@
	@echo [build]: created $(branch-output)/

.PHONY:links

links: $(public-branch-output)/specifications
$(public-branch-output)/specifications:$(public-branch-output)/specification
	@$(DOCS_DIR)/bin/create-link $(notdir $<) $(notdir $@) $@

$(public-output)/index.html:$(DOCS_DIR)/themes/meta-driver/index.html
	@cp $< $@
	@echo [build]: migrated $@
$(public-branch-output)/sitemap.xml.gz:$(branch-output)/sitemap.xml.gz
	@cp $< $@
	@echo [build]: migrated $@
$(public-output)/osd.xml:$(DOCS_DIR)/themes/meta-driver/osd.xml
	@cp $< $@
	@echo [build]: migrated $@

# Clean up/removal targets.
clean:
	-rm -rf $(branch-output)/*
clean-public:
	-rm -rf $(public-output)/*
clean-all:
	-rm -rf $(output)/*

######################################################################
#
# Default HTML Sphinx build targets
#
######################################################################

.PHONY: html dirhtml singlehtml epub sitemap
html:

	@echo [html]: build starting at `date`.
	@mkdir -p $(branch-output)/html
	@echo [html]: created $(branch-output)/html
	$(SPHINXBUILD) -b html $(ALLSPHINXOPTS) $(branch-output)/html
	@echo [html]: build complete at `date`.
dirhtml:
	@echo [dirhtml]: build starting at `date`.
	@mkdir -p $(branch-output)/dirhtml
	@echo [dirhtml]: created $(branch-output)/dirhtml
	$(SPHINXBUILD) -b dirhtml $(ALLSPHINXOPTS) $(branch-output)/dirhtml
	@echo [dirhtml]: build complete at `date`.
singlehtml:
	@echo [singlehtml]: build started at `date`.
	@mkdir -p $(branch-output)/singlehtml
	@echo [singlehtml]: created $(branch-output)/singlehtml
	$(SPHINXBUILD) -b singlehtml $(ALLSPHINXOPTS) $(branch-output)/singlehtml
	@echo [singlehtml]: build complete at `date`.

epub-command = $(SPHINXBUILD) -b epub $(ALLSPHINXOPTS) $(branch-output)/epub
epub-filter = sed $(SED_ARGS_REGEX) -e '/^WARNING: unknown mimetype.*ignoring$$/d' -e '/^WARNING: search index.*incomplete.$$/d'
epub:
	@echo [epub]: starting epub build at `date`.
	@mkdir -p $(branch-output)/epub
	@echo [epub]: created $(branch-output)/epub
	@echo $(epub-command)
	@{ $(epub-command) 2>&1 1>&3 | $(epub-filter) 1>&2; } 3>&1
	@echo [epub]: build complete at `date`.

######################################################################
#
# Sitemap Builder
#
######################################################################

ifeq ($(shell test -f /etc/arch-release && echo arch || echo Linux),arch)
PYTHONBIN = python2
else
PYTHONBIN = python
endif

$(branch-output)/sitemap.xml.gz:$(branch-output)/dirhtml

SITEMAPBUILD = $(PYTHONBIN) $(DOCS_DIR)/bin/sitemap_gen.py
sitemap:$(branch-output)/sitemap.xml.gz
$(branch-output)/sitemap.xml.gz:$(public-output)/latest
	@echo [sitemap]: starting sitemap build at `date`.
	@echo [sitemap]: build time\: `date` >> $(branch-output)/sitemap-build.log
	@$(SITEMAPBUILD) --testing --config=$(DOCS_DIR)/conf-sitemap.xml 2>&1 >> $(branch-output)/sitemap-build.log
	@mv $(output)/sitemap.xml.gz $@
	@echo [sitemap]: sitemap built at `date`.


######################################################################
#
# Targets for manpages
#
######################################################################

# helpers for compressing man pages
UNCOMPRESSED_MAN := $(wildcard $(branch-output)/man/*.1)
COMPRESSED_MAN := $(subst .1,.1.gz,$(UNCOMPRESSED_MAN))

man:
	@echo [man]: starting man build at `date`.
	@mkdir -p $(branch-output)/man
	@echo [build]: created $(branch-output)/man
	$(SPHINXBUILD) -b man $(ALLSPHINXOPTS) $(branch-output)/man
	@echo [man]: build complete at `date`.

# Targets to build compressed man pages.
build-man: man $(COMPRESSED_MAN)
compress-man: $(COMPRESSED_MAN)
$(branch-output)/man/%.1.gz: $(branch-output)/man/%.1
	gzip $< -c > $@

##########################################################################
#
# Default Sphinx targets that are totally unused, but around just in case.
#
##########################################################################

.PHONY: changes linkcheck json doctest
json:
	@echo [json]: build started at `date`.
	@mkdir -p $(branch-output)/json
	@echo [json]: created $(branch-output)/json
	$(SPHINXBUILD) -b json $(ALLSPHINXOPTS) $(branch-output)/json
	@echo [json]: build finished at `date`.
changes:
	@echo [changes]: build started at `date`.
	@mkdir -p $(branch-output)/changes
	@echo [changes]: created $(branch-output)/changes
	$(SPHINXBUILD) -b changes $(ALLSPHINXOPTS) $(branch-output)/changes
	@echo [changes]: build finished at `date`.
linkcheck:
	@echo [link]: build started at `date`.
	@mkdir -p $(branch-output)/linkcheck
	@echo [link]: created $(branch-output)/linkcheck
	$(SPHINXBUILD) -b linkcheck $(ALLSPHINXOPTS) $(branch-output)/linkcheck
	@echo [link]: Link check complete at `date`. See $(branch-output)/linkcheck/output.txt.
doctest:
	@echo [test]: build started at `date`.
	@mkdir -p $(branch-output)/doctest
	@echo [test]: created $(branch-output)/doctest
	$(SPHINXBUILD) -b doctest $(ALLSPHINXOPTS) $(branch-output)/doctest
	@echo [test]: doctest complete at `date`.

######################################################################
#
# PDF Build System.
#
######################################################################

.PHONY:pdfs latex latexpdf

latex:
	@echo [latex]: starting TeX file generation at `date`.
	@mkdir -p $(branch-output)/latex
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(branch-output)/latex
	@echo [latex]: TeX file generated at `date`.
latexpdf:latex
	$(MAKE) -C $(branch-output)/latex all-pdf
	@echo [pdf]: build complete.

LATEX_CORRECTION = "s/(index|bfcode)\{(.*!*)*--(.*)\}/\1\{\2-\{-\}\3\}/g"

$(branch-output)/latex/%.tex:
	@sed $(SED_ARGS_FILE) -e $(LATEX_CORRECTION) -e $(LATEX_CORRECTION) $@
	@echo [latex]: fixing '$@' TeX from the Sphinx output

pdfs:$(subst .tex,.pdf,$(wildcard $(branch-output)/latex/*.tex))

PDFLATEXCOMMAND = TEXINPUTS=".:$(branch-output)/latex/:" pdflatex --interaction batchmode --output-directory $(branch-output)/latex/

%.pdf:%.tex
	@echo [pdf]: pdf compilation started at `date`.
	@$(PDFLATEXCOMMAND) $(LATEXOPTS) '$<' >|$@.log
	@echo [pdf]: \(1/4\) pdflatex $<
	@-makeindex -s $(branch-output)/latex/python.ist '$(basename $<).idx' >>$@.log 2>&1
	@echo [pdf]: \(2/4\) Indexing: $(basename $<).idx
	@$(PDFLATEXCOMMAND) $(LATEXOPTS) '$<' >>$@.log
	@echo [pdf]: \(3/4\) pdflatex $<
	@$(PDFLATEXCOMMAND) $(LATEXOPTS) '$<' >>$@.log
	@echo [pdf]: \(4/4\) pdflatex $<
	@echo [pdf]: see '$@.log' for a full report of the pdf build process.
	@echo [pdf]: pdf compilation complete at `date`.

##########################################################################
#
# Archiving $(public-output) for cleaner full rebuilds
#
##########################################################################

ARCHIVE_DATE := $(shell date +%s)
archive:$(public-output).$(ARCHIVE_DATE).tar.gz
	@echo [archive]: created $< archive.
$(public-output).$(ARCHIVE_DATE).tar.gz:$(public-output)
	tar -czvf $@ $<
