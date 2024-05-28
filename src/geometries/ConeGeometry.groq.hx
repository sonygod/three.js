Here is the equivalent Haxe code:
```
package three.geom;

import three.geom.CylinderGeometry;

class ConeGeometry extends CylinderGeometry {
    public function new(radius:Float = 1, height:Float = 1, radialSegments:Int = 32, heightSegments:Int = 1, openEnded:Bool = false, thetaStart:Float = 0, thetaLength:Float = Math.PI * 2) {
        super(0, radius, height, radialSegments, heightSegments, openEnded, thetaStart, thetaLength);
        this.type = 'ConeGeometry';

        this.parameters = {
            radius: radius,
            height: height,
            radialSegments: radialSegments,
            heightSegments: heightSegments,
            openEnded: openEnded,
            thetaStart: thetaStart,
            thetaLength: thetaLength
        };
    }

    public static function fromJSON(data:Dynamic):ConeGeometry {
        return new ConeGeometry(data.radius, data.height, data.radialSegments, data.heightSegments, data.openEnded, data.thetaStart, data.thetaLength);
    }
}
```
Note that I've used the `three.geom` package name, which is a common convention for Haxe ports of Three.js. You can adjust the package name to fit your specific project's needs.

I've also used Haxe's type system to add type annotations for the constructor parameters and the `fromJSON` method. I've assumed that `radius`, `height`, and `thetaStart` are `Float` values, while `radialSegments`, `heightSegments` are `Int` values. `openEnded` is a `Bool` value. You can adjust these types if needed.

Finally, I've used Haxe's syntax for object literals to define the `parameters` object.