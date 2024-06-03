import js.Browser.document;
import js.Browser.window;
import js.Promise;
import js.node.fs.promises.FileSystem;
import js.node.http.Http;
import js.node.express.Express;
import js.node.path.Path;
import js.node.puppeteer.Puppeteer;
import js.node.chalk.Chalk;
import js.node.jimp.Jimp;
import js.node.pixelmatch.PixelMatch;

class PromiseQueue {
    var func: Dynamic;
    var promises: Array<Promise<Void>>;

    public function new(func, ...args) {
        this.func = func.bind(this, args);
        this.promises = [];
    }

    public function add(...args) {
        var promise = this.func(args);
        this.promises.push(promise);
        promise.then(() => {
            var index = this.promises.indexOf(promise);
            if (index > -1) {
                this.promises.splice(index, 1);
            }
        });
    }

    public function waitForAll(): Promise<Void> {
        if (this.promises.length > 0) {
            return Promise.all(this.promises).then(() => this.waitForAll());
        } else {
            return Promise.resolve();
        }
    }
}

var exceptionList = [
    // List of exceptions
];

var port = 1234;
var pixelThreshold = 0.1;
var maxDifferentPixels = 0.3;
var numAttempts = 2;
var numPages = 8;
var numCIJobs = 4;
var width = 400;
var height = 250;
var viewScale = 2;
var jpgQuality = 95;

var browser: Puppeteer.Browser;
var app = Express.create();
app.use(Express.static(Path.resolve()));
var server = Http.createServer(app);
server.listen(port, main);

function main() {
    // The main function
}

function preparePage(page, injection, build, errorMessages) {
    // The preparePage function
}

function makeAttempt(pages, failedScreenshots, cleanPage, isMakeScreenshot, file, attemptID = 0): Promise<Void> {
    // The makeAttempt function
}

function close(exitCode = 1) {
    browser.close();
    server.close();
    window.process.exit(exitCode);
}