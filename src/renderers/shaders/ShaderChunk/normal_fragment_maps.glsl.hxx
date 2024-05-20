class NormalFragmentMaps {
    static var shader:String =
        #if USE_NORMALMAP_OBJECTSPACE
            "normal = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0; // overrides both flatShading and attribute normals" +
            #if FLIP_SIDED
                "- normal;" +
            #end
            #if DOUBLE_SIDED
                "normal = normal * faceDirection;" +
            #end
            "normal = normalize( normalMatrix * normal );" +
        #elseif USE_NORMALMAP_TANGENTSPACE
            "vec3 mapN = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;" +
            "mapN.xy *= normalScale;" +
            "normal = normalize( tbn * mapN );" +
        #elseif USE_BUMPMAP
            "normal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );" +
        #end;
}