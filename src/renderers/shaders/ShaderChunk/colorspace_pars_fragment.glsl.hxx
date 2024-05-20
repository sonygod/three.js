class ShaderChunk {
    static var LINEAR_SRGB_TO_LINEAR_DISPLAY_P3:Array<Array<Float>> = [
        [0.8224621, 0.177538, 0.0],
        [0.0331941, 0.9668058, 0.0],
        [0.0170827, 0.0723974, 0.9105199]
    ];

    static var LINEAR_DISPLAY_P3_TO_LINEAR_SRGB:Array<Array<Float>> = [
        [1.2249401, -0.2249404, 0.0],
        [-0.0420569, 1.0420571, 0.0],
        [-0.0196376, -0.0786361, 1.0982735]
    ];

    public static function LinearSRGBToLinearDisplayP3(value:Array<Float>):Array<Float> {
        var result:Array<Float> = [];
        for (i in 0...3) {
            var sum:Float = 0.0;
            for (j in 0...3) {
                sum += value[j] * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3[j][i];
            }
            result.push(sum);
        }
        return result;
    }

    public static function LinearDisplayP3ToLinearSRGB(value:Array<Float>):Array<Float> {
        var result:Array<Float> = [];
        for (i in 0...3) {
            var sum:Float = 0.0;
            for (j in 0...3) {
                sum += value[j] * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB[j][i];
            }
            result.push(sum);
        }
        return result;
    }

    // ... 其他函数的转换 ...
}