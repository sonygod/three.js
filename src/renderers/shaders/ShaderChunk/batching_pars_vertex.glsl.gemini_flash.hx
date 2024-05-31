class Shader {
  public static var source:String = /* glsl */
    "#ifdef USE_BATCHING\n" +
    "  attribute float batchId;\n" +
    "  uniform highp sampler2D batchingTexture;\n" +
    "  mat4 getBatchingMatrix(const in float i) {\n" +
    "    int size = textureSize(batchingTexture, 0).x;\n" +
    "    int j = int(i) * 4;\n" +
    "    int x = j % size;\n" +
    "    int y = j / size;\n" +
    "    vec4 v1 = texelFetch(batchingTexture, ivec2(x, y), 0);\n" +
    "    vec4 v2 = texelFetch(batchingTexture, ivec2(x + 1, y), 0);\n" +
    "    vec4 v3 = texelFetch(batchingTexture, ivec2(x + 2, y), 0);\n" +
    "    vec4 v4 = texelFetch(batchingTexture, ivec2(x + 3, y), 0);\n" +
    "    return mat4(v1, v2, v3, v4);\n" +
    "  }\n" +
    "#endif\n" +
    "\n" +
    "#ifdef USE_BATCHING_COLOR\n" +
    "  uniform sampler2D batchingColorTexture;\n" +
    "  vec3 getBatchingColor(const in float i) {\n" +
    "    int size = textureSize(batchingColorTexture, 0).x;\n" +
    "    int j = int(i);\n" +
    "    int x = j % size;\n" +
    "    int y = j / size;\n" +
    "    return texelFetch(batchingColorTexture, ivec2(x, y), 0).rgb;\n" +
    "  }\n" +
    "#endif\n";
}