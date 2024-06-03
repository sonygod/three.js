import js.Browser.document;
import js.html.WebGLRenderingContext;
import three.ShaderChunk;

class CSMShader {

    static var lights_fragment_begin:String = """
vec3 geometryPosition = - vViewPosition;
vec3 geometryNormal = normal;
vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );

vec3 geometryClearcoatNormal = vec3( 0.0 );

#ifdef USE_CLEARCOAT

    geometryClearcoatNormal = clearcoatNormal;

#endif

#ifdef USE_IRIDESCENCE
    float dotNVi = saturate( dot( normal, geometryViewDir ) );
    if ( material.iridescenceThickness == 0.0 ) {
        material.iridescence = 0.0;
    } else {
        material.iridescence = saturate( material.iridescence );
    }
    if ( material.iridescence > 0.0 ) {
        material.iridescenceFresnel = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor );
        // Iridescence F0 approximation
        material.iridescenceF0 = Schlick_to_F0( material.iridescenceFresnel, 1.0, dotNVi );
    }
#endif

IncidentLight directLight;

#if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )

    PointLight pointLight;
    #if defined( USE_SHADOWMAP ) && NUM_POINT_LIGHT_SHADOWS > 0
    PointLightShadow pointLightShadow;
    #endif

    #pragma unroll_loop_start
    for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {

        pointLight = pointLights[ i ];

        getPointLightInfo( pointLight, geometryPosition, directLight );

        #if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )
        pointLightShadow = pointLightShadows[ i ];
        directLight.color *= ( directLight.visible && receiveShadow ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;
        #endif

        RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );

    }
    #pragma unroll_loop_end

#endif

// Rest of the code...
"""

    static var lights_pars_begin:String = """
#if defined( USE_CSM ) && defined( CSM_CASCADES )
uniform vec2 CSM_cascades[CSM_CASCADES];
uniform float cameraNear;
uniform float shadowFar;
#endif
""" + ShaderChunk.lights_pars_begin;
}