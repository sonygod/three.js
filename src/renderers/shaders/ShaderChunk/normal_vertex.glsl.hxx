class NormalVertex {
    public static function getShaderChunk():String {
        return #if !FLAT_SHADED
            "vNormal = normalize( transformedNormal );" +
            #if USE_TANGENT
                "vTangent = normalize( transformedTangent );" +
                "vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );"
            #end
        #end;
    }
}