class FogFragment {
    public static function getShaderChunk(useFog:Bool, fogExp2:Bool, fogDensity:Float, fogNear:Float, fogFar:Float, fogColor:Float, vFogDepth:Float):String {
        var shaderChunk = "";

        if (useFog) {
            var fogFactor:Float;

            if (fogExp2) {
                fogFactor = 1.0 - Math.exp(- fogDensity * fogDensity * vFogDepth * vFogDepth);
            } else {
                fogFactor = Math.smoothstep(fogNear, fogFar, vFogDepth);
            }

            shaderChunk += "gl_FragColor.rgb = mix(gl_FragColor.rgb, " + fogColor.toString() + ", " + fogFactor.toString() + ");";
        }

        return shaderChunk;
    }
}