package three.shader;

import three.textures.DataTexture;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.utils.MagicSquareNoise;

class GTAOShader {
    public var name(default, null):String = 'GTAOShader';

    public var defines:Dynamic = {
        PERSPECTIVE_CAMERA: 1,
        SAMPLES: 16,
        NORMAL_VECTOR_TYPE: 1,
        DEPTH_SWIZZLING: 'x',
        SCREEN_SPACE_RADIUS: 0,
        SCREEN_SPACE_RADIUS_SCALE: 100.0,
        SCENE_CLIP_BOX: 0,
    };

    public var uniforms:Dynamic = {
        tNormal: { value: null },
        tDepth: { value: null },
        tNoise: { value: null },
        resolution: { value: new Vector2() },
        cameraNear: { value: null },
        cameraFar: { value: null },
        cameraProjectionMatrix: { value: new Matrix4() },
        cameraProjectionMatrixInverse: { value: new Matrix4() },
        cameraWorldMatrix: { value: new Matrix4() },
        radius: { value: 0.25 },
        distanceExponent: { value: 1. },
        thickness: { value: 1. },
        distanceFallOff: { value: 1. },
        scale: { value: 1. },
        sceneBoxMin: { value: new Vector3( - 1, - 1, - 1 ) },
        sceneBoxMax: { value: new Vector3( 1, 1, 1 ) },
    };

    public var vertexShader:String = '
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }';

    public var fragmentShader:String = '
        varying vec2 vUv;
        uniform highp sampler2D tNormal;
        uniform highp sampler2D tDepth;
        uniform sampler2D tNoise;
        uniform vec2 resolution;
        uniform float cameraNear;
        uniform float cameraFar;
        uniform mat4 cameraProjectionMatrix;
        uniform mat4 cameraProjectionMatrixInverse;
        uniform mat4 cameraWorldMatrix;
        uniform float radius;
        uniform float distanceExponent;
        uniform float thickness;
        uniform float distanceFallOff;
        uniform float scale;
        #if SCENE_CLIP_BOX == 1
            uniform vec3 sceneBoxMin;
            uniform vec3 sceneBoxMax;
        #endif

        #include <common>
        #include <packing>

        #ifndef FRAGMENT_OUTPUT
        #define FRAGMENT_OUTPUT vec4(vec3(ao), 1.)
        #endif

        // Rest of the shader code...
    ';
}

class GTAODepthShader {
    public var name(default, null):String = 'GTAODepthShader';

    public var defines:Dynamic = {
        PERSPECTIVE_CAMERA: 1
    };

    public var uniforms:Dynamic = {
        tDepth: { value: null },
        cameraNear: { value: null },
        cameraFar: { value: null },
    };

    public var vertexShader:String = '
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }';

    public var fragmentShader:String = '
        uniform sampler2D tDepth;
        uniform float cameraNear;
        uniform float cameraFar;
        varying vec2 vUv;

        #include <packing>

        float getLinearDepth( const in vec2 screenPosition ) {
            #if PERSPECTIVE_CAMERA == 1
                float fragCoordZ = texture2D( tDepth, screenPosition ).x;
                float viewZ = perspectiveDepthToViewZ( fragCoordZ, cameraNear, cameraFar );
                return viewZToOrthographicDepth( viewZ, cameraNear, cameraFar );
            #else
                return texture2D( tDepth, screenPosition ).x;
            #endif
        }

        void main() {
            float depth = getLinearDepth( vUv );
            gl_FragColor = vec4( vec3( 1.0 - depth ), 1.0 );
        }';
}

class GTAOBlendShader {
    public var name(default, null):String = 'GTAOBlendShader';

    public var uniforms:Dynamic = {
        tDiffuse: { value: null },
        intensity: { value: 1.0 }
    };

    public var vertexShader:String = '
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }';

    public var fragmentShader:String = '
        uniform float intensity;
        uniform sampler2D tDiffuse;
        varying vec2 vUv;

        void main() {
            vec4 texel = texture2D( tDiffuse, vUv );
            gl_FragColor = vec4(mix(vec3(1.), texel.rgb, intensity), texel.a);
        }';
}

class MagicSquareNoise {
    public static function generateMagicSquareNoise(size:Int = 5):DataTexture {
        // Magic square noise generation code...
    }

    public static function generateMagicSquare(size:Int):Array<Int> {
        // Magic square generation code...
    }
}