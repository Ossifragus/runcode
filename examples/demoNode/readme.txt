
Oct. 2, 2020

Haim Bar and HaiYing Wang

This is a very simple demo that shows how to use the talk2stat Python package
in order to build web interfaces which perform on-the-fly statistical
calculations, using R and/or Julia. The talk2stat also works with Matlab
and Python, and can be extended to other statistical software tools, but
here we only demonstrate with R and Julia.


Files
-----
	classifiers.jl   The source file to perform classification with Julia
	classifiers.R    The source file to perform classification with R
	index.htm        The html file for the web interface
	julia.config     The configuration file used by talk2stat to start a Julia
					   session
	R.config         The configuration file used by talk2stat to start an R
					   session
	readme.txt       This file
	test3.js         The Node.js source file used to start the web server


Prerequisites
-------------

1. To run this demo, the following must be installed on the computer:
	- Python3    https://www.python.org/
	- R          https://cran.r-project.org/
	- Julia      https://julialang.org
	- Node.js    https://nodejs.org/en/

2. Once these are installed, the following packages need to be installed:

	Python
		- talk2stat https://pypi.org/project/talk2stat/
	  The syntax to install packages (from a command-line shell) is:
		pip3 install PackageName

	Julia
		- DelimitedFiles
		- Random
		- Statistics
		- XGBoost
		- LIBLINEAR
		- LIBSVM
		- FreqTables
		- Suppressor
	  The syntax to install packages (from a Julia session) is:
		using Pkg
		Pkg.add("PackageName")

	R
		- rpart
		- randomForest
		- e1071
		- kableExtra
	  The syntax to install packages (from an R session) is:
		install.packages("PackageName")

	Node.js
		- express
		- body-parser
	  The syntax to install packages (from a command-ine shell) is:
		npm install PackageName


Starting the demo
-----------------

The following uses the syntax for Linux of Mac OS. It is assumed that
all the demo files are stored in a folder called "~/demoNode"
Update the following commands according to the path for the files
on your computer.

1. In a command-line shell, execute the following
	cd ~/demoNode
    python3 -c 'from talk2stat.talk2stat import server,client; server("./","R")'

   This should give the following output:
     R: Ready
     Listening to port: 65432

2. Execute the following to load the data to R:

    python3 -c 'from talk2stat.talk2stat import client; client("./","R","```source(\"classifiers.R\");dfAll <- loadData()```")'


3. Similarly, from the command-line shell, start the Julia server 
	python3 -c 'from talk2stat.talk2stat import server,client; server("./","julia")'

4. Execute the following to load the data to Julia:

    python3 -c 'from talk2stat.talk2stat import client;client("./","julia","```include(\"classifiers.jl\")```")';


5. To start the web server, run the following:
	 node test3.js

   This should give the following output:
     Example app listening at http://127.0.0.1:8081

   Note: if you want to keep the web server running and get back the 
   command-line prompt, you can execute the following: nohup node test3.js &

6. Start a web browser, and enter the following URL:
     http://127.0.0.1:8081/
   Choose a classifier from the menu, and choose the fraction of data
   training (0.1-0.9), and click Submit


Quitting the demo
-----------------

1. If you did not run node in the background (using &) you can just use 
   ctrl-C to stop the web server.
2. To stop the R and Julia servers, execute the following from the 
   command-line shell:

  python3 -c 'from talk2stat.talk2stat import client; client("./","R","QUIT")'
  python3 -c 'from talk2stat.talk2stat import client; client("./","julia","QUIT")'
