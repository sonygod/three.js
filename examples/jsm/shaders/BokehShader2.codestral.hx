import js.three.Vector2;

class BokehShader {
    static var name:String = "BokehShader";

    static var uniforms:Dynamic = {
        'textureWidth': { value: 1.0 },
        'textureHeight': { value: 1.0 },
        'focalDepth': { value: 1.0 },
        'focalLength': { value: 24.0 },
        'fstop': { value: 0.9 },
        'tColor': { value: null },
        'tDepth': { value: null },
        'maxblur': { value: 1.0 },
        'showFocus': { value: 0 },
        'manualdof': { value: 0 },
        'vignetting': { value: 0 },
        'depthblur': { value: 0 },
        'threshold': { value: 0.5 },
        'gain': { value: 2.0 },
        'bias': { value: 0.5 },
        'fringe': { value: 0.7 },
        'znear': { value: 0.1 },
        'zfar': { value: 100 },
        'noise': { value: 1 },
        'dithering': { value: 0.0001 },
        'pentagon': { value: 0 },
        'shaderFocus': { value: 1 },
        'focusCoords': { value: new Vector2() }
    };

    static var vertexShader:String = `
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }`;

    static var fragmentShader:String = `
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
        uniform float znear;
        uniform float zfar;
        const int samples = SAMPLES;
        const int rings = RINGS;
        const int maxringsamples = rings * samples;
        uniform bool manualdof;
        float ndofstart = 1.0;
        float ndofdist = 2.0;
        float fdofstart = 1.0;
        float fdofdist = 3.0;
        float CoC = 0.03;
        uniform bool vignetting;
        float vignout = 1.3;
        float vignin = 0.0;
        float vignfade = 22.0;
        uniform bool shaderFocus;
        uniform vec2 focusCoords;
        uniform float maxblur;
        uniform float threshold;
        uniform float gain;
        uniform float bias;
        uniform float fringe;
        uniform bool noise;
        uniform float dithering;
        uniform bool depthblur;
        float dbsize = 1.25;
        uniform bool pentagon;
        float feather = 0.4;
        // rest of the shader code...
    `;
}

class BokehDepthShader {
    static var name:String = "BokehDepthShader";

    static var uniforms:Dynamic = {
        'mNear': { value: 1.0 },
        'mFar': { value: 1000.0 }
    };

    static var vertexShader:String = `
        varying float vViewZDepth;
        void main() {
            #include <begin_vertex>
            #include <project_vertex>
            vViewZDepth = - mvPosition.z;
        }`;

    static var fragmentShader:String = `
        uniform float mNear;
        uniform float mFar;
        varying float vViewZDepth;
        void main() {
            float color = 1.0 - smoothstep( mNear, mFar, vViewZDepth );
            gl_FragColor = vec4( vec3( color ), 1.0 );
        }`;
}