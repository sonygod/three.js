import haxe.unit.TestCase;
import three.Scene;
import three.Object3D;

class SceneTests {
  public function new() {}

  public function testScene() {
    var scene = new Scene();
    assertTrue(scene instanceof Object3D, "Scene extends from Object3D");
  }

  public function testInstancing() {
    var scene = new Scene();
    assertTrue(scene != null, "Can instantiate a Scene.");
  }

  public function todoType() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function todoBackground() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function todoEnvironment() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function todoFog() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function todoBackgroundBlurriness() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function todoBackgroundIntensity() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function todoOverrideMaterial() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function testIsScene() {
    var scene = new Scene();
    assertTrue(scene.isScene, "Scene.isScene should be true");
  }

  public function todoCopy() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function todoToJson() {
    assertTrue(false, "everything's gonna be alright");
  }
}