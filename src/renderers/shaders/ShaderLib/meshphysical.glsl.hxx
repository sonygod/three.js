package three.js.src.renderers.shaders.ShaderLib;

import js.Lib;

class MeshPhysicalShader {

    public static var vertex:String = /* glsl */`
    #define STANDARD

    varying vec3 vViewPosition;

    #ifdef USE_TRANSMISSION

        varying vec3 vWorldPosition;

    #endif

    // Include other GLSL files here...

    void main() {

        // GLSL code here...

        vViewPosition = - mvPosition.xyz;

        // GLSL code here...

        #ifdef USE_TRANSMISSION

            vWorldPosition = worldPosition.xyz;

        #endif
    }
    `;

    public static var fragment:String = /* glsl */`
    #define STANDARD

    // Define other macros here...

    uniform vec3 diffuse;
    uniform vec3 emissive;
    uniform float roughness;
    uniform float metalness;
    uniform float opacity;

    // Define other uniforms here...

    varying vec3 vViewPosition;

    // Include other GLSL files here...

    void main() {

        vec4 diffuseColor = vec4( diffuse, opacity );
        // GLSL code here...

        ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
        vec3 totalEmissiveRadiance = emissive;

        // GLSL code here...

        vec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;
        vec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;

        // GLSL code here...

        vec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;

        // GLSL code here...

        #include <opaque_fragment>
        #include <tonemapping_fragment>
        #include <colorspace_fragment>
        #include <fog_fragment>
        #include <premultiplied_alpha_fragment>
        #include <dithering_fragment>

    }
    `;
}