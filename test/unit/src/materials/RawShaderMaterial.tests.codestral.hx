import js.Browser.document;
import js.Browser.Window;
import three.materials.RawShaderMaterial;
import three.materials.ShaderMaterial;

class RawShaderMaterialTests {
    public function new() {
        var module = js.Boot.getClass(Window.getField('QUnit')).staticField('module');
        module.call(js.Boot.getClass(Window.getField('QUnit')), "Materials", $bind(this, this.materialsModule));
    }

    private function materialsModule() {
        var module = js.Boot.getClass(Window.getField('QUnit')).staticField('module');
        module.call(js.Boot.getClass(Window.getField('QUnit')), "RawShaderMaterial", $bind(this, this.rawShaderMaterialModule));
    }

    private function rawShaderMaterialModule() {
        var test = js.Boot.getClass(Window.getField('QUnit')).staticField('test');

        test.call(js.Boot.getClass(Window.getField('QUnit')), "Extending", $bind(this, this.extending));
        test.call(js.Boot.getClass(Window.getField('QUnit')), "Instancing", $bind(this, this.instancing));
        test.call(js.Boot.getClass(Window.getField('QUnit')), "type", $bind(this, this.type));
        test.call(js.Boot.getClass(Window.getField('QUnit')), "isRawShaderMaterial", $bind(this, this.isRawShaderMaterial));
    }

    private function extending(assert:Dynamic) {
        var object = new RawShaderMaterial();
        assert.strictEqual(
            js.Boot.instanceof(object, ShaderMaterial), true,
            'RawShaderMaterial extends from ShaderMaterial'
        );
    }

    private function instancing(assert:Dynamic) {
        var object = new RawShaderMaterial();
        assert.ok(object, 'Can instantiate a RawShaderMaterial.');
    }

    private function type(assert:Dynamic) {
        var object = new RawShaderMaterial();
        assert.ok(
            object.type == 'RawShaderMaterial',
            'RawShaderMaterial.type should be RawShaderMaterial'
        );
    }

    private function isRawShaderMaterial(assert:Dynamic) {
        var object = new RawShaderMaterial();
        assert.ok(
            object.isRawShaderMaterial,
            'RawShaderMaterial.isRawShaderMaterial should be true'
        );
    }
}