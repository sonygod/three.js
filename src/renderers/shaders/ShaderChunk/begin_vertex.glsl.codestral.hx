class BeginVertexShader {
    public static function getShader():String {
        return "vec3 transformed = vec3( position );" +
               "#ifdef USE_ALPHAHASH\n" +
               "vPosition = vec3( position );\n" +
               "#endif";
    }
}