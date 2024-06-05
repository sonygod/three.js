import qunit.QUnit;
import three.core.Object3D;
import three.objects.Mesh;
import three.objects.SkinnedMesh;
import three.constants.AttachedBindMode;

class SkinnedMeshTest {

	static function main() {
		QUnit.module("Objects", function() {
			QUnit.module("SkinnedMesh", function() {

				// INHERITANCE
				QUnit.test("Extending", function(assert) {
					var skinnedMesh = new SkinnedMesh();

					assert.strictEqual(skinnedMesh instanceof Object3D, true, "SkinnedMesh extends from Object3D");
					assert.strictEqual(skinnedMesh instanceof Mesh, true, "SkinnedMesh extends from Mesh");
				});

				// INSTANCING
				QUnit.test("Instancing", function(assert) {
					var object = new SkinnedMesh();
					assert.ok(object, "Can instantiate a SkinnedMesh.");
				});

				// PROPERTIES
				QUnit.test("type", function(assert) {
					var object = new SkinnedMesh();
					assert.ok(object.type == "SkinnedMesh", "SkinnedMesh.type should be SkinnedMesh");
				});

				QUnit.test("bindMode", function(assert) {
					var object = new SkinnedMesh();
					assert.ok(object.bindMode == AttachedBindMode, "SkinnedMesh.bindMode should be AttachedBindMode");
				});

				QUnit.todo("bindMatrix", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				QUnit.todo("bindMatrixInverse", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				// PUBLIC
				QUnit.test("isSkinnedMesh", function(assert) {
					var object = new SkinnedMesh();
					assert.ok(object.isSkinnedMesh, "SkinnedMesh.isSkinnedMesh should be true");
				});

				QUnit.todo("copy", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				QUnit.todo("bind", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				QUnit.todo("pose", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				QUnit.todo("normalizeSkinWeights", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				QUnit.todo("updateMatrixWorld", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				QUnit.todo("applyBoneTransform", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});
			});
		});
	}
}

SkinnedMeshTest.main();