class SpecularMapFragmentShader {
    public static function getShaderChunk(): String {
        return "#ifdef USE_SPECULARMAP\n" +
               "\tuniform sampler2D specularMap;\n" +
               "#endif\n";
    }
}