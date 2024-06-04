import three.Color;
import three.Vector3;
import three.ShaderMaterial;
import three.UniformsUtils;

class GodRaysDepthMaskShader {

	public static var name:String = "GodRaysDepthMaskShader";

	public static var uniforms:Dynamic = {
		tInput: { value: null }
	};

	public static var vertexShader:String = /*glsl*/`
		varying vec2 vUv;

		void main() {

		 vUv = uv;
		 gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

	 }`;

	public static var fragmentShader:String = /*glsl*/`

		varying vec2 vUv;

		uniform sampler2D tInput;

		void main() {

			gl_FragColor = vec4( 1.0 ) - texture2D( tInput, vUv );

		}`;

}

class GodRaysGenerateShader {

	public static var name:String = "GodRaysGenerateShader";

	public static var uniforms:Dynamic = {
		tInput: { value: null },
		fStepSize: { value: 1.0 },
		vSunPositionScreenSpace: { value: new Vector3() }
	};

	public static var vertexShader:String = /*glsl*/`

		varying vec2 vUv;

		void main() {

		 vUv = uv;
		 gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

	 }`;

	public static var fragmentShader:String = /*glsl*/`

		#define TAPS_PER_PASS 6.0

		varying vec2 vUv;

		uniform sampler2D tInput;

		uniform vec3 vSunPositionScreenSpace;
		uniform float fStepSize; // filter step size

		void main() {

		// delta from current pixel to "sun" position

			vec2 delta = vSunPositionScreenSpace.xy - vUv;
			float dist = length( delta );

		// Step vector (uv space)

			vec2 stepv = fStepSize * delta / dist;

		// Number of iterations between pixel and sun

			float iters = dist/fStepSize;

			vec2 uv = vUv.xy;
			float col = 0.0;

		// This breaks ANGLE in Chrome 22
		//	- see http://code.google.com/p/chromium/issues/detail?id=153105

		/*
		// Unrolling didnt do much on my hardware (ATI Mobility Radeon 3450),
		// so i've just left the loop

		"for ( float i = 0.0; i < TAPS_PER_PASS; i += 1.0 ) {",

		// Accumulate samples, making sure we dont walk past the light source.

		// The check for uv.y < 1 would not be necessary with "border" UV wrap
		// mode, with a black border color. I don't think this is currently
		// exposed by three.js. As a result there might be artifacts when the
		// sun is to the left, right or bottom of screen as these cases are
		// not specifically handled.

		"	col += ( i <= iters && uv.y < 1.0 ? texture2D( tInput, uv ).r : 0.0 );",
		"	uv += stepv;",

		"}",
		*/

		// Unrolling loop manually makes it work in ANGLE

			float f = min( 1.0, max( vSunPositionScreenSpace.z / 1000.0, 0.0 ) ); // used to fade out godrays

			if ( 0.0 <= iters && uv.y < 1.0 ) col += texture2D( tInput, uv ).r * f;
			uv += stepv;

			if ( 1.0 <= iters && uv.y < 1.0 ) col += texture2D( tInput, uv ).r * f;
			uv += stepv;

			if ( 2.0 <= iters && uv.y < 1.0 ) col += texture2D( tInput, uv ).r * f;
			uv += stepv;

			if ( 3.0 <= iters && uv.y < 1.0 ) col += texture2D( tInput, uv ).r * f;
			uv += stepv;

			if ( 4.0 <= iters && uv.y < 1.0 ) col += texture2D( tInput, uv ).r * f;
			uv += stepv;

			if ( 5.0 <= iters && uv.y < 1.0 ) col += texture2D( tInput, uv ).r * f;
			uv += stepv;

		// Should technically be dividing by 'iters but 'TAPS_PER_PASS' smooths out
		// objectionable artifacts, in particular near the sun position. The side
		// effect is that the result is darker than it should be around the sun, as
		// TAPS_PER_PASS is greater than the number of samples actually accumulated.
		// When the result is inverted (in the shader 'godrays_combine this produces
		// a slight bright spot at the position of the sun, even when it is occluded.

			gl_FragColor = vec4( col/TAPS_PER_PASS );
			gl_FragColor.a = 1.0;

		}`

}

class GodRaysCombineShader {

	public static var name:String = "GodRaysCombineShader";

	public static var uniforms:Dynamic = {
		tColors: { value: null },
		tGodRays: { value: null },
		fGodRayIntensity: { value: 0.69 }
	};

	public static var vertexShader:String = /*glsl*/`

		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`;

	public static var fragmentShader:String = /*glsl*/`

		varying vec2 vUv;

		uniform sampler2D tColors;
		uniform sampler2D tGodRays;

		uniform float fGodRayIntensity;

		void main() {

		// Since THREE.MeshDepthMaterial renders foreground objects white and background
		// objects black, the god-rays will be white streaks. Therefore value is inverted
		// before being combined with tColors

			gl_FragColor = texture2D( tColors, vUv ) + fGodRayIntensity * vec4( 1.0 - texture2D( tGodRays, vUv ).r );
			gl_FragColor.a = 1.0;

		}`

}

class GodRaysFakeSunShader {

	public static var name:String = "GodRaysFakeSunShader";

	public static var uniforms:Dynamic = {
		vSunPositionScreenSpace: { value: new Vector3() },
		fAspect: { value: 1.0 },
		sunColor: { value: new Color( 0xffee00 ) },
		bgColor: { value: new Color( 0x000000 ) }
	};

	public static var vertexShader:String = /*glsl*/`

		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`;

	public static var fragmentShader:String = /*glsl*/`

		varying vec2 vUv;

		uniform vec3 vSunPositionScreenSpace;
		uniform float fAspect;

		uniform vec3 sunColor;
		uniform vec3 bgColor;

		void main() {

			vec2 diff = vUv - vSunPositionScreenSpace.xy;

		// Correct for aspect ratio

			diff.x *= fAspect;

			float prop = clamp( length( diff ) / 0.5, 0.0, 1.0 );
			prop = 0.35 * pow( 1.0 - prop, 3.0 );

			gl_FragColor.xyz = ( vSunPositionScreenSpace.z > 0.0 ) ? mix( sunColor, bgColor, 1.0 - prop ) : bgColor;
			gl_FragColor.w = 1.0;

		}`

}

class GodRaysShaders {

	public static function getDepthMaskShader():ShaderMaterial {
		return new ShaderMaterial({
			uniforms: UniformsUtils.clone( GodRaysDepthMaskShader.uniforms ),
			vertexShader: GodRaysDepthMaskShader.vertexShader,
			fragmentShader: GodRaysDepthMaskShader.fragmentShader
		});
	}

	public static function getGenerateShader():ShaderMaterial {
		return new ShaderMaterial({
			uniforms: UniformsUtils.clone( GodRaysGenerateShader.uniforms ),
			vertexShader: GodRaysGenerateShader.vertexShader,
			fragmentShader: GodRaysGenerateShader.fragmentShader
		});
	}

	public static function getCombineShader():ShaderMaterial {
		return new ShaderMaterial({
			uniforms: UniformsUtils.clone( GodRaysCombineShader.uniforms ),
			vertexShader: GodRaysCombineShader.vertexShader,
			fragmentShader: GodRaysCombineShader.fragmentShader
		});
	}

	public static function getFakeSunShader():ShaderMaterial {
		return new ShaderMaterial({
			uniforms: UniformsUtils.clone( GodRaysFakeSunShader.uniforms ),
			vertexShader: GodRaysFakeSunShader.vertexShader,
			fragmentShader: GodRaysFakeSunShader.fragmentShader
		});
	}
}