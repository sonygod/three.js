package;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Field;
import haxe.macro.Type;

class GlslLighting {

    public static function get(ctx:Context):Expr {
        return macro(ctx);
    }

    static function macro(ctx:Context):Expr {
        var out = new StringBuf();

        out.add(
            "/**\n" +
            " * This is a template that can be used to light a material, it uses pluggable\n" +
            " * RenderEquations (RE)for specific lighting scenarios.\n" +
            " *\n" +
            " * Instructions for use:\n" +
            " * - Ensure that both RE_Direct, RE_IndirectDiffuse and RE_IndirectSpecular are defined\n" +
            " * - Create a material parameter that is to be passed as the third parameter to your lighting functions.\n" +
            " *\n" +
            " * TODO:\n" +
            " * - Add area light support.\n" +
            " * - Add sphere light support.\n" +
            " * - Add diffuse light probe (irradiance cubemap) support.\n" +
            " */\n" +
            "\n" +
            "vec3 geometryPosition = - vViewPosition;\n" +
            "vec3 geometryNormal = normal;\n" +
            "vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );\n" +
            "\n" +
            "vec3 geometryClearcoatNormal = vec3( 0.0 );\n" +
            "\n" +
            "#ifdef USE_CLEARCOAT\n" +
            "\n" +
            "	geometryClearcoatNormal = clearcoatNormal;\n" +
            "\n" +
            "#endif\n" +
            "\n" +
            "#ifdef USE_IRIDESCENCE\n" +
            "\n" +
            "	float dotNVi = saturate( dot( normal, geometryViewDir ) );\n" +
            "\n" +
            "	if ( material.iridescenceThickness == 0.0 ) {\n" +
            "\n" +
            "		material.iridescence = 0.0;\n" +
            "\n" +
            "	} else {\n" +
            "\n" +
            "		material.iridescence = saturate( material.iridescence );\n" +
            "\n" +
            "	}\n" +
            "\n" +
            "	if ( material.iridescence > 0.0 ) {\n" +
            "\n" +
            "		material.iridescenceFresnel = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor );\n" +
            "\n" +
            "		// Iridescence F0 approximation\n" +
            "		material.iridescenceF0 = Schlick_to_F0( material.iridescenceFresnel, 1.0, dotNVi );\n" +
            "\n" +
            "	}\n" +
            "\n" +
            "#endif\n" +
            "\n" +
            "IncidentLight directLight;\n" +
            "\n"
        );

        // Point lights
        out.add(
            "#if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )\n" +
            "\n" +
            "	PointLight pointLight;\n"
        );

        if(ctx.meta.hasField("USE_SHADOWMAP") && ctx.meta.hasField("NUM_POINT_LIGHT_SHADOWS") && ctx.meta.getField("NUM_POINT_LIGHT_SHADOWS").expr.toCode().toInt() > 0) {
            out.add(
                "	#if defined( USE_SHADOWMAP ) && NUM_POINT_LIGHT_SHADOWS > 0\n" +
                "	PointLightShadow pointLightShadow;\n" +
                "	#endif\n"
            );
        }

        out.add(
            "	#pragma unroll_loop_start\n" +
            "	for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {\n" +
            "\n" +
            "		pointLight = pointLights[ i ];\n" +
            "\n" +
            "		getPointLightInfo( pointLight, geometryPosition, directLight );\n" +
            "\n"
        );

        if(ctx.meta.hasField("USE_SHADOWMAP") && ctx.meta.hasField("NUM_POINT_LIGHT_SHADOWS") && ctx.meta.getField("NUM_POINT_LIGHT_SHADOWS").expr.toCode().toInt() > 0) {
            out.add(
                "		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )\n" +
                "		pointLightShadow = pointLightShadows[ i ];\n" +
                "		directLight.color *= ( directLight.visible && receiveShadow ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;\n" +
                "		#endif\n"
            );
        }

        out.add(
            "		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );\n" +
            "\n" +
            "	}\n" +
            "	#pragma unroll_loop_end\n" +
            "\n" +
            "#endif\n"
        );

        // Spot lights
        out.add(
            "#if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )\n" +
            "\n" +
            "	SpotLight spotLight;\n" +
            "	vec4 spotColor;\n" +
            "	vec3 spotLightCoord;\n" +
            "	bool inSpotLightMap;\n" +
            "\n"
        );

        if(ctx.meta.hasField("USE_SHADOWMAP") && ctx.meta.hasField("NUM_SPOT_LIGHT_SHADOWS") && ctx.meta.getField("NUM_SPOT_LIGHT_SHADOWS").expr.toCode().toInt() > 0) {
            out.add(
                "	#if defined( USE_SHADOWMAP ) && NUM_SPOT_LIGHT_SHADOWS > 0\n" +
                "	SpotLightShadow spotLightShadow;\n" +
                "	#endif\n"
            );
        }

        out.add(
            "	#pragma unroll_loop_start\n" +
            "	for ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {\n" +
            "\n" +
            "		spotLight = spotLights[ i ];\n" +
            "\n" +
            "		getSpotLightInfo( spotLight, geometryPosition, directLight );\n" +
            "\n" +
            "		// spot lights are ordered [shadows with maps, shadows without maps, maps without shadows, none]\n"
        );

        // Check for spot light maps
        var hasSpotLightMaps = ctx.meta.hasField("NUM_SPOT_LIGHT_MAPS") && ctx.meta.getField("NUM_SPOT_LIGHT_MAPS").expr.toCode().toInt() > 0;
        var hasSpotLightShadowsWithMaps = ctx.meta.hasField("NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS") && ctx.meta.getField("NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS").expr.toCode().toInt() > 0;
        var hasSpotLightShadows = ctx.meta.hasField("NUM_SPOT_LIGHT_SHADOWS") && ctx.meta.getField("NUM_SPOT_LIGHT_SHADOWS").expr.toCode().toInt() > 0;

        if(hasSpotLightMaps && hasSpotLightShadowsWithMaps && hasSpotLightShadows) {
            out.add(
                "		#if ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )\n" +
                "		#define SPOT_LIGHT_MAP_INDEX UNROLLED_LOOP_INDEX\n" +
                "		#elif ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )\n" +
                "		#define SPOT_LIGHT_MAP_INDEX NUM_SPOT_LIGHT_MAPS\n" +
                "		#else\n" +
                "		#define SPOT_LIGHT_MAP_INDEX ( UNROLLED_LOOP_INDEX - NUM_SPOT_LIGHT_SHADOWS + NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )\n" +
                "		#endif\n" +
                "\n" +
                "		#if ( SPOT_LIGHT_MAP_INDEX < NUM_SPOT_LIGHT_MAPS )\n" +
                "			spotLightCoord = vSpotLightCoord[ i ].xyz / vSpotLightCoord[ i ].w;\n" +
                "			inSpotLightMap = all( lessThan( abs( spotLightCoord * 2. - 1. ), vec3( 1.0 ) ) );\n" +
                "			spotColor = texture2D( spotLightMap[ SPOT_LIGHT_MAP_INDEX ], spotLightCoord.xy );\n" +
                "			directLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;\n" +
                "		#endif\n" +
                "\n" +
                "		#undef SPOT_LIGHT_MAP_INDEX\n"
            );
        }

        // Check for spot light shadows
        if(ctx.meta.hasField("USE_SHADOWMAP") && hasSpotLightShadows) {
            out.add(
                "		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )\n" +
                "		spotLightShadow = spotLightShadows[ i ];\n" +
                "		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( spotShadowMap[ i ], spotLightShadow.shadowMapSize, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;\n" +
                "		#endif\n"
            );
        }

        out.add(
            "		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );\n" +
            "\n" +
            "	}\n" +
            "	#pragma unroll_loop_end\n" +
            "\n" +
            "#endif\n"
        );

        // Directional lights
        out.add(
            "#if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct )\n" +
            "\n" +
            "	DirectionalLight directionalLight;\n"
        );

        if(ctx.meta.hasField("USE_SHADOWMAP") && ctx.meta.hasField("NUM_DIR_LIGHT_SHADOWS") && ctx.meta.getField("NUM_DIR_LIGHT_SHADOWS").expr.toCode().toInt() > 0) {
            out.add(
                "	#if defined( USE_SHADOWMAP ) && NUM_DIR_LIGHT_SHADOWS > 0\n" +
                "	DirectionalLightShadow directionalLightShadow;\n" +
                "	#endif\n"
            );
        }

        out.add(
            "	#pragma unroll_loop_start\n" +
            "	for ( int i = 0; i < NUM_DIR_LIGHTS; i ++ ) {\n" +
            "\n" +
            "		directionalLight = directionalLights[ i ];\n" +
            "\n" +
            "		getDirectionalLightInfo( directionalLight, directLight );\n" +
            "\n"
        );

        if(ctx.meta.hasField("USE_SHADOWMAP") && ctx.meta.hasField("NUM_DIR_LIGHT_SHADOWS") && ctx.meta.getField("NUM_DIR_LIGHT_SHADOWS").expr.toCode().toInt() > 0) {
            out.add(
                "		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS )\n" +
                "		directionalLightShadow = directionalLightShadows[ i ];\n" +
                "		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;\n" +
                "		#endif\n"
            );
        }

        out.add(
            "		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );\n" +
            "\n" +
            "	}\n" +
            "	#pragma unroll_loop_end\n" +
            "\n" +
            "#endif\n"
        );

        // Rect area lights
        out.add(
            "#if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )\n" +
            "\n" +
            "	RectAreaLight rectAreaLight;\n" +
            "\n" +
            "	#pragma unroll_loop_start\n" +
            "	for ( int i = 0; i < NUM_RECT_AREA_LIGHTS; i ++ ) {\n" +
            "\n" +
            "		rectAreaLight = rectAreaLights[ i ];\n" +
            "		RE_Direct_RectArea( rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );\n" +
            "\n" +
            "	}\n" +
            "	#pragma unroll_loop_end\n" +
            "\n" +
            "#endif\n"
        );

        // Indirect diffuse
        out.add(
            "#if defined( RE_IndirectDiffuse )\n" +
            "\n" +
            "	vec3 iblIrradiance = vec3( 0.0 );\n" +
            "\n" +
            "	vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );\n" +
            "\n"
        );

        // Check for light probes
        if(ctx.meta.hasField("USE_LIGHT_PROBES")) {
            out.add(
                "	#if defined( USE_LIGHT_PROBES )\n" +
                "\n" +
                "		irradiance += getLightProbeIrradiance( lightProbe, geometryNormal );\n" +
                "\n" +
                "	#endif\n"
            );
        }

        // Check for hemisphere lights
        if(ctx.meta.hasField("NUM_HEMI_LIGHTS") && ctx.meta.getField("NUM_HEMI_LIGHTS").expr.toCode().toInt() > 0) {
            out.add(
                "	#if ( NUM_HEMI_LIGHTS > 0 )\n" +
                "\n" +
                "		#pragma unroll_loop_start\n" +
                "		for ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {\n" +
                "\n" +
                "			irradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometryNormal );\n" +
                "\n" +
                "		}\n" +
                "		#pragma unroll_loop_end\n" +
                "\n" +
                "	#endif\n"
            );
        }

        out.add(
            "#endif\n"
        );

        // Indirect specular
        out.add(
            "#if defined( RE_IndirectSpecular )\n" +
            "\n" +
            "	vec3 radiance = vec3( 0.0 );\n" +
            "	vec3 clearcoatRadiance = vec3( 0.0 );\n" +
            "\n" +
            "#endif\n"
        );

        return ctx.makeExpr(out.toString());
    }
}