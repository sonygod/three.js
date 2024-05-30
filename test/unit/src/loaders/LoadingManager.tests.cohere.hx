import js.QUnit;
import js.RegExp.prototype.test;

import js.Three.LoadingManager;
import js.Three.Loader;

class _Main {
    static function main() {
        QUnit.module('Loaders', function () {
            QUnit.module('LoadingManager', function () {
                // INSTANCING
                QUnit.test('Instancing', function (assert) {
                    // no params
                    var object = new LoadingManager();
                    assert.ok(object, 'Can instantiate a LoadingManager.');
                });

                // PUBLIC
                QUnit.todo('onStart', function (assert) {
                    // Refer to #5689 for the reason why we don't set .onStart
                    // in the constructor
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('onLoad', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('onProgress', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('onError', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('itemStart', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('itemEnd', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('itemError', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('resolveURL', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('setURLModifier', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('addHandler', function (assert) {
                    // addHandler( regex, loader )
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('removeHandler', function (assert) {
                    // removeHandler( regex )
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('getHandler', function (assert) {
                    // getHandler( file )
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                QUnit.test('addHandler/getHandler/removeHandler', function (assert) {
                    var loadingManager = new LoadingManager();
                    var loader = new Loader();

                    var regex1 = ~/\.jpg$/i;
                    var regex2 = ~/\.jpg$/gi;

                    loadingManager.addHandler(regex1, loader);

                    assert.equal(loadingManager.getHandler('foo.jpg'), loader, 'Returns the expected loader.');
                    assert.equal(loadingManager.getHandler('foo.jpg.png'), null, 'Returns null since the correct file extension is not at the end of the file name.');
                    assert.equal(loadingManager.getHandler('foo.jpeg'), null, 'Returns null since file extension is wrong.');

                    loadingManager.removeHandler(regex1);
                    loadingManager.addHandler(regex2, loader);

                    assert.equal(loadingManager.getHandler('foo.jpg'), loader, 'Returns the expected loader when using a regex with "g" flag.');
                    assert.equal(loadingManager.getHandler('foo.jpg'), loader, 'Returns the expected loader when using a regex with "g" flag. Test twice, see #17920.');
                });
            });
        });
    }
}