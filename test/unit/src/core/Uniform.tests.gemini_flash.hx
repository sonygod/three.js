import qunit.QUnit;
import three.core.Uniform;
import three.math.Vector3;
import three.utils.MathConstants;

class UniformTest {
	static function main() {
		QUnit.module("Core", function() {
			QUnit.module("Uniform", function() {
				QUnit.test("Instancing", function(assert) {
					var a:Uniform;
					var b = new Vector3(MathConstants.x, MathConstants.y, MathConstants.z);

					a = new Uniform(5);
					assert.strictEqual(a.value, 5, "New constructor works with simple values");

					a = new Uniform(b);
					assert.ok(a.value.equals(b), "New constructor works with complex values");
				});

				QUnit.todo("value", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				QUnit.test("clone", function(assert) {
					var a = new Uniform(23);
					var b = a.clone();

					assert.strictEqual(b.value, a.value, "clone() with simple values works");

					a = new Uniform(new Vector3(1, 2, 3));
					b = a.clone();

					assert.ok(b.value.equals(a.value), "clone() with complex values works");
				});
			});
		});
	}
}

class Main {
	static function main() {
		UniformTest.main();
	}
}