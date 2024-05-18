package three.shader;

import three.math.Vector2;

class BokehShader {
	static public var NAME:String = 'BokehShader';

	static public var uniforms = {
		textureWidth: { value: 1.0 },
		textureHeight: { value: 1.0 },
		focalDepth: { value: 1.0 },
		focalLength: { value: 24.0 },
		fstop: { value: 0.9 },
		tColor: { value: null },
		tDepth: { value: null },
		maxblur: { value: 1.0 },
		showFocus: { value: 0 },
		manualdof: { value: 0 },
		vignetting: { value: 0 },
		depthblur: { value: 0 },
		threshold: { value: 0.5 },
		gain: { value: 2.0 },
		bias: { value: 0.5 },
		fringe: { value: 0.7 },
		znear: { value: 0.1 },
		zfar: { value: 100.0 },
		noise: { value: 1 },
		dithering: { value: 0.0001 },
		pentagon: { value: 0 },
		shaderFocus: { value: 1 },
		focusCoords: { value: new Vector2() }
	};

	static public var vertexShader = 
	"
	varying vec2 vUv;

	void main() {
		vUv = uv;
		gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
	}
	";

	static public var fragmentShader = 
	"
	#include <common>

	varying vec2 vUv;

	uniform sampler2D tColor;
	uniform sampler2D tDepth;
	uniform float textureWidth;
	uniform float textureHeight;

	uniform float focalDepth;
	uniform float focalLength;
	uniform float fstop;

	uniform bool showFocus;
	uniform bool manualdof;
	uniform bool vignetting;
	uniform bool depthblur;

	uniform float maxblur;
	uniform float threshold;
	uniform float gain;
	uniform float bias;
	uniform float fringe;

	uniform float znear;
	uniform float zfar;

	uniform bool noise;
	uniform float dithering;
	uniform bool pentagon;
	uniform bool shaderFocus;
	uniform vec2 focusCoords;

	// ... (rest of the shader code remains the same)

	";

	public function new() {}
}

class BokehDepthShader {
	static public var NAME:String = 'BokehDepthShader';

	static public var uniforms = {
		mNear: { value: 1.0 },
		mFar: { value: 1000.0 }
	};

	static public var vertexShader = 
	"
	varying float vViewZDepth;

	void main() {
		#include <begin_vertex>
		#include <project_vertex>
		vViewZDepth = - mvPosition.z;
	}
	";

	static public var fragmentShader = 
	"
	uniform float mNear;
	uniform float mFar;

	varying float vViewZDepth;

	void main() {
		float color = 1.0 - smoothstep( mNear, mFar, vViewZDepth );
		gl_FragColor = vec4( vec3( color ), 1.0 );
	}
	";
}