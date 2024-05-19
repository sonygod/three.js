package three.js.test.e2e;

import chalk.Chalk;
import puppeteer.Puppeteer;
import express.Express;
import path.Path;
import pixelmatch.Pixelmatch;
import jimp.Jimp;
import fs.FsPromises;

class PromiseQueue {
    var func:Dynamic->Void;
    var promises:Array<Promise<Dynamic>>;

    public function new(func:Dynamic->Void, ...args) {
        this.func = func.bind(this, ...args);
        this.promises = [];
    }

    public function add(...args) {
        var promise = this.func(...args);
        this.promises.push(promise);
        promise.then(_ -> this.promises.remove(promise));
    }

    public function waitForAll() {
        while (this.promises.length > 0) {
            Promise.all(this.promises).then(_ -> {});
        }
    }
}

/* CONFIG VARIABLES START */

var idleTime:Int = 9; // 9 seconds - for how long there should be no network requests
var parseTime:Int = 6; // 6 seconds per megabyte

var exceptionList:Array<String> = [
    // video tag isn't deterministic enough?
    'css3d_youtube',
    'webgl_materials_video',
    'webgl_video_kinect',
    'webgl_video_panorama_equirectangular',

    // WebXR also isn't deterministic enough?
    'webxr_ar_lighting',
    'webxr_vr_sandbox',
    'webxr_vr_video',
    'webxr_xr_ballshooter',

    // ... (rest of the exceptions)
];

/* CONFIG VARIABLES END */

var port:Int = 1234;
var pixelThreshold:Float = 0.1; // threshold error in one pixel
var maxDifferentPixels:Float = 0.3; // at most 0.3% different pixels

var networkTimeout:Int = 5; // 5 minutes, set to 0 to disable
var renderTimeout:Int = 5; // 5 seconds, set to 0 to disable

var numAttempts:Int = 2; // perform 2 attempts before failing

var numPages:Int = 8; // use 8 browser pages

var numCIJobs:Int = 4; // GitHub Actions run the script in 4 threads

var width:Int = 400;
var height:Int = 250;
var viewScale:Int = 2;
var jpgQuality:Int = 95;

var consoleRed:String->Void = msg -> Sys.println(Chalk.red(msg));
var consoleYellow:String->Void = msg -> Sys.println(Chalk.yellow(msg));
var consoleGreen:String->Void = msg -> Sys.println(Chalk.green(msg));

var browser:Puppeteer.Browser;

/* Launch server */

var app:Express.App = Express.createServer();
app.use(Express.static(Path.resolve()));
var server = app.listen(port, main);

Sys.signal(Signal.SIGINT, _ -> close());

