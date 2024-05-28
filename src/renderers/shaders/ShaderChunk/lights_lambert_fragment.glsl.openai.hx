package three.js.src.renderers.shaders.ShaderChunk;

class LightsLambertFragment {
    public static inline var CODE:String = "
    LambertMaterial material;
    material.diffuseColor = diffuseColor.rgb;
    material.specularStrength = specularStrength;
    ";
}