package three.math.interpolants;

import three.math.CubicInterpolant;
import three.math.Interpolant;

class CubicInterpolantTests {

    public function new() {}

    public function testAll() {
        MathsTests.test("Interpolants", () => {
            InterpolantsTests.test("CubicInterpolant", () => {
                // INHERITANCE
                TestAssert.test("Extending", () => {
                    var object = new CubicInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                    Assert.isTrue(object instanceof Interpolant, "CubicInterpolant extends from Interpolant");
                });

                // INSTANCING
                TestAssert.test("Instancing", () => {
                    // parameterPositions, sampleValues, sampleSize, resultBuffer
                    var object = new CubicInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                    Assert.notNull(object, "Can instantiate a CubicInterpolant.");
                });

                // PRIVATE - TEMPLATE METHODS
                TestAssert.todo("intervalChanged_", () => {
                    // intervalChanged_( i1, t0, t1 )
                    Assert.fail("everything's gonna be alright");
                });

                TestAssert.todo("interpolate_", () => {
                    // interpolate_( i1, t0, t, t1 )
                    // return equal to base class Interpolant.resultBuffer after call
                    Assert.fail("everything's gonna be alright");
                });
            });
        });
    }
}