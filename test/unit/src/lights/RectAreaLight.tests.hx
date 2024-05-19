package three.lights;

import haxe.unit.TestCase;

class RectAreaLightTest extends TestCase {
  var lights:Array<RectAreaLight>;

  override public function setup() {
    var parameters = {
      color: 0xaaaaaa,
      intensity: 0.5,
      width: 100,
      height: 50
    };

    lights = [
      new RectAreaLight(parameters.color),
      new RectAreaLight(parameters.color, parameters.intensity),
      new RectAreaLight(parameters.color, parameters.intensity, parameters.width),
      new RectAreaLight(parameters.color, parameters.intensity, parameters.width, parameters.height)
    ];
  }

  public function testExtending() {
    var object = new RectAreaLight();
    assertTrue(object instanceof Light, 'RectAreaLight extends from Light');
  }

  public function testInstancing() {
    var object = new RectAreaLight();
    assertNotNull(object, 'Can instantiate a RectAreaLight.');
  }

  public function testType() {
    var object = new RectAreaLight();
    assertEquals(object.type, 'RectAreaLight', 'RectAreaLight.type should be RectAreaLight');
  }

  public function testPower() {
    var a = new RectAreaLight(0xaaaaaa, 1, 10, 10);
    var actual:Float;
    var expected:Float;

    a.intensity = 100;
    actual = a.power;
    expected = 100 * a.width * a.height * Math.PI;
    assertEquals(actual, expected, 'Correct power for an intensity of 100');

    a.intensity = 40;
    actual = a.power;
    expected = 40 * a.width * a.height * Math.PI;
    assertEquals(actual, expected, 'Correct power for an intensity of 40');

    a.power = 100;
    actual = a.intensity;
    expected = 100 / (a.width * a.height * Math.PI);
    assertEquals(actual, expected, 'Correct intensity for a power of 100');
  }

  public function testIsRectAreaLight() {
    var object = new RectAreaLight();
    assertTrue(object.isRectAreaLight, 'RectAreaLight.isRectAreaLight should be true');
  }

  public function testStandardLightTests() {
    runStdLightTests(this, lights);
  }
}