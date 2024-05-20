class EnvMapCommonParsFragment {
    public static var envMapIntensity(default, null):Float;
    public static var flipEnvMap(default, null):Float;
    public static var envMapRotation(default, null):Mat3;

    #if ENVMAP_TYPE_CUBE
        public static var envMap(default, null):samplerCube;
    #else
        public static var envMap(default, null):sampler2D;
    #end
}