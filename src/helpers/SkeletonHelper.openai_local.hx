import three.objects.LineSegments;
import three.math.Matrix4;
import three.materials.LineBasicMaterial;
import three.math.Color;
import three.math.Vector3;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;

class SkeletonHelper extends LineSegments {

    private var root:Dynamic;
    private var bones:Array<Dynamic>;

    private static var _vector:Vector3 = new Vector3();
    private static var _boneMatrix:Matrix4 = new Matrix4();
    private static var _matrixWorldInv:Matrix4 = new Matrix4();

    public function new(object:Dynamic) {
        var bones = getBoneList(object);
        
        var geometry = new BufferGeometry();
        var vertices = [];
        var colors = [];
        
        var color1 = new Color(0, 0, 1);
        var color2 = new Color(0, 1, 0);
        
        for (i in 0...bones.length) {
            var bone = bones[i];
            
            if (bone.parent != null && bone.parent.isBone) {
                vertices.push(0, 0, 0);
                vertices.push(0, 0, 0);
                colors.push(color1.r, color1.g, color1.b);
                colors.push(color2.r, color2.g, color2.b);
            }
        }
        
        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));
        
        var material = new LineBasicMaterial({
            vertexColors: true, 
            depthTest: false, 
            depthWrite: false, 
            toneMapped: false, 
            transparent: true
        });
        
        super(geometry, material);
        
        this.isSkeletonHelper = true;
        this.type = 'SkeletonHelper';
        this.root = object;
        this.bones = bones;
        this.matrix = object.matrixWorld;
        this.matrixAutoUpdate = false;
    }

    public function updateMatrixWorld(force:Bool) {
        var bones = this.bones;
        var geometry = this.geometry;
        var position = geometry.getAttribute('position');
        
        _matrixWorldInv.copy(this.root.matrixWorld).invert();
        
        for (i in 0...bones.length) {
            var bone = bones[i];
            
            if (bone.parent != null && bone.parent.isBone) {
                _boneMatrix.multiplyMatrices(_matrixWorldInv, bone.matrixWorld);
                _vector.setFromMatrixPosition(_boneMatrix);
                position.setXYZ(j, _vector.x, _vector.y, _vector.z);
                
                _boneMatrix.multiplyMatrices(_matrixWorldInv, bone.parent.matrixWorld);
                _vector.setFromMatrixPosition(_boneMatrix);
                position.setXYZ(j + 1, _vector.x, _vector.y, _vector.z);
                
                j += 2;
            }
        }
        
        geometry.getAttribute('position').needsUpdate = true;
        
        super.updateMatrixWorld(force);
    }

    public function dispose() {
        this.geometry.dispose();
        this.material.dispose();
    }

    private static function getBoneList(object:Dynamic):Array<Dynamic> {
        var boneList:Array<Dynamic> = [];
        
        if (object.isBone) {
            boneList.push(object);
        }
        
        for (i in 0...object.children.length) {
            boneList.pushAll(getBoneList(object.children[i]));
        }
        
        return boneList;
    }

    public var isSkeletonHelper:Bool;
    public var type:String;
}