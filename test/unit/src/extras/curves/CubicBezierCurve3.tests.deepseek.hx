package three.test.unit.src.extras.curves;

import three.src.extras.curves.CubicBezierCurve3;
import three.src.extras.core.Curve;
import three.src.math.Vector3;
import haxe.unit.Test;

class CubicBezierCurve3Test extends Test {
    var curve:CubicBezierCurve3;

    public function new() {
        super();
        curve = new CubicBezierCurve3(
            new Vector3(-10, 0, 2),
            new Vector3(-5, 15, 4),
            new Vector3(20, 15, -5),
            new Vector3(10, 0, 10)
        );
    }

    public function testExtending() {
        var object = new CubicBezierCurve3();
        assert(object instanceof Curve);
    }

    public function testInstancing() {
        var object = new CubicBezierCurve3();
        assert(object != null);
    }

    public function testType() {
        var object = new CubicBezierCurve3();
        assert(object.type == "CubicBezierCurve3");
    }

    // ... 其他测试方法 ...
}