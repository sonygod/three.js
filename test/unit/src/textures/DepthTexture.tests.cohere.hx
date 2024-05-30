import js.QUnit;

import js.Three.DepthTexture;
import js.Three.Texture;

class TestDepthTexture {
    static function extending() {
        var object = new DepthTexture();
        var result = Std.is(object, Texture);
        QUnit.strictEqual(result, true, "DepthTexture extends from Texture");
    }

    static function instancing() {
        var object = new DepthTexture();
        QUnit.ok(object, "Can instantiate a DepthTexture.");
    }

    static function isDepthTexture() {
        var object = new DepthTexture();
        QUnit.ok(object.isDepthTexture, "DepthTexture.isDepthTexture should be true");
    }
}

QUnit.module("Textures", {
    afterEach: function() {},
    beforeEach: function() {},
    after: function() {},
    before: function() {}
});

QUnit.module("DepthTexture", {
    afterEach: function() {},
    beforeEach: function() {},
    after: function() {},
    before: function() {}
});

QUnit.test("Extending", TestDepthTexture.extending);
QUnit.test("Instancing", TestDepthTexture.instancing);
QUnit.test("isDepthTexture", TestDepthTexture.isDepthTexture);