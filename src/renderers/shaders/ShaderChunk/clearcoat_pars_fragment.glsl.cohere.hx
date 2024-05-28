import openfl.display.DisplayObject;
import openfl.display.BitmapData;
import openfl.display.Shader;

class MyShader extends Shader {
	public function new() {
		super();
		init();
	}

	override public function init() {
		// Define the shader code
		vertexCode = null;
		fragmentCode =
			#if js-cpp
			'precision mediump float;' +
			#end
			'
			#ifdef USE_CLEARCOATMAP

				uniform sampler2D clearcoatMap;

			#endif

			#ifdef USE_CLEARCOAT_NORMALMAP

				uniform sampler2D clearcoatNormalMap;
				uniform vec2 clearcoatNormalScale;

			#endif

			#ifdef USE_CLEARCOAT_ROUGHNESSMAP

				uniform sampler2D clearcoatRoughnessMap;

			#endif
			';
	}
}