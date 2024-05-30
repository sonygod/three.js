import three.js.examples.jsm.lines.LineSegments2;
import three.js.examples.jsm.lines.LineGeometry;
import three.js.examples.jsm.lines.LineMaterial;

class Line2 extends LineSegments2 {

	public function new(geometry:LineGeometry = new LineGeometry(), material:LineMaterial = new LineMaterial({color: Math.random() * 0xffffff})):Void {
		super(geometry, material);
		this.isLine2 = true;
		this.type = 'Line2';
	}

}

typedef Line2 = three.js.examples.jsm.lines.Line2;