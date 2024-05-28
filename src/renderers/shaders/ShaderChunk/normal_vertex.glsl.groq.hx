package three.js.src.renderers.shaders.ShaderChunk;

class NormalVertex {
    public static var shader:String = "
#ifndef FLAT_SHADED // normal is computed with derivatives when FLAT_SHADED

    vNormal = normalize( transformedNormal );

    #ifdef USE_TANGENT

    vTangent = normalize( transformedTangent );
    vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );

    #endif

#endif
";
}