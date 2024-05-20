class ShaderLib {
    public static var vertex:String = /* glsl */`
    #define TOON

    varying vec3 vViewPosition;

    // ... rest of the vertex shader code ...
    `;

    public static var fragment:String = /* glsl */`
    #define TOON

    uniform vec3 diffuse;
    uniform vec3 emissive;
    uniform float opacity;

    // ... rest of the fragment shader code ...
    `;
}