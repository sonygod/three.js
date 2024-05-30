package three.js.examples.jsm.shaders;

class HalftoneShader {

    static var name:String = 'HalftoneShader';

    static var uniforms:Map<String, Dynamic> = {
        'tDiffuse': { value: null },
        'shape': { value: 1 },
        'radius': { value: 4 },
        'rotateR': { value: Math.PI / 12 * 1 },
        'rotateG': { value: Math.PI / 12 * 2 },
        'rotateB': { value: Math.PI / 12 * 3 },
        'scatter': { value: 0 },
        'width': { value: 1 },
        'height': { value: 1 },
        'blending': { value: 1 },
        'blendingMode': { value: 1 },
        'greyscale': { value: false },
        'disable': { value: false }
    };

    static var vertexShader:String = `
        varying vec2 vUV;

        void main() {
            vUV = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }`;

    static var fragmentShader:String = `
        #define SQRT2_MINUS_ONE 0.41421356
        #define SQRT2_HALF_MINUS_ONE 0.20710678
        #define PI2 6.28318531
        #define SHAPE_DOT 1
        #define SHAPE_ELLIPSE 2
        #define SHAPE_LINE 3
        #define SHAPE_SQUARE 4
        #define BLENDING_LINEAR 1
        #define BLENDING_MULTIPLY 2
        #define BLENDING_ADD 3
        #define BLENDING_LIGHTER 4
        #define BLENDING_DARKER 5
        uniform sampler2D tDiffuse;
        uniform float radius;
        uniform float rotateR;
        uniform float rotateG;
        uniform float rotateB;
        uniform float scatter;
        uniform float width;
        uniform float height;
        uniform int shape;
        uniform bool disable;
        uniform float blending;
        uniform int blendingMode;
        varying vec2 vUV;
        uniform bool greyscale;
        const int samples = 8;

        // ... rest of the code ...
    `;
}