documents := paper submission revision1 revision2

${documents}: %: %-pdf

%-pdf: %.tex
	latexmk -pdf -pvc $<

clean:
	rm -f *.aux *.bbl *.bcf *.bib *.blg *.fdb_latexmk *.fls *.log *.out *.pdf *.xml

.PHONY: ${documents} clean
