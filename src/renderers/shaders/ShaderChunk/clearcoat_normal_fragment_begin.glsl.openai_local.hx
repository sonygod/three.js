class ClearcoatNormalFragmentBegin {
    public static function getShaderChunk():String {
        var shader:String = "
            #ifdef USE_CLEARCOAT

                vec3 clearcoatNormal = nonPerturbedNormal;

            #endif
        ";
        return shader;
    }
}