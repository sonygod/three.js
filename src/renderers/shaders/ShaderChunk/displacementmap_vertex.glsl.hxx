@:js("""
#ifdef USE_DISPLACEMENTMAP

	transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );

#endif
""")
class DisplacementMapVertexShader {
    // Your Haxe code here
}