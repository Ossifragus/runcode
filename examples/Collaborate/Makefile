# Use the cache, compile from tmp files, remove temporary code files
overleaf:
	touch ForceCache
	xelatex -shell-escape sidsmain.tex

clean:
	rm -f sidsmain.aux tmp/*.txt

# stop the talk2stat server, but don't compile the book:
stopserver: clean
	python3 -c 'from talk2stat.talk2stat import client; client("./","R","QUIT")'
	rm -f serverPIDR.txt Rdebug.txt talk2stat.log nohup.out
 
# build the book and use the server, not the cache option:
build: clean
	rm -f ForceCache nohup.out
	xelatex -shell-escape sidsmain.tex