async function main() {
    /* Create output directory */

    try {
        FsPromises.rm('test/e2e/output-screenshots', { recursive: true, force: true });
    } catch (_) {}

    try {
        FsPromises.mkdir('test/e2e/output-screenshots');
    } catch (_) {}

    /* Find files */

    var isMakeScreenshot:Bool = Sys.args()[2] == '--make';

    var exactList:Array<String> = Sys.args().slice(isMakeScreenshot ? 3 : 2).map(f -> f.replace('.html', ''));

    var isExactList:Bool = exactList.length != 0;

    var files:Array<String> = (await FsPromises.readdir('examples'))
        .filter(s -> s.endsWith('.html') && s != 'index.html')
        .map(s -> s.slice(0, s.length - 5))
        .filter(f -> isExactList ? exactList.includes(f) : !exceptionList.includes(f));

    if (isExactList) {
        for (file in exactList) {
            if (!files.includes(file)) {
                consoleRed('Warning! Unrecognised example name: ' + file);
            }
        }
    }

    /* CI parallelism */

    if (Sys.env().exists('CI')) {
        var ci:Int = Std.parseInt(Sys.env().get('CI'));
        files = files.slice(
            Math.floor(ci * files.length / numCIJobs),
            Math.floor((ci + 1) * files.length / numCIJobs)
        );
    }

    /* Launch browser */

    var flags:Array<String> = ['--hide-scrollbars', '--enable-gpu'];
    // flags.push('--enable-unsafe-webgpu', '--enable-features=Vulkan', '--use-gl=swiftshader', '--use-angle=swiftshader', '--use-vulkan=swiftshader');
    // if (Sys.platform() == 'linux') flags.push('--enable-features=Vulkan,UseSkiaRenderer', '--use-vulkan=native', '--disable-vulkan-surface', '--disable-features=VaapiVideoDecoder', '--ignore-gpu-blocklist', '--use-angle=vulkan');

    var viewport:Puppeteer.Viewport = {
        width: width * viewScale,
        height: height * viewScale
    };

    browser = await Puppeteer.launch({
        headless: Sys.env().exists('VISIBLE') ? false : 'new',
        args: flags,
        defaultViewport: viewport,
        handleSIGINT: false,
        protocolTimeout: 0
    });

    // this line is intended to stop the script if the browser (in headful mode) is closed by user (while debugging)
    // browser.on('targetdestroyed', target -> (target.type() === 'other') ? close() : null);
    // for some reason it randomly stops the script after about ~30 screenshots processed

    /* Prepare injections */

    var cleanPage:String = await FsPromises.readFile('test/e2e/clean-page.js', 'utf8');
    var injection:String = await FsPromises.readFile('test/e2e/deterministic-injection.js', 'utf8');
    var build:String = (await FsPromises.readFile('build/three.module.js', 'utf8')).replace(/Math\.random\(\) \* 0xffffffff/g, 'Math._random() * 0xffffffff');

    /* Prepare pages */

    var errorMessagesCache:Array<String> = [];

    var pages:Array<Puppeteer.Page> = await browser.pages();
    while (pages.length < numPages && pages.length < files.length) {
        pages.push(await browser.newPage());
    }

    for (page in pages) {
        await preparePage(page, injection, build, errorMessagesCache);
    }

    /* Loop for each file */

    var failedScreenshots:Array<String> = [];

    var queue:PromiseQueue = new PromiseQueue(makeAttempt, pages, failedScreenshots, cleanPage, isMakeScreenshot);
    for (file in files) {
        queue.add(file);
    }
    await queue.waitForAll();

    /* Finish */

    failedScreenshots.sort((a, b) -> a.localeCompare(b));
    var list:String = failedScreenshots.join(' ');

    if (isMakeScreenshot && failedScreenshots.length > 0) {
        consoleRed('List of failed screenshots: ' + list);
        consoleRed('If you are sure that everything is correct, try to run "npm run make-screenshot ' + list + '". If this does not help, try increasing idleTime and parseTime variables in /test/e2e/puppeteer.js file. If this also does not help, add remaining screenshots to the exception list.');
        consoleRed(failedScreenshots.length + ' from ' + files.length + ' screenshots have not generated succesfully.');
    } else if (isMakeScreenshot && failedScreenshots.length == 0) {
        consoleGreen(files.length + ' screenshots succesfully generated.');
    } else if (failedScreenshots.length > 0) {
        consoleRed('List of failed screenshots: ' + list);
        consoleRed('If you are sure that everything is correct, try to run "npm run make-screenshot ' + list + '". If this does not help, try increasing idleTime and parseTime variables in /test/e2e/puppeteer.js file. If this also does not help, add remaining screenshots to the exception list.');
        consoleRed('TEST FAILED! ' + failedScreenshots.length + ' from ' + files.length + ' screenshots have not rendered correctly.');
    } else {
        consoleGreen('TEST PASSED! ' + files.length + ' screenshots rendered correctly.');
    }

    setTimeout(close, 300, failedScreenshots.length);
}

async function preparePage(page:Puppeteer.Page, injection:String, build:String, errorMessages:Array<String>) {
    /* let page.file, page.pageSize, page.error */

    await page.evaluateOnNewDocument(injection);
    await page.setRequestInterception(true);

    page.on('console', async msg -> {
        var type:String = msg.type();

        if (type !== 'warning' && type !== 'error') {
            return;
        }

        var file:String = page.file;

        if (file === undefined) {
            return;
        }

        var args:Array<Dynamic> = await Promise.all(msg.args().map(arg -> arg.executionContext().evaluate(arg => arg instanceof Error ? arg.message : arg, arg)));

        var text:String = args.join(' '); // https://github.com/puppeteer/puppeteer/issues/3397#issuecomment-434970058

        text = text.trim();
        if (text === '') return;

        text = file + ': ' + text.replace(/\[\.WebGL-(.+?)\]/g, '');

        if (text === `${file}: JSHandle@error`) {
            text = `${file}: Unknown error`;
        }

        if (text.includes('Unable to access the camera/webcam')) {
            return;
        }

        if (errorMessages.includes(text)) {
            return;
        }

        errorMessages.push(text);

        if (type === 'warning') {
            consoleYellow(text);
        } else {
            page.error = text;
        }
    });

    page.on('response', async response -> {
        try {
            if (response.status === 200) {
                await response.buffer().then(buffer -> page.pageSize += buffer.length);
            }
        } catch (_) {}
    });

    page.on('request', async request -> {
        if (request.url === `http://localhost:${port}/build/three.module.js`) {
            await request.respond({
                status: 200,
                contentType: 'application/javascript; charset=utf-8',
                body: build
            });
        } else {
            await request.continue();
        }
    });
}

