package three.js.test.unit.src.helpers;

import three.js.helpers.PointLightHelper;
import three.js.objects.Mesh;
import three.js.lights.PointLight;

class PointLightHelperTests {
    public function new() {}

    public function test():Void {
        test("Extending", function(assert) {
            var light = new PointLight(0xaaaaaa);
            var object = new PointLightHelper(light, 1, 0xaaaaaa);
            assert.isTrue(object instanceof Mesh, 'PointLightHelper extends from Mesh');
        });

        test("Instancing", function(assert) {
            var light = new PointLight(0xaaaaaa);
            var object = new PointLightHelper(light, 1, 0xaaaaaa);
            assert.notNull(object, 'Can instantiate a PointLightHelper.');
        });

        test("type", function(assert) {
            var light = new PointLight(0xaaaaaa);
            var object = new PointLightHelper(light, 1, 0xaaaaaa);
            assert.equal(object.type, 'PointLightHelper', 'PointLightHelper.type should be PointLightHelper');
        });

        todo("light", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("color", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("matrix", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo("matrixAutoUpdate", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        test("dispose", function(assert) {
            assert.expect(0);
            var light = new PointLight(0xaaaaaa);
            var object = new PointLightHelper(light, 1, 0xaaaaaa);
            object.dispose();
        });

        todo("update", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}