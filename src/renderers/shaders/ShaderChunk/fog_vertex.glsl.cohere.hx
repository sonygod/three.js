#if js
import js.Browser.WebGL.WebGLRenderingContext;
#end

class ShaderCode {
    public static var fogDepth:String = "
#if OPENFL_ WebGLRenderingContext
	vFogDepth = -mvPosition.z;
#endif
	";
}