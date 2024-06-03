class SkinbaseVertexShader {
    public static function getShaderCode():String {
        var shaderCode:String = "";
        #if USE_SKINNING
            shaderCode = """
                mat4 boneMatX = getBoneMatrix( skinIndex.x );
                mat4 boneMatY = getBoneMatrix( skinIndex.y );
                mat4 boneMatZ = getBoneMatrix( skinIndex.z );
                mat4 boneMatW = getBoneMatrix( skinIndex.w );
            """;
        #end
        return shaderCode;
    }
}