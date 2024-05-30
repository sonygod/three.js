import js.QUnit;
import js.three.materials.MeshBasicMaterial;
import js.three.materials.Material;

class _Main {
    static function main() {
        QUnit.module('Materials', function() {
            QUnit.module('MeshBasicMaterial', function() {
                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var object = new MeshBasicMaterial();
                    assert.strictEqual(
                        Std.is(object, Material), true,
                        'MeshBasicMaterial extends from Material'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var object = new MeshBasicMaterial();
                    assert.ok(object, 'Can instantiate a MeshBasicMaterial.');
                });

                // PROPERTIES
                QUnit.test('type', function(assert) {
                    var object = new MeshBasicMaterial();
                    assert.ok(
                        object.type == 'MeshBasicMaterial',
                        'MeshBasicMaterial.type should be MeshBasicMaterial'
                    );
                });

                QUnit.todo('color', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('map', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('lightMap', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('lightMapIntensity', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('aoMap', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('aoMapIntensity', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('specularMap', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('alphaMap', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('envMap', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('combine', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('reflectivity', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('refractionRatio', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('wireframe', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('wireframeLinewidth', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('wireframeLinecap', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('wireframeLinejoin', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('fog', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isMeshBasicMaterial', function(assert) {
                    var object = new MeshBasicMaterial();
                    assert.ok(
                        object.isMeshBasicMaterial,
                        'MeshBasicMaterial.isMeshBasicMaterial should be true'
                    );
                });

                QUnit.todo('copy', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}