package three.js.test.e2e;

import chalk.Chalk;
import sys.FileSystem;
import sys.io.File;

class CheckCoverage {
  static function main() {
    Sys.println("_running_");

    var chalk = new Chalk();
    Sys.println = function(msg:String) {
      Sys.print(chalk.reset + msg + chalk.reset + "\n");
    };
    Sys.red = function(msg:String) {
      Sys.println(chalk.red(msg));
    };
    Sys.green = function(msg:String) {
      Sys.println(chalk.green(msg));
    };

    mainAsync();
  }

  static async function mainAsync() {
    // examples
    var E:Array<String> = asyncGetFiles("examples").filter(s -> s.endsWith(".html")).map(s -> s.slice(0, s.indexOf("."))).filter(f -> f != "index");

    // screenshots
    var S:Array<String> = asyncGetFiles("examples/screenshots").filter(s -> s.indexOf(".") != -1).map(s -> s.slice(0, s.indexOf(".")));

    // files.js
    var F:Array<String> = [];
    var files:Dynamic = Json.parse(File.getContent("examples/files.json"));
    for (section in files) {
      F = F.concat(section);
    }

    var subES:Array<String> = E.filter(x -> !S.has(x));
    var subSE:Array<String> = S.filter(x -> !E.has(x));
    var subEF:Array<String> = E.filter(x -> !F.has(x));
    var subFE:Array<String> = F.filter(x -> !E.has(x));

    if (subES.length + subSE.length + subEF.length + subFE.length == 0) {
      Sys.green("TEST PASSED! All examples is covered with screenshots and descriptions in files.json!");
    } else {
      if (subES.length > 0) Sys.red("Make screenshot for example(s): " + subES.join(" "));
      if (subSE.length > 0) Sys.red("Remove unnecessary screenshot(s): " + subSE.join(" "));
      if (subEF.length > 0) Sys.red("Add description in files.json for example(s): " + subEF.join(" "));
      if (subFE.length > 0) Sys.red("Remove description in files.json for example(s): " + subFE.join(" "));

      Sys.red("TEST FAILED!");
      Sys.exit(1);
    }
  }

  static function asyncGetFiles(path:String):Array<String> {
    return FileSystem.readDirectory(path).filter(s -> s.indexOf(".") != -1);
  }
}