var express = require('express');
var app = express();
var bodyParser = require('body-parser');
const { response } = require('express');

// Create application/x-www-form-urlencoded parser
var urlencodedParser = bodyParser.urlencoded({ extended: false })


function showConfusionMatrix(confmatrix, method, pcttrain) {
    var htmlstr = '<div style="margin: auto;width: 70%;"><P style="margin-top: 30px;margin-bottom: 10px;margin-right: 150px;margin-left: 80px;color: blue;text-align: justify;font-size: 20;">Results using ' + method + ', with ' + 100*pcttrain + '% of the data used for training.';
    htmlstr += '</div><div style="margin: auto;width: 70%;"><P style="margin-top: 10px;margin-bottom: 10px;margin-right: 150px;margin-left: 80px;color: black;text-align: justify;font-size: 18;">Rows = Actual outcome, Columns = predicted outcome.</div><div style="margin: auto;width: 40%;">' + confmatrix + '</div>';
    return(htmlstr);
  }

app.use(express.static('public'));

app.get('/index.htm', function (req, res) {
   res.sendFile( __dirname + "/" + "index.htm" );
})

app.get('/', function (req, res) {
    res.sendFile( __dirname + "/" + "index.htm" );
 })
 

app.post('/process_post', urlencodedParser, function (req, res) {
    var response = {
        method:req.body.method,
        trainpct:req.body.percentTraining
    };
    //console.log(response.method);
    const { spawn } = require('child_process');
    var lang = response.method.substring(0,5);
    if (lang == "julia") {
	//console.log(lang, response.method.substring(5),"\n\n")
        const initfile = 'from talk2stat.talk2stat import client';
        var ls = spawn('python3', ['-c',initfile]);
	    const strexe = 'tableAsHtml(classifyCancer(\\\"' + response.method.substring(5) + '\\\",' + response.trainpct +'))';
        var sendstr =  'from talk2stat.talk2stat import client;client("./","julia","```' + strexe + '```")';
    } else {
        const initfile = 'from talk2stat.talk2stat import client';
        var ls = spawn('python3', ['-c',initfile]);
        var sendstr =  'from talk2stat.talk2stat import client;client("./","R","```classifyCancer(dfAll, \'' + response.method + '\',' + response.trainpct +')```")';
    }
    ls = spawn('python3', ['-c',sendstr]);
    ls.stdout.on('data', (data) => {
        res.end(showConfusionMatrix(data, response.method, response.trainpct))
        //console.log(`stdout: ${data}`);
    });
    ls.stderr.on('data', (data) => {
        console.log(`stderr: ${data}`);
    });
    ls.on('close', (code) => {
        console.log(`child process exited with code ${code}`);
    });
    console.log(response);
})


var server = app.listen(8081, '127.0.0.1', function () {
   var host = server.address().address
   var port = server.address().port
   console.log("Example app listening at http://%s:%s", host, port)
})

