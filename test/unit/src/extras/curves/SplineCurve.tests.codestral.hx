import qunit.QUnit;
import three.extras.curves.SplineCurve;
import three.extras.core.Curve;
import three.math.Vector2;

class SplineCurveTests {
    private var _curve:SplineCurve;

    @:before
    private function before():Void {
        _curve = new SplineCurve([
            new Vector2(-10, 0),
            new Vector2(-5, 5),
            new Vector2(0, 0),
            new Vector2(5, -5),
            new Vector2(10, 0)
        ]);
    }

    @:test
    public function extending(assert:qunit.Assert):Void {
        var object = new SplineCurve();
        assert.eq(Std.is(object, Curve), true, 'SplineCurve extends from Curve');
    }

    @:test
    public function instancing(assert:qunit.Assert):Void {
        var object = new SplineCurve();
        assert.isTrue(object != null, 'Can instantiate a SplineCurve.');
    }

    @:test
    public function type(assert:qunit.Assert):Void {
        var object = new SplineCurve();
        assert.eq(object.type, 'SplineCurve', 'SplineCurve.type should be SplineCurve');
    }

    @:test
    public function isSplineCurve(assert:qunit.Assert):Void {
        var object = new SplineCurve();
        assert.isTrue(object.isSplineCurve, 'SplineCurve.isSplineCurve should be true');
    }

    // ... Add other tests as per your JavaScript code ...
}