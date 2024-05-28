package three.renderers.shaders.ShaderChunk;

#if (js && (USE_LOGDEPTHBUF == true))

    @:glsl("")

    class LogDepthBufParsVertex {

        @:varying public var vFragDepth:Float;
        @:varying public var vIsPerspective:Float;

    }

#else

    class LogDepthBufParsVertex {

    }

#end