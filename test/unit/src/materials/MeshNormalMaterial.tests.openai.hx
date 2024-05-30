package three.test.unit.src.materials;

import three.materials.MeshNormalMaterial;
import three.materials.Material;

class MeshNormalMaterialTests {
  public function new() {}

  public static function main() {
    // INHERITANCE
    test("Extending", ASSERT => {
      var object = new MeshNormalMaterial();
      ASSERT.isTrue_STD(object instanceof Material, "MeshNormalMaterial extends from Material");
    });

    // INSTANCING
    test("Instancing", ASSERT => {
      var object = new MeshNormalMaterial();
      ASSERT.isTrue_STD(object != null, "Can instantiate a MeshNormalMaterial.");
    });

    // PROPERTIES
    test("type", ASSERT => {
      var object = new MeshNormalMaterial();
      ASSERT.equals(STD, object.type, "MeshNormalMaterial");
    });

    todo("bumpMap", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });

    todo("bumpScale", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });

    todo("normalMap", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });

    todo("normalMapType", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });

    todo("normalScale", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });

    todo("displacementMap", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });

    todo("displacementScale", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });

    todo("displacementBias", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });

    todo("wireframe", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });

    todo("wireframeLinewidth", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });

    todo("flatShading", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });

    // PUBLIC
    test("isMeshNormalMaterial", ASSERT => {
      var object = new MeshNormalMaterial();
      ASSERT.isTrue_STD(object.isMeshNormalMaterial, "MeshNormalMaterial.isMeshNormalMaterial should be true");
    });

    todo("copy", ASSERT => {
      ASSERT.isTrue_STD(false, "everything's gonna be alright");
    });
  }
}