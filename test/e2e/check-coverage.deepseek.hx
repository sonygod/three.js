import chalk.Chalk;
import js.Promise;
import js.Lib.fs;
import js.Lib.process;

class Main {
    static function main() {
        var chalk = new Chalk();
        console.red = msg -> trace(chalk.red(msg));
        console.green = msg -> trace(chalk.green(msg));

        js.Promise.resolve(mainAsync());
    }

    static function mainAsync():Promise<Void> {
        return Promise.all([
            fs.readdir('examples'),
            fs.readdir('examples/screenshots'),
            fs.readFile('examples/files.json')
        ]).then(results -> {
            var E = results[0].filter(s -> s.endsWith('.html'))
                .map(s -> s.split('.').shift())
                .filter(f -> f != 'index');

            var S = results[1].filter(s -> s.indexOf('.') != -1)
                .map(s -> s.split('.').shift());

            var F = [];
            var files = haxe.Json.parse(results[2]);
            for (section in files.values()) {
                F.push(section);
            }

            var subES = E.filter(x -> !S.includes(x));
            var subSE = S.filter(x -> !E.includes(x));
            var subEF = E.filter(x -> !F.includes(x));
            var subFE = F.filter(x -> !E.includes(x));

            if (subES.length + subSE.length + subEF.length + subFE.length == 0) {
                console.green('TEST PASSED! All examples is covered with screenshots and descriptions in files.json!');
            } else {
                if (subES.length > 0) console.red('Make screenshot for example(s): ' + subES.join(' '));
                if (subSE.length > 0) console.red('Remove unnecessary screenshot(s): ' + subSE.join(' '));
                if (subEF.length > 0) console.red('Add description in files.json for example(s): ' + subEF.join(' '));
                if (subFE.length > 0) console.red('Remove description in files.json for example(s): ' + subFE.join(' '));

                console.red('TEST FAILED!');

                process.exit(1);
            }
        });
    }

    static function main() {
        Main.main();
    }
}