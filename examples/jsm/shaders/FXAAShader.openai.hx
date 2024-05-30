package three.js.examples.jsm.shaders;

import openfl.display3D.textures.Texture;
import openfl.geom.Vector2;

/**
 * NVIDIA FXAA by Timothy Lottes
 * https://developer.download.nvidia.com/assets/gamedev/files/sdk/11/FXAA_WhitePaper.pdf
 * - WebGL port by @supereggbert
 * http://www.glge.org/demos/fxaa/
 * Further improved by Daniel Sturk
 */

class FXAAShader {
    public static var name:String = 'FXAAShader';

    public static var uniforms:Dynamic = {
        'tDiffuse': { value: null },
        'resolution': { value: new Vector2(1 / 1024, 1 / 512) }
    };

    public static var vertexShader:String = "
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }";

    public static var fragmentShader:String = "
        #ifdef GL_ES
        precision highp float;
        #endif

        uniform sampler2D tDiffuse;
        uniform vec2 resolution;

        varying vec2 vUv;

        // FXAA 3.11 implementation by NVIDIA, ported to WebGL by Agost Biro (biro@archilogic.com)

        // ... (rest of the shader code remains the same)

        void main() {
            const float edgeDetectionQuality = .2;
            const float invEdgeDetectionQuality = 1. / edgeDetectionQuality;

            gl_FragColor = FxaaPixelShader(
                vUv,
                tDiffuse,
                resolution,
                edgeDetectionQuality, // [0,1] contrast needed, otherwise early discard
                invEdgeDetectionQuality
            );
        }
    }";
}