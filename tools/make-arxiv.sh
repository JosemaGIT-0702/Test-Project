#!/usr/bin/env bash
# Bundle the paper for arXiv: sources, .bbl, styles, figures and generated files.
set -euo pipefail
cd "$(dirname "$0")/.."

out=build/arxiv
rm -rf "$out" && mkdir -p "$out"
cp paper/main.tex paper/main.bbl paper/jheppub.sty paper/JHEP.bst paper/macros.tex "$out"/
cp -R paper/sections paper/figures paper/images paper/generated "$out"/
# strip comments from .tex files (arXiv makes sources public)
find "$out" -name '*.tex' -exec perl -i -ne 'print unless /^\s*%/' {} +
tar -czf build/arxiv.tar.gz -C "$out" .
echo "wrote build/arxiv.tar.gz -- test it by compiling $out with pdflatex before uploading"
