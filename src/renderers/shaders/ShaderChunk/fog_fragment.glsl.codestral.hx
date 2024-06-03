class FogFragmentShader {
    static function getShaderChunk(useFog:Bool, fogExp2:Bool, fogDensity:Float, fogNear:Float, fogFar:Float, vFogDepth:Float, fogColor:Color, gl_FragColor:Color):String {
        if (useFog) {
            var fogFactor:Float;
            if (fogExp2) {
                fogFactor = 1.0 - Math.exp( - fogDensity * fogDensity * vFogDepth * vFogDepth );
            } else {
                fogFactor = smoothstep(fogNear, fogFar, vFogDepth);
            }
            gl_FragColor.rgb = gl_FragColor.rgb.lerp(fogColor, fogFactor);
        }
        return gl_FragColor.toString();
    }

    static function smoothstep(edge0:Float, edge1:Float, x:Float):Float {
        var t = Math.clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
        return t * t * (3.0 - 2.0 * t);
    }
}