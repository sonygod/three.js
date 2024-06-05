package three.js.src.renderers.shaders.ShaderChunk;

@:build(macro.Compiler.includeFile("three.js/src/renderers/shaders/ShaderChunk/bumpmap_pars_fragment.glsl"))
class bumpmap_pars_fragment {
    static var glsl = "#ifdef USE_BUMPMAP\n\n" +
        "\tuniform sampler2D bumpMap;\n" +
        "\tuniform float bumpScale;\n\n" +
        "\t// Bump Mapping Unparametrized Surfaces on the GPU by Morten S. Mikkelsen\n" +
        "\t// https://mmikk.github.io/papers3d/mm_sfgrad_bump.pdf\n\n" +
        "\t// Evaluate the derivative of the height w.r.t. screen-space using forward differencing (listing 2)\n\n" +
        "\tvec2 dHdxy_fwd() {\n\n" +
        "\t\tvec2 dSTdx = dFdx( vBumpMapUv );\n" +
        "\t\tvec2 dSTdy = dFdy( vBumpMapUv );\n\n" +
        "\t\tfloat Hll = bumpScale * texture2D( bumpMap, vBumpMapUv ).x;\n" +
        "\t\tfloat dBx = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdx ).x - Hll;\n" +
        "\t\tfloat dBy = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdy ).x - Hll;\n\n" +
        "\t\treturn vec2( dBx, dBy );\n\n" +
        "\t}\n\n" +
        "\tvec3 perturbNormalArb( vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection ) {\n\n" +
        "\t\t// normalize is done to ensure that the bump map looks the same regardless of the texture's scale\n" +
        "\t\tvec3 vSigmaX = normalize( dFdx( surf_pos.xyz ) );\n" +
        "\t\tvec3 vSigmaY = normalize( dFdy( surf_pos.xyz ) );\n" +
        "\t\tvec3 vN = surf_norm; // normalized\n\n" +
        "\t\tvec3 R1 = cross( vSigmaY, vN );\n" +
        "\t\tvec3 R2 = cross( vN, vSigmaX );\n\n" +
        "\t\tfloat fDet = dot( vSigmaX, R1 ) * faceDirection;\n\n" +
        "\t\tvec3 vGrad = sign( fDet ) * ( dHdxy.x * R1 + dHdxy.y * R2 );\n" +
        "\t\treturn normalize( abs( fDet ) * surf_norm - vGrad );\n\n" +
        "\t}\n\n" +
        "#endif";
}