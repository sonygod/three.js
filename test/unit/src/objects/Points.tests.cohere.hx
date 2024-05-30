import js.QUnit;
import js.Object3D;
import js.Material;
import js.Points;

class PointsTest {
    static function main() {
        QUnit.module('Objects', {
            beforeEach: function() {},
            afterEach: function() {}
        });

        QUnit.module('Points', {
            beforeEach: function() {},
            afterEach: function() {}
        });

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var points = new Points();
            assert.strictEqual(points instanceof Object3D, true, 'Points extends from Object3D');
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var object = new Points();
            assert.ok(object, 'Can instantiate a Points');
        });

        // PROPERTIES
        QUnit.test('type', function(assert) {
            var object = new Points();
            assert.ok(object.type == 'Points', 'Points.type should be Points');
        });

        QUnit.todo('geometry', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('material', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test('isPoints', function(assert) {
            var object = new Points();
            assert.ok(object.isPoints, 'Points.isPoints should be true');
        });

        QUnit.todo('copy', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('copy/material', function(assert) {
            // Material arrays are cloned
            var mesh1 = new Points();
            mesh1.material = [new Material()];

            var copy1 = mesh1.clone();
            assert.notStrictEqual(mesh1.material, copy1.material);

            // Non arrays are not cloned
            var mesh2 = new Points();
            mesh1.material = new Material();
            var copy2 = mesh2.clone();
            assert.strictEqual(mesh2.material, copy2.material);
        });

        QUnit.todo('raycast', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('updateMorphTargets', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}