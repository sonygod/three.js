import js.Browser;
import js.lib.ArrayBuffer;
import js.lib.Uint8Array;
import js.lib.Float32Array;
import js.lib.Float64Array;
import js.lib.Int16Array;
import js.lib.Int32Array;
import js.lib.Uint16Array;
import js.lib.Uint32Array;

class LogLuvLoader {

    public var type: Int;

    public function new(manager: Dynamic) {
        this.type = HalfFloatType;
    }

    public function parse(buffer: ArrayBuffer): Dynamic {
        var ifds = UTIF.decode(buffer);
        UTIF.decodeImage(buffer, ifds[0]);
        var rgba = UTIF.toRGBA(ifds[0], this.type);

        return {
            width: ifds[0].width,
            height: ifds[0].height,
            data: rgba,
            format: RGBAFormat,
            type: this.type,
            flipY: true
        };
    }

    public function setDataType(value: Int): LogLuvLoader {
        this.type = value;
        return this;
    }

}

class UTIF {

    public static function decode(buff: ArrayBuffer, prm: Dynamic = null): Array<Dynamic> {
        if (prm == null) prm = { parseMN: true, debug: false };
        var data = new Uint8Array(buff);
        var offset = 0;

        var id = Binary.readASCII(data, offset, 2);
        offset += 2;
        var bin = id == 'II' ? BinLE : BinBE;
        bin.readUshort(data, offset);
        offset += 2;

        var ifdo = bin.readUint(data, offset);
        var ifds = [];
        while (true) {
            var cnt = bin.readUshort(data, ifdo);
            var typ = bin.readUshort(data, ifdo + 4);
            if (cnt != 0) {
                if (typ < 1 || 13 < typ) {
                    Browser.console.log('error in TIFF');
                    break;
                }
            }

            readIFD(bin, data, ifdo, ifds, 0, prm);

            ifdo = bin.readUint(data, ifdo + 2 + cnt * 12);
            if (ifdo == 0) break;
        }

        return ifds;
    }

    public static function decodeImage(buff: ArrayBuffer, img: Dynamic, ifds: Dynamic = null) {
        if (img.data) return;
        var data = new Uint8Array(buff);
        var id = Binary.readASCII(data, 0, 2);

        if (img['t256'] == null) return;
        img.isLE = id == 'II';
        img.width = img['t256'][0];
        img.height = img['t257'][0];

        var cmpr = img['t259'] ? img['t259'][0] : 1;
        var fo = img['t266'] ? img['t266'][0] : 1;
        if (img['t284'] && img['t284'][0] == 2) Browser.console.log('PlanarConfiguration 2 should not be used!');
        if (cmpr == 7 && img['t258'] && img['t258'].length > 3) img['t258'] = img['t258'].slice(0, 3);

        var bipp;
        if (img['t258']) bipp = Math.min(32, img['t258'][0]) * img['t258'].length;
        else bipp = img['t277'] ? img['t277'][0] : 1;

        if (cmpr == 1 && img['t279'] != null && img['t278'] && img['t262'][0] == 32803) {
            bipp = Math.round((img['t279'][0] * 8) / (img.width * img['t278'][0]));
        }

        var bipl = Math.ceil(img.width * bipp / 8) * 8;
        var soff = img['t273'];
        if (soff == null) soff = img['t324'];
        var bcnt = img['t279'];
        if (cmpr == 1 && soff.length == 1) bcnt = [img.height * (bipl >>> 3)];
        if (bcnt == null) bcnt = img['t325'];

        var bytes = new Uint8Array(img.height * (bipl >>> 3));
        var bilen = 0;

        if (img['t322'] != null) {
            var tw = img['t322'][0];
            var th = img['t323'][0];
            var tx = Math.floor((img.width + tw - 1) / tw);
            var ty = Math.floor((img.height + th - 1) / th);
            var tbuff = new Uint8Array(Math.ceil(tw * th * bipp / 8) | 0);
            for (var y = 0; y < ty; y++) {
                for (var x = 0; x < tx; x++) {
                    var i = y * tx + x;
                    for (var j = 0; j < tbuff.length; j++) tbuff[j] = 0;
                    decode._decompress(img, ifds, data, soff[i], bcnt[i], cmpr, tbuff, 0, fo);
                    if (cmpr == 6) bytes = tbuff;
                    else copyTile(tbuff, Math.ceil(tw * bipp / 8) | 0, th, bytes, Math.ceil(img.width * bipp / 8) | 0, img.height, Math.ceil(x * tw * bipp / 8) | 0, y * th);
                }
            }
            bilen = bytes.length * 8;
        } else {
            var rps = img['t278'] ? img['t278'][0] : img.height;
            rps = Math.min(rps, img.height);
            for (var i = 0; i < soff.length; i++) {
                decode._decompress(img, ifds, data, soff[i], bcnt[i], cmpr, bytes, Math.ceil(bilen / 8) | 0, fo);
                bilen += bipl * rps;
            }
            bilen = Math.min(bilen, bytes.length * 8);
        }

        img.data = new Uint8Array(bytes.buffer, 0, Math.ceil(bilen / 8) | 0);
    }

