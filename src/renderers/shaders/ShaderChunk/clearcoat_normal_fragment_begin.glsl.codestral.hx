class ClearcoatNormalFragmentBegin {
    public static function getCode():String {
        return """
        #ifdef USE_CLEARCOAT

            var clearcoatNormal:Array<Float> = nonPerturbedNormal;

        #endif
        """;
    }
}