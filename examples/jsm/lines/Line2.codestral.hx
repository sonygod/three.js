import LineSegments2 from 'three.js.lines.LineSegments2';
import LineGeometry from 'three.js.lines.LineGeometry';
import LineMaterial from 'three.js.lines.LineMaterial';

class Line2 extends LineSegments2 {

    public function new(geometry: LineGeometry = new LineGeometry(), material: LineMaterial = new LineMaterial({"color": Math.random() * 0xffffff })) {
        super(geometry, material);

        this.isLine2 = true;

        this.type = 'Line2';
    }

}

export default Line2;