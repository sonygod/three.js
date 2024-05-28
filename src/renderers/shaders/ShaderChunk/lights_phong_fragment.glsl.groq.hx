package three.src.renderers.shaders.ShaderChunk;

class LightsPhongFragment {
    public static var material:BlinnPhongMaterial = new BlinnPhongMaterial();

    public static function init():Void {
        material.diffuseColor = diffuseColor.rgb;
        material.specularColor = specular;
        material.specularShininess = shininess;
        material.specularStrength = specularStrength;
    }
}