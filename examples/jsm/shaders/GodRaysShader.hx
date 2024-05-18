package three.js.examples.jsm.shaders;

import three.Color;
import three.Vector3;

/**
 * God-rays (crepuscular rays)
 *
 * Similar implementation to the one used by Crytek for CryEngine 2 [Sousa2008].
 * Blurs a mask generated from the depth map along radial lines emanating from the light
 * source. The blur repeatedly applies a blur filter of increasing support but constant
 * sample count to produce a blur filter with large support.
 *
 * My implementation performs 3 passes, similar to the implementation from Sousa. I found
 * just 6 samples per pass produced acceptable results. The blur is applied three times,
 * with decreasing filter support. The result is equivalent to a single pass with
 * 6*6*6 = 216 samples.
 *
 * References:
 *
 * Sousa2008 - Crysis Next Gen Effects, GDC2008, http://www.crytek.com/sites/default/files/GDC08_SousaT_CrysisEffects.ppt
 */

class GodRaysDepthMaskShader {
    public static var NAME:String = "GodRaysDepthMaskShader";

    public static var uniforms:Dynamic = {
        tInput: { value: null }
    };

    public static var vertexShader:String = "
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }";

    public static var fragmentShader:String = "
        varying vec2 vUv;

        uniform sampler2D tInput;

        void main() {
            gl_FragColor = vec4( 1.0 ) - texture2D( tInput, vUv );
        }";
}


/**
 * The god-ray generation shader.
 *
 * First pass:
 *
 * The depth map is blurred along radial lines towards the "sun". The
 * output is written to a temporary render target (I used a 1/4 sized
 * target).
 *
 * Pass two & three:
 *
 * The results of the previous pass are re-blurred, each time with a
 * decreased distance between samples.
 */

class GodRaysGenerateShader {
    public static var NAME:String = "GodRaysGenerateShader";

    public static var uniforms:Dynamic = {
        tInput: { value: null },
        fStepSize: { value: 1.0 },
        vSunPositionScreenSpace: { value: new Vector3() }
    };

    public static var vertexShader:String = "
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }";

    public static var fragmentShader:String = "
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
            //  - see http://code.google.com/p/chromium/issues/detail?id=153105

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

            gl_FragColor = vec4( col/TAPS_PER_PASS );
            gl_FragColor.a = 1.0;
        }";
}


/**
 * Additively applies god rays from texture tGodRays to a background (tColors).
 * fGodRayIntensity attenuates the god rays.
 */

class GodRaysCombineShader {
    public static var NAME:String = "GodRaysCombineShader";

    public static var uniforms:Dynamic = {
        tColors: { value: null },
        tGodRays: { value: null },
        fGodRayIntensity: { value: 0.69 }
    };

    public static var vertexShader:String = "
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }";

    public static var fragmentShader:String = "
        varying vec2 vUv;

        uniform sampler2D tColors;
        uniform sampler2D tGodRays;

        uniform float fGodRayIntensity;

        void main() {
            gl_FragColor = texture2D( tColors, vUv ) + fGodRayIntensity * vec4( 1.0 - texture2D( tGodRays, vUv ).r );
            gl_FragColor.a = 1.0;
        }";
}


/**
 * A dodgy sun/sky shader. Makes a bright spot at the sun location. Would be
 * cheaper/faster/simpler to implement this as a simple sun sprite.
 */

class GodRaysFakeSunShader {
    public static var NAME:String = "GodRaysFakeSunShader";

    public static var uniforms:Dynamic = {
        vSunPositionScreenSpace: { value: new Vector3() },
        fAspect: { value: 1.0 },
        sunColor: { value: new Color(0xffee00) },
        bgColor: { value: new Color(0x000000) }
    };

    public static var vertexShader:String = "
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }";

    public static var fragmentShader:String = "
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
        }";
}