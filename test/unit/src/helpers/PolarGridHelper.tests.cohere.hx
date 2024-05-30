import js.QUnit;
import js.PolarGridHelper;
import js.LineSegments;

class PolarGridHelperTest {
    static function extending() {
        var object = new PolarGridHelper();
        var result = Std.is(object, LineSegments);
        Js.console.log(result);
        Js.console.log(result == true);
        QUnit.ok(result, "PolarGridHelper extends from LineSegments");
    }

    static function instantiating() {
        var object = new PolarGridHelper();
        QUnit.ok(object != null, "Can instantiate a PolarGridHelper.");
    }

    static function type() {
        var object = new PolarGridHelper();
        var result = object.getType();
        QUnit.ok(result == "PolarGridHelper", "PolarGridHelper.type should be PolarGridHelper");
    }

    static function dispose() {
        var object = new PolarGridHelper();
        object.dispose();
    }
}

class PolarGridHelperModule {
    static function run() {
        QUnit.module("Helpers", function() {
            QUnit.module("PolarGridHelper", function() {
                PolarGridHelperTest.extending();
                PolarGridHelperTest.instantiating();
                PolarGridHelperTest.type();
                PolarGridHelperTest.dispose();
            });
        });
    }
}

PolarGridHelperModule.run();