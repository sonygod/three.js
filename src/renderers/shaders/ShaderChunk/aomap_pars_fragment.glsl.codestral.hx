class AOMapParsFragment {
    public static function getCode():String {
        return "#ifdef USE_AOMAP\n\
            \n\
                uniform sampler2D aoMap;\n\
                uniform float aoMapIntensity;\n\
            \n\
            #endif\n";
    }
}