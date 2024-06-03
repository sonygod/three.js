import js.html.FileLoader;
import js.html.Loader;
import js.html.ShapePath;

class FontLoader extends Loader {

    public function new(manager:js.html.LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:js.Function, onProgress:js.Function, onError:js.Function):Void {
        var scope = this;
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
            var font = scope.parse(js.JSON.parse(text));
            if (onLoad != null) onLoad.call(font);
        }, onProgress, onError);
    }

    public function parse(json:Dynamic):Font {
        return new Font(json);
    }
}

class Font {
    public var isFont:Bool = true;
    public var type:String = "Font";
    public var data:Dynamic;

    public function new(data:Dynamic) {
        this.data = data;
    }

    public function generateShapes(text:String, size:Float = 100):Array<ShapePath> {
        var shapes = new Array<ShapePath>();
        var paths = createPaths(text, size, this.data);

        for (path in paths) {
            shapes = shapes.concat(path.toShapes());
        }

        return shapes;
    }
}

function createPaths(text:String, size:Float, data:Dynamic):Array<ShapePath> {
    var chars = Array.from(text);
    var scale = size / data.resolution;
    var line_height = (data.boundingBox.yMax - data.boundingBox.yMin + data.underlineThickness) * scale;

    var paths = new Array<ShapePath>();

    var offsetX = 0.0;
    var offsetY = 0.0;

    for (i in 0...chars.length) {
        var char = chars[i];

        if (char == '\n') {
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

function createPath(char:String, scale:Float, offsetX:Float, offsetY:Float, data:Dynamic):Dynamic {
    var glyph = data.glyphs[char] != null ? data.glyphs[char] : data.glyphs['?'];

    if (glyph == null) {
        js.Browser.console.error("THREE.Font: character \"" + char + "\" does not exists in font family " + data.familyName + ".");
        return null;
    }

    var path = new ShapePath();

    var x:Float, y:Float, cpx:Float, cpy:Float, cpx1:Float, cpy1:Float, cpx2:Float, cpy2:Float;

    if (glyph.o != null) {
        var outline = glyph._cachedOutline != null ? glyph._cachedOutline : (glyph._cachedOutline = glyph.o.split(' '));

        for (i in 0...outline.length) {
            var action = outline[i++];

            switch (action) {
                case 'm': // moveTo
                    x = outline[i++] * scale + offsetX;
                    y = outline[i++] * scale + offsetY;
                    path.moveTo(x, y);
                    break;

                case 'l': // lineTo
                    x = outline[i++] * scale + offsetX;
                    y = outline[i++] * scale + offsetY;
                    path.lineTo(x, y);
                    break;

                case 'q': // quadraticCurveTo
                    cpx = outline[i++] * scale + offsetX;
                    cpy = outline[i++] * scale + offsetY;
                    cpx1 = outline[i++] * scale + offsetX;
                    cpy1 = outline[i++] * scale + offsetY;
                    path.quadraticCurveTo(cpx1, cpy1, cpx, cpy);
                    break;

                case 'b': // bezierCurveTo
                    cpx = outline[i++] * scale + offsetX;
                    cpy = outline[i++] * scale + offsetY;
                    cpx1 = outline[i++] * scale + offsetX;
                    cpy1 = outline[i++] * scale + offsetY;
                    cpx2 = outline[i++] * scale + offsetX;
                    cpy2 = outline[i++] * scale + offsetY;
                    path.bezierCurveTo(cpx1, cpy1, cpx2, cpy2, cpx, cpy);
                    break;
            }
        }
    }

    return { offsetX: glyph.ha * scale, path: path };
}

export FontLoader;
export Font;