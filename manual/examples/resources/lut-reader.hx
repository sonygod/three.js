package three.js.manual.examples.resources;

class LutReader {
    static function splitOnSpaceHandleQuotesWithEscapes(str:String, splits:String = ' \t\n\r'):Array<String> {
        var strings:Array<String> = [];
        var quoteType:Null<String> = null;
        var escape:Bool = false;
        var s:Array<String> = [];
        for (i in 0...str.length) {
            var c:String = str.charAt(i);
            if (escape) {
                escape = false;
                s.push(c);
            } else {
                if (quoteType != null) { // we're inside quotes
                    if (c == quoteType) {
                        quoteType = null;
                        strings.push(s.join(''));
                        s = [];
                    } else if (c == '\\') {
                        escape = true;
                    } else {
                        s.push(c);
                    }
                } else { // we're not in quotes
                    if (splits.indexOf(c) >= 0) {
                        if (s.length > 0) {
                            strings.push(s.join(''));
                            s = [];
                        }
                    } else if (c == '"' || c == '\'') {
                        if (s.length > 0) { // its in the middle of a word
                            s.push(c);
                        } else {
                            quoteType = c;
                        }
                    } else {
                        s.push(c);
                    }
                }
            }
        }
        if (s.length > 0 || strings.length == 0) {
            strings.push(s.join(''));
        }
        return strings;
    }

    static var startWhitespaceRE:EReg = ~/^\s+/;
    static var intRE:EReg = ~/^\d+$/;
    static function isNum(s:String):Bool {
        return intRE.match(s);
    }

    static var quotesRE:EReg = ~/^".*"$/;
    static function trimQuotes(s:String):String {
        return quotesRE.match(s) ? s.substring(1, s.length - 1) : s;
    }

    static function splitToNumbers(s:String):Array<Float> {
        return s.split(' ').map(parseFloat);
    }

    static function parseCSP(str:String):Lut {
        var data:Array<Float> = [];
        var lut:Lut = {
            name: 'unknown',
            type: '1D',
            size: 0,
            data: data,
            min: [0, 0, 0],
            max: [1, 1, 1],
        };
        var lines:Array<String> = str.split('\n').map(StringTools.trim).filter(function(s:String):Bool {
            return s.length > 0 && !startWhitespaceRE.match(s);
        });
        // check header
        lut.type = lines[1];
        if (lines[0] != 'CSPLUTV100' || (lut.type != '1D' && lut.type != '3D')) {
            throw new Error('not CSP');
        }
        // skip meta (read to first number)
        var lineNdx:Int = 2;
        while (lineNdx < lines.length) {
            var line:String = lines[lineNdx++];
            if (isNum(line)) {
                break;
            }
            if (line.startsWith('TITLE ')) {
                lut.name = trimQuotes(line.substring(6).trim());
            }
        }
        // read ranges
        for (i in 0...3) {
            lineNdx++;
            var input:Array<Float> = splitToNumbers(lines[lineNdx++]);
            var output:Array<Float> = splitToNumbers(lines[lineNdx++]);
            if (input.length != 2 || output.length != 2 || input[0] != 0 || input[1] != 1 || output[0] != 0 || output[1] != 1) {
                throw new Error('mapped ranges not support');
            }
        }
        // read sizes
        var sizes:Array<Float> = splitToNumbers(lines[lineNdx++]);
        if (sizes[0] != sizes[1] || sizes[0] != sizes[2]) {
            throw new Error('only cubic sizes supported');
        }
        lut.size = sizes[0];
        // read data
        while (lineNdx < lines.length) {
            var parts:Array<Float> = splitToNumbers(lines[lineNdx++]);
            if (parts.length != 3) {
                throw new Error('malformed file');
            }
            data.push(parts[0]);
            data.push(parts[1]);
            data.push(parts[2]);
        }
        return lut;
    }

