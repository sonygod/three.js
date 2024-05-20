class ShaderChunk {
    static var XYZ_TO_REC709:Array<Array<Float>> = [
        [3.2404542, -0.9692660, 0.0556434],
        [-1.5371385, 1.8760108, -0.2040259],
        [-0.4985314, 0.0415560, 1.0572252]
    ];

    public static function Fresnel0ToIor(fresnel0:Array<Float>):Array<Float> {
        var sqrtF0:Array<Float> = [];
        for (f in fresnel0) {
            sqrtF0.push(Math.sqrt(f));
        }
        return [(1.0 + sqrtF0[0]) / (1.0 - sqrtF0[0]), (1.0 + sqrtF0[1]) / (1.0 - sqrtF0[1]), (1.0 + sqrtF0[2]) / (1.0 - sqrtF0[2])];
    }

    // ... 其他函数的转换 ...

    public static function evalIridescence(outsideIOR:Float, eta2:Float, cosTheta1:Float, thinFilmThickness:Float, baseF0:Array<Float>):Array<Float> {
        // ... 函数体 ...
    }
}