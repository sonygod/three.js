package three.js.test.unit.src.animation;

import three.js.src.animation.PropertyBinding;
import three.js.src.geometries.BoxGeometry;
import three.js.src.objects.Mesh;
import three.js.src.materials.MeshBasicMaterial;
import js.Lib;

class PropertyBindingTests {
    static function main() {
        QUnit.module('Animation', () -> {
            QUnit.module('PropertyBinding', () -> {
                QUnit.test('Instancing', (assert) -> {
                    var geometry = new BoxGeometry();
                    var material = new MeshBasicMaterial();
                    var mesh = new Mesh(geometry, material);
                    var path = ".material.opacity";
                    var parsedPath = {
                        nodeName: "",
                        objectName: "material",
                        objectIndex: null,
                        propertyName: "opacity",
                        propertyIndex: null
                    };

                    var object = new PropertyBinding(mesh, path);
                    assert.ok(object, 'Can instantiate a PropertyBinding.');

                    var object_all = new PropertyBinding(mesh, path, parsedPath);
                    assert.ok(object_all, 'Can instantiate a PropertyBinding with mesh, path, and parsedPath.');
                });

                QUnit.todo('Composite', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('create', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test('sanitizeNodeName', (assert) -> {
                    assert.equal(
                        PropertyBinding.sanitizeNodeName('valid-name-123_'),
                        'valid-name-123_',
                        'Leaves valid name intact.'
                    );

                    assert.equal(
                        PropertyBinding.sanitizeNodeName('急須'),
                        '急須',
                        'Leaves non-latin unicode characters intact.'
                    );

                    assert.equal(
                        PropertyBinding.sanitizeNodeName('space separated name 123_ -'),
                        'space_separated_name_123__-',
                        'Replaces spaces with underscores.'
                    );

                    assert.equal(
                        PropertyBinding.sanitizeNodeName('"Mátyás" %_* 😇'),
                        '"Mátyás"_%_*_😇',
                        'Allows various punctuation and symbols.'
                    );

                    assert.equal(
                        PropertyBinding.sanitizeNodeName('/invalid: name ^123.[_]'),
                        'invalid_name_^123_',
                        'Strips reserved characters.'
                    );
                });

                QUnit.test('parseTrackName', (assert) -> {
                    var paths = [
                        ['.property', {
                            nodeName: null,
                            objectName: null,
                            objectIndex: null,
                            propertyName: 'property',
                            propertyIndex: null
                        }],
                        // ... 其他路径测试
                    ];

                    paths.forEach(function(path) {
                        assert.smartEqual(
                            PropertyBinding.parseTrackName(path[0]),
                            path[1],
                            'Parses track name: ' + path[0]
                        );
                    });
                });

                QUnit.todo('findNode', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('BindingType', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('Versioning', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('GetterByBindingType', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('SetterByBindingTypeAndVersioning', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('getValue', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test('setValue', (assert) -> {
                    var paths = [
                        '.material.opacity',
                        '.material[opacity]'
                    ];

                    paths.forEach(function(path) {
                        var originalValue = 0;
                        var expectedValue = 1;

                        var geometry = new BoxGeometry();
                        var material = new MeshBasicMaterial();
                        material.opacity = originalValue;
                        var mesh = new Mesh(geometry, material);

                        var binding = new PropertyBinding(mesh, path, null);
                        binding.bind();

                        assert.equal(
                            material.opacity,
                            originalValue,
                            'Sets property of material with "' + path + '" (pre-setValue)'
                        );

                        binding.setValue([expectedValue], 0);
                        assert.equal(
                            material.opacity,
                            expectedValue,
                            'Sets property of material with "' + path + '" (post-setValue)'
                        );
                    });
                });

                QUnit.todo('bind', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('unbind', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}