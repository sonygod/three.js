package three.js.examples.jsm.loaders;

import three.js.loaders.Loader;
import three.js.loaders.FileLoader;
import three.js.core.ShapePath;

class FontLoader extends Loader {
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, ?onLoad:Font->Void, ?onProgress:haxe.io.Bytes->Void, ?onError:haxe.io.Error->Void) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
            var font:Font = parse(JSON.parse(text));
            if (onLoad != null) onLoad(font);
        }, onProgress, onError);
    }

    private function parse(json:Dynamic):Font {
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

    public function generateShapes(text:String, size:Int = 100):Array<ShapePath> {
        var shapes:Array<ShapePath> = [];
        var paths:Array<ShapePath> = createPaths(text, size, this.data);
        for (p in paths) {
            shapes = shapes.concat(p.toShapes());
        }
        return shapes;
    }
}

function createPaths(text:String, size:Int, data:Dynamic):Array<Array<ShapePath>> {
    var chars:Array<String> = [for (char in text.split("")) char];
    var scale:Float = size / data.resolution;
    var lineHeight:Float = (data.boundingBox.yMax - data.boundingBox.yMin + data.underlineThickness) * scale;
    var paths:Array<Array<ShapePath>> = [];
    var offsetX:Float = 0;
    var offsetY:Float = 0;
    for (char in chars) {
        if (char == "\n") {
            offsetX = 0;
            offsetY -= lineHeight;
        } else {
            var ret = createPath(char, scale, offsetX, offsetY, data);
            offsetX += ret.offsetX;
            paths.push([ret.path]);
        }
    }
    return paths;
}

function createPath(char:String, scale:Float, offsetX:Float, offsetY:Float, data:Dynamic):{offsetX:Float, path:ShapePath} {
    var glyph:Dynamic = data.glyphs.get(char) != null ? data.glyphs.get(char) : data.glyphs.get('?');
    if (glyph == null) {
        trace('THREE.Font: character "' + char + '" does not exists in font family ' + data.familyName + '.');
        return null;
    }
    var path:ShapePath = new ShapePath();
    var x:Float, y:Float, cpx:Float, cpy:Float, cpx1:Float, cpy1:Float, cpx2:Float, cpy2:Float;
    if (glyph.o != null) {
        var outline:Array<String> = glyph._cachedOutline != null ? glyph._cachedOutline : glyph.o.split(" ");
        for (i in 0...outline.length) {
            var action:String = outline[i++];
            switch (action) {
                case 'm': // moveTo
                    x = outline[i++] * scale + offsetX;
                    y = outline[i++] * scale + offsetY;
                    path.moveTo(x, y);
                case 'l': // lineTo
                    x = outline[i++] * scale + offsetX;
                    y = outline[i++] * scale + offsetY;
                    path.lineTo(x, y);
                case 'q': // quadraticCurveTo
                    cpx = outline[i++] * scale + offsetX;
                    cpy = outline[i++] * scale + offsetY;
                    cpx1 = outline[i++] * scale + offsetX;
                    cpy1 = outline[i++] * scale + offsetY;
                    path.quadraticCurveTo(cpx1, cpy1, cpx, cpy);
                case 'b': // bezierCurveTo
                    cpx = outline[i++] * scale + offsetX;
                    cpy = outline[i++] * scale + offsetY;
                    cpx1 = outline[i++] * scale + offsetX;
                    cpy1 = outline[i++] * scale + offsetY;
                    cpx2 = outline[i++] * scale + offsetX;
                    cpy2 = outline[i++] * scale + offsetY;
                    path.bezierCurveTo(cpx1, cpy1, cpx2, cpy2, cpx, cpy);
            }
        }
    }
    return {offsetX: glyph.ha * scale, path: path};
}