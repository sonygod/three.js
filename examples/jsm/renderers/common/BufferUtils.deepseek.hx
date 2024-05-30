import Constants.GPU_CHUNK_BYTES;

function getFloatLength(floatLength:Float):Float {

	// ensure chunk size alignment (STD140 layout)

	return floatLength + ( ( GPU_CHUNK_BYTES - ( floatLength % GPU_CHUNK_BYTES ) ) % GPU_CHUNK_BYTES );

}

function getVectorLength(count:Int, vectorLength:Int = 4):Float {

	var strideLength:Int = getStrideLength(vectorLength);

	var floatLength:Float = strideLength * count;

	return getFloatLength(floatLength);

}

function getStrideLength(vectorLength:Int):Int {

	var strideLength:Int = 4;

	return vectorLength + ( ( strideLength - ( vectorLength % strideLength ) ) % strideLength );

}

class BufferUtils {

	static function getFloatLength(floatLength:Float):Float {
		return getFloatLength(floatLength);
	}

	static function getVectorLength(count:Int, vectorLength:Int = 4):Float {
		return getVectorLength(count, vectorLength);
	}

	static function getStrideLength(vectorLength:Int):Int {
		return getStrideLength(vectorLength);
	}

}