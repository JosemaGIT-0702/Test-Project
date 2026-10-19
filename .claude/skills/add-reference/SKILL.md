---
name: add-reference
description: Add a citation to paper/references.bib using BibTeX from INSPIRE-HEP (by arXiv ID, DOI, texkey or search), and optionally a literature note. Use when citing a paper or fixing an undefined citation.
argument-hint: "<arXiv id | DOI | INSPIRE texkey | search terms>"
---

# Add a reference from INSPIRE

Query: `$ARGUMENTS`

1. Fetch BibTeX from the INSPIRE API (never write BibTeX by hand or from memory):
   - arXiv: `curl -s "https://inspirehep.net/api/arxiv/<id>?format=bibtex"`
   - DOI:   `curl -s "https://inspirehep.net/api/doi/<doi>?format=bibtex"`
   - texkey or free search:
     `curl -s "https://inspirehep.net/api/literature?q=<url-encoded query>&size=5&fields=titles,authors.full_name,texkeys,arxiv_eprints,publication_info"`
     -- show the candidates and let the user pick if more than one plausibly matches,
     then fetch with `&format=bibtex`.
2. If the texkey is already in `paper/references.bib`, say so and stop.
3. Append the entry unchanged (keep the INSPIRE texkey as the key).
4. Tell the user the key to use: `\cite{Key}`. If asked to insert it, put it where it belongs.
5. Optionally (ask) create `literature/<texkey>.md` from the abstract
   (`https://inspirehep.net/api/literature?q=texkey:<key>&fields=abstracts`): summary,
   conventions, results relevant to us -- clearly marking what comes from the abstract
   versus what still needs reading.
