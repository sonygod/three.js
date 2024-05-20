class ShadowmapVertex {
    public static function getShaderChunk():String {
        var shaderChunk = "";

        if ((Defines.USE_SHADOWMAP && (Defines.NUM_DIR_LIGHT_SHADOWS > 0 || Defines.NUM_POINT_LIGHT_SHADOWS > 0)) || (Defines.NUM_SPOT_LIGHT_COORDS > 0)) {
            shaderChunk += "\n\t// Offsetting the position used for querying occlusion along the world normal can be used to reduce shadow acne.\n\tvec3 shadowWorldNormal = inverseTransformDirection(transformedNormal, viewMatrix);\n\tvec4 shadowWorldPosition;\n\n";
        }

        if (Defines.USE_SHADOWMAP) {
            if (Defines.NUM_DIR_LIGHT_SHADOWS > 0) {
                for (i in 0...Defines.NUM_DIR_LIGHT_SHADOWS) {
                    shaderChunk += "\n\t\tshadowWorldPosition = worldPosition + vec4(shadowWorldNormal * directionalLightShadows[" + i + "].shadowNormalBias, 0);\n\t\tvDirectionalShadowCoord[" + i + "] = directionalShadowMatrix[" + i + "] * shadowWorldPosition;\n\n";
                }
            }

            if (Defines.NUM_POINT_LIGHT_SHADOWS > 0) {
                for (i in 0...Defines.NUM_POINT_LIGHT_SHADOWS) {
                    shaderChunk += "\n\t\tshadowWorldPosition = worldPosition + vec4(shadowWorldNormal * pointLightShadows[" + i + "].shadowNormalBias, 0);\n\t\tvPointShadowCoord[" + i + "] = pointShadowMatrix[" + i + "] * shadowWorldPosition;\n\n";
                }
            }

            /*
            if (Defines.NUM_RECT_AREA_LIGHTS > 0) {
                // TODO (abelnation): update vAreaShadowCoord with area light info
            }
            */
        }

        if (Defines.NUM_SPOT_LIGHT_COORDS > 0) {
            for (i in 0...Defines.NUM_SPOT_LIGHT_COORDS) {
                shaderChunk += "\n\t\tshadowWorldPosition = worldPosition;\n\t\t";
                if (Defines.USE_SHADOWMAP && i < Defines.NUM_SPOT_LIGHT_SHADOWS) {
                    shaderChunk += "shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[" + i + "].shadowNormalBias;\n\t\t";
                }
                shaderChunk += "vSpotLightCoord[" + i + "] = spotLightMatrix[" + i + "] * shadowWorldPosition;\n\n";
            }
        }

        return shaderChunk;
    }
}