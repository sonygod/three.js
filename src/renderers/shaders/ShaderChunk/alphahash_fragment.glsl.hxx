class AlphaHashFragment {
    static var shaderCode:String = haxe.Resource.fromString(`
#ifdef USE_ALPHAHASH

	if ( diffuseColor.a < getAlphaHashThreshold( vPosition ) ) discard;

#endif
`);
}