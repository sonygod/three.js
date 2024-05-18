package three.shaderlib;

class DisplacementMapVertexShader {
    public static var shader:String = "
#ifdef USE_DISPLACEMENTMAP

    transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );

#endif
";
}