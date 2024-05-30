package three.src.renderers.shaders.ShaderChunk;

class BatchingParsVertex {

    static var fragmentShader =
#if use_batching
        "attribute float batchId;\n" +
        "uniform highp sampler2D batchingTexture;\n" +
        "mat4 getBatchingMatrix( const in float i ) {\n" +
        "\n" +
        "    int size = textureSize( batchingTexture, 0 ).x;\n" +
        "    int j = int( i ) * 4;\n" +
        "    int x = j % size;\n" +
        "    int y = j / size;\n" +
        "    vec4 v1 = texelFetch( batchingTexture, ivec2( x, y ), 0 );\n" +
        "    vec4 v2 = texelFetch( batchingTexture, ivec2( x + 1, y ), 0 );\n" +
        "    vec4 v3 = texelFetch( batchingTexture, ivec2( x + 2, y ), 0 );\n" +
        "    vec4 v4 = texelFetch( batchingTexture, ivec2( x + 3, y ), 0 );\n" +
        "    return mat4( v1, v2, v3, v4 );\n" +
        "\n" +
        "}\n" +
#end

#if use_batching_color
        "uniform sampler2D batchingColorTexture;\n" +
        "vec3 getBatchingColor( const in float i ) {\n" +
        "\n" +
        "    int size = textureSize( batchingColorTexture, 0 ).x;\n" +
        "    int j = int( i );\n" +
        "    int x = j % size;\n" +
        "    int y = j / size;\n" +
        "    return texelFetch( batchingColorTexture, ivec2( x, y ), 0 ).rgb;\n" +
        "\n" +
        "}\n" +
#end
        "";

}