async function makeAttempt(pages:Array<Puppeteer.Page>, failedScreenshots:Array<String>, cleanPage:String, isMakeScreenshot:Bool, file:String, attemptID:Int = 0) {
    var page:Puppeteer.Page = await new Promise((resolve, reject) -> {
        var interval = setInterval(() -> {
            for (page in pages) {
                if (page.file === undefined) {
                    page.file = file; // acquire lock
                    clearInterval(interval);
                    resolve(page);
                    break;
                }
            }
        }, 100);
    });

    try {
        page.pageSize = 0;
        page.error = undefined;

        /* Load target page */

        try {
            await page.goto(`http://localhost:${port}/examples/${file}.html`, {
                waitUntil: 'networkidle0',
                timeout: networkTimeout * 60000
            });
        } catch (e) {
            throw new Error(`Error happened while loading file ${file}: ${e}`);
        }

        try {
            /* Render page */

            await page.evaluate(cleanPage);

            await page.waitForNetworkIdle({
                timeout: networkTimeout * 60000,
                idleTime: idleTime * 1000
            });

            await page.evaluate(async (renderTimeout, parseTime) -> {
                await new Promise(resolve -> setTimeout(resolve, parseTime));

                /* Resolve render promise */

                window._renderStarted = true;

                await new Promise((resolve, reject) -> {
                    var renderStart:Float = performance.now();

                    var waitingLoop = setInterval(() -> {
                        var renderTimeoutExceeded:Bool = (renderTimeout > 0) && (performance.now() - renderStart > 1000 * renderTimeout);

                        if (renderTimeoutExceeded) {
                            clearInterval(waitingLoop);
                            reject('Render timeout exceeded');
                        } else if (window._renderFinished) {
                            clearInterval(waitingLoop);
                            resolve();
                        }
                    }, 10);
                });
            }, renderTimeout, page.pageSize / 1024 / 1024 * parseTime * 1000);

        } catch (e) {
            if (e.includes && e.includes('Render timeout exceeded') === false) {
                throw new Error(`Error happened while rendering file ${file}: ${e}`);
            } /* else { // This can mean that the example doesn't use requestAnimationFrame loop

                consoleYellow(`Render timeout exceeded in file ${file}`);

            } */ // TODO: fix this
        }

        var screenshot:Jimp.Image = (await jimp.read(await page.screenshot())).scale(1 / viewScale).quality(jpgQuality);

        if (page.error !== undefined) throw new Error(page.error);

        if (isMakeScreenshot) {
            /* Make screenshots */

            await screenshot.writeAsync(`examples/screenshots/${file}.jpg`);

            consoleGreen(`Screenshot generated for file ${file}`);
        } else {
            /* Diff screenshots */

            var expected:Jimp.Image;

            try {
                expected = await jimp.read(`examples/screenshots/${file}.jpg`);
            } catch (_) {
                await screenshot.writeAsync(`test/e2e/output-screenshots/${file}-actual.jpg`);
                throw new Error(`Screenshot does not exist: ${file}`);
            }

            var actual:Jimp.Image = screenshot;

            var diff:Jimp.Image = screenshot.clone();

            var numDifferentPixels:Int;

            try {
                numDifferentPixels = pixelmatch(expected.bitmap.data, actual.bitmap.data, diff.bitmap.data, actual.width, actual.height, {
                    threshold: pixelThreshold,
                    alpha: 0.2
                });
            } catch (_) {
                await screenshot.writeAsync(`test/e2e/output-screenshots/${file}-actual.jpg`);
                await expected.writeAsync(`test/e2e/output-screenshots/${file}-expected.jpg`);
                throw new Error(`Image sizes does not match in file: ${file}`);
            }

            /* Print results */

            var differentPixels:Float = numDifferentPixels / (actual.width * actual.height) * 100;

            if (differentPixels < maxDifferentPixels) {
                consoleGreen(`Diff ${differentPixels.toFixed(1)}% in file: ${file}`);
            } else {
                await screenshot.writeAsync(`test/e2e/output-screenshots/${file}-actual.jpg`);
                await expected.writeAsync(`test/e2e/output-screenshots/${file}-expected.jpg`);
                await diff.writeAsync(`test/e2e/output-screenshots/${file}-diff.jpg`);
                throw new Error(`Diff wrong in ${differentPixels.toFixed(1)}% of pixels in file: ${file}`);
            }
        }
    } catch (e) {
        if (attemptID === numAttempts - 1) {
            consoleRed(e);
            failedScreenshots.push(file);
        } else {
            consoleYellow(`${e}, another attempt...`);
            this.add(file, attemptID + 1);
        }
    }

    page.file = undefined; // release lock
}

function close(exitCode:Int = 1) {
    console.log('Closing...');

    browser.close();
    server.close();
    Sys.exit(exitCode);
}