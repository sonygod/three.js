package three.js.manual.resources.tools.geo_picking;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import haxe.io.Bytes;

class MakeGeoPickingTextureOGC {
    static function main() {
        var baseDir = Sys.args()[0];
        var areas = readJSON('level1.json');
        for (area in areas) {
            try {
                var buf = Bytes.ofString(area.geom, 'base64');
                area.geom = parseGeom(buf);
            } catch (e:Dynamic) {
                trace('ERROR: ' + e);
                trace(Json.stringify(area, null, 2));
                throw e;
            }
        }
        trace(Json.stringify(areas, null, 2));
    }

    static function readJSON(name:String):Dynamic {
        var filePath = FileSystem.absolutePath(name, baseDir);
        var jsonData = File.getContent(filePath);
        return Json.parse(jsonData);
    }
}