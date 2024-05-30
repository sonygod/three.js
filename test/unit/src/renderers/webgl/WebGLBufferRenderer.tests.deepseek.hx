package three.js.test.unit.src.renderers.webgl;

import js.Lib;

class WebGLBufferRendererTest {

    static function main() {
        var module = Lib.QUnit.module('Renderers');
        module.module('WebGL');
        module.module('WebGLBufferRenderer');

        // INSTANCING
        Lib.QUnit.todo('Instancing', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC STUFF
        Lib.QUnit.todo('setMode', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        Lib.QUnit.todo('render', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        Lib.QUnit.todo('renderInstances', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}