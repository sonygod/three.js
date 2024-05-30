package three.renderers.shaders.chunk;

class LogDepthBuf_vertex {
    static public function main() {
        #if use_logdepthbuf
            return "vFragDepth = 1.0 + gl_Position.w;\nvIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );\n";
        #else
            return "";
        #end
    }
}