package;

class EmissiveMapShader {
	public static var shader:String = "#ifdef USE_EMISSIVEMAP \n uniform sampler2D emissiveMap; \n #endif";
}