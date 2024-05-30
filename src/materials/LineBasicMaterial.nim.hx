import Material.Material;
import math.Color;

class LineBasicMaterial extends Material {

    public var isLineBasicMaterial:Bool = true;
    public var type:String = 'LineBasicMaterial';
    public var color:Color = new Color(0xffffff);
    public var map:Null<Dynamic> = null;
    public var linewidth:Float = 1;
    public var linecap:String = 'round';
    public var linejoin:String = 'round';
    public var fog:Bool = true;

    public function new(parameters:Dynamic) {
        super();
        this.setValues(parameters);
    }

    public function copy(source:LineBasicMaterial):LineBasicMaterial {
        super.copy(source);
        this.color.copy(source.color);
        this.map = source.map;
        this.linewidth = source.linewidth;
        this.linecap = source.linecap;
        this.linejoin = source.linejoin;
        this.fog = source.fog;
        return this;
    }

}

export class LineBasicMaterial;