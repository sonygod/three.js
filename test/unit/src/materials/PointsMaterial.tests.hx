package three.test.unit.src.materials;

import three.materials.PointsMaterial;
import three.materials.Material;

class PointsMaterialTest
{
    public function new()
    {
        QUnit.module("Materials", () ->
        {
            QUnit.module("PointsMaterial", () ->
            {
                // INHERITANCE
                QUnit.test("Extending", (assert) ->
                {
                    var object = new PointsMaterial();
                    assert.isTrue(object instanceof Material, "PointsMaterial extends from Material");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) ->
                {
                    var object = new PointsMaterial();
                    assert.ok(object, "Can instantiate a PointsMaterial.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) ->
                {
                    var object = new PointsMaterial();
                    assert.equals(object.type, "PointsMaterial", "PointsMaterial.type should be PointsMaterial");
                });

                QUnit.todo("color", (assert) ->
                {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("map", (assert) ->
                {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("alphaMap", (assert) ->
                {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("size", (assert) ->
                {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("sizeAttenuation", (assert) ->
                {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("fog", (assert) ->
                {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isPointsMaterial", (assert) ->
                {
                    var object = new PointsMaterial();
                    assert.isTrue(object.isPointsMaterial, "PointsMaterial.isPointsMaterial should be true");
                });

                QUnit.todo("copy", (assert) ->
                {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}