import sys.io.File;
import sys.FileSystem;
import haxe.Json;
import haxe.crypto.Base64;

class GeoPickingTextureOgc {
    static function main():Void {
        var baseDir:String = Sys.args()[2];

        var areas:Array<Dynamic> = readJSON('level1.json');
        for (area in areas) {
            Sys.println(area.ndx);
            try {
                var buf:Bytes = Bytes.ofString(area.geom, 'base64');
                area.geom = parseGeom(buf);
            } catch (e:Dynamic) {
                Sys.println('ERROR: ' + e);
                Sys.println(Json.stringify(area, null, 2));
                throw e;
            }
        }

        Sys.println(Json.stringify(areas, null, 2));
    }

    static function readJSON(name:String):Array<Dynamic> {
        var filePath:String = Path.join([baseDir, name]);
        var content:String = File.getContent(filePath);
        return Json.parse(content);
    }
}