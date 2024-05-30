package three.js.test.unit.src.loaders;

import three.js.src.loaders.Cache;
import js.Lib.QUnit;

class CacheTests {

    public static function main() {

        QUnit.module('Loaders', () -> {

            QUnit.module('Cache', () -> {

                // PROPERTIES
                QUnit.test('enabled', (assert) -> {

                    var actual = Cache.enabled;
                    var expected = false;
                    assert.strictEqual(actual, expected, 'Cache defines enabled.');

                });

                QUnit.test('files', (assert) -> {

                    var actual = Cache.files;
                    var expected = {};
                    assert.deepEqual(actual, expected, 'Cache defines files.');

                });

                // PUBLIC
                QUnit.todo('add', (assert) -> {

                    // function ( key, file )
                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('get', (assert) -> {

                    // function ( key )
                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('remove', (assert) -> {

                    // function ( key )
                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('clear', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}