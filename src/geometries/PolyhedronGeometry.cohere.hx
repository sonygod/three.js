import h2d.Tile;
import h2d.TileMap;
import h2d.TileSheet;

class TileSheetParser {
    public static function parse(data:String, tileWidth:Int, tileHeight:Int):TileSheet {
        var sheet = new TileSheet(tileWidth, tileHeight);
        var lines = data.split("\n");
        for (line in lines) {
            var tokens = line.split(" ");
            if (tokens.length >= 4) {
                var id = Std.parseInt(tokens[0]);
                var x = Std.parseInt(tokens[1]);
                var y = Std.parseInt(tokens[2]);
                var width = Std.parseInt(tokens[3]);
                if (tokens.length >= 5) {
                    var height = Std.parseInt(tokens[4]);
                    sheet.addTile(id, x, y, width, height);
                } else {
                    sheet.addTile(id, x, y, width, tileHeight);
                }
            }
        }
        return sheet;
    }
}

class TileMapParser {
    public static function parse(data:String, sheet:TileSheet):TileMap {
        var map = new TileMap(sheet);
        var lines = data.split("\n");
        for (y in 0...lines.length) {
            var line = lines[y];
            for (x in 0...line.length) {
                var ch = line.charAt(x);
                var id = sheet.getTileId(ch);
                if (id >= 0) {
                    map.setTile(x, y, id);
                }
            }
        }
        return map;
    }
}

class TileMapSerializer {
    public static function serialize(map:TileMap):String {
        var sheet = map.getTileSheet();
        var data = "";
        for (y in 0...map.getHeight()) {
            for (x in 0...map.getWidth()) {
                var id = map.getTileId(x, y);
                var ch = sheet.getTileChar(id);
                data += ch;
            }
            data += "\n";
        }
        return data;
    }
}