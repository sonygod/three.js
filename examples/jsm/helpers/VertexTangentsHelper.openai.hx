package three.js.examples.jsm.helpers;

import three.js.BufferGeometry;
import three.js.Float32BufferAttribute;
import three.js.LineSegments;
import three.js.LineBasicMaterial;
import three.js.Vector3;

class VertexTangentsHelper extends LineSegments {
    
    public var object:Dynamic;
    public var size:Float;
    public var type:String;

    public function new(object:Dynamic, size:Float = 1, color:Int = 0x00ffff) {
        var geometry:BufferGeometry = new BufferGeometry();
        
        var nTangents:Int = object.geometry.attributes.tangent.count;
        var positions:Float32BufferAttribute = new Float32BufferAttribute(nTangents * 2 * 3, 3);
        
        geometry.setAttribute("position", positions);
        
        super(geometry, new LineBasicMaterial({ color: color, toneMapped: false }));
        
        this.object = object;
        this.size = size;
        this.type = "VertexTangentsHelper";
        
        matrixAutoUpdate = false;
        
        update();
    }
    
    public function update():Void {
        object.updateMatrixWorld(true);
        
        var matrixWorld:Matrix4 = object.matrixWorld;
        
        var position:Float32BufferAttribute = geometry.attributes.position;
        
        var objGeometry:Geometry = object.geometry;
        var objPos:Float32BufferAttribute = objGeometry.attributes.position;
        var objTan:Float32BufferAttribute = objGeometry.attributes.tangent;
        
        var _v1:Vector3 = new Vector3();
        var _v2:Vector3 = new Vector3();
        
        var idx:Int = 0;
        
        for (j in 0...objPos.count) {
            _v1.fromBufferAttribute(objPos, j).applyMatrix4(matrixWorld);
            _v2.fromBufferAttribute(objTan, j);
            _v2.transformDirection(matrixWorld).multiplyScalar(size).add(_v1);
            
            position.setXYZ(idx, _v1.x, _v1.y, _v1.z);
            idx++;
            position.setXYZ(idx, _v2.x, _v2.y, _v2.z);
            idx++;
        }
        
        position.needsUpdate = true;
    }
    
    public function dispose():Void {
        geometry.dispose();
        material.dispose();
    }
}