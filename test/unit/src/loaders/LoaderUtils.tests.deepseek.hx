package;

import js.LoaderUtils;
import js.QUnit;

class LoaderUtilsTest {

    static function main() {

        QUnit.module('Loaders', () -> {

            QUnit.module('LoaderUtils', () -> {

                // STATIC
                QUnit.test('decodeText', (assert) -> {

                    var jsonArray = [123, 34, 106, 115, 111, 110, 34, 58, 32, 116, 114, 117, 101, 125];
                    assert.equal('{"json": true}', LoaderUtils.decodeText(jsonArray));

                    var multibyteArray = [230, 151, 165, 230, 156, 172, 229, 155, 189];
                    assert.equal('日本国', LoaderUtils.decodeText(multibyteArray));

                });

                QUnit.test('extractUrlBase', (assert) -> {

                    assert.equal('/path/to/', LoaderUtils.extractUrlBase('/path/to/model.glb'));
                    assert.equal('./', LoaderUtils.extractUrlBase('model.glb'));
                    assert.equal('/', LoaderUtils.extractUrlBase('/model.glb'));

                });

                QUnit.todo('resolveURL', (assert) -> {

                    // static resolveURL(url, path)
                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}