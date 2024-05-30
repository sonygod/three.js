package three.examples.jsm.exporters;

import three.FloatType;
import three.HalfFloatType;
import three.RGBAFormat;
import three.DataUtils;
import fflate.zlibSync;

class EXRExporter {

    public function new() {
        // constructor
    }

    public function parse(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic):Array<Int> {
        // implementation
    }

    private function supportedRTT(renderTarget:Dynamic):Void {
        // implementation
    }

    private function supportedDT(texture:Dynamic):Void {
        // implementation
    }

    private function buildInfoRTT(renderTarget:Dynamic, options:Dynamic = null):Dynamic {
        // implementation
    }

    private function buildInfoDT(texture:Dynamic, options:Dynamic = null):Dynamic {
        // implementation
    }

    private function getPixelData(renderer:Dynamic, rtt:Dynamic, info:Dynamic):Dynamic {
        // implementation
    }

    private function reorganizeDataBuffer(inBuffer:Dynamic, info:Dynamic):Dynamic {
        // implementation
    }

    private function compressData(inBuffer:Dynamic, info:Dynamic):Dynamic {
        // implementation
    }

    private function compressNONE(data:Dynamic):Dynamic {
        // implementation
    }

    private function compressZIP(data:Dynamic, tmpBuffer:Dynamic):Dynamic {
        // implementation
    }

    private function fillHeader(outBuffer:Array<Int>, chunks:Dynamic, info:Dynamic):Void {
        // implementation
    }

    private function fillData(chunks:Dynamic, info:Dynamic):Array<Int> {
        // implementation
    }

    private function decodeLinear(dec:Dynamic, r:Float, g:Float, b:Float, a:Float):Void {
        // implementation
    }

    private function setUint8(dv:Dynamic, value:Int, offset:Dynamic):Void {
        // implementation
    }

    private function setUint32(dv:Dynamic, value:Int, offset:Dynamic):Void {
        // implementation
    }

    private function setFloat16(dv:Dynamic, value:Float, offset:Dynamic):Void {
        // implementation
    }

    private function setFloat32(dv:Dynamic, value:Float, offset:Dynamic):Void {
        // implementation
    }

    private function setUint64(dv:Dynamic, value:Int, offset:Dynamic):Void {
        // implementation
    }

    private function setString(dv:Dynamic, string:String, offset:Dynamic):Void {
        // implementation
    }

    private function decodeFloat16(binary:Int):Float {
        // implementation
    }

    private function getFloat16(arr:Dynamic, i:Int):Float {
        // implementation
    }

    private function getFloat32(arr:Dynamic, i:Int):Float {
        // implementation
    }
}

class NoCompression {
    public static var NO_COMPRESSION:Int = 0;
}

class ZipCompression {
    public static var ZIP_COMPRESSION:Int = 3;
}

class ZipsCompression {
    public static var ZIPS_COMPRESSION:Int = 2;
}