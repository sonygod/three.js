class ShaderChunk {
    static var toneMappingExposure:Float;

    static function LinearToneMapping(color:Float):Float {
        return Math.clamp(toneMappingExposure * color, 0.0, 1.0);
    }

    // 其他函数的转换...
}