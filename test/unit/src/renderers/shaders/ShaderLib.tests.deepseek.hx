package three.js.test.unit.src.renderers.shaders;

import three.js.src.renderers.shaders.ShaderLib;
import js.Lib;

class ShaderLibTests {

    static function main() {
        QUnit.module('Renderers', () -> {
            QUnit.module('Shaders', () -> {
                QUnit.module('ShaderLib', () -> {
                    QUnit.test('Instancing', (assert) -> {
                        assert.ok(ShaderLib != null, 'ShaderLib is defined.');
                    });
                });
            });
        });
    }
}