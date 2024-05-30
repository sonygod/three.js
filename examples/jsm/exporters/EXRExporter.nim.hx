import three.examples.jsm.exporters.EXRExporter;
import three.examples.jsm.exporters.EXRExporter.NO_COMPRESSION;
import three.examples.jsm.exporters.EXRExporter.ZIP_COMPRESSION;
import three.examples.jsm.exporters.EXRExporter.ZIPS_COMPRESSION;

class Main {
    static function main() {
        var exporter = new EXRExporter();
        // Use the exporter as needed
    }
}

// File: three/examples/jsm/exporters/EXRExporter.hx
package three.examples.jsm.exporters;

import three.FloatType;
import three.HalfFloatType;
import three.RGBAFormat;
import three.DataUtils;
import fflate.fflate;

class EXRExporter {
    public static var NO_COMPRESSION:Int = 0;
    public static var ZIP_COMPRESSION:Int = 3;
    public static var ZIPS_COMPRESSION:Int = 2;

    public function new() {}

    public function parse(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic):Dynamic {
        if (! (arg1.isWebGLRenderer || arg1.isDataTexture) ) {
            throw Error("EXRExporter.parse: Unsupported first parameter, expected instance of WebGLRenderer or DataTexture.");
        } else if (arg1.isWebGLRenderer) {
            var renderer = arg1, renderTarget = arg2, options = arg3;
            supportedRTT(renderTarget);
            var info = buildInfoRTT(renderTarget, options),
                dataBuffer = getPixelData(renderer, renderTarget, info),
                rawContentBuffer = reorganizeDataBuffer(dataBuffer, info),
                chunks = compressData(rawContentBuffer, info);
            return fillData(chunks, info);
        } else if (arg1.isDataTexture) {
            var texture = arg1, options = arg2;
            supportedDT(texture);
            var info = buildInfoDT(texture, options),
                dataBuffer = texture.image.data,
                rawContentBuffer = reorganizeDataBuffer(dataBuffer, info),
                chunks = compressData(rawContentBuffer, info);
            return fillData(chunks, info);
        }
    }

    // ... rest of the functions ...
}