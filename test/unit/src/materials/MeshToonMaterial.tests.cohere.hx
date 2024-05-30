import js.QUnit.*;
import MeshToonMaterial from "../../../../src/materials/MeshToonMaterial.hx";
import Material from "../../../../src/materials/Material.hx";

@:export
module materials_MeshToonMaterial_Test {
    QUnit.module("Materials > MeshToonMaterial");

    // INHERITANCE
    QUnit.test("Extending", function() {
        var object = new MeshToonMaterial();
        QUnit.strictEqual(
            Std.is(object, Material),
            true,
            "MeshToonMaterial extends from Material"
        );
    });

    // INSTANCING
    QUnit.test("Instancing", function() {
        var object = new MeshToonMaterial();
        QUnit.ok(object, "Can instantiate a MeshToonMaterial.");
    });

    // PROPERTIES
    QUnit.todo("defines", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.test("type", function() {
        var object = new MeshToonMaterial();
        QUnit.ok(
            object.type == "MeshToonMaterial",
            "MeshToonMaterial.type should be MeshToonMaterial"
        );
    });

    QUnit.todo("color", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("map", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("gradientMap", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("lightMap", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("lightMapIntensity", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("aoMap", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("aoMapIntensity", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("emissive", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("emissiveIntensity", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("emissiveMap", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("bumpMap", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("bumpScale", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("normalMap", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("normalMapType", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("normalScale", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("displacementMap", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("displacementScale", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("displacementBias", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("alphaMap", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("wireframe", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("wireframeLinewidth", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("wireframeLinecap", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("wireframeLinejoin", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("fog", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });

    // PUBLIC
    QUnit.test("isMeshToonMaterial", function() {
        var object = new MeshToonMaterial();
        QUnit.ok(
            object.isMeshToonMaterial,
            "MeshToonMaterial.isMeshToonMaterial should be true"
        );
    });

    QUnit.todo("copy", function() {
        QUnit.ok(false, "everything's gonna be alright");
    });
}