    public static function toRGBA(out: Dynamic, type: Int): Dynamic {
        var w = out.width;
        var h = out.height;
        var area = w * h;
        var data = out.data;

        var img: Dynamic;

        switch (type) {
            case HalfFloatType:
                img = new Uint16Array(area * 4);
                break;
            case FloatType:
                img = new Float32Array(area * 4);
                break;
            default:
                throw 'THREE.LogLuvLoader: Unsupported texture data type: ' + type;
        }

        var intp = out['t262'] ? out['t262'][0] : 2;
        var bps = out['t258'] ? Math.min(32, out['t258'][0]) : 1;

        if (out['t262'] == null && bps == 1) intp = 0;

        if (intp == 32845) {
            for (var y = 0; y < h; y++) {
                for (var x = 0; x < w; x++) {
                    var si = (y * w + x) * 6;
                    var qi = (y * w + x) * 4;
                    var L = (data[si + 1] << 8) | data[si];

                    L = Math.pow(2, (L + 0.5) / 256 - 64);
                    var u = (data[si + 3] + 0.5) / 410;
                    var v = (data[si + 5] + 0.5) / 410;

                    var sX = (9 * u) / (6 * u - 16 * v + 12);
                    var sY = (4 * v) / (6 * u - 16 * v + 12);
                    var bY = L;

                    var X = (sX * bY) / sY;
                    var Y = bY;
                    var Z = (1 - sX - sY) * bY / sY;

                    var r = 2.690 * X - 1.276 * Y - 0.414 * Z;
                    var g = -1.022 * X + 1.978 * Y + 0.044 * Z;
                    var b = 0.061 * X - 0.224 * Y + 1.163 * Z;

                    if (type === HalfFloatType) {
                        img[qi] = DataUtils.toHalfFloat(Math.min(r, 65504));
                        img[qi + 1] = DataUtils.toHalfFloat(Math.min(g, 65504));
                        img[qi + 2] = DataUtils.toHalfFloat(Math.min(b, 65504));
                        img[qi + 3] = DataUtils.toHalfFloat(1);
                    } else {
                        img[qi] = r;
                        img[qi + 1] = g;
                        img[qi + 2] = b;
                        img[qi + 3] = 1;
                    }
                }
            }
        } else {
            throw 'THREE.LogLuvLoader: Unsupported Photometric interpretation: ' + intp;
        }

        return img;
    }
}

class Binary {
    public static function readASCII(buff: Uint8Array, p: Int, l: Int): String {
        var s = '';
        for (var i = 0; i < l; i++) s += String.fromCharCode(buff[p + i]);
        return s;
    }
}

class BinBE {
    public static function readUshort(buff: Uint8Array, p: Int): Int {
        return (buff[p] << 8) | buff[p + 1];
    }

    public static function readUint(buff: Uint8Array, p: Int): Int {
        var a = ui8;
        a[0] = buff[p + 3];
        a[1] = buff[p + 2];
        a[2] = buff[p + 1];
        a[3] = buff[p + 0];
        return ui32[0];
    }

    public static var ui8: Uint8Array = new Uint8Array(8);
    public static var i16: Int16Array = new Int16Array(ui8.buffer);
    public static var i32: Int32Array = new Int32Array(ui8.buffer);
    public static var ui32: Uint32Array = new Uint32Array(ui8.buffer);
    public static var fl32: Float32Array = new Float32Array(ui8.buffer);
    public static var fl64: Float64Array = new Float64Array(ui8.buffer);
}

class BinLE {
    public static function readUshort(buff: Uint8Array, p: Int): Int {
        return (buff[p + 1] << 8) | buff[p];
    }

    public static function readUint(buff: Uint8Array, p: Int): Int {
        var a = ui8;
        a[0] = buff[p + 0];
        a[1] = buff[p + 1];
        a[2] = buff[p + 2];
        a[3] = buff[p + 3];
        return ui32[0];
    }

    public static var ui8: Uint8Array = new Uint8Array(8);
    public static var i16: Int16Array = new Int16Array(ui8.buffer);
    public static var i32: Int32Array = new Int32Array(ui8.buffer);
    public static var ui32: Uint32Array = new Uint32Array(ui8.buffer);
    public static var fl32: Float32Array = new Float32Array(ui8.buffer);
    public static var fl64: Float64Array = new Float64Array(ui8.buffer);
}

function readIFD(bin: Dynamic, data: Uint8Array, offset: Int, ifds: Array<Dynamic>, depth: Int, prm: Dynamic) {
    // Implementation of readIFD function goes here
}

function decode._decompress(img: Dynamic, ifds: Dynamic, data: Uint8Array, off: Int, len: Int, cmpr: Int, tgt: Uint8Array, toff: Int) {
    // Implementation of decode._decompress function goes here
}

function decode._decodeLogLuv32(img: Dynamic, data: Uint8Array, off: Int, len: Int, tgt: Uint8Array, toff: Int) {
    // Implementation of decode._decodeLogLuv32 function goes here
}

function copyTile(tb: Uint8Array, tw: Int, th: Int, b: Uint8Array, w: Int, h: Int, xoff: Int, yoff: Int) {
    // Implementation of copyTile function goes here
}

class DataUtils {
    public static function toHalfFloat(value: Float): Int {
        // Implementation of toHalfFloat function goes here
    }
}