import js.threejs.materials.Material;
import js.threejs.math.Color;

class LineBasicMaterial extends Material {
    public var isLineBasicMaterial: Bool;
    public var color: Color;
    public var map: Dynamic;
    public var linewidth: Float;
    public var linecap: String;
    public var linejoin: String;
    public var fog: Bool;

    public function new(parameters: { }) {
        super();
        this.isLineBasicMaterial = true;
        this.type = "LineBasicMaterial";
        this.color = new Color(0xffffff);
        this.map = null;
        this.linewidth = 1;
        this.linecap = "round";
        this.linejoin = "round";
        this.fog = true;
        this.setValues(parameters);
    }

    public function copy(source: LineBasicMaterial): LineBasicMaterial {
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

typedef LineBasicMaterialType = {
    isLineBasicMaterial: Bool,
    color: Color,
    map: Dynamic,
    linewidth: Float,
    linecap: String,
    linejoin: String,
    fog: Bool,
}

typedef LineBasicMaterialConstructor = {
    new (parameters: { }): LineBasicMaterialType;
}

var LineBasicMaterial: LineBasicMaterialConstructor;

export default LineBasicMaterial;