import three.FileLoader;
import three.Loader;
import three.ShapePath;

class FontLoader extends Loader {

	public function new(manager:Dynamic) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
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

	public var isFont:Bool;
	public var type:String;
	public var data:Dynamic;

	public function new(data:Dynamic) {
		this.isFont = true;
		this.type = 'Font';
		this.data = data;
	}

	public function generateShapes(text:String, size:Float = 100):Array<ShapePath> {
		var shapes = [];
		var paths = createPaths(text, size, this.data);
		for (p in paths) {
			shapes.push(...p.toShapes());
		}
		return shapes;
	}

}

function createPaths(text:String, size:Float, data:Dynamic):Array<ShapePath> {
	var chars = haxe.ds.StringMap.fromString(text).toArray();
	var scale = size / data.resolution;
	var line_height = (data.boundingBox.yMax - data.boundingBox.yMin + data.underlineThickness) * scale;
	var paths = [];
	var offsetX = 0;
	var offsetY = 0;
	for (i in haxe.ds.IntMap.fromRange(0, chars.length)) {
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
	var glyph = data.glyphs[char] ?? data.glyphs['?'];
	if (glyph == null) {
		trace('THREE.Font: character "' + char + '" does not exists in font family ' + data.familyName + '.');
		return null;
	}
	var path = new ShapePath();
	var x:Float;
	var y:Float;
	var cpx:Float;
	var cpy:Float;
	var cpx1:Float;
	var cpy1:Float;
	var cpx2:Float;
	var cpy2:Float;
	if (glyph.o != null) {
		var outline = glyph._cachedOutline ?? (glyph._cachedOutline = glyph.o.split(' '));
		for (i in haxe.ds.IntMap.fromRange(0, outline.length)) {
			var action = outline[i];
			switch (action) {
				case 'm': // moveTo
					x = outline[++i] * scale + offsetX;
					y = outline[++i] * scale + offsetY;
					path.moveTo(x, y);
					break;
				case 'l': // lineTo
					x = outline[++i] * scale + offsetX;
					y = outline[++i] * scale + offsetY;
					path.lineTo(x, y);
					break;
				case 'q': // quadraticCurveTo
					cpx = outline[++i] * scale + offsetX;
					cpy = outline[++i] * scale + offsetY;
					cpx1 = outline[++i] * scale + offsetX;
					cpy1 = outline[++i] * scale + offsetY;
					path.quadraticCurveTo(cpx1, cpy1, cpx, cpy);
					break;
				case 'b': // bezierCurveTo
					cpx = outline[++i] * scale + offsetX;
					cpy = outline[++i] * scale + offsetY;
					cpx1 = outline[++i] * scale + offsetX;
					cpy1 = outline[++i] * scale + offsetY;
					cpx2 = outline[++i] * scale + offsetX;
					cpy2 = outline[++i] * scale + offsetY;
					path.bezierCurveTo(cpx1, cpy1, cpx2, cpy2, cpx, cpy);
					break;
			}
		}
	}
	return {offsetX: glyph.ha * scale, path: path};
}