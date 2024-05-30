package three.js.test.unit.src.math.interpolants;

import three.js.math.interpolants.LinearInterpolant;
import three.js.math.Interpolant;

class LinearInterpolantTests {

    public static function main() {
        utest.TestSuite.create("Maths", () => {
            utest.TestSuite.create("Interpolants", () => {
                utest.TestSuite.create("LinearInterpolant", () => {

                    // INHERITANCE
                    utest.Test.create("Extending", () => {
                        var object = new LinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        utest.Assert.isTrue(object instanceof Interpolant, "LinearInterpolant extends from Interpolant");
                    });

                    // INSTANCING
                    utest.Test.create("Instancing", () => {
                        // parameterPositions, sampleValues, sampleSize, resultBuffer
                        var object = new LinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        utest.Assert.notNull(object, "Can instantiate a LinearInterpolant.");
                    });

                    // PRIVATE - TEMPLATE METHODS
                    utest.Test.create("interpolate_", () => {
                        // Not implemented, todo!
                    });

                });
            });
        });
    }

}