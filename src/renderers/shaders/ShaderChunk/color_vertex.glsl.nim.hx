package three.src.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("color_vertex.glsl"))
class ColorVertex {

    static var fragment =
    "#if defined( USE_COLOR_ALPHA )\n" +
    "\tvColor = vec4( 1.0 );\n" +
    "#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )\n" +
    "\tvColor = vec3( 1.0 );\n" +
    "#endif\n" +
    "#ifdef USE_COLOR\n" +
    "\tvColor *= color;\n" +
    "#endif\n" +
    "#ifdef USE_INSTANCING_COLOR\n" +
    "\tvColor.xyz *= instanceColor.xyz;\n" +
    "#endif\n" +
    "#ifdef USE_BATCHING_COLOR\n" +
    "\tvec3 batchingColor = getBatchingColor( batchId );\n" +
    "\tvColor.xyz *= batchingColor.xyz;\n" +
    "#endif\n";

}