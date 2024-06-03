import js.Browser.document;

class HalftoneShader {

    public static var name:String = 'HalftoneShader';

    public static var uniforms:Dynamic = {
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

    public static var vertexShader:String = "varying vec2 vUV; void main() { vUV = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }";

    public static var fragmentShader:String = "#define SQRT2_MINUS_ONE 0.41421356 #define SQRT2_HALF_MINUS_ONE 0.20710678 #define PI2 6.28318531 #define SHAPE_DOT 1 #define SHAPE_ELLIPSE 2 #define SHAPE_LINE 3 #define SHAPE_SQUARE 4 #define BLENDING_LINEAR 1 #define BLENDING_MULTIPLY 2 #define BLENDING_ADD 3 #define BLENDING_LIGHTER 4 #define BLENDING_DARKER 5 uniform sampler2D tDiffuse; uniform float radius; uniform float rotateR; uniform float rotateG; uniform float rotateB; uniform float scatter; uniform float width; uniform float height; uniform int shape; uniform bool disable; uniform float blending; uniform int blendingMode; varying vec2 vUV; uniform bool greyscale; const int samples = 8; float blend( float a, float b, float t ) { return a * ( 1.0 - t ) + b * t; } float hypot( float x, float y ) { return sqrt( x * x + y * y ); } float rand( vec2 seed ){ return fract( sin( dot( seed.xy, vec2( 12.9898, 78.233 ) ) ) * 43758.5453 ); } float distanceToDotRadius( float channel, vec2 coord, vec2 normal, vec2 p, float angle, float rad_max ) { ... } struct Cell { vec2 normal; vec2 p1; vec2 p2; vec2 p3; vec2 p4; float samp2; float samp1; float samp3; float samp4; }; vec4 getSample( vec2 point ) { ... } float getDotColour( Cell c, vec2 p, int channel, float angle, float aa ) { ... } Cell getReferenceCell( vec2 p, vec2 origin, float grid_angle, float step ) { ... } float blendColour( float a, float b, float t ) { ... } void main() { ... }";
}