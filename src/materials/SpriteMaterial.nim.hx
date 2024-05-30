import three.js.src.materials.Material;
import three.js.src.math.Color;

class SpriteMaterial extends Material {

    public var isSpriteMaterial:Bool = true;

    public var type:String = 'SpriteMaterial';

    public var color:Color = new Color(0xffffff);

    public var map:Null<Dynamic> = null;

    public var alphaMap:Null<Dynamic> = null;

    public var rotation:Float = 0;

    public var sizeAttenuation:Bool = true;

    public var transparent:Bool = true;

    public var fog:Bool = true;

    public function new(parameters:Dynamic) {
        super();
        this.setValues(parameters);
    }

    public function copy(source:SpriteMaterial):SpriteMaterial {
        super.copy(source);
        this.color.copy(source.color);
        this.map = source.map;
        this.alphaMap = source.alphaMap;
        this.rotation = source.rotation;
        this.sizeAttenuation = source.sizeAttenuation;
        this.fog = source.fog;
        return this;
    }

}

export haxe.macro.Type.createInstance(SpriteMaterial, []);