package three.js.examples.jm.geometries;

import three.js.BufferGeometry;
import three.js.Float32BufferAttribute;
import three.js.math.ConvexHull;

class ConvexGeometry extends BufferGeometry {
    public function new(points:Array<Vector3> = []) {
        super();
        
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        
        var convexHull:ConvexHull = new ConvexHull().setFromPoints(points);
        
        // generate vertices and normals
        
        var faces:Array<Face> = convexHull.faces;
        
        for (i in 0...faces.length) {
            var face:Face = faces[i];
            var edge:HalfEdge = face.edge;
            
            // we move along a doubly-connected edge list to access all face points (see HalfEdge docs)
            
            while (true) {
                var point:Vector3 = edge.head().point;
                
                vertices.push(point.x);
                vertices.push(point.y);
                vertices.push(point.z);
                
                normals.push(face.normal.x);
                normals.push(face.normal.y);
                normals.push(face.normal.z);
                
                edge = edge.next;
                
                if (edge == face.edge) break;
            }
        }
        
        // build geometry
        
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
    }
}

extern class ConvexHull {
    public function new() {}
    public function setFromPoints(points:Array<Vector3>):ConvexHull {
        // assume implementation is similar to JavaScript version
        return this;
    }
    public var faces:Array<Face>;
}

extern class Face {
    public var edge:HalfEdge;
    public var normal:Vector3;
}

extern class HalfEdge {
    public function head():Vertex {
        // assume implementation is similar to JavaScript version
        return null;
    }
    public var next:HalfEdge;
}

extern class Vertex {
    public var point:Vector3;
}

extern class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;
}