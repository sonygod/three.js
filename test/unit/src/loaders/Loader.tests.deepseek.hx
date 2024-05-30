package three.js.test.unit.src.loaders;

import three.js.src.loaders.Loader;
import three.js.src.loaders.LoadingManager;
import js.Lib;

class LoaderTests {
    static function main() {
        QUnit.module('Loaders', () -> {
            QUnit.module('Loader', () -> {
                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new Loader();
                    assert.ok(object != null, 'Can instantiate a Loader.');
                });

                // PROPERTIES
                QUnit.test('manager', (assert) -> {
                    // uses default LoadingManager if not supplied in constructor
                    var object = new Loader().manager;
                    assert.strictEqual(
                        object instanceof LoadingManager, true,
                        'Loader defines a default manager if not supplied in constructor.'
                    );
                });

                QUnit.test('crossOrigin', (assert) -> {
                    var actual = new Loader().crossOrigin;
                    var expected = 'anonymous';
                    assert.strictEqual(actual, expected, 'Loader defines crossOrigin.');
                });

                QUnit.test('withCredentials', (assert) -> {
                    var actual = new Loader().withCredentials;
                    var expected = false;
                    assert.strictEqual(actual, expected, 'Loader defines withCredentials.');
                });

                QUnit.test('path', (assert) -> {
                    var actual = new Loader().path;
                    var expected = '';
                    assert.strictEqual(actual, expected, 'Loader defines path.');
                });

                QUnit.test('resourcePath', (assert) -> {
                    var actual = new Loader().resourcePath;
                    var expected = '';
                    assert.strictEqual(actual, expected, 'Loader defines resourcePath.');
                });

                QUnit.test('requestHeader', (assert) -> {
                    var actual = new Loader().requestHeader;
                    var expected = {};
                    assert.deepEqual(actual, expected, 'Loader defines requestHeader.');
                });

                // PUBLIC
                QUnit.todo('load', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('loadAsync', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('parse', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('setCrossOrigin', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('setWithCredentials', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('setPath', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('setResourcePath', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('setRequestHeader', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}