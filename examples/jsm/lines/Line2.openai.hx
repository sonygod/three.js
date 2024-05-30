package three.js.examples.jsm.lines;

import three.js.examples.jsm.lines.LineSegments2;
import three.js.examples.jsm.lines.LineGeometry;
import three.js.examples.jsm.lines.LineMaterial;

class Line2 extends LineSegments2 {
    public var isLine2:Bool = true;
    public var type:String = 'Line2';

    public function new(?geometry:LineGeometry = new LineGeometry(), ?material:LineMaterial = new LineMaterial({ color: Math.random() * 0xffffff })) {
        super(geometry, material);
    }
}