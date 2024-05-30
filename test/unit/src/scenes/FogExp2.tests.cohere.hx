import js.QUnit;

class FogExp2 {
    public function new(?color:Int, ?density:Float) {
    }

    public function isFogExp2():Bool {
        return true;
    }
}

@:expose
class Main {
    static function main() {
        var object = new FogExp2();
        var object_color = new FogExp2(0xFFFFFF);
        var object_all = new FogExp2(0xFFFFFF, 0.00030);

        var ok1 = (object != null);
        var ok2 = (object_color != null);
        var ok3 = (object_all != null);

        var isFogExp2 = object.isFogExp2();

        QUnit.module("Scenes", function() {
            QUnit.module("FogExp2", function() {
                QUnit.test("Instancing", function(assert) {
                    assert.ok(ok1, "Can instantiate a FogExp2.");
                    assert.ok(ok2, "Can instantiate a FogExp2 with color.");
                    assert.ok(ok3, "Can instantiate a FogExp2 with color, density.");
                });

                QUnit.test("isFogExp2", function(assert) {
                    assert.ok(isFogExp2, "FogExp2.isFogExp2 should be true");
                });
            });
        });
    }
}