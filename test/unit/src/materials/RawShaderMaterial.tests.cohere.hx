import js.QUnit;
import js.RawShaderMaterial;
import js.ShaderMaterial;

class _Main {
    static function main() {
        QUnit.module('Materials', function() {
            QUnit.module('RawShaderMaterial', function() {
                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var object = new RawShaderMaterial();
                    assert.strictEqual(
                        Std.is(object, ShaderMaterial), true,
                        'RawShaderMaterial extends from ShaderMaterial'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var object = new RawShaderMaterial();
                    assert.ok(object, 'Can instantiate a RawShaderMaterial.');
                });

                // PROPERTIES
                QUnit.test('type', function(assert) {
                    var object = new RawShaderMaterial();
                    assert.ok(
                        object.type == 'RawShaderMaterial',
                        'RawShaderMaterial.type should be RawShaderMaterial'
                    );
                });

                // PUBLIC
                QUnit.test('isRawShaderMaterial', function(assert) {
                    var object = new RawShaderMaterial();
                    assert.ok(
                        object.isRawShaderMaterial,
                        'RawShaderMaterial.isRawShaderMaterial should be true'
                    );
                });
            });
        });
    }
}