package three.js.test.e2e;

import chalk.Chalk;
import sys.io.File;
import sys.FileSystem;

class CheckCoverage {
  static function main() {
    Sys.println("Checking coverage...");

    var chalk = new Chalk();
    Sys.println = function(msg:String) {
      Sys.println(chalk.red(msg));
    };
    Sys.println.Green = function(msg:String) {
      Sys.println(chalk.green(msg));
    };

    main();
  }

  static async function main() {
    // examples
    var examplesDir = 'examples';
    var exampleFiles = FileSystem.readDirectory(examplesDir);
    var E = Lambda.filter(exampleFiles, function(file:String) return file.endsWith('.html'));
    E = Lambda.map(E, function(file:String) return file.substring(0, file.indexOf('.')));
    E = Lambda.filter(E, function(file:String) return file != 'index');

    // screenshots
    var screenshotsDir = 'examples/screenshots';
    var screenshotFiles = FileSystem.readDirectory(screenshotsDir);
    var S = Lambda.filter(screenshotFiles, function(file:String) return file.indexOf('.') != -1);
    S = Lambda.map(S, function(file:String) return file.substring(0, file.indexOf('.')));

    // files.js
    var filesJson = File.getContent('examples/files.json');
    var files = Json.parse(filesJson);
    var F:Array<String> = [];
    for (section in files) {
      F = F.concat(cast section);
    }

    var subES = Lambda.filter(E, function(x:String) return !Lambda.has(S, x));
    var subSE = Lambda.filter(S, function(x:String) return !Lambda.has(E, x));
    var subEF = Lambda.filter(E, function(x:String) return !Lambda.has(F, x));
    var subFE = Lambda.filter(F, function(x:String) return !Lambda.has(E, x));

    if (subES.length + subSE.length + subEF.length + subFE.length == 0) {
      Sys.println.Green('TEST PASSED! All examples is covered with screenshots and descriptions in files.json!');
    } else {
      if (subES.length > 0) Sys.println.Red('Make screenshot for example(s): ' + subES.join(' '));
      if (subSE.length > 0) Sys.println.Red('Remove unnecessary screenshot(s): ' + subSE.join(' '));
      if (subEF.length > 0) Sys.println.Red('Add description in files.json for example(s): ' + subEF.join(' '));
      if (subFE.length > 0) Sys.println.Red('Remove description in files.json for example(s): ' + subFE.join(' '));

      Sys.println.Red('TEST FAILED!');
      Sys.exit(1);
    }
  }
}