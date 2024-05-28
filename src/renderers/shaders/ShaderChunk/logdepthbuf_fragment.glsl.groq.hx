package three.shader;

class LogDepthbufFragment {
    public static function main() {
        #if (USE_LOGDEPTHBUF)
        gl_FragDepth = (vIsPerspective == 0.0) ? gl_FragCoord.z : Math.log(vFragDepth) * logDepthBufFC * 0.5;
        #end
    }
}