package three.examples.jsm.shaders;

import three.DataTexture;
import three.Matrix4;
import three.RepeatWrapping;
import three.Vector2;
import three.Vector3;

class GTAOShader {

    static var name:String = 'GTAOShader';

    static var defines:Map<String, Int> = {
        PERSPECTIVE_CAMERA: 1,
        SAMPLES: 16,
        NORMAL_VECTOR_TYPE: 1,
        DEPTH_SWIZZLING: 'x',
        SCREEN_SPACE_RADIUS: 0,
        SCREEN_SPACE_RADIUS_SCALE: 100.0,
        SCENE_CLIP_BOX: 0,
    };

    static var uniforms:Map<String, Dynamic> = {
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

    static var vertexShader:String = `
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }`;

    static var fragmentShader:String = `
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

        //#include <common>
        //#include <packing>

        #ifndef FRAGMENT_OUTPUT
        #define FRAGMENT_OUTPUT vec4(vec3(ao), 1.)
        #endif

        // ... rest of the shader code ...
    `;

}

// ... rest of the code ...