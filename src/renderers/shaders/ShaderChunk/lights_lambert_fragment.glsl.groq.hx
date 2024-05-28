package three.js.src.renderers.shaders.ShaderChunk;

class LightsLambertFragmentGlsl {
    public static var shader: String = "
    uniform vec3 diffuseColor;
    uniform float specularStrength;
    
    void main(void) {
        LambertMaterial material;
        material.diffuseColor = vec3(diffuseColor);
        material.specularStrength = specularStrength;
    }
";
}