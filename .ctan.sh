#!/bin/bash

# Extract version/date from runcode.sty (line 7: \ProvidesPackage{runcode}[DATE runcode vX.Y])
rl=$(sed -n '7p' runcode.sty)
rl=$(echo "$rl" | sed 's/.*\[\(.*\)\]/\1/')
rl=$(echo "$rl" | sed 's/runcode //')
VersionDate=$(echo "$rl" | sed 's/\//\\\//g')

mkdir runcode

cp -r runcode.sty runcode.tex runcode.pdf \
       runcode_troubleshoot.tex runcode_troubleshoot.pdf \
       README generated \
       runcode/

# Copy the three auxiliary scripts with the version placeholder substituted
sed "s/XXX-Date Version-XXX/$VersionDate/" wait_for_server.py    > runcode/wait_for_server.py
sed "s/XXX-Date Version-XXX/$VersionDate/" runcode-Makefile.sample > runcode/runcode-Makefile.sample
sed "s/XXX-Date Version-XXX/$VersionDate/" consolidate.py          > runcode/consolidate.py

tar cpvfhz runcode.tar.gz runcode/

rm -r runcode
