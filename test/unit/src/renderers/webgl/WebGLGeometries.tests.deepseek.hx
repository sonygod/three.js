// import.hx
import js.Lib;

class WebGLGeometries {
    static function get() {}
    static function update() {}
    static function getWireframeAttribute() {}
}

// test.hx
import js.Lib;
import WebGLGeometries;

class Test {
    static function main() {
        QUnit.module('Renderers', () -> {
            QUnit.module('WebGL', () -> {
                QUnit.module('WebGLGeometries', () -> {
                    QUnit.todo('Instancing', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                    QUnit.todo('get', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                    QUnit.todo('update', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                    QUnit.todo('getWireframeAttribute', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                });
            });
        });
    }
}