import js.Lib;
import js.Browser.window;

class Test {
    static function main() {
        var QUnit = Lib.require('qunit');
        var Shape = Lib.require('../../../../../src/extras/core/Shape.js').Shape;
        var Path = Lib.require('../../../../../src/extras/core/Path.js').Path;

        QUnit.module('Extras', function() {
            QUnit.module('Core', function() {
                QUnit.module('Shape', function() {
                    // INHERITANCE
                    QUnit.test('Extending', function(assert) {
                        var object = new Shape();
                        assert.strictEqual(object instanceof Path, true, 'Shape extends from Path');
                    });

                    // INSTANCING
                    QUnit.test('Instancing', function(assert) {
                        var object = new Shape();
                        assert.ok(object, 'Can instantiate a Shape.');
                    });

                    // PROPERTIES
                    QUnit.test('type', function(assert) {
                        var object = new Shape();
                        assert.ok(object.type === 'Shape', 'Shape.type should be Shape');
                    });

                    QUnit.todo('uuid', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('holes', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    // PUBLIC
                    QUnit.todo('getPointsHoles', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('extractPoints', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('copy', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('toJSON', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('fromJSON', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                });
            });
        });
    });
}

window.onload = function() {
    Test.main();
};