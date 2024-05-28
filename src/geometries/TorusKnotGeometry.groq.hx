package three.geom;

import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class TorusKnotGeometry extends BufferGeometry {
    
    public function new(radius:Float = 1, tube:Float = 0.4, tubularSegments:Int = 64, radialSegments:Int = 8, p:Int = 2, q:Int = 3) {
        super();
        this.type = 'TorusKnotGeometry';
        this.parameters = {
            radius: radius,
            tube: tube,
            tubularSegments: tubularSegments,
            radialSegments: radialSegments,
            p: p,
            q: q
        };
        
        tubularSegments = Std.int(tubularSegments);
        radialSegments = Std.int(radialSegments);
        
        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];
        
        var vertex:Vector3 = new Vector3();
        var normal:Vector3 = new Vector3();
        
        var P1:Vector3 = new Vector3();
        var P2:Vector3 = new Vector3();
        
        var B:Vector3 = new Vector3();
        var T:Vector3 = new Vector3();
        var N:Vector3 = new Vector3();
        
        for (i in 0...tubularSegments + 1) {
            var u:Float = i / tubularSegments * p * Math.PI * 2;
            
            calculatePositionOnCurve(u, p, q, radius, P1);
            calculatePositionOnCurve(u + 0.01, p, q, radius, P2);
            
            T.subVectors(P2, P1);
            N.addVectors(P2, P1);
            B.crossVectors(T, N);
            N.crossVectors(B, T);
            
            B.normalize();
            N.normalize();
            
            for (j in 0...radialSegments + 1) {
                var v:Float = j / radialSegments * Math.PI * 2;
                var cx:Float = -tube * Math.cos(v);
                var cy:Float = tube * Math.sin(v);
                
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
                
                uvs.push(i / tubularSegments);
                uvs.push(j / radialSegments);
            }
        }
        
        for (j in 1...tubularSegments + 1) {
            for (i in 1...radialSegments + 1) {
                var a:Int = (radialSegments + 1) * (j - 1) + (i - 1);
                var b:Int = (radialSegments + 1) * j + (i - 1);
                var c:Int = (radialSegments + 1) * j + i;
                var d:Int = (radialSegments + 1) * (j - 1) + i;
                
                indices.push(a);
                indices.push(b);
                indices.push(d);
                
                indices.push(b);
                indices.push(c);
                indices.push(d);
            }
        }
        
        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    }
    
    function calculatePositionOnCurve(u:Float, p:Int, q:Int, radius:Float, position:Vector3) {
        var cu:Float = Math.cos(u);
        var su:Float = Math.sin(u);
        var quOverP:Float = q / p * u;
        var cs:Float = Math.cos(quOverP);
        
        position.x = radius * (2 + cs) * 0.5 * cu;
        position.y = radius * (2 + cs) * su * 0.5;
        position.z = radius * Math.sin(quOverP) * 0.5;
    }
    
    override public function copy(source:BufferGeometry):BufferGeometry {
        super.copy(source);
        this.parameters = {};
        for (field in Reflect.fields(source.parameters)) {
            Reflect.setField(this.parameters, field, Reflect.field(source.parameters, field));
        }
        return this;
    }
    
    static public function fromJSON(data:Dynamic):TorusKnotGeometry {
        return new TorusKnotGeometry(data.radius, data.tube, data.tubularSegments, data.radialSegments, data.p, data.q);
    }
}