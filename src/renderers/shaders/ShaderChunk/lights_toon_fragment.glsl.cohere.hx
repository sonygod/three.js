function material_to_glsl(material:Material):String {
    var glsl:String = "ToonMaterial material;\n";
    glsl += "material.diffuseColor = vec3(" + material.diffuseColor.r + ", " + material.diffuseColor.g + ", " + material.diffuseColor.b + ");\n";
    return glsl;
}