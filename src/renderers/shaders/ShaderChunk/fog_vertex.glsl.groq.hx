package three.shader;

class FogVertexShader {
    public static var shader:String = `
#ifdef USE_FOG

	vFogDepth = - mvPosition.z;

#endif
`;
}