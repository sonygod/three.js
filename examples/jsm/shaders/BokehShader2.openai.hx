package three.js.shaders;

import haxe.ds.Vector;

class BokehShader {
	public var name:String;

	public var uniforms:Dynamic<{
		textureWidth: { value: Float },
		textureHeight: { value: Float },
		focalDepth: { value: Float },
		focalLength: { value: Float },
		fstop: { value: Float },
		tColor: { value: null },
		tDepth: { value: null },
		maxblur: { value: Float },
		showFocus: { value: Int },
		manualdof: { value: Int },
		vignetting: { value: Int },
		depthblur: { value: Int },
		threshold: { value: Float },
		gain: { value: Float },
		bias: { value: Float },
		fringe: { value: Float },
		znear: { value: Float },
		zfar: { value: Float },
		noise: { value: Int },
		dithering: { value: Float },
		pentagon: { value: Int },
		shaderFocus: { value: Int },
		focusCoords: { value: Vector2 }
	}>;

	public var vertexShader:String;
	public var fragmentShader:String;

	public function new() {
		name = 'BokehShader';
		uniforms = {
			// ... (same as above)
		};

		vertexShader = /* vertex shader code */;
		fragmentShader = /* fragment shader code */;
	}
}

class BokehDepthShader {
	public var name:String;

	public var uniforms:Dynamic<{
		mNear: { value: Float },
		mFar: { value: Float }
	}>;

	public var vertexShader:String;
	public var fragmentShader:String;

	public function new() {
		name = 'BokehDepthShader';
		uniforms = {
			mNear: { value: 1.0 },
			mFar: { value: 1000.0 }
		};

		vertexShader = /* vertex shader code */;
		fragmentShader = /* fragment shader code */;
	}
}