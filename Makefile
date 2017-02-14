# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SPHINXPROJ    = Gauge
SOURCEDIR     = .
BUILDDIR      = _build	

EXCLUDES      = _images _static .doctrees

REMOTEBRANCHES = $(shell git for-each-ref --format='%(refname:strip=3)' refs/remotes/) 
LOCALBRANCHES = $(shell git for-each-ref --format='%(refname:strip=2)' refs/heads/)
LATESTBRANCH = $(shell git for-each-ref --sort='-*authordate' --format='%(refname:strip=3)' --count=3 refs/remotes/ | grep -v "master\|HEAD")
VERSIONS = $(filter-out $(LATESTBRANCH) HEAD, $(REMOTEBRANCHES))

versions: prune
	
	# sync local with remote
	$(foreach version, $(filter-out $(LOCALBRANCHES) HEAD, $(REMOTEBRANCHES)),\
		echo "Fetching $(version) from remote"; \
		git checkout -b $(version) origin/$(version); \
		git pull; \
	)
	# for each branches, generate html, singlehtml
	$(foreach version, $(VERSIONS), \
		git checkout $(version);\
		sphinx-build -b html . _build/html/$(version) -A current_version=$(version) \
		   -A latest_version=$(LATESTBRANCH) -A versions="$(VERSIONS) latest";\
		sphinx-build -b singlehtml . _build/singlehtml/$(version) -A SINGLEHTML=true;\
	)
	git checkout $(LATESTBRANCH);\
	sphinx-build -b html . _build/html/ -A current_version=latest \
		-A latest_version=$(LATESTBRANCH) -A versions="$(VERSIONS) latest";\
	git checkout master

prune: clean
	git checkout master;\
	$(foreach branch, $(filter-out master, $(LOCALBRANCHES)),\
		git branch -D $(branch); \
	)

zip: versions
	$(foreach folder,$(filter-out $(EXCLUDES), $(notdir $(shell find _build/singlehtml -maxdepth 1 -mindepth 1 -type d))), \
		echo "Using $(folder) "; \
		mkdir -p "_build/html/$(folder)/downloads"; \
		(cd "_build/singlehtml/$(folder)" && zip -r -D "../../../_build/html/$(folder)/downloads/gauge-v-$(folder).zip" *) ; \
	)

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
