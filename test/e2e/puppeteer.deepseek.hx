import chalk.Chalk;
import express.Express;
import fs.Promises;
import jimp.Jimp;
import path.Path;
import pixelmatch.Pixelmatch;
import puppeteer.Browser;
import puppeteer.Page;
import puppeteer.Puppeteer;

class PromiseQueue {

	public function new(func:Dynamic, args:Array<Dynamic>) {
		this.func = Std.instance(func, this).bind(args);
		this.promises = [];
	}

	public function add(args:Array<Dynamic>) {
		var promise = this.func(args);
		this.promises.push(promise);
		promise.then(() => this.promises.splice(this.promises.indexOf(promise), 1));
	}

	public async function waitForAll() {
		while (this.promises.length > 0) {
			await Promise.all(this.promises);
		}
	}

	var func:Dynamic;
	var promises:Array<Dynamic>;
}

/* CONFIG VARIABLES START */

var idleTime = 9; // 9 seconds - for how long there should be no network requests
var parseTime = 6; // 6 seconds per megabyte

var exceptionList = [
	// ...
];

/* CONFIG VARIABLES END */

var port = 1234;
var pixelThreshold = 0.1; // threshold error in one pixel
var maxDifferentPixels = 0.3; // at most 0.3% different pixels

var networkTimeout = 5; // 5 minutes, set to 0 to disable
var renderTimeout = 5; // 5 seconds, set to 0 to disable

var numAttempts = 2; // perform 2 attempts before failing

var numPages = 8; // use 8 browser pages

var numCIJobs = 4; // GitHub Actions run the script in 4 threads

var width = 400;
var height = 250;
var viewScale = 2;
var jpgQuality = 95;

static function main() {
	// ...
}

static async function preparePage(page:Page, injection:String, build:String, errorMessages:Array<String>) {
	// ...
}

static async function makeAttempt(pages:Array<Page>, failedScreenshots:Array<String>, cleanPage:String, isMakeScreenshot:Bool, file:String, attemptID:Int = 0) {
	// ...
}

static function close(exitCode:Int = 1) {
	// ...
}