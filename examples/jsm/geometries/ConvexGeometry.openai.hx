package three.js.examples.jsm.geometries;

import three.js.BufferGeometry;
import three.js.Float32BufferAttribute;
import three.math.ConvexHull;

class ConvexGeometry extends BufferGeometry {
    public function new(points:Array<Vector3> = []) {
        super();

        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];

        var convexHull:ConvexHull = new ConvexHull().setFromPoints(points);

        var faces:Array<Face> = convexHull.faces;

        for (i in 0...faces.length) {
            var face:Face = faces[i];
            var edge:HalfEdge = face.edge;

            do {
                var point:Vector3 = edge.head().point;

                vertices.push(point.x);
                vertices.push(point.y);
                vertices.push(point.z);

                normals.push(face.normal.x);
                normals.push(face.normal.y);
                normals.push(face.normal.z);

                edge = edge.next;
            } while (edge != face.edge);
        }

        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
    }
}