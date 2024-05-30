import haxe.unit.TestCase;
import thx.unit.TestRunner;

import three.animation.PropertyBinding;
import three.geometries.BoxGeometry;
import three.materials.MeshBasicMaterial;
import three.objects.Mesh;

class PropertyBindingTest {
  public function new() {}

  public function test() {
    var testRunner = new TestRunner();
    testRunner.add(new TestCase("PropertyBinding", [
      function(test: TestCase) {
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

        var object = new PropertyBinding(mesh, path);
        test.ok(object != null, "Can instantiate a PropertyBinding.");

        var object_all = new PropertyBinding(mesh, path, parsedPath);
        test.ok(object_all != null, "Can instantiate a PropertyBinding with mesh, path, and parsedPath.");
      },
      function(test: TestCase) {
        test.ok(false, "everything's gonna be alright"); // TODO: implement
      },
      function(test: TestCase) {
        test.ok(false, "everything's gonna be alright"); // TODO: implement
      },
      function(test: TestCase) {
        test.equal(PropertyBinding.sanitizeNodeName("valid-name-123_"), "valid-name-123_", "Leaves valid name intact.");
        test.equal(PropertyBinding.sanitizeNodeName("急須"), "急須", "Leaves non-latin unicode characters intact.");
        test.equal(PropertyBinding.sanitizeNodeName("space separated name 123_ -"), "space_separated_name_123__-", "Replaces spaces with underscores.");
        test.equal(PropertyBinding.sanitizeNodeName('"Mátyás" %_* 😇'), '"Mátyás"_%_*_😇', "Allows various punctuation and symbols.");
        test.equal(PropertyBinding.sanitizeNodeName('/invalid: name ^123.[_]'), 'invalid_name_^123_', "Strips reserved characters.");
      },
      function(test: TestCase) {
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
          // ... all the other paths tests ...
        ];

        for (path in paths) {
          test.smartEqual(PropertyBinding.parseTrackName(path[0]), path[1], 'Parses track name: ' + path[0]);
        }
      },
      function(test: TestCase) {
        test.ok(false, "everything's gonna be alright"); // TODO: implement
      },
      // ... all the other tests ...
    ]));
    testRunner.run();
  }
}