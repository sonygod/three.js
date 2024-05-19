package geometries;

import BufferGeometry;
import BufferAttribute;
import math.Vector3;

class TorusKnotGeometry extends BufferGeometry {

    public var radius:Float;
    public var tube:Float;
    public var tubularSegments:Int;
    public var radialSegments:Int;
    public var p:Int;
    public var q:Int;
    
    public function new(radius:Float = 1, tube:Float = 0.4, tubularSegments:Int = 64, radialSegments:Int = 8, p:Int = 2, q:Int = 3) {
        super();
        
        this.radius = radius;
        this.tube = tube;
        this.tubularSegments = tubularSegments;
        this.radialSegments = radialSegments;
        this.p = p;
        this.q = q;
        
        this.type = "TorusKnotGeometry";
        
        var tubularSegmentsInt = Math.floor(tubularSegments);
        var radialSegmentsInt = Math.floor(radialSegments);
        
        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];
        
        var vertex = new Vector3();
        var normal = new Vector3();
        
        var P1 = new Vector3();
        var P2 = new Vector3();
        
        var B = new Vector3();
        var T = new Vector3();
        var N = new Vector3();
        
        for (i in 0...tubularSegmentsInt) {
            var u = i / tubularSegmentsInt * p * Math.PI * 2;
            
            calculatePositionOnCurve(u, p, q, radius, P1);
            calculatePositionOnCurve(u + 0.01, p, q, radius ,P2);
            
            T.subVectors(P2, P1);
            N.addVectors(P2, P1);
            B.crossVectors(T, N);
            N.crossVectors(B, T);
            
            B.normalize();
            N.normalize();
            
            for (j in 0...radialSegmentsInt) {
                var v = j / radialSegmentsInt * Math.PI * 2;
                var cx = -tube * Math.cos(v);
                var cy = tube * Math.sin(v);
                
                vertex.x = P1.x + (cx * N.x + cy * B.x);
                vertex.y = P1.y + (cx * N.y + cy * B.y);
                vertex.z = P1.z + (cx * N.z + cy * B.z);
                
                vertices.push(vertex.x);
                vertices.push(vertex.y);
                vertices.push(vertex.z);
                
                normal.subVectors(vertex, P1).normalize();
                
                normals.push(normal.x);
                normals.push(normal.y);
                normals.push(normal.z);
                
                uvs.push(i / tubularSegmentsInt);
                uvs.push(j / radialSegmentsInt);
            }
        }
        
        for (j in 1...tubularSegmentsInt) {
            for (i in 1...radialSegmentsInt) {
                var a = (radialSegmentsInt + 1) * (j - 1) + (i - 1);
                var b = (radialSegmentsInt + 1) * j + (i - 1);
                var c = (radialSegmentsInt + 1) * j + i;
                var d = (radialSegmentsInt + 1) * (j - 1) + i;
                
                indices.push(a);
                indices.push(b);
                indices.push(d);
                
                indices.push(b);
                indices.push(c);
                indices.push(d);
            }
        }
        
        this.setIndex(indices);
        this.setAttribute("position", new BufferAttribute(vertices, 3));
        this.setAttribute("normal", new BufferAttribute(normals, 3));
        this.setAttribute("uv", new BufferAttribute(uvs, 2));
    }
    
    private function calculatePositionOnCurve(u:Float, p:Int, q:Int, radius:Float, position:Vector3):Void {
        var cu = Math.cos(u);
        var su = Math.sin(u);
        var quOverP = q / p * u;
        var cs = Math.cos(quOverP);
        
        position.x = radius * (2 + cs) * 0.5 * cu;
        position.y = radius * (2 + cs) * su * 0.5;
        position.z = radius * Math.sin(quOverP) * 0.5;
    }
    
    public function copy(source:TorusKnotGeometry):TorusKnotGeometry {
        super.copy(source);
        this.parameters = { ...source.parameters };
        return this;
    }
    
    public static function fromJson(data:{radius:Float, tube:Float, tubularSegments:Int, radialSegments:Int, p:Int, q:Int}):TorusKnotGeometry {
        return new TorusKnotGeometry(data.radius, data.tube, data.tubularSegments, data.radialSegments, data.p, data.q);
    }
}