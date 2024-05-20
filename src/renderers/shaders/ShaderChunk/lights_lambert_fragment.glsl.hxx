class ShaderChunk {
    public static var lights_lambert_fragment:String = "
    LambertMaterial material;
    material.diffuseColor = diffuseColor.rgb;
    material.specularStrength = specularStrength;
    ";
}