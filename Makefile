all:
	latexmk -pdf -pvc paper.tex

clean:
	rm -f *.aux *.bbl *.bib *.log *.pdf *.blg *.xml *.fdb_latexmk *.fls *.bcf

.PHONY: all clean
