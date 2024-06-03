class ACESFilmicToneMappingShader {
    public static var name:String = "ACESFilmicToneMappingShader";

    public static var uniforms:Map<String, Dynamic> = new Map<String, Dynamic>();

    public static var vertexShader:String = "varying vec2 vUv;\n\nvoid main() {\n\tvUv = uv;\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);\n}\n";

    public static var fragmentShader:String = "#define saturate(a) clamp(a, 0.0, 1.0)\n\nuniform sampler2D tDiffuse;\n\nuniform float exposure;\n\nvarying vec2 vUv;\n\nvec3 RRTAndODTFit(vec3 v) {\n\tvec3 a = v * (v + 0.0245786) - 0.000090537;\n\tvec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;\n\treturn a / b;\n}\n\nvec3 ACESFilmicToneMapping(vec3 color) {\n\tconst mat3 ACESInputMat = mat3(\n\t\tvec3(0.59719, 0.07600, 0.02840), // transposed from source\n\t\tvec3(0.35458, 0.90834, 0.13383),\n\t\tvec3(0.04823, 0.01566, 0.83777)\n\t);\n\n\tconst mat3 ACESOutputMat = mat3(\n\t\tvec3(1.60475, -0.10208, -0.00327), // transposed from source\n\t\tvec3(-0.53108, 1.10813, -0.07276),\n\t\tvec3(-0.07367, -0.00605, 1.07602)\n\t);\n\n\tcolor = ACESInputMat * color;\n\n\t// Apply RRT and ODT\n\tcolor = RRTAndODTFit(color);\n\n\tcolor = ACESOutputMat * color;\n\n\t// Clamp to [0, 1]\n\treturn saturate(color);\n}\n\nvoid main() {\n\tvec4 tex = texture2D(tDiffuse, vUv);\n\n\ttex.rgb *= exposure / 0.6; // pre-exposed, outside of the tone mapping function\n\n\tgl_FragColor = vec4(ACESFilmicToneMapping(tex.rgb), tex.a);\n}";
}

ACESFilmicToneMappingShader.uniforms.set("tDiffuse", { value: null });
ACESFilmicToneMappingShader.uniforms.set("exposure", { value: 1.0 });