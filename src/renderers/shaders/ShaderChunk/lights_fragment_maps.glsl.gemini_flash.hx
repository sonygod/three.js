class Shader {

    public static function main(): String {
        return
        '#if defined( RE_IndirectDiffuse )\n' +
        '\n' +
        '#ifdef USE_LIGHTMAP\n' +
        '\n' +
        '    vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );\n' +
        '    vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;\n' +
        '\n' +
        '    irradiance += lightMapIrradiance;\n' +
        '\n' +
        '#end\n' +
        '\n' +
        '#if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )\n' +
        '\n' +
        '    iblIrradiance += getIBLIrradiance( geometryNormal );\n' +
        '\n' +
        '#end\n' +
        '\n' +
        '#end\n' +
        '\n' +
        '#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )\n' +
        '\n' +
        '#ifdef USE_ANISOTROPY\n' +
        '\n' +
        '    radiance += getIBLAnisotropyRadiance( geometryViewDir, geometryNormal, material.roughness, material.anisotropyB, material.anisotropy );\n' +
        '\n' +
        '#else\n' +
        '\n' +
        '    radiance += getIBLRadiance( geometryViewDir, geometryNormal, material.roughness );\n' +
        '\n' +
        '#end\n' +
        '\n' +
        '#ifdef USE_CLEARCOAT\n' +
        '\n' +
        '    clearcoatRadiance += getIBLRadiance( geometryViewDir, geometryClearcoatNormal, material.clearcoatRoughness );\n' +
        '\n' +
        '#end\n' +
        '\n' +
        '#end\n';
    }
}


The Haxe code is essentially the same as the JavaScript code, as it's just a string literal containing the GLSL code. You'd typically use a Haxe macro or a string interpolation technique if you wanted to embed this GLSL code within a larger Haxe program. 

For example, you could define a macro function like this:


macro function embedGLSL(code: String) {
  return macro $v{code};
}


Then you could use it like this:


class MyShader {
  public static var fragmentShaderSource = embedGLSL(`
    // ... your GLSL code here ...
  `);
}