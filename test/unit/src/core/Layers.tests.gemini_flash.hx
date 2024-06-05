import qunit.QUnit;

class Layers {
  public var mask:Int;

  public function new() {
    this.mask = 0;
  }

  public function set( channel:Int ) : Void {
    this.mask = Math.pow(2, channel);
  }

  public function enable( channel:Int ) : Void {
    this.mask |= Math.pow(2, channel);
  }

  public function toggle( channel:Int ) : Void {
    this.mask ^= Math.pow(2, channel);
  }

  public function disable( channel:Int ) : Void {
    this.mask &= ~Math.pow(2, channel);
  }

  public function test( other:Layers ) : Bool {
    return (this.mask & other.mask) == this.mask;
  }

  public function isEnabled( channel:Int ) : Bool {
    return (this.mask & Math.pow(2, channel)) != 0;
  }
}

class CoreTest {
  static function main() {
    QUnit.module("Core", function() {
      QUnit.module("Layers", function() {
        // INSTANCING
        QUnit.test("Instancing", function(assert) {
          var object = new Layers();
          assert.ok(object, "Can instantiate a Layers.");
        });

        // PROPERTIES
        QUnit.todo("mask", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("set", function(assert) {
          var a = new Layers();
          for (i in 0...31) {
            a.set(i);
            assert.strictEqual(a.mask, Math.pow(2, i), "Mask has the expected value for channel: " + i);
          }
        });

        QUnit.test("enable", function(assert) {
          var a = new Layers();
          a.set(0);
          a.enable(0);
          assert.strictEqual(a.mask, 1, "Enable channel 0 with mask 0");

          a.set(0);
          a.enable(1);
          assert.strictEqual(a.mask, 3, "Enable channel 1 with mask 0");

          a.set(1);
          a.enable(0);
          assert.strictEqual(a.mask, 3, "Enable channel 0 with mask 1");

          a.set(1);
          a.enable(1);
          assert.strictEqual(a.mask, 2, "Enable channel 1 with mask 1");
        });

        QUnit.todo("enableAll", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.test("toggle", function(assert) {
          var a = new Layers();
          a.set(0);
          a.toggle(0);
          assert.strictEqual(a.mask, 0, "Toggle channel 0 with mask 0");

          a.set(0);
          a.toggle(1);
          assert.strictEqual(a.mask, 3, "Toggle channel 1 with mask 0");

          a.set(1);
          a.toggle(0);
          assert.strictEqual(a.mask, 3, "Toggle channel 0 with mask 1");

          a.set(1);
          a.toggle(1);
          assert.strictEqual(a.mask, 0, "Toggle channel 1 with mask 1");
        });

        QUnit.test("disable", function(assert) {
          var a = new Layers();
          a.set(0);
          a.disable(0);
          assert.strictEqual(a.mask, 0, "Disable channel 0 with mask 0");

          a.set(0);
          a.disable(1);
          assert.strictEqual(a.mask, 1, "Disable channel 1 with mask 0");

          a.set(1);
          a.disable(0);
          assert.strictEqual(a.mask, 2, "Disable channel 0 with mask 1");

          a.set(1);
          a.disable(1);
          assert.strictEqual(a.mask, 0, "Disable channel 1 with mask 1");
        });

        QUnit.todo("disableAll", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.test("test", function(assert) {
          var a = new Layers();
          var b = new Layers();
          assert.ok(a.test(b), "Start out true");

          a.set(1);
          assert.notOk(a.test(b), "Set channel 1 in a and fail the QUnit.test");

          b.toggle(1);
          assert.ok(a.test(b), "Toggle channel 1 in b and pass again");
        });

        QUnit.test("isEnabled", function(assert) {
          var a = new Layers();
          a.enable(1);
          assert.ok(a.isEnabled(1), "Enable channel 1 and pass the QUnit.test");

          a.enable(2);
          assert.ok(a.isEnabled(2), "Enable channel 2 and pass the QUnit.test");

          a.toggle(1);
          assert.notOk(a.isEnabled(1), "Toggle channel 1 and fail the QUnit.test");
          assert.ok(a.isEnabled(2), "Channel 2 still enabled and pass the QUnit.test");
        });
      });
    });
  }
}