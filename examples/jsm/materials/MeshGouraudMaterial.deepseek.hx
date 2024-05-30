import three.UniformsUtils;
import three.UniformsLib;
import three.ShaderMaterial;
import three.Color;
import three.MultiplyOperation;

class MeshGouraudMaterial extends ShaderMaterial {

    public function new(parameters:Dynamic) {
        super();

        this.isMeshGouraudMaterial = true;
        this.type = 'MeshGouraudMaterial';

        this.combine = MultiplyOperation;
        this.fog = false;
        this.lights = true;
        this.clipping = false;

        var shader = GouraudShader;

        this.defines = shader.defines;
        this.uniforms = UniformsUtils.clone(shader.uniforms);
        this.vertexShader = shader.vertexShader;
        this.fragmentShader = shader.fragmentShader;

        this.setValues(parameters);
    }

    public function copy(source:MeshGouraudMaterial) {
        super.copy(source);

        this.color.copy(source.color);

        this.map = source.map;
        this.lightMap = source.lightMap;
        this.lightMapIntensity = source.lightMapIntensity;
        this.aoMap = source.aoMap;
        this.aoMapIntensity = source.aoMapIntensity;
        this.emissive.copy(source.emissive);
        this.emissiveMap = source.emissiveMap;
        this.emissiveIntensity = source.emissiveIntensity;
        this.specularMap = source.specularMap;
        this.alphaMap = source.alphaMap;
        this.envMap = source.envMap;
        this.combine = source.combine;
        this.reflectivity = source.reflectivity;
        this.refractionRatio = source.refractionRatio;
        this.opacity = source.opacity;
        this.diffuse = source.diffuse;

        this.wireframe = source.wireframe;
        this.wireframeLinewidth = source.wireframeLinewidth;
        this.wireframeLinecap = source.wireframeLinecap;
        this.wireframeLinejoin = source.wireframeLinejoin;

        this.fog = source.fog;

        return this;
    }
}