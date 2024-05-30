import js.QUnit;
import Uniform from "../../../../src/core/Uniform.hx";
import Vector3 from "../../../../src/math/Vector3.hx";
import { x, y, z } from "../../utils/math_constants.hx";

class _Main {
    static main() {
        var module = QUnit.module("Core");
        var module1 = module.module("Uniform");
        var test = module1.test("Instancing");
        var a = null;
        var b = new Vector3(x, y, z);
        a = new Uniform(5);
        test.strictEqual(a.value, 5, "New constructor works with simple values");
        a = new Uniform(b);
        test.ok(a.value.equals(b), "New constructor works with complex values");
        var test1 = module1.todo("value");
        test1.ok(false, "everything's gonna be alright");
        var test2 = module1.test("clone");
        var a1 = new Uniform(23);
        var b1 = a1.clone();
        test2.strictEqual(b1.value, a1.value, "clone() with simple values works");
        var a2 = new Uniform(new Vector3(1, 2, 3));
        var b2 = a2.clone();
        test2.ok(b2.value.equals(a2.value), "clone() with complex values works");
    }
}