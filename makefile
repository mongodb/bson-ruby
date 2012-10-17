DOCS_SOURCE = docs/source
DOCS_DIR = docs

include $(DOCS_DIR)/makefile

.PHONY:cucumber cuke cukes

cuke cukes:cucumber
cucumber: 
	cucumber ./cucumber
