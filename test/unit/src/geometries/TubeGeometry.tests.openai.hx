package three.js.test.unit.src.geometries;

import three.js.src.geometries.TubeGeometry;
import three.js.src.extras.curves.LineCurve3;
import three.js.src.math.Vector3;
import three.js.src.core.BufferGeometry;

class TubeGeometryTests {
  public static function main(): Void {
    Suite.run(new TestSuite("Geometries"), {
      Suite.run(new TestSuite("TubeGeometry"), {
        var geometries:Array<BufferGeometry>;

        Before.each(function(): Void {
          var path:LineCurve3 = new LineCurve3(new Vector3(0, 0, 0), new Vector3(0, 1, 0));
          geometries = [new TubeGeometry(path)];
        });

        Test.async("Extending", function(assert): Void {
          var object:TubeGeometry = new TubeGeometry();
          assert.isTrue(Std.is(object, BufferGeometry), "TubeGeometry extends from BufferGeometry");
        });

        Test.async("Instancing", function(assert): Void {
          var object:TubeGeometry = new TubeGeometry();
          assert.ok(object, "Can instantiate a TubeGeometry.");
        });

        Test.async("type", function(assert): Void {
          var object:TubeGeometry = new TubeGeometry();
          assert.equals(object.type, "TubeGeometry", "TubeGeometry.type should be TubeGeometry");
        });

        // todo: implement these tests
        Test.todo("parameters", function(assert): Void {
          assert.ok(false, "everything's gonna be alright");
        });

        Test.todo("tangents", function(assert): Void {
          assert.ok(false, "everything's gonna be alright");
        });

        Test.todo("normals", function(assert): Void {
          assert.ok(false, "everything's gonna be alright");
        });

        Test.todo("binormals", function(assert): Void {
          assert.ok(false, "everything's gonna be alright");
        });

        // todo: implement these tests
        Test.todo("toJSON", function(assert): Void {
          assert.ok(false, "everything's gonna be alright");
        });

        Test.todo("fromJSON", function(assert): Void {
          assert.ok(false, "everything's gonna be alright");
        });

        Test.todo("Standard geometry tests", function(assert): Void {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}