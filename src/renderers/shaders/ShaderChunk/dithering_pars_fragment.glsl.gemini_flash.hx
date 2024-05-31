class ShaderUtils {
  public static function dithering(color:Vec3):Vec3 {
    //Calculate grid position
    var gridPosition:Float = Math.random(); // Assuming you have a rand function for Haxe

    //Shift the individual colors differently, thus making it even harder to see the dithering pattern
    var ditherShiftRGB:Vec3 = new Vec3(0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0);

    //modify shift according to grid position.
    ditherShiftRGB = Vec3.lerp(ditherShiftRGB * 2.0, ditherShiftRGB * -2.0, gridPosition);

    //shift the color by dither_shift
    return color + ditherShiftRGB;
  }
}

// Example usage in a Haxe shader context (assuming you are using a library like Luxe or OpenFL)
#if DITHERING
  final color:Vec3 = ShaderUtils.dithering(inputColor);
#endif