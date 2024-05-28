import Material from './Material.hx';
import Color from '../math/Color.hx';

class PointsMaterial extends Material {
    public var isPointsMaterial:Bool = true;
    public var type:String = 'PointsMaterial';
    public var color:Color;
    public var map:Null<Dynamic>;
    public var alphaMap:Null<Dynamic>;
    public var size:Float;
    public var sizeAttenuation:Bool;
    public var fog:Bool;

    public function new(parameters:Null<Dynamic> = null) {
        super();
        color = new Color(0xffffff);
        size = 1;
        sizeAttenuation = true;
        fog = true;
        setValues(parameters);
    }

    public function copy(source:PointsMaterial):Void {
        super.copy(source);
        color.copy(source.color);
        map = source.map;
        alphaMap = source.alphaMap;
        size = source.size;
        sizeAttenuation = source.sizeAttenuation;
        fog = source.fog;
    }
}