import haxe.io.Bytes;

class Constants {
	static var GPU_CHUNK_BYTES = 16;
}

class ShaderUtils {
	public static function getFloatLength(floatLength:Int):Int {
		// ensure chunk size alignment (STD140 layout)
		return floatLength + ((Constants.GPU_CHUNK_BYTES - (floatLength % Constants.GPU_CHUNK_BYTES)) % Constants.GPU_CHUNK_BYTES);
	}

	public static function getVectorLength(count:Int, vectorLength:Int = 4):Int {
		var strideLength = getStrideLength(vectorLength);
		var floatLength = strideLength * count;
		return getFloatLength(floatLength);
	}

	public static function getStrideLength(vectorLength:Int):Int {
		var strideLength = 4;
		return vectorLength + ((strideLength - (vectorLength % strideLength)) % strideLength);
	}
}