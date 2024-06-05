package;

class IridescenceShader {
	public static var shader:String = "
		#ifdef USE_IRIDESCENCEMAP
			uniform sampler2D iridescenceMap;
		#endif
		#ifdef USE_IRIDESCENCE_THICKNESSMAP
			uniform sampler2D iridescenceThicknessMap;
		#endif
	";
}