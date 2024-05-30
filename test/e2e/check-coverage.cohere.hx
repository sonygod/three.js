import js.Node.Fs;
import js.Node.Process;

class Console {
    static function red(msg:String) {
        trace(js.Node.ChildProcess.execSync("chalk -r '" + msg + "'"));
    }

    static function green(msg:String) {
        trace(js.Node.ChildProcess.execSync("chalk -g '" + msg + "'"));
    }
}

@:async
static function main() {
    // examples
    var E = [];
    var dir = await Fs.readdir('examples');
    for (f in dir) {
        if (f.endsWith('.html')) {
            E.push(f.substring(0, f.indexOf('.')));
        }
    }
    E = E.filter(f -> f != 'index');

    // screenshots
    var S = [];
    var dir = await Fs.readdir('examples/screenshots');
    for (f in dir) {
        if (f.indexOf('.') != -1) {
            S.push(f.substring(0, f.indexOf('.')));
        }
    }

    // files.json
    var F = [];
    var files = JSON.parse(await Fs.readFile('examples/files.json'));
    for (section in files) {
        for (f in files[section]) {
            F.push(f);
        }
    }

    var subES = E.filter(x -> !S.includes(x));
    var subSE = S.filter(x -> !E.includes(x));
    var subEF = E.filter(x -> !F.includes(x));
    var subFE = F.filter(x -> !E.includes(x));

    if (subES.length + subSE.length + subEF.length + subFE.length == 0) {
        Console.green('TEST PASSED! All examples are covered with screenshots and descriptions in files.json!');
    } else {
        if (subES.length > 0) Console.red('Make screenshot for example(s): ' + subES.join(' '));
        if (subSE.length > 0) Console.red('Remove unnecessary screenshot(s): ' + subSE.join(' '));
        if (subEF.length > 0) Console.red('Add description in files.json for example(s): ' + subEF.join(' '));
        if (subFE.length > 0) Console.red('Remove description in files.json for example(s): ' + subFE.join(' '));

        Console.red('TEST FAILED!');

        Process.exit(1);
    }
}

$hxRunMain();