package three.shader;

class AlphaMapFragment {
    public function new() {}

    public function getShader():String {
        return "
#ifdef USE_ALPHAMAP

	diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;

#endif
";
    }
}