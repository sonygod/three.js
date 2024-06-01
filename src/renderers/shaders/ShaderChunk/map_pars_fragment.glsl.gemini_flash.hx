class ShaderChunk {

    public static function get( name : String ) : String {
        switch( name ) {
            case "default_vertex":
                return "
#ifdef USE_MAP

	uniform sampler2D map;

#endif
";
            default:
                return "";
        }
    }

}