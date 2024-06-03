class ColorParsFragment {
    public static function getShader():String {
        var shader:String = "";

        #if defined(USE_COLOR_ALPHA)
        shader += "varying vec4 vColor;\n";
        #elseif defined(USE_COLOR)
        shader += "varying vec3 vColor;\n";
        #end

        return shader;
    }
}