package three.extras.curves;

import three.extras.curves.ArcCurve;
import three.extras.curves.EllipseCurve;

class ArcCurveTests {
    public static function main() {
        // Note: In Haxe, there is no direct equivalent to QUnit, so I've adapted the code to use Haxe's built-in unit testing framework
        utest.UTest.run([
            new utest.Test({
                name: "Extras.Curves.ArcCurve",
                tests: [
                    new utest.Test({
                        name: "Inheritance",
                        exec: function(t: utest.Async) {
                            var object = new ArcCurve();
                            t.assertTrue(Std.is(object, EllipseCurve), "ArcCurve extends from EllipseCurve");
                            t.done();
                        }
                    }),
                    new utest.Test({
                        name: "Instancing",
                        exec: function(t: utest.Async) {
                            var object = new ArcCurve();
                            t.assertNotNull(object, "Can instantiate an ArcCurve.");
                            t.done();
                        }
                    }),
                    new utest.Test({
                        name: "Properties",
                        exec: function(t: utest.Async) {
                            var object = new ArcCurve();
                            t.assertEquals(object.type, "ArcCurve", "ArcCurve.type should be ArcCurve");
                            t.done();
                        }
                    }),
                    new utest.Test({
                        name: "Public",
                        exec: function(t: utest.Async) {
                            var object = new ArcCurve();
                            t.assertTrue(object.isArcCurve, "ArcCurve.isArcCurve should be true");
                            t.done();
                        }
                    })
                ]
            })
        ]);
    }
}