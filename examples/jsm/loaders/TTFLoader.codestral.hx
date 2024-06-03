import three.FileLoader;
import three.Loader;
import opentype.Opentype;

class TTFLoader extends Loader {

    public var reversed:Bool = false;

    public function new(manager:three.LoadingManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType(three.Loader.ARRAY_BUFFER);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(buffer:ArrayBuffer) {
            try {
                onLoad(this.parse(buffer));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }.bind(this), onProgress, onError);
    }

    public function parse(arraybuffer:ArrayBuffer):Dynamic {
        return convert(Opentype.parse(arraybuffer), this.reversed);
    }

    private static function convert(font:Opentype.Font, reversed:Bool):Dynamic {
        var glyphs:Dynamic = new Dynamic();
        var scale:Float = 100000 / ((font.unitsPerEm != null ? font.unitsPerEm : 2048) * 72);

        var glyphIndexMap = font.encoding.cmap.glyphIndexMap;
        var unicodes = Reflect.fields(glyphIndexMap);

        for (unicode in unicodes) {
            var glyph = font.glyphs.glyphs[glyphIndexMap[unicode]];

            if (unicode != null) {
                var token = {
                    ha: Math.round(glyph.advanceWidth * scale),
                    x_min: Math.round(glyph.xMin * scale),
                    x_max: Math.round(glyph.xMax * scale),
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

                    if (command.x != null && command.y != null) {
                        token.o += Math.round(command.x * scale) + ' ' + Math.round(command.y * scale) + ' ';
                    }

                    if (command.x1 != null && command.y1 != null) {
                        token.o += Math.round(command.x1 * scale) + ' ' + Math.round(command.y1 * scale) + ' ';
                    }

                    if (command.x2 != null && command.y2 != null) {
                        token.o += Math.round(command.x2 * scale) + ' ' + Math.round(command.y2 * scale) + ' ';
                    }
                }

                glyphs[String.fromCodePoint(glyph.unicode)] = token;
            }
        }

        return {
            glyphs: glyphs,
            familyName: font.getEnglishName('fullName'),
            ascender: Math.round(font.ascender * scale),
            descender: Math.round(font.descender * scale),
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

    private static function reverseCommands(commands:Array<Dynamic>):Array<Dynamic> {
        var paths:Array<Array<Dynamic>> = [];
        var path:Array<Dynamic> = null;

        for (command in commands) {
            if (command.type.toLowerCase() == 'm') {
                path = [command];
                paths.push(path);
            } else if (command.type.toLowerCase() != 'z') {
                path.push(command);
            }
        }

        var reversed:Array<Dynamic> = [];

        for (path in paths) {
            var result = {
                type: 'm',
                x: path[path.length - 1].x,
                y: path[path.length - 1].y
            };

            reversed.push(result);

            for (i in (path.length - 1).downTo(1)) {
                var command = path[i];
                var result = {type: command.type};

                if (command.x2 != null && command.y2 != null) {
                    result.x1 = command.x2;
                    result.y1 = command.y2;
                    result.x2 = command.x1;
                    result.y2 = command.y1;
                } else if (command.x1 != null && command.y1 != null) {
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
}