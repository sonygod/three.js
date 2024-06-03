import js.node.FileSystem;
import js.chalk.Chalk;

class Main {
    static function main() {
        js.node.Console.red = function(msg:String) {
            js.node.Console.log(Chalk.red(msg));
        }
        js.node.Console.green = function(msg:String) {
            js.node.Console.log(Chalk.green(msg));
        }
        Main.runMain();
    }

    static async function runMain() {
        var fs = FileSystem.promises;

        var E = (await fs.readdir('examples'))
            .filter(function(s:String) { return s.endsWith('.html'); })
            .map(function(s:String) { return s.substring(0, s.indexOf('.')); })
            .filter(function(f:String) { return f !== 'index'; });

        var S = (await fs.readdir('examples/screenshots'))
            .filter(function(s:String) { return s.indexOf('.') !== -1; })
            .map(function(s:String) { return s.substring(0, s.indexOf('.')); });

        var F = [];

        var files = JSON.parse(await fs.readFile('examples/files.json'));

        for (var section in js.Boot.objectKeys(files)) {
            F.push(...js.Boot.cast(files[section], Array<String>));
        }

        var subES = E.filter(function(x:String) { return !S.includes(x); });
        var subSE = S.filter(function(x:String) { return !E.includes(x); });
        var subEF = E.filter(function(x:String) { return !F.includes(x); });
        var subFE = F.filter(function(x:String) { return !E.includes(x); });

        if (subES.length + subSE.length + subEF.length + subFE.length === 0) {
            js.node.Console.green('TEST PASSED! All examples is covered with screenshots and descriptions in files.json!');
        } else {
            if (subES.length > 0) js.node.Console.red('Make screenshot for example(s): ' + subES.join(' '));
            if (subSE.length > 0) js.node.Console.red('Remove unnecessary screenshot(s): ' + subSE.join(' '));
            if (subEF.length > 0) js.node.Console.red('Add description in files.json for example(s): ' + subEF.join(' '));
            if (subFE.length > 0) js.node.Console.red('Remove description in files.json for example(s): ' + subFE.join(' '));

            js.node.Console.red('TEST FAILED!');

            js.node.Process.exit(1);
        }
    }
}