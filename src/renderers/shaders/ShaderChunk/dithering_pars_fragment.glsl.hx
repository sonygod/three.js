package renderers.shaders.ShaderChunk;

#if DITHERING

class Dithering {
    public static function dithering(color:Vec3):Vec3 {
        // Calculate grid position
        var gridPosition:Float = rand(gl_FragCoord.xy);

        // Shift the individual colors differently, thus making it even harder to see the dithering pattern
        var ditherShiftRGB:Vec3 = new Vec3(0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0);

        // Modify shift according to grid position
        ditherShiftRGB = mix(2.0 * ditherShiftRGB, -2.0 * ditherShiftRGB, gridPosition);

        // Shift the color by dither_shift
        return color + ditherShiftRGB;
    }
}

#end