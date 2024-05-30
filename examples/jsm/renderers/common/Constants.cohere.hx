package;

@:enum(Int)
enum AttributeType {
	VERTEX = 1,
	INDEX = 2,
	STORAGE = 4
}

// size of a chunk in bytes (STD140 layout)

var GPU_CHUNK_BYTES = 16;

// @TODO: Move to src/constants.hx

var BlendColorFactor = 211;
var OneMinusBlendColorFactor = 212;