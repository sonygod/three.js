import three.examples.jsm.lines.LineSegments2;
import three.examples.jsm.lines.LineGeometry;
import three.examples.jsm.lines.LineMaterial;

class Line2 extends LineSegments2 {

    public function new(geometry:LineGeometry = new LineGeometry(), material:LineMaterial = new LineMaterial({color: Math.random() * 0xffffff})) {

        super(geometry, material);

        this.isLine2 = true;

        this.type = 'Line2';

    }

}

export haxe.macro.Type.createInstance(Line2, []);