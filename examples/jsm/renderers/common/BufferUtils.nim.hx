import GPU_CHUNK_BYTES from './Constants.hx';

function getFloatLength(floatLength:Int):Int {
  // ensure chunk size alignment (STD140 layout)
  return floatLength + ( (GPU_CHUNK_BYTES - (floatLength % GPU_CHUNK_BYTES)) % GPU_CHUNK_BYTES );
}

function getVectorLength(count:Int, vectorLength:Int = 4):Int {
  const strideLength = getStrideLength(vectorLength);
  const floatLength = strideLength * count;
  return getFloatLength(floatLength);
}

function getStrideLength(vectorLength:Int):Int {
  const strideLength = 4;
  return vectorLength + ( (strideLength - (vectorLength % strideLength)) % strideLength );
}

export {
  getFloatLength,
  getVectorLength,
  getStrideLength
};