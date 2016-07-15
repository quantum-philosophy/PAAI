paper: paper-pdf

submission: submission-pdf

%-pdf: %.tex
	latexmk -pdf -pvc $<

clean:
	rm -f *.aux *.bbl *.bib *.log *.pdf *.blg *.xml *.fdb_latexmk *.fls *.bcf

.PHONY: paper submission clean
