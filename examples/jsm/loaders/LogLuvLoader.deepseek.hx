package three.examples.jsm.loaders;

import three.DataUtils;
import three.DataTextureLoader;
import three.FloatType;
import three.HalfFloatType;
import three.RGBAFormat;

class LogLuvLoader extends DataTextureLoader {

    public function new(manager:Dynamic) {
        super(manager);
        this.type = HalfFloatType;
    }

    public function parse(buffer:haxe.io.Bytes):Dynamic {
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

    public function setDataType(value:Dynamic):LogLuvLoader {
        this.type = value;
        return this;
    }
}

// from https://github.com/photopea/UTIF.js (MIT License)

class UTIF {
    public static function decode(buff:haxe.io.Bytes, prm:Dynamic = null):Array<Dynamic> {
        if (prm == null) prm = {parseMN: true, debug: false}; // read MakerNote, debug
        var data = new haxe.io.BytesInput(buff).getBytes();

        var id = UTIF._binBE.readASCII(data, 0, 2);
        var bin = id == 'II' ? UTIF._binLE : UTIF._binBE;
        bin.readUshort(data, 0);

        var ifdo = bin.readUint(data, 2);
        var ifds = [];
        while (true) {
            var cnt = bin.readUshort(data, ifdo);
            var typ = bin.readUshort(data, ifdo + 4);
            if (cnt != 0) {
                if (typ < 1 || 13 < typ) {
                    trace('error in TIFF');
                    break;
                }
            }

            UTIF._readIFD(bin, data, ifdo, ifds, 0, prm);

            ifdo = bin.readUint(data, ifdo + 2 + cnt * 12);
            if (ifdo == 0) break;
        }

        return ifds;
    }

    // ... rest of the UTIF class ...
}