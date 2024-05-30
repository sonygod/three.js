import js.Browser.Window;

import js.threelabs.lines.LineGeometry;
import js.threelabs.lines.LineMaterial;
import js.threelabs.lines.LineSegments2;

class Line2 extends LineSegments2 {
    public var isLine2:Bool = true;
    public var type:String = "Line2";

    public function new(?geometry:LineGeometry, ?material:LineMaterial) {
        super(geometry ?? new LineGeometry(), material ?? new LineMaterial(#color(Window.random() * 0xFFFFFF)));
    }
}

@:expose("Line2")
class Line2Extern {
    public static function new(?geometry:LineGeometry, ?material:LineMaterial) {
        return new Line2(geometry, material);
    }
}