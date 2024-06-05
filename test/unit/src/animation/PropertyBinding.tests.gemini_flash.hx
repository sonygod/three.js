import qunit.QUnit;
import three.animation.PropertyBinding;
import three.geometries.BoxGeometry;
import three.materials.MeshBasicMaterial;
import three.objects.Mesh;

class PropertyBindingTest {
  static function main() {
    QUnit.module("Animation", function() {
      QUnit.module("PropertyBinding", function() {
        // INSTANCING
        QUnit.test("Instancing", function(assert) {
          var geometry = new BoxGeometry();
          var material = new MeshBasicMaterial();
          var mesh = new Mesh(geometry, material);
          var path = ".material.opacity";
          var parsedPath = {
            nodeName: "",
            objectName: "material",
            objectIndex: null,
            propertyName: "opacity",
            propertyIndex: null
          };

          // mesh, path
          var object = new PropertyBinding(mesh, path);
          assert.ok(object, "Can instantiate a PropertyBinding.");

          // mesh, path, parsedPath
          var object_all = new PropertyBinding(mesh, path, parsedPath);
          assert.ok(object_all, "Can instantiate a PropertyBinding with mesh, path, and parsedPath.");
        });

        // STATIC
        QUnit.todo("Composite", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("create", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.test("sanitizeNodeName", function(assert) {
          assert.equal(PropertyBinding.sanitizeNodeName("valid-name-123_"), "valid-name-123_", "Leaves valid name intact.");
          assert.equal(PropertyBinding.sanitizeNodeName("急須"), "急須", "Leaves non-latin unicode characters intact.");
          assert.equal(PropertyBinding.sanitizeNodeName("space separated name 123_ -"), "space_separated_name_123__-", "Replaces spaces with underscores.");
          assert.equal(PropertyBinding.sanitizeNodeName("\"Mátyás\" %_* 😇"), "\"Mátyás\"_%_*_😇", "Allows various punctuation and symbols.");
          assert.equal(PropertyBinding.sanitizeNodeName("/invalid: name ^123.[_]"), "invalid_name_^123_", "Strips reserved characters.");
        });

        QUnit.test("parseTrackName", function(assert) {
          var paths = [
            [".property", {
              nodeName: null,
              objectName: null,
              objectIndex: null,
              propertyName: "property",
              propertyIndex: null
            }],
            ["nodeName.property", {
              nodeName: "nodeName",
              objectName: null,
              objectIndex: null,
              propertyName: "property",
              propertyIndex: null
            }],
            ["a.property", {
              nodeName: "a",
              objectName: null,
              objectIndex: null,
              propertyName: "property",
              propertyIndex: null
            }],
            ["no.de.Name.property", {
              nodeName: "no.de.Name",
              objectName: null,
              objectIndex: null,
              propertyName: "property",
              propertyIndex: null
            }],
            ["no.d-e.Name.property", {
              nodeName: "no.d-e.Name",
              objectName: null,
              objectIndex: null,
              propertyName: "property",
              propertyIndex: null
            }],
            ["nodeName.property[accessor]", {
              nodeName: "nodeName",
              objectName: null,
              objectIndex: null,
              propertyName: "property",
              propertyIndex: "accessor"
            }],
            ["nodeName.material.property[accessor]", {
              nodeName: "nodeName",
              objectName: "material",
              objectIndex: null,
              propertyName: "property",
              propertyIndex: "accessor"
            }],
            ["no.de.Name.material.property", {
              nodeName: "no.de.Name",
              objectName: "material",
              objectIndex: null,
              propertyName: "property",
              propertyIndex: null
            }],
            ["no.de.Name.material[materialIndex].property", {
              nodeName: "no.de.Name",
              objectName: "material",
              objectIndex: "materialIndex",
              propertyName: "property",
              propertyIndex: null
            }],
            ["uuid.property[accessor]", {
              nodeName: "uuid",
              objectName: null,
              objectIndex: null,
              propertyName: "property",
              propertyIndex: "accessor"
            }],
            ["uuid.objectName[objectIndex].propertyName[propertyIndex]", {
              nodeName: "uuid",
              objectName: "objectName",
              objectIndex: "objectIndex",
              propertyName: "propertyName",
              propertyIndex: "propertyIndex"
            }],
            ["parentName/nodeName.property", {
              // directoryName is currently unused.
              nodeName: "nodeName",
              objectName: null,
              objectIndex: null,
              propertyName: "property",
              propertyIndex: null
            }],
            ["parentName/no.de.Name.property", {
              // directoryName is currently unused.
              nodeName: "no.de.Name",
              objectName: null,
              objectIndex: null,
              propertyName: "property",
              propertyIndex: null
            }],
            ["parentName/parentName/nodeName.property[index]", {
              // directoryName is currently unused.
              nodeName: "nodeName",
              objectName: null,
              objectIndex: null,
              propertyName: "property",
              propertyIndex: "index"
            }],
            [".bone[Armature.DEF_cog].position", {
              nodeName: null,
              objectName: "bone",
              objectIndex: "Armature.DEF_cog",
              propertyName: "position",
              propertyIndex: null
            }],
            ["scene:helium_balloon_model:helium_balloon_model.position", {
              nodeName: "helium_balloon_model",
              objectName: null,
              objectIndex: null,
              propertyName: "position",
              propertyIndex: null
            }],
            ["急須.材料[零]", {
              nodeName: "急須",
              objectName: null,
              objectIndex: null,
              propertyName: "材料",
              propertyIndex: "零"
            }],
            ["📦.🎨[🔴]", {
              nodeName: "📦",
              objectName: null,
              objectIndex: null,
              propertyName: "🎨",
              propertyIndex: "🔴"
            }]
          ];

          paths.forEach(function(path) {
            assert.smartEqual(PropertyBinding.parseTrackName(path[0]), path[1], "Parses track name: " + path[0]);
          });
        });

        QUnit.todo("findNode", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC STUFF
        QUnit.todo("BindingType", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("Versioning", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("GetterByBindingType", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("SetterByBindingTypeAndVersioning", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getValue", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.test("setValue", function(assert) {
          var paths = [
            ".material.opacity",
            ".material[opacity]"
          ];

          paths.forEach(function(path) {
            var originalValue = 0;
            var expectedValue = 1;

            var geometry = new BoxGeometry();
            var material = new MeshBasicMaterial();
            material.opacity = originalValue;
            var mesh = new Mesh(geometry, material);

            var binding = new PropertyBinding(mesh, path, null);
            binding.bind();

            assert.equal(material.opacity, originalValue, 'Sets property of material with "' + path + '" (pre-setValue)');

            binding.setValue([expectedValue], 0);
            assert.equal(material.opacity, expectedValue, 'Sets property of material with "' + path + '" (post-setValue)');
          });
        });

        QUnit.todo("bind", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("unbind", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}

PropertyBindingTest.main();