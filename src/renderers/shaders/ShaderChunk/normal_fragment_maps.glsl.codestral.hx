class NormalFragmentMaps {
    static function getShaderChunk():String {
        return """
#ifdef USE_NORMALMAP_OBJECTSPACE

    normal = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0; // overrides both flatShading and attribute normals

    #ifdef FLIP_SIDED

        normal = - normal;

    #endif

    #ifdef DOUBLE_SIDED

        normal = normal * faceDirection;

    #endif

    normal = normalize( normalMatrix * normal );

#elif defined( USE_NORMALMAP_TANGENTSPACE )

    var mapN:Vec3 = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
    mapN.xy *= normalScale;

    normal = normalize( tbn * mapN );

#elif defined( USE_BUMPMAP )

    normal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );

#endif
""";
    }
}

// Usage
trace(NormalFragmentMaps.getShaderChunk());