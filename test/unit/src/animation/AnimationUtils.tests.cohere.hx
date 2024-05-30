package js.QUnit;

class Animation {
    public static function Animation() {
        #if js
        QUnit.module('Animation', function () {
            QUnit.module('AnimationUtils', function () {
                // PUBLIC
                QUnit.todo('convertArray', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('isTypedArray', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('getKeyframeOrder', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('sortedArray', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('flattenJSON', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('subclip', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('makeClipAdditive', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
        #end
    }
}