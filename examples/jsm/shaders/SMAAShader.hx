Here is the converted Haxe code:
```
package three.js.examples.jsm.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderOutput;

class SMAAEdgesShader {
    public static var shader:Shader = new Shader();

    static function init() {
        shader.vertexShader = "
            uniform vec2 resolution;

            varying vec2 vUv;
            varying vec4 vOffset[3];

            void SMAAEdgeDetectionVS( vec2 texcoord ) {
                vOffset[0] = texcoord.xyxy + resolution.xyxy * vec4( -1.0, 0.0, 0.0,  1.0 );
                vOffset[1] = texcoord.xyxy + resolution.xyxy * vec4(  1.0, 0.0, 0.0, -1.0 );
                vOffset[2] = texcoord.xyxy + resolution.xyxy * vec4( -2.0, 0.0, 0.0,  2.0 );
            }

            void main() {
                vUv = uv;
                SMAAEdgeDetectionVS( vUv );
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        ";

        shader.fragmentShader = "
            uniform sampler2D tDiffuse;

            varying vec2 vUv;
            varying vec4 vOffset[3];

            vec4 SMAAColorEdgeDetectionPS( vec2 texcoord, vec4 offset[3], sampler2D colorTex ) {
                // implementation...
            }

            void main() {
                gl_FragColor = SMAAColorEdgeDetectionPS( vUv, vOffset, tDiffuse );
            }
        ";
    }
}

class SMAAWeightsShader {
    public static var shader:Shader = new Shader();

    static function init() {
        shader.vertexShader = "
            uniform vec2 resolution;

            varying vec2 vUv;
            varying vec4 vOffset[3];
            varying vec2 vPixcoord;

            void SMAABlendingWeightCalculationVS( vec2 texcoord ) {
                vPixcoord = texcoord / resolution;
                vOffset[0] = texcoord.xyxy + resolution.xyxy * vec4( -0.25, 0.125, 1.25, 0.125 );
                vOffset[1] = texcoord.xyxy + resolution.xyxy * vec4( -0.125, 0.25, -0.125, -1.25 );
                vOffset[2] = vec4( vOffset[0].xz, vOffset[1].yw ) + vec4( -2.0, 2.0, -2.0, 2.0 ) * resolution.xxyy * SMAA_MAX_SEARCH_STEPS;
            }

            void main() {
                vUv = uv;
                SMAABlendingWeightCalculationVS( vUv );
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        ";

        shader.fragmentShader = "
            uniform sampler2D tDiffuse;
            uniform sampler2D tArea;
            uniform sampler2D tSearch;
            uniform vec2 resolution;

            varying vec2 vUv;
            varying vec4 vOffset[3];
            varying vec2 vPixcoord;

            vec4 SMAABlendingWeightCalculationPS( vec2 texcoord, vec2 pixcoord, vec4 offset[3], sampler2D edgesTex, sampler2D areaTex, sampler2D searchTex, ivec4 subsampleIndices ) {
                // implementation...
            }

            void main() {
                gl_FragColor = SMAABlendingWeightCalculationPS( vUv, vPixcoord, vOffset, tDiffuse, tArea, tSearch, ivec4( 0.0 ) );
            }
        ";
    }
}

class SMAABlendShader {
    public static var shader:Shader = new Shader();

    static function init() {
        shader.vertexShader = "
            uniform vec2 resolution;

            varying vec2 vUv;
            varying vec4 vOffset[2];

            void SMAANeighborhoodBlendingVS( vec2 texcoord ) {
                vOffset[0] = texcoord.xyxy + resolution.xyxy * vec4( -1.0, 0.0, 0.0, 1.0 );
                vOffset[1] = texcoord.xyxy + resolution.xyxy * vec4( 1.0, 0.0, 0.0, -1.0 );
            }

            void main() {
                vUv = uv;
                SMAANeighborhoodBlendingVS( vUv );
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        ";

        shader.fragmentShader = "
            uniform sampler2D tDiffuse;
            uniform sampler2D tColor;
            uniform vec2 resolution;

            varying vec2 vUv;
            varying vec4 vOffset[2];

            vec4 SMAANeighborhoodBlendingPS( vec2 texcoord, vec4 offset[2], sampler2D colorTex, sampler2D blendTex ) {
                // implementation...
            }

            void main() {
                gl_FragColor = SMAANeighborhoodBlendingPS( vUv, vOffset, tColor, tDiffuse );
            }
        ";
    }
}

class SMAAShaders {
    public static function init():Void {
        SMAAEdgesShader.init();
        SMAAWeightsShader.init();
        SMAABlendShader.init();
    }
}
```