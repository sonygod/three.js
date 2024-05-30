import js.js_math.QuaternionLinearInterpolant;
import js.js_math.Interpolant;

class Main {
    static function main() {
        var object = new QuaternionLinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);

        var isInstanceOfInterpolant = (object instanceof Interpolant);
        trace(isInstanceOfInterpolant); // expected true

        var isObjectInstantiated = (object != null);
        trace(isObjectInstantiated); // expected true
    }
}