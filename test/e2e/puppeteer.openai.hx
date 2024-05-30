import js.node Fs;
import js.node.Path;
import js.Lib;
import js.html.Console;
import js.puppeteer.Puppeteer;
import js.puppeteer.Browser;
import js.puppeteer.Page;
import js.jimp.Jimp;
import js.pixelmatch.Pixelmatch;

class PromiseQueue {
  var func: Dynamic;
  var promises: Array<js.lib.Promise<Dynamic>>;

  public function new(func: Dynamic, ...args: Dynamic) {
    this.func = func.bind(this, ...args);
    this.promises = [];
  }

  public function add(...args: Dynamic) {
    var promise = this.func(...args);
    this.promises.push(promise);
    promise.then(function() {
      this.promises.splice(this.promises.indexOf(promise), 1);
    });
  }

  public async function waitForAll() {
    while (this.promises.length > 0) {
      await js.lib.Promise.all(this.promises);
    }
  }
}

class Main {
  static function main() {
    var idleTime = 9; // 9 seconds - for how long there should be no network requests
    var parseTime = 6; // 6 seconds per megabyte

    var exceptionList = [
      // ... ( same list as in the original JavaScript code )
    ];

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

    Console.addRedLogFunction(function(msg) {
      Console.log(chalk.red(msg));
    });

    Console.addYellowLogFunction(function(msg) {
      Console.log(chalk.yellow(msg));
    });

    Console.addGreenLogFunction(function(msg) {
      Console.log(chalk.green(msg));
    });

    var browser: Browser;

    express()
      .use(express.static(Path.resolve()))
      .listen(port, function() {
        start();
      });

    process.on('SIGINT', function() {
      close(0);
    });

    function start() {
      Fs.mkdir('test/e2e/output-screenshots', function(err) {
        if (err) {
          Console.error(err);
          return;
        }
        var files = Fs.readdirSync('examples')
          .filter(function(s) {
            return s.endsWith('.html') && s != 'index.html';
          })
          .map(function(s) {
            return s.slice(0, s.length - 5);
          })
          .filter(function(f) {
            return !exceptionList.includes(f);
          });

        if (process.argv.length > 2 && process.argv[2] === '--make') {
          var exactList = process.argv.slice(3)
            .map(function(f) {
              return f.replace('.html', '');
            });
          files = files.filter(function(f) {
            return exactList.includes(f);
          });
          exactList.forEach(function(file) {
            if (!files.includes(file)) {
              Console.log(`Warning! Unrecognised example name: ${file}`);
            }
          });
        }

        if ('CI' in process.env) {
          var ci = parseInt(process.env.CI);
          files = files.slice(
            Math.floor(ci * files.length / numCIJobs),
            Math.floor((ci + 1) * files.length / numCIJobs)
          );
        }

        var flags = [
          '--hide-scrollbars',
          '--enable-gpu'
        ];
        // ...
        var viewport = {
          width: width * viewScale,
          height: height * viewScale
        };

        Puppeteer.launch({
          headless: process.env.VISIBLE ? false : 'new',
          args: flags,
          defaultViewport: viewport,
          handleSIGINT: false,
          protocolTimeout: 0
        }).then(function(browser) {
          browser.on('targetdestroyed', function(target) {
            // ...
          });

          var cleanPage = Fs.readFileSync('test/e2e/clean-page.js', 'utf8');
          var injection = Fs.readFileSync('test/e2e/deterministic-injection.js', 'utf8');
          var build = Fs.readFileSync('build/three.module.js', 'utf8')
            .replace(/Math\.random\(\) \* 0xffffffff/g, 'Math._random() * 0xffffffff');

          var errorMessagesCache = [];

          var pages = browser.pages.then(function(pages) {
            while (pages.length < numPages && pages.length < files.length) {
              pages.push(browser.newPage());
            }

            for (page in pages) {
              preparePage(page, injection, build, errorMessagesCache);
            }

            var queue = new PromiseQueue(makeAttempt, pages, failedScreenshots, cleanPage, process.argv[2] === '--make');
            for (file in files) {
              queue.add(file);
            }
            queue.waitForAll();
          });
        });
      });
    }

    function preparePage(page: Page, injection: String, build: String, errorMessagesCache: Array<String>) {
      // ...
    }

    function makeAttempt(pages: Array<Page>, failedScreenshots: Array<String>, cleanPage: String, isMakeScreenshot: Bool, file: String, attemptID: Int = 0) {
      // ...
    }

    function close(exitCode: Int = 1) {
      Console.log('Closing...');
      browser.close();
      server.close();
      process.exit(exitCode);
    }
  }
}