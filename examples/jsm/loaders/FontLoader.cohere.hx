package;

import js.three.FileLoader;
import js.three.Loader;
import js.three.ShapePath;

class FontLoader extends Loader {
    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var scope = this;
        var loader = new FileLoader(this.manager);
        loader.path = this.path;
        loader.requestHeader = this.requestHeader;
        loader.withCredentials = this.withCredentials;
        loader.load(url, function(text) {
            var font = scope.parse(js.Json.parse(text));
            if (onLoad != null) {
                onLoad(font);
            }
        }, onProgress, onError);
    }

    public function parse(json:Dynamic):Font {
        return new Font(json);
    }
}

class Font {
    public var isFont:Bool;
    public var type:String;
    public var data:Dynamic;

    public function new(data:Dynamic) {
        this.isFont = true;
        this.type = 'Font';
        this.data = data;
    }

    public function generateShapes(text:String, size:Float = 100.):Array<Dynamic> {
        var shapes = [];
        var paths = createPaths(text, size, this.data);
        for (p in 0...paths.length) {
            var path = paths[p];
            shapes.pushArray(path.toShapes());
        }
        return shapes;
    }
}

function createPaths(text:String, size:Float, data:Dynamic):Array<ShapePath> {
    var chars = text.split('');
    var scale = size / data.resolution;
    var lineHeight = (data.boundingBox.yMax - data.boundingBox.yMin + data.underlineThickness) * scale;
    var paths = [];
    var offsetX = 0.;
    var offsetY = 0.;

    for (i in 0...chars.length) {
        var char = chars[i];
        if (char == '\n') {
            offsetX = 0.;
            offsetY -= lineHeight;
        } else {
            var ret = createPath(char, scale, offsetX, offsetY, data);
            offsetX += ret.offsetX;
            paths.push(ret.path);
        }
    }

    return paths;
}

function createPath(char:String, scale:Float, offsetX:Float, offsetY:Float, data:Dynamic):{path:ShapePath, offsetX:Float} {
    var glyph = data.glyphs[char] ?? data.glyphs['?'];
    if (glyph == null) {
        trace('THREE.Font: character "' + char + '" does not exist in font family ' + data.familyName + '.');
        return {path: null, offsetX: 0.};
    }

    var path = new ShapePath();
    var x = 0.;
    var y = 0.;
    var cpx = 0.;
    var cpy = 0.;
    var cpx1 = 0.;
    var cpy1 = 0.;
    var cpx2 = 0.;
    var cpy2 = 0.;

    if (glyph.o != null) {
        var outline = glyph._cachedOutline ?? (glyph._cachedOutline = glyph.o.split(' '));
        var i = 0;
        while (i < outline.length) {
            var action = outline[i++];
            switch (action) {
                case 'm': // moveTo
                    x = Std.parseFloat(outline[i++]) * scale + offsetX;
                    y = Std.parseFloat(outline[i++]) * scale + offsetY;
                    path.moveTo(x, y);
                    break;
                case 'l': // lineTo
                    x = Std.parseFloat(outline[i++]) * scale + offsetX;
                    y = Std.parseFloat(outline[i++]) * scale + offsetY;
                    path.lineTo(x, y);
                    break;
                case 'q': // quadraticCurveTo
                    cpx = Std.parseFloat(outline[i++]) * scale + offsetX;
                    cpy = Std.parseFloat(outline[i++]) * scale + offsetY;
                    cpx1 = Std.parseFloat(outline[i++]) * scale + offsetX;
                    cpy1 = Std.parseFloat(outline[i++]) * scale + offsetY;
                    path.quadraticCurveTo(cpx1, cpy1, cpx, cpy);
                    break;
                case 'b': // bezierCurveTo
                    cpx = Std.parseFloat(outline[i++]) * scale + offsetX;
                    cpy = Std.parseFloat(outline[i++]) * scale + offsetY;
                    cpx1 = Std.parseFloat(outline[i++]) * scale + offsetX;
                    cpy1 = Std.parseFloat(outline[i++]) * scale + offsetY;
                    cpx2 = Std.parseFloat(outline[i++]) * scale + offsetX;
                    cpy2 = Std.parseFloat(outline[i++]) * scale + offsetY;
                    path.bezierCurveTo(cpx1, cpy1, cpx2, cpy2, cpx, cpy);
                    break;
            }
        }
    }

    return {path: path, offsetX: glyph.ha * scale};
}