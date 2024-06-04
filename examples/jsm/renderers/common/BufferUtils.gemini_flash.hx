import Constants;

function getFloatLength(floatLength:Int):Int {

	// ensure chunk size alignment (STD140 layout)

	return floatLength + ( ( Constants.GPU_CHUNK_BYTES - ( floatLength % Constants.GPU_CHUNK_BYTES ) ) % Constants.GPU_CHUNK_BYTES );

}

function getVectorLength(count:Int, vectorLength:Int = 4):Int {

	const strideLength = getStrideLength(vectorLength);

	const floatLength = strideLength * count;

	return getFloatLength(floatLength);

}

function getStrideLength(vectorLength:Int):Int {

	const strideLength = 4;

	return vectorLength + ( ( strideLength - ( vectorLength % strideLength ) ) % strideLength );

}

class Utils {
	public static function getFloatLength(floatLength:Int):Int {
		return getFloatLength(floatLength);
	}

	public static function getVectorLength(count:Int, vectorLength:Int = 4):Int {
		return getVectorLength(count, vectorLength);
	}

	public static function getStrideLength(vectorLength:Int):Int {
		return getStrideLength(vectorLength);
	}
}