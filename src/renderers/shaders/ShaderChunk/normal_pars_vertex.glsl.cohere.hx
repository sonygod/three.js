package openfl._internal.renderer.opengl.shaders;

class NormalShader {
    public static var source:String = "
			varying vec3 vNormal;

			#ifdef USE_TANGENT

				varying vec3 vTangent;
				varying vec3 vBitangent;

			#endif
		";
}