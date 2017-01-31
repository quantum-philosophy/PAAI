documents := paper submission revision1 revision2

${documents}: %: %-pdf

%-pdf: %.tex
	latexmk -pdf -pvc $<

clean:
	rm -f *.aux *.bbl *.bib *.log *.pdf *.blg *.xml *.fdb_latexmk *.fls *.bcf

.PHONY: ${documents} clean
