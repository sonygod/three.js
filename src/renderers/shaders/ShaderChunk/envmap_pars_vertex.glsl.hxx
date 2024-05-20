class EnvmapParsVertex {
    public static var code(useEnvmap:Bool, useBumpmap:Bool, useNormalmap:Bool, phong:Bool, lambert:Bool, refractionRatio:Float):String {
        var result = "";

        if (useEnvmap) {
            if (useBumpmap || useNormalmap || phong || lambert) {
                result += "#define ENV_WORLDPOS\n";
            }

            if (result.indexOf("ENV_WORLDPOS") != -1) {
                result += "varying vec3 vWorldPosition;\n";
            } else {
                result += "varying vec3 vReflect;\n";
                result += "uniform float refractionRatio;\n";
            }
        }

        return result;
    }
}