class AttributeType {
  public static var VERTEX:Int = 1;
  public static var INDEX:Int = 2;
  public static var STORAGE:Int = 4;
}

// size of a chunk in bytes (STD140 layout)
const GPU_CHUNK_BYTES:Int = 16;

// @TODO: Move to src/constants.hx
const BlendColorFactor:Int = 211;
const OneMinusBlendColorFactor:Int = 212;