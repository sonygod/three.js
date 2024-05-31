package ;

import three.core.ShapePath;
import three.loaders.FileLoader;
import three.loaders.Loader;

class FontLoader extends Loader {

    public function new(manager:Dynamic = null) {
        super(manager);
    }

    override public function load(url:String, onLoad:Dynamic->Void, ?onProgress:Dynamic->Void, ?onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
            var font = scope.parse(haxe.Json.parse(text));
            if (onLoad != null) onLoad(font);
        }, onProgress, onError);
    }

    public function parse(json:Dynamic):Font {
        return new Font(json);
    }
}

class Font {

    public var isFont(default, null):Bool = true;
    public var type(default, null):String = "Font";
    public var data:Dynamic;

    public function new(data:Dynamic) {
        this.data = data;
    }

    public function generateShapes(text:String, size:Float = 100):Array<ShapePath> {
        var shapes = [];
        var paths = createPaths(text, size, this.data);
        for (p in 0...paths.length) {
            for (shape in paths[p].toShapes()) {
                shapes.push(shape);
            }
        }
        return shapes;
    }
}

function createPaths(text:String, size:Float, data:Dynamic):Array<ShapePath> {
    var chars = text.split("");
    var scale = size / data.resolution;
    var line_height = (data.boundingBox.yMax - data.boundingBox.yMin + data.underlineThickness) * scale;
    var paths = [];
    var offsetX = 0.0;
    var offsetY = 0.0;
    for (i in 0...chars.length) {
        var char = chars[i];
        if (char == "\n") {
            offsetX = 0;
            offsetY -= line_height;
        } else {
            var ret = createPath(char, scale, offsetX, offsetY, data);
            offsetX += ret.offsetX;
            paths.push(ret.path);
        }
    }
    return paths;
}

function createPath(char:String, scale:Float, offsetX:Float, offsetY:Float, data:Dynamic):{offsetX:Float, path:ShapePath} {
    var glyph = (data.glyphs.exists(char)) ? data.glyphs[char] : data.glyphs["?"];
    if (glyph == null) {
        trace('THREE.Font: character "' + char + '" does not exists in font family ' + data.familyName + '.');
        return null;
    }
    var path = new ShapePath();
    var x:Float = 0;
    var y:Float = 0;
    var cpx:Float = 0;
    var cpy:Float = 0;
    var cpx1:Float = 0;
    var cpy1:Float = 0;
    var cpx2:Float = 0;
    var cpy2:Float = 0;
    if (glyph.o != null) {
        var outline = glyph._cachedOutline != null ? glyph._cachedOutline : glyph._cachedOutline = glyph.o.split(" ");
        var i = 0;
        while (i < outline.length) {
            var action = outline[i++];
            switch (action) {
                case "m": // moveTo
                    x = Std.parseFloat(outline[i++]) * scale + offsetX;
                    y = Std.parseFloat(outline[i++]) * scale + offsetY;
                    path.moveTo(x, y);
                case "l": // lineTo
                    x = Std.parseFloat(outline[i++]) * scale + offsetX;
                    y = Std.parseFloat(outline[i++]) * scale + offsetY;
                    path.lineTo(x, y);
                case "q": // quadraticCurveTo
                    cpx = Std.parseFloat(outline[i++]) * scale + offsetX;
                    cpy = Std.parseFloat(outline[i++]) * scale + offsetY;
                    cpx1 = Std.parseFloat(outline[i++]) * scale + offsetX;
                    cpy1 = Std.parseFloat(outline[i++]) * scale + offsetY;
                    path.quadraticCurveTo(cpx1, cpy1, cpx, cpy);
                case "b": // bezierCurveTo
                    cpx = Std.parseFloat(outline[i++]) * scale + offsetX;
                    cpy = Std.parseFloat(outline[i++]) * scale + offsetY;
                    cpx1 = Std.parseFloat(outline[i++]) * scale + offsetX;
                    cpy1 = Std.parseFloat(outline[i++]) * scale + offsetY;
                    cpx2 = Std.parseFloat(outline[i++]) * scale + offsetX;
                    cpy2 = Std.parseFloat(outline[i++]) * scale + offsetY;
                    path.bezierCurveTo(cpx1, cpy1, cpx2, cpy2, cpx, cpy);
            }
        }
    }
    return { offsetX: glyph.ha * scale, path: path };
}