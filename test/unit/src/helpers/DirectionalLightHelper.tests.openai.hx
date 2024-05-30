package three.helpers;

import three.core.Object3D;
import three.lights.DirectionalLight;
import utest.Runner;
import utest.ui.Report;

class DirectionalLightHelperTest {
  public function new() {}

  public static function main() {
    var runner = new Runner();
    runner.addCase(new DirectionalLightHelperTest());
    Report.create( runner );
    runner.run();
  }

  public function test_Extending() {
    var parameters = {
      size: 1,
      color: 0xaaaaaa,
      intensity: 0.8
    };

    var light = new DirectionalLight(parameters.color);
    var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
    Assert.isTrue(object instanceof Object3D, 'DirectionalLightHelper extends from Object3D');
  }

  public function test_Instancing() {
    var parameters = {
      size: 1,
      color: 0xaaaaaa,
      intensity: 0.8
    };

    var light = new DirectionalLight(parameters.color);
    var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
    Assert.notNull(object, 'Can instantiate a DirectionalLightHelper.');
  }

  public function test_type() {
    var parameters = {
      size: 1,
      color: 0xaaaaaa,
      intensity: 0.8
    };

    var light = new DirectionalLight(parameters.color);
    var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
    Assert.equals(object.type, 'DirectionalLightHelper', 'DirectionalLightHelper.type should be DirectionalLightHelper');
  }

  public function todo_light() {
    Assert.fail('not implemented');
  }

  public function todo_matrix() {
    Assert.fail('not implemented');
  }

  public function todo_matrixAutoUpdate() {
    Assert.fail('not implemented');
  }

  public function todo_color() {
    Assert.fail('not implemented');
  }

  public function test_dispose() {
    var parameters = {
      size: 1,
      color: 0xaaaaaa,
      intensity: 0.8
    };

    var light = new DirectionalLight(parameters.color);
    var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
    object.dispose();
  }

  public function todo_update() {
    Assert.fail('not implemented');
  }
}