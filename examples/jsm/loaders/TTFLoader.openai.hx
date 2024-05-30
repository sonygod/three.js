package three.js.loaders;

import three.js.loaders.Loader;
import three.js.loaders.FileLoader;
import js.lib.opentype.OpenType;

class TTFLoader extends Loader {
    var reversed:Bool;

    public function new(manager:Loader) {
        super(manager);
        reversed = false;
    }

    public function load(url:String, onLoad:(font:Json<TtfFont>) -> Void, onProgress:(itemsLoaded:Int, itemsTotal:Int) -> Void, onError:(error:Error) -> Void) {
        var fileLoader = new FileLoader(manager);
        fileLoader.setPath(path);
        fileLoader.setResponseType('arraybuffer');
        fileLoader.setRequestHeader(requestHeader);
        fileLoader.setWithCredentials(withCredentials);
        fileLoader.load(url, function(buffer:ArrayBuffer) {
            try {
                onLoad(parse(buffer));
            } catch (e:Error) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    function parse(buffer:ArrayBuffer):Json<TtfFont> {
        function convert(font:OpenType.Font, reversed:Bool):Json<TtfFont> {
            var round = Math.round;
            var glyphs:Map<String, Glyph> = new Map();
            var scale = (100000) / (font.unitsPerEm * 72);
            var glyphIndexMap = font.encoding.cmap.glyphIndexMap;
            var unicodes = [for (unicode in glyphIndexMap.keys()) unicode];

            for (unicode in unicodes) {
                var glyph = font.glyphs.glyphs[glyphIndexMap[unicode]];
                if (unicode != null) {
                    var token:Glyph = {
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

                        if (command.x != null && command.y != null) {
                            token.o += round(command.x * scale) + ' ' + round(command.y * scale) + ' ';
                        }

                        if (command.x1 != null && command.y1 != null) {
                            token.o += round(command.x1 * scale) + ' ' + round(command.y1 * scale) + ' ';
                        }

                        if (command.x2 != null && command.y2 != null) {
                            token.o += round(command.x2 * scale) + ' ' + round(command.y2 * scale) + ' ';
                        }
                    }

                    glyphs[unicode] = token;
                }
            }

            return {
                glyphs: [for (glyph in glyphs) glyph],
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
                originalFontInformation: font.tables.name
            };
        }

        function reverseCommands(commands:Array<OpenType.PathCommand>):Array<OpenType.PathCommand> {
            var paths:Array<Array<OpenType.PathCommand>> = [];
            var path:Array<OpenType.PathCommand>;

            for (command in commands) {
                if (command.type.toLowerCase() == 'm') {
                    path = [command];
                    paths.push(path);
                } else if (command.type.toLowerCase() != 'z') {
                    path.push(command);
                }
            }

            var reversed:Array<OpenType.PathCommand> = [];

            for (p in paths) {
                var result:OpenType.PathCommand = {
                    type: 'm',
                    x: p[p.length - 1].x,
                    y: p[p.length - 1].y
                };
                reversed.push(result);

                for (i in p.length - 1...0) {
                    var command = p[i];
                    result = { type: command.type };

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
            }

            return reversed;
        }

        return convert(opentype.OpenType.parse(buffer), this.reversed);
    }
}