package three.js.examples.jsm.materials;

import three.js.utils.UniformsUtils;
import three.js.utils.UniformsLib;
import three.js.materials.ShaderMaterial;
import three.js.math.Color;
import three.js.constants.MultiplyOperation;

class GouraudShader {
    public static var name:String = "GouraudShader";

    public static var uniforms:Dynamic = UniformsUtils.merge([
        UniformsLib.common,
        UniformsLib.specularmap,
        UniformsLib.envmap,
        UniformsLib.aomap,
        UniformsLib.lightmap,
        UniformsLib.emissivemap,
        UniformsLib.fog,
        UniformsLib.lights,
        {
            emissive: { value: new Color(0x000000) }
        }
    ]);

    public static var vertexShader:String = "
        #define GOURAUD

        varying vec3 vLightFront;
        varying vec3 vIndirectFront;

        #ifdef DOUBLE_SIDED
            varying vec3 vLightBack;
            varying vec3 vIndirectBack;
        #endif

        //... (rest of the vertex shader code)
    ";

    public static var fragmentShader:String = "
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

        //... (rest of the fragment shader code)
    ";
}

class MeshGouraudMaterial extends ShaderMaterial {
    public function new(parameters:Dynamic = null) {
        super();

        this.isMeshGouraudMaterial = true;

        this.type = 'MeshGouraudMaterial';

        //... (rest of the constructor code)

        const shader:GouraudShader = GouraudShader;

        this.defines = shader.defines;
        this.uniforms = UniformsUtils.clone(shader.uniforms);
        this.vertexShader = shader.vertexShader;
        this.fragmentShader = shader.fragmentShader;

        //... (rest of the property definitions)

        this.setValues(parameters);
    }

    public function copy(source:MeshGouraudMaterial):MeshGouraudMaterial {
        super.copy(source);

        //... (rest of the copy method code)

        return this;
    }
}

// Export the MeshGouraudMaterial class
extern class MeshGouraudMaterial {}