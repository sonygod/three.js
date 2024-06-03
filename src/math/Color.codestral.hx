import three.math.MathUtils;
import three.math.ColorManagement;
import three.constants.SRGBColorSpace;

class Color {
    public var r:Float = 1.0;
    public var g:Float = 1.0;
    public var b:Float = 1.0;
    public var isColor:Bool = true;

    public function new(r?:Dynamic, g?:Dynamic, b?:Dynamic) {
        if (r != null && g == null && b == null) {
            if (Std.is(r, Int)) {
                this.setHex(r);
            } else if (Std.is(r, String)) {
                this.setStyle(r);
            } else if (Std.is(r, Color)) {
                this.copy(r);
            }
        } else if (r != null && g != null && b != null) {
            this.setRGB(r, g, b);
        }
    }

    // Rest of the methods...
    // Convert the remaining methods from JavaScript to Haxe using similar syntax and logic.
}