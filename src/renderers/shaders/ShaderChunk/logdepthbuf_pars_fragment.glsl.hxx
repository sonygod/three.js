@:js("export default /* glsl */`\n#if defined( USE_LOGDEPTHBUF )\n\n\tuniform float logDepthBufFC;\n\tvarying float vFragDepth;\n\tvarying float vIsPerspective;\n\n#endif\n`;")
class ShaderChunk {
}