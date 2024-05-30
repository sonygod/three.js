package three.js.examples.jsm.materials;

import three.js.UniformsUtils;
import three.js.UniformsLib;
import three.js.ShaderMaterial;
import three.js.Color;
import three.js.MultiplyOperation;

class MeshGouraudMaterial extends ShaderMaterial {
    public var isMeshGouraudMaterial:Bool = true;
    public var type:String = 'MeshGouraudMaterial';

    // uniforms
    public var emissive:Color = new Color(0x000000);
    public var opacity:Float = 1.0;

    // shader
    private var gouraudShader:Dynamic = {
        name: 'GouraudShader',
        uniforms: UniformsUtils.merge([
            UniformsLib.common,
            UniformsLib.specularmap,
            UniformsLib.envmap,
            UniformsLib.aomap,
            UniformsLib.lightmap,
            UniformsLib.emissivemap,
            UniformsLib.fog,
            UniformsLib.lights,
            { emissive: { value: new Color(0x000000) } }
        ]),
        vertexShader: '
            #define GOURAUD
            varying vec3 vLightFront;
            varying vec3 vIndirectFront;
            #ifdef DOUBLE_SIDED
                varying vec3 vLightBack;
                varying vec3 vIndirectBack;
            #endif
            ...  // rest of the vertex shader code
        ',
        fragmentShader: '
            #define GOURAUD
            uniform vec3 diffuse;
            uniform vec3 emissive;
            uniform float opacity;
            varying vec3 vLightFront;
            varying vec3 vIndirectFront;
            #ifdef DOUBLE_SIDED
                varying vec3 vLightBack;
                varying vec3 vIndirectBack;
            #endif
            ...  // rest of the fragment shader code
        ',
    };

    public function new(parameters:Dynamic = null) {
        super();
        this.defines = {};
        this.uniforms = UniformsUtils.clone(gouraudShader.uniforms);
        this.vertexShader = gouraudShader.vertexShader;
        this.fragmentShader = gouraudShader.fragmentShader;
        this.setValues(parameters);
    }

    override public function copy(source:MeshGouraudMaterial):MeshGouraudMaterial {
        super.copy(source);
        this.emissive.copy(source.emissive);
        return this;
    }
}