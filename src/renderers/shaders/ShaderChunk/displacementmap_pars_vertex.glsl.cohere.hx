package openfl._internal;

class ShaderCode {
    public static var displacement:String = '''
		#ifdef USE_DISPLACEMENTMAP

			uniform sampler2D displacementMap;
			uniform float displacementScale;
			uniform float displacementBias;

		#endif
		''';
}