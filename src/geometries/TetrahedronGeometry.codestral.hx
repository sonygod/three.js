import three.geometries.PolyhedronGeometry;

class TetrahedronGeometry extends PolyhedronGeometry {

    public function new(radius:Float = 1, detail:Int = 0) {
        super(getVertices(radius), getIndices(), radius, detail);

        this.type = 'TetrahedronGeometry';

        this.parameters = {
            radius: radius,
            detail: detail
        };
    }

    private function getVertices(radius:Float):Array<Float> {
        return [
            1 * radius, 1 * radius, 1 * radius, -1 * radius, -1 * radius, 1 * radius, -1 * radius, 1 * radius, -1 * radius, 1 * radius, -1 * radius, -1 * radius
        ];
    }

    private function getIndices():Array<Int> {
        return [
            2, 1, 0, 0, 3, 2, 1, 3, 0, 2, 3, 1
        ];
    }

    public static function fromJSON(data:Dynamic):TetrahedronGeometry {
        return new TetrahedronGeometry(data.radius, data.detail);
    }
}