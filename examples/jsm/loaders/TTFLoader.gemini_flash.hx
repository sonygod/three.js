import three.loaders.Loader;
import three.loaders.FileLoader;
import opentype.Opentype;

/**
 * Requires opentype.js to be included in the project.
 * Loads TTF files and converts them into typeface JSON that can be used directly
 * to create THREE.Font objects.
 */
class TTFLoader extends Loader {
    public var reversed:Bool;

    public function new(manager:Loader = null) {
        super(manager);
        this.reversed = false;
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
        var scope = this;
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(buffer:haxe.io.Bytes) {
            try {
                onLoad(scope.parse(buffer));
            } catch(e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    Sys.println(e);
                }

                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(arraybuffer:haxe.io.Bytes):Dynamic {
        function convert(font:Opentype.Font, reversed:Bool):Dynamic {
            var round = Math.round;

            var glyphs = new haxe.ds.StringMap<Dynamic>();
            var scale = (100000) / ((font.unitsPerEm || 2048) * 72);

            var glyphIndexMap = font.encoding.cmap.glyphIndexMap;
            var unicodes = Reflect.fields(glyphIndexMap);

            for (i in 0...unicodes.length) {
                var unicode = unicodes[i];
                var glyph = font.glyphs.glyphs[glyphIndexMap[unicode]];

                if (unicode != null) {
                    var token = {
                        ha: round(glyph.advanceWidth * scale),
                        x_min: round(glyph.xMin * scale),
                        x_max: round(glyph.xMax * scale),
                        o: ''
                    };

                    if (reversed) {
                        glyph.path.commands = reverseCommands(glyph.path.commands);
                    }

                    glyph.path.commands.forEach(function(command) {
                        if (command.type.toLowerCase() == 'c') {
                            command.type = 'b';
                        }

                        token.o += command.type.toLowerCase() + ' ';

                        if (command.x != null && command.y != null) {
                            token.o += round(command.x * scale) + ' ' + round(command.y * scale) + ' ';
                        }

                        if (command.x1 != null && command.y1 != null) {
                            token.o += round(command.x1 * scale) + ' ' + round(command.y1 * scale) + ' ';
                        }

                        if (command.x2 != null && command.y2 != null) {
                            token.o += round(command.x2 * scale) + ' ' + round(command.y2 * scale) + ' ';
                        }

                    });

                    glyphs.set(String.fromCharCode(glyph.unicode), token);
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
            var paths = new Array<Array<Dynamic>>();
            var path:Array<Dynamic>;

            commands.forEach(function(c) {
                if (c.type.toLowerCase() == 'm') {
                    path = [c];
                    paths.push(path);
                } else if (c.type.toLowerCase() != 'z') {
                    path.push(c);
                }
            });

            var reversed = new Array<Dynamic>();

            paths.forEach(function(p) {
                var result = {
                    type: 'm',
                    x: p[p.length - 1].x,
                    y: p[p.length - 1].y
                };

                reversed.push(result);

                for (i in p.length - 1...1... - 1) {
                    var command = p[i];
                    var result = { type: command.type };

                    if (command.x2 != null && command.y2 != null) {
                        result.x1 = command.x2;
                        result.y1 = command.y2;
                        result.x2 = command.x1;
                        result.y2 = command.y1;
                    } else if (command.x1 != null && command.y1 != null) {
                        result.x1 = command.x1;
                        result.y1 = command.y1;
                    }

                    result.x = p[i - 1].x;
                    result.y = p[i - 1].y;
                    reversed.push(result);
                }
            });

            return reversed;
        }

        return convert(Opentype.parse(arraybuffer), this.reversed);
    }
}