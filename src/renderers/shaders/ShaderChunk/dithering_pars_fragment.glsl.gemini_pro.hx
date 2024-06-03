#if DITHERING

	// based on https://www.shadertoy.com/view/MslGR8
	function dithering(color:Vec3):Vec3 {
		//Calculate grid position
		var grid_position:Float = rand(gl_FragCoord.xy);

		//Shift the individual colors differently, thus making it even harder to see the dithering pattern
		var dither_shift_RGB:Vec3 = new Vec3(0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0);

		//modify shift according to grid position.
		dither_shift_RGB = mix(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position);

		//shift the color by dither_shift
		return color + dither_shift_RGB;
	}

#end