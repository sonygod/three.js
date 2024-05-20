class ShaderChunk {
    public static var clearcoatNormalFragmentBegin(nonPerturbedNormal:String):String {
        return #if (USE_CLEARCOAT)
                var clearcoatNormal = nonPerturbedNormal;
               #end;
    }
}