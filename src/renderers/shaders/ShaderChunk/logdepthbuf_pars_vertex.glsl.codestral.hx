class ShaderChunkLogdepthbufParsVertex {
    static public function getCode():String {
        return "#ifdef USE_LOGDEPTHBUF\n\n\tvarying float vFragDepth;\n\tvarying float vIsPerspective;\n\n#endif\n";
    }
}