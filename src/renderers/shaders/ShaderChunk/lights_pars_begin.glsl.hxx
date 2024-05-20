class ShaderChunk {
    public static var receiveShadow:Bool;
    public static var ambientLightColor:Float3;

    #if defined(USE_LIGHT_PROBES)
        public static var lightProbe:Array<Float3>;
    #end

    // ... 其他函数和变量 ...

    public static function shGetIrradianceAt(normal:Float3, shCoefficients:Array<Float3>):Float3 {
        // ... 函数体 ...
    }

    // ... 其他函数 ...
}