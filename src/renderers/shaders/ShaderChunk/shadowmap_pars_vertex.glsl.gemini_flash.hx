class ShaderMacros {

    public static function main():String {
        var result:String = "";

        result += "#if NUM_SPOT_LIGHT_COORDS > 0\n";
        result += "\tuniform mat4 spotLightMatrix[ NUM_SPOT_LIGHT_COORDS ];\n";
        result += "\tvarying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];\n";
        result += "#end\n";
        result += "\n";

        result += "#ifdef USE_SHADOWMAP\n";
        result += "\n";
        result += "\t#if NUM_DIR_LIGHT_SHADOWS > 0\n";
        result += "\n";
        result += "\t\tuniform mat4 directionalShadowMatrix[ NUM_DIR_LIGHT_SHADOWS ];\n";
        result += "\t\tvarying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];\n";
        result += "\n";
        result += "\t\tstruct DirectionalLightShadow {\n";
        result += "\t\t\tfloat shadowBias;\n";
        result += "\t\t\tfloat shadowNormalBias;\n";
        result += "\t\t\tfloat shadowRadius;\n";
        result += "\t\t\tvec2 shadowMapSize;\n";
        result += "\t\t};\n";
        result += "\n";
        result += "\t\tuniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];\n";
        result += "\n";
        result += "\t#end\n";
        result += "\n";
        result += "\t#if NUM_SPOT_LIGHT_SHADOWS > 0\n";
        result += "\n";
        result += "\t\tstruct SpotLightShadow {\n";
        result += "\t\t\tfloat shadowBias;\n";
        result += "\t\t\tfloat shadowNormalBias;\n";
        result += "\t\t\tfloat shadowRadius;\n";
        result += "\t\t\tvec2 shadowMapSize;\n";
        result += "\t\t};\n";
        result += "\n";
        result += "\t\tuniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];\n";
        result += "\n";
        result += "\t#end\n";
        result += "\n";
        result += "\t#if NUM_POINT_LIGHT_SHADOWS > 0\n";
        result += "\n";
        result += "\t\tuniform mat4 pointShadowMatrix[ NUM_POINT_LIGHT_SHADOWS ];\n";
        result += "\t\tvarying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];\n";
        result += "\n";
        result += "\t\tstruct PointLightShadow {\n";
        result += "\t\t\tfloat shadowBias;\n";
        result += "\t\t\tfloat shadowNormalBias;\n";
        result += "\t\t\tfloat shadowRadius;\n";
        result += "\t\t\tvec2 shadowMapSize;\n";
        result += "\t\t\tfloat shadowCameraNear;\n";
        result += "\t\t\tfloat shadowCameraFar;\n";
        result += "\t\t};\n";
        result += "\n";
        result += "\t\tuniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];\n";
        result += "\n";
        result += "\t#end\n";
        result += "\n";
        result += "\t/*\n";
        result += "\t#if NUM_RECT_AREA_LIGHTS > 0\n";
        result += "\n";
        result += "\t\t// TODO (abelnation): uniforms for area light shadows\n";
        result += "\n";
        result += "\t#end\n";
        result += "\t*/\n";
        result += "\n";
        result += "#end";
        return result;
    }
}