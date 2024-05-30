import three.materials.Material;
import three.math.Color;

class SpriteMaterial extends Material {

    public var isSpriteMaterial:Bool;
    public var type:String;
    public var color:Color;
    public var map:Dynamic;
    public var alphaMap:Dynamic;
    public var rotation:Float;
    public var sizeAttenuation:Bool;
    public var fog:Bool;

    public function new(parameters:Dynamic = null) {
        super();

        this.isSpriteMaterial = true;
        this.type = "SpriteMaterial";
        this.color = new Color(0xffffff);
        this.map = null;
        this.alphaMap = null;
        this.rotation = 0;
        this.sizeAttenuation = true;
        this.transparent = true;
        this.fog = true;

        this.setValues(parameters);
    }

    public override function copy(source:Material):SpriteMaterial {
        super.copy(source);

        var spriteSource:SpriteMaterial = cast source;
        this.color.copy(spriteSource.color);
        this.map = spriteSource.map;
        this.alphaMap = spriteSource.alphaMap;
        this.rotation = spriteSource.rotation;
        this.sizeAttenuation = spriteSource.sizeAttenuation;
        this.fog = spriteSource.fog;

        return this;
    }

    private function setValues(parameters:Dynamic):Void {
        // Implement this function according to how 'setValues' is implemented in the original Material class
    }

}