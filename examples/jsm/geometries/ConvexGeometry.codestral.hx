import js.three.BufferGeometry;
import js.three.Float32BufferAttribute;
import js.three.math.ConvexHull;

class ConvexGeometry extends BufferGeometry {

    public function new(points:Array<Dynamic> = []) {
        super();

        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];

        var convexHull = new ConvexHull().setFromPoints(points);

        var faces = convexHull.faces;

        for (i in 0...faces.length) {
            var face = faces[i];
            var edge = face.edge;

            do {
                var point = edge.head().point;

                vertices.push(point.x, point.y, point.z);
                normals.push(face.normal.x, face.normal.y, face.normal.z);

                edge = edge.next;

            } while (edge != face.edge);
        }

        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
    }
}