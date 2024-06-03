class EnvmapVertex {
    public static function process(useEnvmap:Bool, envWorldPos:Bool, isOrthographic:Bool, cameraPosition:Float, worldPosition:Float, viewMatrix:Array<Array<Float>>, transformedNormal:Float, refractionRatio:Float) {
        if (useEnvmap) {
            if (envWorldPos) {
                vWorldPosition = worldPosition.xyz;
            } else {
                var cameraToVertex:Array<Float>;
                if (isOrthographic) {
                    cameraToVertex = [-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]].normalize();
                } else {
                    cameraToVertex = [worldPosition.x - cameraPosition.x, worldPosition.y - cameraPosition.y, worldPosition.z - cameraPosition.z].normalize();
                }

                var worldNormal:Array<Float> = [-viewMatrix[0][0] * transformedNormal.x - viewMatrix[1][0] * transformedNormal.y - viewMatrix[2][0] * transformedNormal.z,
                                               -viewMatrix[0][1] * transformedNormal.x - viewMatrix[1][1] * transformedNormal.y - viewMatrix[2][1] * transformedNormal.z,
                                               -viewMatrix[0][2] * transformedNormal.x - viewMatrix[1][2] * transformedNormal.y - viewMatrix[2][2] * transformedNormal.z].normalize();

                #if ENVMAP_MODE_REFLECTION
                    vReflect = reflect(cameraToVertex, worldNormal);
                #else
                    vReflect = refract(cameraToVertex, worldNormal, refractionRatio);
                #endif
            }
        }
    }

    private static function normalize(v:Array<Float>):Array<Float> {
        var length:Float = Math.sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
        return [v[0]/length, v[1]/length, v[2]/length];
    }

    private static function reflect(i:Array<Float>, n:Array<Float>):Array<Float> {
        var dotProduct:Float = i[0]*n[0] + i[1]*n[1] + i[2]*n[2];
        return [i[0] - 2.0 * dotProduct * n[0], i[1] - 2.0 * dotProduct * n[1], i[2] - 2.0 * dotProduct * n[2]];
    }

    private static function refract(i:Array<Float>, n:Array<Float>, eta:Float):Array<Float> {
        var dotN:Float = i[0]*n[0] + i[1]*n[1] + i[2]*n[2];
        var k:Float = 1.0 - eta * eta * (1.0 - dotN * dotN);
        if (k < 0.0) {
            return [0.0, 0.0, 0.0]; // total internal reflection
        } else {
            var a:Float = eta * dotN + Math.sqrt(k);
            return [eta * i[0] - a * n[0], eta * i[1] - a * n[1], eta * i[2] - a * n[2]];
        }
    }
}