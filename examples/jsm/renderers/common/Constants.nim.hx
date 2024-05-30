package three.examples.jsm.renderers.common;

@:enum abstract AttributeType(Int) from Int {
	var VERTEX = 1;
	var INDEX = 2;
	var STORAGE = 4;
}

@:const public var GPU_CHUNK_BYTES = 16;

@:const public var BlendColorFactor = 211;
@:const public var OneMinusBlendColorFactor = 212;