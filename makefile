DOCS_SOURCE = docs/source
DOCS_DIR = docs

include $(DOCS_DIR)/makefile

.PHONY:cucumber cuke cukesgs 

cuke cukes:cucumber
cucumber: 
	cucumber ./cucumber
