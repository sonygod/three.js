package three.js.examples.jsm.shaders;

import vec2.Vector2;

class SMAAEdgesShader {
    public var name:String = 'SMAAEdgesShader';
    public var defines:Map<String, String> = [
        'SMAA_THRESHOLD' => '0.1'
    ];

    public var uniforms:Map<String, Dynamic> = [
        'tDiffuse' => { value: null },
        'resolution' => { value: new Vector2(1 / 1024, 1 / 512) }
    ];

    public var vertexShader:String = '
        uniform vec2 resolution;

        varying vec2 vUv;
        varying vec4 vOffset[3];

        void SMAAEdgeDetectionVS(vec2 texcoord) {
            vOffset[0] = texcoord.xyxy + resolution.xyxy * vec4(-1.0, 0.0, 0.0, 1.0);
            vOffset[1] = texcoord.xyxy + resolution.xyxy * vec4(1.0, 0.0, 0.0, -1.0);
            vOffset[2] = texcoord.xyxy + resolution.xyxy * vec4(-2.0, 0.0, 0.0, 2.0);
        }

        void main() {
            vUv = uv;
            SMAAEdgeDetectionVS(vUv);
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    ';

    public var fragmentShader:String = '
        uniform sampler2D tDiffuse;

        varying vec2 vUv;
        varying vec4 vOffset[3];

        vec4 SMAAColorEdgeDetectionPS(vec2 texcoord, vec4 offset[3], sampler2D colorTex) {
            // ...
        }

        void main() {
            gl_FragColor = SMAAColorEdgeDetectionPS(vUv, vOffset, tDiffuse);
        }
    ';
}

class SMAAWeightsShader {
    public var name:String = 'SMAAWeightsShader';
    public var defines:Map<String, String> = [
        'SMAA_MAX_SEARCH_STEPS' => '8',
        'SMAA_AREATEX_MAX_DISTANCE' => '16',
        'SMAA_AREATEX_PIXEL_SIZE' => '(1.0 / vec2(160.0, 560.0))',
        'SMAA_AREATEX_SUBTEX_SIZE' => '(1.0 / 7.0)'
    ];

    public var uniforms:Map<String, Dynamic> = [
        'tDiffuse' => { value: null },
        'tArea' => { value: null },
        'tSearch' => { value: null },
        'resolution' => { value: new Vector2(1 / 1024, 1 / 512) }
    ];

    public var vertexShader:String = '
        uniform vec2 resolution;

        varying vec2 vUv;
        varying vec4 vOffset[3];
        varying vec2 vPixcoord;

        void SMAABlendingWeightCalculationVS(vec2 texcoord) {
            vPixcoord = texcoord / resolution;
            vOffset[0] = texcoord.xyxy + resolution.xyxy * vec4(-0.25, 0.125, 1.25, 0.125);
            vOffset[1] = texcoord.xyxy + resolution.xyxy * vec4(-0.125, 0.25, -0.125, -1.25);
            vOffset[2] = vec4(vOffset[0].xz, vOffset[1].yw) + vec4(-2.0, 2.0, -2.0, 2.0) * resolution.xxyy * float(SMAA_MAX_SEARCH_STEPS);
        }

        void main() {
            vUv = uv;
            SMAABlendingWeightCalculationVS(vUv);
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    ';

    public var fragmentShader:String = '
        #define SMAASampleLevelZeroOffset(tex, coord, offset) texture2D(tex, coord + float(offset) * resolution, 0.0)

        uniform sampler2D tDiffuse;
        uniform sampler2D tArea;
        uniform sampler2D tSearch;
        uniform vec2 resolution;

        varying vec2 vUv;
        varying vec4 vOffset[3];
        varying vec2 vPixcoord;

        // ...
    ';
}

class SMAABlendShader {
    public var name:String = 'SMAABlendShader';
    public var uniforms:Map<String, Dynamic> = [
        'tDiffuse' => { value: null },
        'tColor' => { value: null },
        'resolution' => { value: new Vector2(1 / 1024, 1 / 512) }
    ];

    public var vertexShader:String = '
        uniform vec2 resolution;

        varying vec2 vUv;
        varying vec4 vOffset[2];

        void SMAANeighborhoodBlendingVS(vec2 texcoord) {
            vOffset[0] = texcoord.xyxy + resolution.xyxy * vec4(-1.0, 0.0, 0.0, 1.0);
            vOffset[1] = texcoord.xyxy + resolution.xyxy * vec4(1.0, 0.0, 0.0, -1.0);
        }

        void main() {
            vUv = uv;
            SMAANeighborhoodBlendingVS(vUv);
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    ';

    public var fragmentShader:String = '
        uniform sampler2D tDiffuse;
        uniform sampler2D tColor;
        uniform vec2 resolution;

        varying vec2 vUv;
        varying vec4 vOffset[2];

        vec4 SMAANeighborhoodBlendingPS(vec2 texcoord, vec4 offset[2], sampler2D colorTex, sampler2D blendTex) {
            // ...
        }

        void main() {
            gl_FragColor = SMAANeighborhoodBlendingPS(vUv, vOffset, tColor, tDiffuse);
        }
    ';
}