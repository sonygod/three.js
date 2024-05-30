package three.shaderlib.ShaderChunk;

class DisplacementMapParsVertex {
    public function new() {}

    public static var shader:String = "
#ifdef USE_DISPLACEMENTMAP

	uniform sampler2D displacementMap;
	uniform float displacementScale;
	uniform float displacementBias;

#endif
";
}