class SpecularMapFragment {
    public static function getCode():String {
        return "float specularStrength;\n" +
               "#ifdef USE_SPECULARMAP\n" +
               "    vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );\n" +
               "    specularStrength = texelSpecular.r;\n" +
               "#else\n" +
               "    specularStrength = 1.0;\n" +
               "#endif";
    }
}