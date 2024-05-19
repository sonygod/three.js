import haxe.unit.TestCase;
import Layers;

class LayersTests {
  public function new() {}

  public function testInstancing() {
    var object = new Layers();
    assertTrue(object != null, 'Can instantiate a Layers.');
  }

  public function testSet() {
    var a = new Layers();
    for (i in 0...31) {
      a.set(i);
      assertEquals(a.mask, Math.pow(2, i), 'Mask has the expected value for channel: ' + i);
    }
  }

  public function testEnable() {
    var a = new Layers();
    a.set(0);
    a.enable(0);
    assertEquals(a.mask, 1, 'Enable channel 0 with mask 0');

    a.set(0);
    a.enable(1);
    assertEquals(a.mask, 3, 'Enable channel 1 with mask 0');

    a.set(1);
    a.enable(0);
    assertEquals(a.mask, 3, 'Enable channel 0 with mask 1');

    a.set(1);
    a.enable(1);
    assertEquals(a.mask, 2, 'Enable channel 1 with mask 1');
  }

  public function testToggle() {
    var a = new Layers();
    a.set(0);
    a.toggle(0);
    assertEquals(a.mask, 0, 'Toggle channel 0 with mask 0');

    a.set(0);
    a.toggle(1);
    assertEquals(a.mask, 3, 'Toggle channel 1 with mask 0');

    a.set(1);
    a.toggle(0);
    assertEquals(a.mask, 3, 'Toggle channel 0 with mask 1');

    a.set(1);
    a.toggle(1);
    assertEquals(a.mask, 0, 'Toggle channel 1 with mask 1');
  }

  public function testDisable() {
    var a = new Layers();
    a.set(0);
    a.disable(0);
    assertEquals(a.mask, 0, 'Disable channel 0 with mask 0');

    a.set(0);
    a.disable(1);
    assertEquals(a.mask, 1, 'Disable channel 1 with mask 0');

    a.set(1);
    a.disable(0);
    assertEquals(a.mask, 2, 'Disable channel 0 with mask 1');

    a.set(1);
    a.disable(1);
    assertEquals(a.mask, 0, 'Disable channel 1 with mask 1');
  }

  public function testTest() {
    var a = new Layers();
    var b = new Layers();
    assertTrue(a.test(b), 'Start out true');

    a.set(1);
    assertFalse(a.test(b), 'Set channel 1 in a and fail the test');

    b.toggle(1);
    assertTrue(a.test(b), 'Toggle channel 1 in b and pass again');
  }

  public function testIsEnabled() {
    var a = new Layers();
    a.enable(1);
    assertTrue(a.isEnabled(1), 'Enable channel 1 and pass the test');

    a.enable(2);
    assertTrue(a.isEnabled(2), 'Enable channel 2 and pass the test');

    a.toggle(1);
    assertFalse(a.isEnabled(1), 'Toggle channel 1 and fail the test');
    assertTrue(a.isEnabled(2), 'Channel 2 still enabled and pass the test');
  }
}