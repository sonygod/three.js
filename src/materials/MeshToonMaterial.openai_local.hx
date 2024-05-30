以下是将给定的 JavaScript 代码转换为 Haxe 代码的版本：

```haxe
import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;
import three.math.Color;

class MeshToonMaterial extends Material {

    public var isMeshToonMaterial:Bool;
    public var defines:Dynamic;
    public var type:String;

    public var color:Color;
    public var map:Dynamic;
    public var gradientMap:Dynamic;

    public var lightMap:Dynamic;
    public var lightMapIntensity:Float;

    public var aoMap:Dynamic;
    public var aoMapIntensity:Float;

    public var emissive:Color;
    public var emissiveIntensity:Float;
    public var emissiveMap:Dynamic;

    public var bumpMap:Dynamic;
    public var bumpScale:Float;

    public var normalMap:Dynamic;
    public var normalMapType:Int;
    public var normalScale:Vector2;

    public var displacementMap:Dynamic;
    public var displacementScale:Float;
    public var displacementBias:Float;

    public var alphaMap:Dynamic;

    public var wireframe:Bool;
    public var wireframeLinewidth:Float;
    public var wireframeLinecap:String;
    public var wireframeLinejoin:String;

    public var fog:Bool;

    public function new(parameters:Dynamic) {
        super();
        
        this.isMeshToonMaterial = true;
        this.defines = { 'TOON': '' };
        this.type = 'MeshToonMaterial';

        this.color = new Color(0xffffff);

        this.map = null;
        this.gradientMap = null;

        this.lightMap = null;
        this.lightMapIntensity = 1.0;

        this.aoMap = null;
        this.aoMapIntensity = 1.0;

        this.emissive = new Color(0x000000);
        this.emissiveIntensity = 1.0;
        this.emissiveMap = null;

        this.bumpMap = null;
        this.bumpScale = 1;

        this.normalMap = null;
        this.normalMapType = TangentSpaceNormalMap;
        this.normalScale = new Vector2(1, 1);

        this.displacementMap = null;
        this.displacementScale = 1;
        this.displacementBias = 0;

        this.alphaMap = null;

        this.wireframe = false;
        this.wireframeLinewidth = 1;
        this.wireframeLinecap = 'round';
        this