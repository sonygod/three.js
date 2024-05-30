import DataUtils;
import DataTextureLoader;
import FloatType;
import HalfFloatType;
import RGBAFormat;

class LogLuvLoader extends DataTextureLoader {
    public var type:Int;

    public function new(manager:Dynamic) {
        super(manager);
        type = HalfFloatType;
    }

    public function parse(buffer:Bytes):Dynamic {
        var ifds = UTIF.decode(buffer);
        UTIF.decodeImage(buffer, ifds[0]);
        var rgba = UTIF.toRGBA(ifds[0], type);

        return {
            width: Std.int(ifds[0].width),
            height: Std.int(ifds[0].height),
            data: rgba,
            format: RGBAFormat,
            type: type,
            flipY: true
        };
    }

    public function setDataType(value:Int):LogLuvLoader {
        type = value;
        return this;
    }
}

class UTIF {
    public static function decode(buff:Bytes, prm:Dynamic = { parseMN: true, debug: false }):Array<Dynamic> {
        if (prm == null) prm = { parseMN: true, debug: false }; // read MakerNote, debug
        var data = buff.getData();
        var offset:Int = 0;

        var id = _binBE.readASCII(data, offset, 2);
        offset += 2;
        var bin = id == 'II' ? _binLE : _binBE;
        offset += bin.readUshort(data, offset);

        var ifdo = bin.readUint(data, offset);
        var ifds:Array<Dynamic> = [];
        while (true) {
            var cnt = bin.readUshort(data, ifdo);
            var typ = bin.readUshort(data, ifdo + 4);
            if (cnt != 0 && (typ < 1 || 13 < typ)) {
                trace('error in TIFF');
                break;
            }

            _readIFD(bin, data, ifdo, ifds, 0, prm);

            ifdo = bin.readUint(data, ifdo + 2 + cnt * 12);
            if (ifdo == 0) break;
        }

        return ifds;
    }

    public static function decodeImage(buff:Bytes, img:Dynamic, ifds:Array<Dynamic>) {
        if (img.data != null) return;
        var data = buff.getData();
        var id = _binBE.readASCII(data, 0, 2);

        if (img['t256'] == null) return; // No width => probably not an image
        img.isLE = id == 'II';
        img.width = img['t256'][0];
        img.height = img['t257'][0];

        var cmpr = img['t259'] ? img['t259'][0] : 1;
        var fo = img['t266'] ? img['t266'][0] : 1;
        if (img['t284'] && img['t284'][0] == 2) trace('PlanarConfiguration 2 should not be used!');
        if (cmpr == 7 && img['t258'] && img['t258'].length > 3) img['t258'] = img['t258'].slice(0, 3);

        var bipp:Float; // bits per pixel
        if (img['t258']) bipp = Math.min(32, img['t258'][0]) * img['t258'].length;
        else bipp = (img['t277'] ? img['t277'][0] : 1);
        // Some .NEF files have t258==14, even though they use 16 bits per pixel
        if (cmpr == 1 && img['t279'] != null && img['t278'] && img['t262'][0] == 32803) {
            bipp = Math.round((img['t279'][0] * 8) / (img.width * img['t278'][0]));
        }

        var bipl = Std.int(Math.ceil(img.width * bipp / 8) * 8);
        var soff = img['t273'];
        if (soff == null) soff = img['t324'];
        var bcnt = img['t279'];
        if (cmpr == 1 && soff.length == 1) bcnt = [img.height * (bipl >> 3)];
        if (bcnt == null) bcnt = img['t325'];
        //bcnt[0] = Math.min(bcnt[0], data.length);  // Hasselblad, "RAW_HASSELBLAD_H3D39II.3FR"
        var bytes = new Bytes(img.height * (bipl >> 3));
        var bilen:Int;

        if (img['t322'] != null) {
            var tw = img['t322'][0];
            var th = img['t323'][0];
            var tx = Std.int(Math.floor((img.width + tw - 1) / tw));
            var ty = Std.int(Math.floor((img.height + th - 1) / th));
            var tbuff = new Bytes(Std.int(Math.ceil(tw * th * bipp / 8)));
            var i:Int, j:Int, x:Int, y:Int;
            for (y = 0; y < ty; y++) {
                for (x = 0; x < tx; x++) {
                    var i = y * tx + x;
                    for (j = 0; j < tbuff.length; j++) tbuff.set(j, 0);
                    decode._decompress(img, ifds, data, soff[i], bcnt[i], cmpr, tbuff, 0, fo);
                    // Might be required for 7 too. Need to check
                    if (cmpr == 6) bytes = tbuff;
                    else _copyTile(tbuff, Std.int(Math.ceil(tw * bipp / 8)), th, bytes, Std.int(Math.ceil(img.width * bipp / 8)), img.height, Std.int(Math.ceil(x * tw * bipp / 8)), y * th);
                }
            }
            bilen = bytes.length * 8;
        } else {
            var rps = img['t278'] ? img['t278'][0] : img.height;
            rps = Math.min(rps, img.height);
            var i:Int;
            for (i = 0; i < soff.length; i++) {
                decode._decompress(img, ifds, data, soff[i], bcnt[i], cmpr, bytes, Std.int(Math.ceil(bilen / 8)), fo);
                bilen += bipl * rps;
            }

            bilen = Math.min(bilen, bytes.length * 8);
        }

        img.data = bytes.slice(0, Std.int(Math.ceil(bilen / 8)));
    }

