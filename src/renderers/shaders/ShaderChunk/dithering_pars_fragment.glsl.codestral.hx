#ifdef DITHERING

// based on https://www.shadertoy.com/view/MslGR8
function dithering(color: Float3): Float3 {
    // Calculate grid position
    var grid_position: Float = Std.random(gl_FragCoord.xy);

    // Shift the individual colors differently, thus making it even harder to see the dithering pattern
    var dither_shift_RGB: Float3 = new Float3(0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0);

    // Modify shift according to grid position.
    dither_shift_RGB = Float3.lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position);

    // Shift the color by dither_shift
    return color + dither_shift_RGB;
}

#endif