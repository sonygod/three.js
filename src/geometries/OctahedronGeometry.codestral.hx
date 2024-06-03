import three.geometries.PolyhedronGeometry;

class OctahedronGeometry extends PolyhedronGeometry {

    public function new(radius:Float = 1.0, detail:Int = 0) {
        super(radius, detail);

        this.type = 'OctahedronGeometry';
        this.parameters = { radius: radius, detail: detail };
    }

    override public function createVertices():Array<Float> {
        return [
            1, 0, 0, -1, 0, 0, 0, 1, 0,
            0, -1, 0, 0, 0, 1, 0, 0, -1
        ];
    }

    override public function createIndices():Array<Int> {
        return [
            0, 2, 4, 0, 4, 3, 0, 3, 5,
            0, 5, 2, 1, 2, 5, 1, 5, 3,
            1, 3, 4, 1, 4, 2
        ];
    }

    public static function fromJSON(data:Dynamic):OctahedronGeometry {
        return new OctahedronGeometry(data.radius, data.detail);
    }
}