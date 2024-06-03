// Define a constant
var GPU_CHUNK_BYTES:Int = 16; // replace 16 with the actual value

function getFloatLength(floatLength:Int):Int {
    // ensure chunk size alignment (STD140 layout)
    return floatLength + ((GPU_CHUNK_BYTES - (floatLength % GPU_CHUNK_BYTES)) % GPU_CHUNK_BYTES);
}

function getVectorLength(count:Int, vectorLength:Int = 4):Int {
    var strideLength:Int = getStrideLength(vectorLength);
    var floatLength:Int = strideLength * count;
    return getFloatLength(floatLength);
}

function getStrideLength(vectorLength:Int):Int {
    var strideLength:Int = 4;
    return vectorLength + ((strideLength - (vectorLength % strideLength)) % strideLength);
}