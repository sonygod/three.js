class QUnit {
    static function module(name:String, callback:Void->Void) {
        callback();
    }

    static function test(name:String, callback:Void->Void) {
        callback();
    }

    static function todo(name:String, callback:Void->Void) {
        // TODO: Implement this
    }
}

class LineCurve3 {
    public var v1:Vector3;
    public var v2:Vector3;
    public var isLineCurve3:Bool;

    public function new(v1:Vector3, v2:Vector3) {
        this.v1 = v1;
        this.v2 = v2;
        this.isLineCurve3 = true;
    }

    public function getPointAt(t:Float, optionalTarget:Vector3):Vector3 {
        // TODO: Implement this
        return null;
    }

    public function getPoints():Array<Vector3> {
        // TODO: Implement this
        return [];
    }

    public function getLength():Float {
        // TODO: Implement this
        return 0;
    }

    public function getLengths(segments:Int):Array<Float> {
        // TODO: Implement this
        return [];
    }

    public function getTangent(t:Float, optionalTarget:Vector3):Vector3 {
        // TODO: Implement this
        return null;
    }

    public function getTangentAt(t:Float):Vector3 {
        // TODO: Implement this
        return null;
    }

    public function computeFrenetFrames(segments:Int, closed:Bool):{tangents:Array<Vector3>, normals:Array<Vector3>, binormals:Array<Vector3>} {
        // TODO: Implement this
        return null;
    }

    public function getUtoTmapping(u:Float, distance:Float):Float {
        // TODO: Implement this
        return 0;
    }

    public function getSpacedPoints(divisions:Int):Array<Vector3> {
        // TODO: Implement this
        return [];
    }
}

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function new(x:Float, y:Float, z:Float) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
}

class Curve {
    // TODO: Implement this
}

class Main {
    static function main() {
        QUnit.module("Extras", function() {
            QUnit.module("Curves", function() {
                QUnit.module("LineCurve3", function(hooks) {
                    var _points:Array<Vector3>;
                    var _curve:LineCurve3;
                    hooks.before(function() {
                        _points = [
                            new Vector3(0, 0, 0),
                            new Vector3(10, 10, 10),
                            new Vector3(-10, 10, -10),
                            new Vector3(-8, 5, -7)
                        ];

                        _curve = new LineCurve3(_points[0], _points[1]);
                    });

                    // INHERITANCE
                    QUnit.test("Extending", function(assert) {
                        var object = new LineCurve3(_points[0], _points[1]);
                        assert.strictEqual(object instanceof Curve, true, "LineCurve3 extends from Curve");
                    });

                    // INSTANCING
                    QUnit.test("Instancing", function(assert) {
                        var object = new LineCurve3(_points[0], _points[1]);
                        assert.ok(object, "Can instantiate a LineCurve3.");
                    });

                    // PROPERTIES
                    QUnit.test("type", function(assert) {
                        var object = new LineCurve3(_points[0], _points[1]);
                        assert.ok(object.type == "LineCurve3", "LineCurve3.type should be LineCurve3");
                    });

                    // TODO: Implement the rest of the tests
                });
            });
        });
    }
}