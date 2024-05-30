#import haxe.unit.TestRunner;

class SpotLightTests {
  static function main() {
    var runner = new TestRunner();
    runner.add(new SpotLightTest());
    runner.run();
  }
}

class SpotLightTest {
  var lights:Array<SpotLight>;

  public function new() {}

  @Before
  public function setup() {
    var parameters = {
      color: 0xaaaaaa,
      intensity: 0.5,
      distance: 100,
      angle: 0.8,
      penumbra: 8,
      decay: 2
    };

    lights = [
      new SpotLight(parameters.color),
      new SpotLight(parameters.color, parameters.intensity),
      new SpotLight(parameters.color, parameters.intensity, parameters.distance),
      new SpotLight(parameters.color, parameters.intensity, parameters.distance, parameters.angle),
      new SpotLight(parameters.color, parameters.intensity, parameters.distance, parameters.angle, parameters.penumbra),
      new SpotLight(parameters.color, parameters.intensity, parameters.distance, parameters.angle, parameters.penumbra, parameters.decay)
    ];
  }

  @Test
  public function testExtending() {
    var object = new SpotLight();
    assertTrue(object instanceof Light, 'SpotLight extends from Light');
  }

  @Test
  public function testInstancing() {
    var object = new SpotLight();
    assertNotNull(object, 'Can instantiate a SpotLight.');
  }

  @Test
  public function testType() {
    var object = new SpotLight();
    assertEquals(object.type, 'SpotLight', 'SpotLight.type should be SpotLight');
  }

  @Test
  public function testPower() {
    var a = new SpotLight(0xaaaaaa);
    a.intensity = 100;
    assertEquals(a.power, 100 * Math.PI, 'Correct power for an intensity of 100');

    a.intensity = 40;
    assertEquals(a.power, 40 * Math.PI, 'Correct power for an intensity of 40');

    a.power = 100;
    assertEquals(a.intensity, 100 / Math.PI, 'Correct intensity for a power of 100');
  }

  @Test
  public function testIsSpotLight() {
    var object = new SpotLight();
    assertTrue(object.isSpotLight, 'SpotLight.isSpotLight should be true');
  }

  @Test
  public function testDispose() {
    var object = new SpotLight();
    object.dispose();
    // ensure calls dispose() on shadow
  }

  @Test
  public function testStandardLightTests() {
    runStdLightTests(lights);
  }
}

class StdLightTests {
  public static function runStdLightTests(lights:Array<SpotLight>) {
    // implement standard light tests here
  }
}