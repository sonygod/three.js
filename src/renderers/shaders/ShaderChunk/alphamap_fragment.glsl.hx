package three.shader;

class AlphaMapFragment {
    public static var shader:String = "
#ifdef USE_ALPHAMAP

	diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;

#endif
";
}