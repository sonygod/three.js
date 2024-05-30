package three.renderers.shaders.ShaderChunk;

class logdepthbuf_pars_fragment {
    static function main() {
        #if defined(USE_LOGDEPTHBUF)
            var logDepthBufFC:Float;
            var vFragDepth:Float;
            var vIsPerspective:Float;
        #end
        return null;
    }
}