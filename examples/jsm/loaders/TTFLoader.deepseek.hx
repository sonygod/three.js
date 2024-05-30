import js.Browser.FileLoader;
import js.Browser.Loader;
import js.Lib.opentype;

/**
 * Requires opentype.js to be included in the project.
 * Loads TTF files and converts them into typeface JSON that can be used directly
 * to create THREE.Font objects.
 */

class TTFLoader extends Loader {

	var reversed:Bool;

	public function new(manager:Loader) {
		super(manager);
		this.reversed = false;
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(buffer:ArrayBuffer) {
			try {
				onLoad(scope.parse(buffer));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					trace(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(arraybuffer:ArrayBuffer):Dynamic {
		function convert(font:Dynamic, reversed:Bool):Dynamic {
			var round = Math.round;
			var glyphs = {};
			var scale = (100000) / ((font.unitsPerEm || 2048) * 72);
			var glyphIndexMap = font.encoding.cmap.glyphIndexMap;
			var unicodes = Object.keys(glyphIndexMap);
			for (i in unicodes) {
				var unicode = unicodes[i];
				var glyph = font.glyphs.glyphs[glyphIndexMap[unicode]];
				if (unicode !== undefined) {
					var token = {
						ha: round(glyph.advanceWidth * scale),
						x_min: round(glyph.xMin * scale),
						x_max: round(glyph.xMax * scale),
						o: ''
					};
					if (reversed) {
						glyph.path.commands = reverseCommands(glyph.path.commands);
					}
					for (command in glyph.path.commands) {
						if (command.type.toLowerCase() == 'c') {
							command.type = 'b';
						}
						token.o += command.type.toLowerCase() + ' ';
						if (command.x !== undefined && command.y !== undefined) {
							token.o += round(command.x * scale) + ' ' + round(command.y * scale) + ' ';
						}
						if (command.x1 !== undefined && command.y1 !== undefined) {
							token.o += round(command.x1 * scale) + ' ' + round(command.y1 * scale) + ' ';
						}
						if (command.x2 !== undefined && command.y2 !== undefined) {
							token.o += round(command.x2 * scale) + ' ' + round(command.y2 * scale) + ' ';
						}
					}
					glyphs[String.fromCodePoint(glyph.unicode)] = token;
				}
			}
			return {
				glyphs: glyphs,
				familyName: font.getEnglishName('fullName'),
				ascender: round(font.ascender * scale),
				descender: round(font.descender * scale),
				underlinePosition: font.tables.post.underlinePosition,
				underlineThickness: font.tables.post.underlineThickness,
				boundingBox: {
					xMin: font.tables.head.xMin,
					xMax: font.tables.head.xMax,
					yMin: font.tables.head.yMin,
					yMax: font.tables.head.yMax
				},
				resolution: 1000,
				original_font_information: font.tables.name
			};
		}
		function reverseCommands(commands:Array<Dynamic>):Array<Dynamic> {
			var paths = [];
			var path;
			for (command in commands) {
				if (command.type.toLowerCase() == 'm') {
					path = [command];
					paths.push(path);
				} else if (command.type.toLowerCase() != 'z') {
					path.push(command);
				}
			}
			var reversed = [];
			for (path in paths) {
				var result = {
					type: 'm',
					x: path[path.length - 1].x,
					y: path[path.length - 1].y
				};
				reversed.push(result);
				for (i in path.length - 1) {
					var command = path[i];
					var result = {type: command.type};
					if (command.x2 !== undefined && command.y2 !== undefined) {
						result.x1 = command.x2;
						result.y1 = command.y2;
						result.x2 = command.x1;
						result.y2 = command.y1;
					} else if (command.x1 !== undefined && command.y1 !== undefined) {
						result.x1 = command.x1;
						result.y1 = command.y1;
					}
					result.x = path[i - 1].x;
					result.y = path[i - 1].y;
					reversed.push(result);
				}
			}
			return reversed;
		}
		return convert(opentype.parse(arraybuffer), this.reversed);
	}
}