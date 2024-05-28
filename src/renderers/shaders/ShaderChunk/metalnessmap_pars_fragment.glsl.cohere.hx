package openfl._internal.renderer.opengl.shaders;

class MetalnessMapShader {
	public static var code:String = '#ifdef USE_METALNESSMAP' + '\n\t' +
		'uniform sampler2D metalnessMap;' + '\n' +
		'#endif';
}