    static function parseCUBE(str:String):Lut {
        var data:Array<Float> = [];
        var lut:Lut = {
            name: 'unknown',
            type: '1D',
            size: 0,
            data: data,
            min: [0, 0, 0],
            max: [1, 1, 1],
        };
        var lines:Array<String> = str.split('\n');
        for (line in lines) {
            var hashNdx:Int = line.indexOf('#');
            var line:String = hashNdx >= 0 ? line.substring(0, hashNdx) : line;
            var parts:Array<String> = splitOnSpaceHandleQuotesWithEscapes(line);
            switch (parts[0].toUpperCase()) {
                case 'TITLE':
                    lut.name = parts[1];
                    break;
                case 'LUT_1D_SIZE':
                    lut.size = Std.parseInt(parts[1]);
                    lut.type = '1D';
                    break;
                case 'LUT_3D_SIZE':
                    lut.size = Std.parseInt(parts[1]);
                    lut.type = '3D';
                    break;
                case 'DOMAIN_MIN':
                    lut.min = parts.slice(1).map(parseFloat);
                    break;
                case 'DOMAIN_MAX':
                    lut.max = parts.slice(1).map(parseFloat);
                    break;
                default:
                    if (parts.length == 3) {
                        data.push(parseFloat(parts[0]));
                        data.push(parseFloat(parts[1]));
                        data.push(parseFloat(parts[2]));
                    }
                    break;
            }
        }
        if (!lut.size) {
            lut.size = lut.type == '1D' ? (data.length / 3) : Math.cbrt(data.length / 3);
        }
        return lut;
    }

    static function lerp(a:Float, b:Float, t:Float):Float {
        return a + (b - a) * t;
    }

    static function lut1Dto3D(lut:Lut):Lut {
        var src:Array<Float> = lut.data;
        if (src.length / 3 != lut.size) {
            src = [];
            for (i in 0...Std.int(lut.size)) {
                var u:Float = i / lut.size * lut.data.length;
                var i0:Int = Std.int(u) * 3;
                var i1:Int = i0 + 3;
                var t:Float = u % 1;
                src.push(lerp(lut.data[i0 + 0], lut.data[i1 + 0], t));
                src.push(lerp(lut.data[i0 + 1], lut.data[i1 + 1], t));
                src.push(lerp(lut.data[i0 + 2], lut.data[i1 + 2], t));
            }
        }
        var data:Array<Float> = [];
        for (i in 0...lut.size * lut.size) {
            data.push(src[i % lut.size]);
            data.push(src[(i % lut.size) + 1]);
            data.push(src[(i % lut.size) + 2]);
        }
        return { ...lut, data: data };
    }

    static var parsers:Map<String, Lut->Lut> = [
        'cube' => parseCUBE,
        'csp' => parseCSP,
    ];

    static function parse(str:String, format:String = 'cube'):Lut {
        var parser:Lut->Lut = parsers.get(format.toLowerCase());
        if (parser == null) {
            throw new Error('no parser for format: $format');
        }
        return parser(str);
    }

    static function lutTo2D3Drgba8(lut:Lut):Lut {
        if (lut.type == '1D') {
            lut = lut1Dto3D(lut);
        }
        var min:Array<Float> = lut.min;
        var max:Array<Float> = lut.max;
        var range:Array<Float> = [max[0] - min[0], max[1] - min[1], max[2] - min[2]];
        var src:Array<Float> = lut.data;
        var size:Int = lut.size;
        var data:Array<Int> = new Array<Int>(size * size * size * 4);
        var srcOffset:Int->Int->Int->Int = function(offX:Int, offY:Int, offZ:Int) {
            return (offX + offY * size + offZ * size * size) * 3;
        };
        var dOffset:Int->Int->Int->Int = function(offX:Int, offY:Int, offZ:Int) {
            return (offX + offY * size + offZ * size * size) * 4;
        };
        for (dz in 0...size) {
            for (dy in 0...size) {
                for (dx in 0...size) {
                    var sx:Int = dx;
                    var sy:Int = dz;
                    var sz:Int = dy;
                    var sOff:Int = srcOffset(sx, sy, sz);
                    var dOff:Int = dOffset(dx, dy, dz);
                    data[dOff + 0] = Std.int((src[sOff + 0] - min[0]) / range[0] * 255);
                    data[dOff + 1] = Std.int((src[sOff + 1] - min[1]) / range[1] * 255);
                    data[dOff + 2] = Std.int((src[sOff + 2] - min[2]) / range[2] * 255);
                    data[dOff + 3] = 255;
                }
            }
        }
        return { ...lut, data: data };
    }
}

typedef Lut = {
    var name:String;
    var type:String;
    var size:Int;
    var data:Array<Float>;
    var min:Array<Float>;
    var max:Array<Float>;
}