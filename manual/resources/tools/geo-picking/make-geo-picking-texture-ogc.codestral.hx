import js.node.FileSystem;
import js.node.Path;
import js.node.Process;
import js.node.Buffer;
import haxe.Json;
import js.html.Console;

var fs = FileSystem.instance;
var path = Path.instance;

var baseDir = Process.argv[2];

function readJSON(name:String) {
    var content = fs.readFileSync(path.join(baseDir, name), {encoding: 'utf-8'});
    return Json.parse(content);
}

function main() {
    var areas = readJSON('level1.json');
    for (ndx in 0...areas.length) {
        Console.log(ndx);
        try {
            var buf = js.node.buffer.Buffer.from(areas[ndx].geom, 'base64');
            areas[ndx].geom = parseGeom(buf.buffer); // Assuming parseGeom is a Haxe function
        } catch (e:Dynamic) {
            Console.log('ERROR: ' + Std.string(e));
            Console.log(Json.stringify(areas[ndx], null, 2));
            throw e;
        }
    }
    Console.log(Json.stringify(areas, null, 2));
}

main();