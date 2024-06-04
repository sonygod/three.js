import haxe.io.Bytes;
import haxe.io.File;
import haxe.io.Path;
import haxe.json.Json;
import haxe.io.Encoding;

class Main {

  static function main() {
    var baseDir = Sys.args()[1];

    function readJSON(name:String):Dynamic {
      return Json.parse(File.getContent(Path.join([baseDir, name]), Encoding.UTF8));
    }

    var areas = readJSON("level1.json");
    areas.forEach((area, ndx) => {
      trace(ndx);
      try {
        var buf = Bytes.ofData(Base64.decode(area.geom));
        area.geom = parseGeom(buf);
      } catch(e) {
        trace("ERROR:", e);
        trace(Json.stringify(area, null, 2));
        throw e;
      }
    });

    trace(Json.stringify(areas, null, 2));
  }
}

// You need to implement the `parseGeom` function yourself.
// This function should take a `Bytes` object as input and return the parsed geometry.
function parseGeom(buf:Bytes):Dynamic {
  // Implement your geometry parsing logic here
  return null;
}