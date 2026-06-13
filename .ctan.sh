#!/bin/bash

mkdir runcode

cp -r runcode.sty runcode.tex runcode.pdf runcode_troubleshoot.tex runcode_troubleshoot.pdf README generated \
       wait_for_rserver.py runcode-Makefile.sample consolidate.py \
       runcode/

tar cpvfhz runcode.tar.gz runcode/

rm -r runcode 

# tar cpvfhz runcode.tar.gz runcode.sty runcode.tex runcode.pdf troubleshoot.tex troubleshoot.pdf generated ./CTAN/README --transform='flags=r;s|./CTAN/README|README|'


