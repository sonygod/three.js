package three.shader;

class NormalFragmentBegin {

    static var code = "

    var faceDirection:Float = gl_FrontFacing ? 1.0 : -1.0;

    #ifdef FLAT_SHADED

        var fdx:Vector3 = dFdx( vViewPosition );
        var fdy:Vector3 = dFdy( vViewPosition );
        var normal:Vector3 = normalize( cross( fdx, fdy ) );

    #else

        var normal:Vector3 = normalize( vNormal );

        #ifdef DOUBLE_SIDED

            normal *= faceDirection;

        #endif

    #endif

    #if defined( USE_NORMALMAP_TANGENTSPACE ) || defined( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY )

        #ifdef USE_TANGENT

            var tbn:Matrix3 = new Matrix3( normalize( vTangent ), normalize( vBitangent ), normal );

        #else

            var tbn:Matrix3 = getTangentFrame( -vViewPosition, normal,
                #if defined( USE_NORMALMAP )
                    vNormalMapUv
                #elif defined( USE_CLEARCOAT_NORMALMAP )
                    vClearcoatNormalMapUv
                #else
                    vUv
                #endif
            );

        #endif

        #if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )

            tbnMultiplyRow( tbn, 0, faceDirection );
            tbnMultiplyRow( tbn, 1, faceDirection );

        #endif

    #endif

    #ifdef USE_CLEARCOAT_NORMALMAP

        #ifdef USE_TANGENT

            var tbn2:Matrix3 = new Matrix3( normalize( vTangent ), normalize( vBitangent ), normal );

        #else

            var tbn2:Matrix3 = getTangentFrame( -vViewPosition, normal, vClearcoatNormalMapUv );

        #endif

        #if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )

            tbnMultiplyRow( tbn2, 0, faceDirection );
            tbnMultiplyRow( tbn2, 1, faceDirection );

        #endif

    #endif

    // non perturbed normal for clearcoat among others

    var nonPerturbedNormal:Vector3 = normal;

    ";

}