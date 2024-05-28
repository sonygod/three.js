Here is the equivalent Haxe code:
```
package three.js.src.geometries;

import three.js.src.geometries.PolyhedronGeometry;

class OctahedronGeometry extends PolyhedronGeometry {
    public function new(radius:Float = 1, detail:Int = 0) {
        var vertices:Array<Float> = [
            1, 0, 0, -1, 0, 0, 0, 1, 0,
            0, -1, 0, 0, 0, 1, 0, 0, -1
        ];

        var indices:Array<Int> = [
            0, 2, 4, 0, 4, 3, 0, 3, 5,
            0, 5, 2, 1, 2, 5, 1, 5, 3,
            1, 3, 4, 1, 4, 2
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
```
Note that I've made the following assumptions:

* I've used the `Float` type for the `radius` parameter, as it's a floating-point value.
* I've used the `Int` type for the `detail` parameter, as it's an integer value.
* I've used the `Array<Float>` type for the `vertices` array, as it contains floating-point values.
* I've used the `Array<Int>` type for the `indices` array, as it contains integer values.
* I've used the `Dynamic` type for the `data` parameter in the `fromJSON` method, as it can contain arbitrary data.

Please let me know if these assumptions are correct or if you need any further adjustments!