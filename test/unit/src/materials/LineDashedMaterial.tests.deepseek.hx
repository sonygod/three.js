// 导入必要的模块
import js.Lib;
import three.materials.LineDashedMaterial;
import three.materials.Material;

class LineDashedMaterialTest {
    static function main() {
        // 模块
        QUnit.module('Materials', () => {
            QUnit.module('LineDashedMaterial', () => {
                // 继承
                QUnit.test('Extending', (assert) => {
                    var object = new LineDashedMaterial();
                    assert.strictEqual(
                        Std.is(object, Material), true,
                        'LineDashedMaterial extends from Material'
                    );
                });

                // 实例化
                QUnit.test('Instancing', (assert) => {
                    var object = new LineDashedMaterial();
                    assert.ok(object, 'Can instantiate a LineDashedMaterial.');
                });

                // 属性
                QUnit.test('type', (assert) => {
                    var object = new LineDashedMaterial();
                    assert.ok(
                        object.type == 'LineDashedMaterial',
                        'LineDashedMaterial.type should be LineDashedMaterial'
                    );
                });

                QUnit.todo('scale', (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('dashSize', (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('gapSize', (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // 公共
                QUnit.test('isLineDashedMaterial', (assert) => {
                    var object = new LineDashedMaterial();
                    assert.ok(
                        object.isLineDashedMaterial,
                        'LineDashedMaterial.isLineDashedMaterial should be true'
                    );
                });

                QUnit.todo('copy', (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}