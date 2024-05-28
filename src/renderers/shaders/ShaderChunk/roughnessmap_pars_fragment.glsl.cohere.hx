package;

class ShaderCode {
	public static var code:String = '''
#ifdef USE_ROUGHNESSMAP

	uniform sampler2D roughnessMap;

#endif
	''';
}