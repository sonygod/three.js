import three.geometries.PolyhedronGeometry;

class TetrahedronGeometry extends PolyhedronGeometry {

    public function new(radius:Float = 1, detail:Int = 0) {
        var vertices = [
            1, 1, 1, 	- 1, - 1, 1, 	- 1, 1, - 1, 	1, - 1, - 1
        ];

        var indices = [
            2, 1, 0, 	0, 3, 2,	1, 3, 0,	2, 3, 1
        ];

        super(vertices, indices, radius, detail);

        this.type = "TetrahedronGeometry";

        this.parameters = {
            radius: radius,
            detail: detail
        };
    }

    public static function fromJSON(data:Dynamic):TetrahedronGeometry {
        return new TetrahedronGeometry(data.radius, data.detail);
    }
}