class LogDepthBufVertex {
    public static function getShaderCode():String {
        return """
#ifdef USE_LOGDEPTHBUF

    vFragDepth = 1.0 + gl_Position.w;
    vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );

#endif
""";
    }
}