package;

import js.Lib;
import three.scenes.Fog;

class FogTests {

    static function main() {
        QUnit.module('Scenes', () -> {
            QUnit.module('Fog', () -> {
                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    // Fog( color, near = 1, far = 1000 )
                    // no params
                    var object = new Fog();
                    assert.ok(object, 'Can instantiate a Fog.');
                    // color
                    var object_color = new Fog(0xffffff);
                    assert.ok(object_color, 'Can instantiate a Fog with color.');
                    // color, near, far
                    var object_all = new Fog(0xffffff, 0.015, 100);
                    assert.ok(object_all, 'Can instantiate a Fog with color, near, far.');
                });
                // PROPERTIES
                QUnit.todo('name', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
                QUnit.todo('color', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
                QUnit.todo('near', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
                QUnit.todo('far', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
                // PUBLIC
                QUnit.test('isFog', (assert) -> {
                    var object = new Fog();
                    assert.ok(object.isFog, 'Fog.isFog should be true');
                });
                QUnit.todo('clone', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
                QUnit.todo('toJSON', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}