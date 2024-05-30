package three.js.examples.jsm.renderers.common;

@:enum abstract AttributeType(Int) {
	var VERTEX = 1;
	var INDEX = 2;
	var STORAGE = 4;
}

class Constants {
	public static inline var GPU_CHUNK_BYTES:Int = 16;

	public static inline var BlendColorFactor:Int = 211;
	public static inline var OneMinusBlendColorFactor:Int = 212;
}