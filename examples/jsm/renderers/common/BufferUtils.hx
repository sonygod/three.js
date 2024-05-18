package three.js.examples.jsm.renderers.common;

import Constants;

class BufferUtils {
    static var GPU_CHUNK_BYTES:Int = Constants.GPU_CHUNK_BYTES;

    static function getFloatLength(floatLength:Int):Int {
        // ensure chunk size alignment (STD140 layout)
        return floatLength + ( (GPU_CHUNK_BYTES - (floatLength % GPU_CHUNK_BYTES)) % GPU_CHUNK_BYTES );
    }

    static function getVectorLength(count:Int, ?vectorLength:Int = 4):Int {
        var strideLength:Int = getStrideLength(vectorLength);
        var floatLength:Int = strideLength * count;
        return getFloatLength(floatLength);
    }

    static function getStrideLength(vectorLength:Int):Int {
        var strideLength:Int = 4;
        return vectorLength + ( (strideLength - (vectorLength % strideLength)) % strideLength );
    }
}