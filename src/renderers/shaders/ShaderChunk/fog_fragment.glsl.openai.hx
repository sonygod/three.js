package three.shader;

class FogFragmentShader {
  public function new() {}

  public function shader() {
    #ifdef USE_FOG
      #ifdef FOG_EXP2
        var fogFactor:Float = 1.0 - Math.exp(-fogDensity * fogDensity * vFogDepth * vFogDepth);
      #else
        var fogFactor:Float = smoothstep(fogNear, fogFar, vFogDepth);
      #end

      gl_FragColor.rgb = mix(gl_FragColor.rgb, fogColor, fogFactor);
    #end
  }
}