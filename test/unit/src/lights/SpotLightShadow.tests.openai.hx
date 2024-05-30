package three.lights;

import haxe.unit.TestCase;

class SpotLightShadowTests extends TestCase {
  override public function testAll() {
    testExtending();
    testInstancing();
    testProperties();
    testPublic();
    testOthers();
  }

  function testExtending() {
    var object = new SpotLightShadow();
    assertTrue(object instanceof LightShadow, "SpotLightShadow extends from LightShadow");
  }

  function testInstancing() {
    var object = new SpotLightShadow();
    assertNotNull(object, "Can instantiate a SpotLightShadow.");
  }

  function testProperties() {
    // todo: implement
  }

  function testPublic() {
    var object = new SpotLightShadow();
    assertTrue(object.isSpotLightShadow, "SpotLightShadow.isSpotLightShadow should be true");
  }

  function testOthers() {
    var a = new SpotLightShadow();
    var b = new SpotLightShadow();

    assertFalse(a == b, "Newly instanced shadows are not equal");

    var c = a.clone();
    assertEquals(a, c, "Shadows are identical after clone()");

    c.mapSize.set(256, 256);
    assertFalse(a == c, "Shadows are different again after change");

    b.copy(a);
    assertEquals(a, b, "Shadows are identical after copy()");

    b.mapSize.set(512, 512);
    assertFalse(a == b, "Shadows are different again after change");

    // toJSON test
    var light = new SpotLight();
    var shadow = new SpotLightShadow();

    shadow.bias = 10;
    shadow.radius = 5;
    shadow.mapSize.set(128, 128);
    light.shadow = shadow;

    var json = light.toJson();
    var newLight = new ObjectLoader().parse(json);

    assertEquals(newLight.shadow, light.shadow, "Reloaded shadow is equal to the original one");
  }
}