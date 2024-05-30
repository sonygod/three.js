import Material.Material;
import Color.Color;

class PointsMaterial extends Material {

    public var isPointsMaterial:Bool = true;
    public var type:String = 'PointsMaterial';
    public var color:Color = new Color(0xffffff);
    public var map:Null<Dynamic> = null;
    public var alphaMap:Null<Dynamic> = null;
    public var size:Float = 1;
    public var sizeAttenuation:Bool = true;
    public var fog:Bool = true;

    public function new(parameters:Null<Dynamic>) {
        super();
        this.setValues(parameters);
    }

    public function copy(source:PointsMaterial):PointsMaterial {
        super.copy(source);
        this.color.copy(source.color);
        this.map = source.map;
        this.alphaMap = source.alphaMap;
        this.size = source.size;
        this.sizeAttenuation = source.sizeAttenuation;
        this.fog = source.fog;
        return this;
    }

}

export class Main {
    public static function main() {
        var pointsMaterial = new PointsMaterial(null);
    }
}