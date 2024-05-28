package three.renderers.shaders.ShaderChunk;

class NormalFragmentBegin {
  public static var code = '

    var faceDirection:Float = gl_FrontFacing ? 1.0 : -1.0;

    #ifdef FLAT_SHADED

    var fdx:Vec3 = dFdx(vViewPosition);
    var fdy:Vec3 = dFdy(vViewPosition);
    var normal:Vec3 = normalize(cross(fdx, fdy));

    #else

    var normal:Vec3 = normalize(vNormal);

    #ifdef DOUBLE_SIDED

    normal *= faceDirection;

    #endif

    #endif

    #if defined(USE_NORMALMAP_TANGENTSPACE) || defined(USE_CLEARCOAT_NORMALMAP) || defined(USE_ANISOTROPY)

    #ifdef USE_TANGENT

    var tbn:Mat3 = new Mat3(normalize(vTangent), normalize(vBitangent), normal);

    #else

    var tbn:Mat3 = getTangentFrame(-vViewPosition, normal,
        #if defined(USE_NORMALMAP)
        vNormalMapUv
        #elif defined(USE_CLEARCOAT_NORMALMAP)
        vClearcoatNormalMapUv
        #else
        vUv
        #endif
    );

    #endif

    #if defined(DOUBLE_SIDED) && !defined(FLAT_SHADED)

    tbn.m[0] *= faceDirection;
    tbn.m[1] *= faceDirection;

    #endif

    #endif

    #ifdef USE_CLEARCOAT_NORMALMAP

    #ifdef USE_TANGENT

    var tbn2:Mat3 = new Mat3(normalize(vTangent), normalize(vBitangent), normal);

    #else

    var tbn2:Mat3 = getTangentFrame(-vViewPosition, normal, vClearcoatNormalMapUv);

    #endif

    #if defined(DOUBLE_SIDED) && !defined(FLAT_SHADED)

    tbn2.m[0] *= faceDirection;
    tbn2.m[1] *= faceDirection;

    #endif

    #endif

    // non perturbed normal for clearcoat among others

    var nonPerturbedNormal:Vec3 = normal;

  ';
}