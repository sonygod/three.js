package three.shader;

class LightsPhongFragmentShader {
    public function new() {}

    public static var shaderCode:String = "
        uniform vec3 diffuseColor;
        uniform vec3 specular;
        uniform float shininess;
        uniform float specularStrength;

        void main() {
            BlinnPhongMaterial material;
            material.diffuseColor = vec3(diffuseColor);
            material.specularColor = specular;
            material.specularShininess = shininess;
            material.specularStrength = specularStrength;
        }
    ";
}