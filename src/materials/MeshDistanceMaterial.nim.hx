import three.js.src.materials.Material;

class MeshDistanceMaterial extends Material {

    public var isMeshDistanceMaterial:Bool = true;

    public var type:String = 'MeshDistanceMaterial';

    public var map:Null<Dynamic> = null;

    public var alphaMap:Null<Dynamic> = null;

    public var displacementMap:Null<Dynamic> = null;
    public var displacementScale:Float = 1;
    public var displacementBias:Float = 0;

    public function new(parameters:Dynamic) {

        super();

        this.isMeshDistanceMaterial = true;

        this.type = 'MeshDistanceMaterial';

        this.map = null;

        this.alphaMap = null;

        this.displacementMap = null;
        this.displacementScale = 1;
        this.displacementBias = 0;

        this.setValues(parameters);

    }

    public function copy(source:MeshDistanceMaterial):MeshDistanceMaterial {

        super.copy(source);

        this.map = source.map;

        this.alphaMap = source.alphaMap;

        this.displacementMap = source.displacementMap;
        this.displacementScale = source.displacementScale;
        this.displacementBias = source.displacementBias;

        return this;

    }

}

export class Main {
    public static function main() {
        trace(new MeshDistanceMaterial({}));
    }
}