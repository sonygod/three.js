class Shader {
  public static function main(): String {
    return
      '#ifdef USE_FOG\n' +
      '#ifdef FOG_EXP2\n' +
      '  float fogFactor = 1.0 - exp( - fogDensity * fogDensity * vFogDepth * vFogDepth );\n' +
      '#else\n' +
      '  float fogFactor = smoothstep( fogNear, fogFar, vFogDepth );\n' +
      '#endif\n' +
      '  gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );\n' +
      '#endif\n';
  }
}