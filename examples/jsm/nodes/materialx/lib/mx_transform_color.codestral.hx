// Haxe Transpiler
// Equivalent to Three.js code at: https://github.com/AcademySoftwareFoundation/MaterialX/blob/main/libraries/stdlib/genglsl/lib/mx_transform_color.glsl

import js.Array;
import js.html.ArrayBufferView;

class Mx_Transform_Color {
    public static function mx_srgb_texture_to_lin_rec709(color_immutable: Array<Float>): Array<Float> {
        var color: Array<Float> = color_immutable.slice();
        var isAbove: Array<Bool> = [color[0] > 0.04045, color[1] > 0.04045, color[2] > 0.04045];
        var linSeg: Array<Float> = [color[0] / 12.92, color[1] / 12.92, color[2] / 12.92];
        var powSeg: Array<Float> = [Math.pow(Math.max((color[0] + 0.055) / 1.055, 0.0), 2.4), Math.pow(Math.max((color[1] + 0.055) / 1.055, 0.0), 2.4), Math.pow(Math.max((color[2] + 0.055) / 1.055, 0.0), 2.4)];

        var result: Array<Float> = [isAbove[0] ? powSeg[0] : linSeg[0], isAbove[1] ? powSeg[1] : linSeg[1], isAbove[2] ? powSeg[2] : linSeg[2]];

        return result;
    }
}