    public static function toRGBA(out:Dynamic, type:Int):Dynamic {
        var w = out.width;
        var h = out.height;
        var area = w * h;
        var data = out.data;

        var img:Dynamic;

        switch (type) {
            case HalfFloatType:
                img = new Bytes(area * 4);
                break;
            case FloatType:
                img = new Bytes(area * 4);
                break;
            default:
                throw new Error('LogLuvLoader: Unsupported texture data type: ' + type);
        }

        var intp = out['t262'] ? out['t262'][0] : 2;
        var bps = out['t258'] ? Math.min(32, out['t258'][0]) : 1;

        if (out['t262'] == null && bps == 1) intp = 0;

        if (intp == 32845) {
            var x:Int, y:Int, si:Int, qi:Int, L:Int;
            for (y = 0; y < h; y++) {
                for (x = 0; x < w; x++) {
                    si = (y * w + x) * 6;
                    qi = (y * w + x) * 4;
                    L = (data.get(si + 1) << 8) | data.get(si);

                    L = Math.pow(2, (L + 0.5) / 256 - 64);
                    var u = (data.get(si + 3) + 0.5) / 410;
                    var v = (data.get(si + 5) + 0.5) / 410;

                    // Luv to xyY
                    var sX = (9 * u) / (6 * u - 16 * v + 12);
                    var sY = (4 * v) / (6 * u - 16 * v + 12);
                    var bY = L;

                    // xyY to XYZ
                    var X = (sX * bY) / sY;
                    var Y = bY;
                    var Z = (1 - sX - sY) * bY / sY;

                    // XYZ to linear RGB
                    var r = 2.690 * X - 1.276 * Y - 0.414 * Z;
                    var g = -1.022 * X + 1.978 * Y + 0.044 * Z;
                    var b = 0.061 * X - 0.224 * Y + 1.163 * Z;

                    if (type == HalfFloatType) {
                        img.set(qi, DataUtils.toHalfFloat(Math.min(r, 65504)));
                        img.set(qi + 1, DataUtils.toHalfFloat(Math.min(g, 65504)));
                        img.set(qi + 2, DataUtils.toHalfFloat(Math.min(b, 65504)));
                        img.set(qi + 3, DataUtils.toHalfFloat(1));
                    } else {
                        img.set(qi, r);
                        img.set(qi + 1, g);
                        img.set(qi + 2, b);
                        img.set(qi + 3, 1);
                    }
                }
            }
        } else {
            throw new Error('LogLuvLoader: Unsupported Photometric interpretation: ' + intp);
        }

        return img;
    }

    public static var tags:Dynamic;

    public static var _types:Dynamic = {
        basic: {
            main: [0, 0, 0, 0, 4, 3, 3, 3, 3, 3, 0, 0, 3, 0, 0, 0, 3, 0, 0, 2, 2, 2, 2, 4, 3, 0, 0, 3, 4, 4, 3, 3, 5, 5, 3, 2, 5, 5, 0, 0, 0, 0, 4, 4, 0, 0, 3, 3, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 3, 5, 5, 3, 0, 3, 3, 4, 4, 4, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 3, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0