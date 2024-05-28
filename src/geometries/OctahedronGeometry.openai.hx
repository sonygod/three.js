package three.geom;

import three.geom.PolyhedronGeometry;

class OctahedronGeometry extends PolyhedronGeometry {
    
    public function new(?radius:Float = 1, ?detail:Int = 0) {
        var vertices:Array<Float> = [
            1, 0, 0, 
            -1, 0, 0, 
            0, 1, 0, 
            0, -1, 0, 
            0, 0, 1, 
            0, 0, -1
        ];

        var indices:Array<Int> = [
            0, 2, 4, 
            0, 4, 3, 
            0, 3, 5, 
            0, 5, 2, 
            1, 2, 5, 
            1, 5, 3, 
            1, 3, 4, 
            1, 4, 2
        ];

        super(vertices, indices, radius, detail);

        this.type = 'OctahedronGeometry';

        this.parameters = {
            radius: radius,
            detail: detail
        };
    }

    public static function fromJSON(data:Dynamic):OctahedronGeometry {
        return new OctahedronGeometry(data.radius, data.detail);
    }
}