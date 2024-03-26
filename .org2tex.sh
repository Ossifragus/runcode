#!/bin/bash

emacs README.org --batch --no-init-file --load .org2tex.el -f org-latex-export-to-latex --kill -f toggle-debug-on-error

rl=`sed -n '7p' runcode.sty`
rl=`echo $rl | sed 's/.*\[\(.*\)\]/\1/'`
rl=`echo $rl | sed 's/runcode //'`
VersionDate=$(echo $rl | sed 's/\//\\\//g')

sed "s/XXX-Date Version-XXX/$VersionDate/" CTAN/README  > README
sed "s/XXX-Date Version-XXX/$VersionDate/" CTAN/header.tex  > header.tex
sed -i 's/% Intended LaTeX compiler: pdflatex//' runcode.tex

addheader=`cat header.tex ; cat runcode.tex`
echo "$addheader" > runcode.tex


# sed -i '1d' ./CTAN/README 
# sed '1,1 s/.*/$VersionDate/' ./CTAN/README
# sed -re "s/XXX-Date Version-XXX/$(VersionDate)/" CTAN/README

# # pdflatex -shell-escape runcode.tex
