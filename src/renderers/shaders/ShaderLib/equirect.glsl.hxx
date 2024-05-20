import js.Lib.three.src.renderers.shaders.ShaderLib.equirect;

class Equirect {
    static var vertex:String = /* glsl */`
    varying vec3 vWorldDirection;

    #include <common>

    void main() {

        vWorldDirection = transformDirection( position, modelMatrix );

        #include <begin_vertex>
        #include <project_vertex>

    }
    `;

    static var fragment:String = /* glsl */`
    uniform sampler2D tEquirect;

    varying vec3 vWorldDirection;

    #include <common>

    void main() {

        vec3 direction = normalize( vWorldDirection );

        vec2 sampleUV = equirectUv( direction );

        gl_FragColor = texture2D( tEquirect, sampleUV );

        #include <tonemapping_fragment>
        #include <colorspace_fragment>

    }
    `;
}