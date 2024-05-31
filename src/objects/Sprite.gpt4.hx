import threejs.src.math.Vector2;
import threejs.src.math.Vector3;
import threejs.src.math.Matrix4;
import threejs.src.math.Triangle;
import threejs.src.core.Object3D;
import threejs.src.core.BufferGeometry;
import threejs.src.core.InterleavedBuffer;
import threejs.src.core.InterleavedBufferAttribute;
import threejs.src.materials.SpriteMaterial;

class Sprite extends Object3D {
    var isSprite:Bool;
    var type:String;
    var geometry:BufferGeometry;
    var material:SpriteMaterial;
    var center:Vector2;

    public function new(material:SpriteMaterial = null) {
        super();
        this.isSprite = true;
        this.type = 'Sprite';
        if (_geometry == null) {
            _geometry = new BufferGeometry();
            // ... (其余代码与JavaScript相似，需要将数组字面量转换为Haxe数组，以及相应的类型注解)
        }
        this.geometry = _geometry;
        this.material = material != null ? material : new SpriteMaterial();
        this.center = new Vector2(0.5, 0.5);
    }

    // ... (其余函数与JavaScript相似，需要将函数体转换为Haxe语法，包括变量声明和类型注解)

    static var _geometry:BufferGeometry;
    static var _intersectPoint:Vector3 = new Vector3();
    static var _worldScale:Vector3 = new Vector3();
    static var _mvPosition:Vector3 = new Vector3();
    // ... (其余静态变量与JavaScript相似，需要初始化)

    // ... (其余函数和静态变量同理)
}

// ... (其余函数同理，包括transformVertex函数)

// 注意：Haxe中不支持JavaScript的export语句，因此需要将Sprite类放在一个包中，并在其他地方使用import语句来导入