package three.js.src.renderers.shaders.ShaderChunk;

#if macro
#define DITHERING
#end

class dithering_pars_fragment {
    static function main() {
        #if (DITHERING)
            trace("// based on https://www.shadertoy.com/view/MslGR8");
            trace("vec3 dithering( vec3 color ) {");
            trace("//Calculate grid position");
            trace("float grid_position = rand( gl_FragCoord.xy );");
            trace("");
            trace("//Shift the individual colors differently, thus making it even harder to see the dithering pattern");
            trace("vec3 dither_shift_RGB = vec3( 0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0 );");
            trace("");
            trace("//modify shift according to grid position.");
            trace("dither_shift_RGB = mix( 2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position );");
            trace("");
            trace("//shift the color by dither_shift");
            trace("return color + dither_shift_RGB;");
            trace("}");
        #end
    }
}