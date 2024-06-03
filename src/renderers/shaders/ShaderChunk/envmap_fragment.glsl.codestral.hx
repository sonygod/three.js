class EnvmapFragment {
    static function getShaderChunk(useEnvmap:Bool, envWorldPos:Bool, isOrthographic:Bool, viewMatrix:Array<Array<Float>>, cameraPosition:Array<Float>, normal:Array<Float>, refractionRatio:Float, flipEnvMap:Float, envMapRotation:Mat3, envMap:CubeTexture, outgoingLight:Array<Float>, specularStrength:Float, reflectivity:Float):String {
        if (useEnvmap) {
            var reflectVec:Array<Float>;

            if (envWorldPos) {
                var cameraToFrag:Array<Float>;

                if (isOrthographic) {
                    cameraToFrag = [-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]].map(Math.normalize);
                } else {
                    cameraToFrag = [vWorldPosition[0] - cameraPosition[0], vWorldPosition[1] - cameraPosition[1], vWorldPosition[2] - cameraPosition[2]].map(Math.normalize);
                }

                var worldNormal:Array<Float> = inverseTransformDirection(normal, viewMatrix);

                #if defined ENVMAP_MODE_REFLECTION
                    reflectVec = reflect(cameraToFrag, worldNormal);
                #else
                    reflectVec = refract(cameraToFrag, worldNormal, refractionRatio);
                #endif
            } else {
                reflectVec = vReflect;
            }

            var envColor:Array<Float>;

            #if defined ENVMAP_TYPE_CUBE
                var envMapVec3:Array<Float> = [flipEnvMap * reflectVec[0], reflectVec[1], reflectVec[2]];
                envMapVec3 = envMapRotation.multiply(envMapVec3);
                envColor = envMap.sample(envMapVec3);
            #else
                envColor = [0.0, 0.0, 0.0, 0.0];
            #endif

            #if defined ENVMAP_BLENDING_MULTIPLY
                outgoingLight = outgoingLight.map((value, index) => value * (1 - specularStrength * reflectivity) + envColor[index] * outgoingLight[index] * specularStrength * reflectivity);
            #elif defined ENVMAP_BLENDING_MIX
                outgoingLight = outgoingLight.map((value, index) => value * (1 - specularStrength * reflectivity) + envColor[index] * specularStrength * reflectivity);
            #elif defined ENVMAP_BLENDING_ADD
                outgoingLight = outgoingLight.map((value, index) => value + envColor[index] * specularStrength * reflectivity);
            #endif
        }

        return outgoingLight.join(",");
    }

    static function inverseTransformDirection(normal:Array<Float>, viewMatrix:Array<Array<Float>>):Array<Float> {
        // Implement this function according to your needs
        return [];
    }

    static function reflect(cameraToFrag:Array<Float>, worldNormal:Array<Float>):Array<Float> {
        // Implement this function according to your needs
        return [];
    }

    static function refract(cameraToFrag:Array<Float>, worldNormal:Array<Float>, refractionRatio:Float):Array<Float> {
        // Implement this function according to your needs
        return [];
    }
}