package three.materials;

import three.materials.LineBasicMaterial;

class LineDashedMaterial extends LineBasicMaterial {
    public var isLineDashedMaterial:Bool = true;
    public var type:String = 'LineDashedMaterial';
    public var scale:Float = 1;
    public var dashSize:Float = 3;
    public var gapSize:Float = 1;

    public function new(parameters:Dynamic = null) {
        super();
        if (parameters != null) {
            setValues(parameters);
        }
    }

    public function copy(source:LineDashedMaterial):LineDashedMaterial {
        super.copy(source);
        scale = source.scale;
        dashSize = source.dashSize;
        gapSize = source.gapSize;
        return this;
    }
}