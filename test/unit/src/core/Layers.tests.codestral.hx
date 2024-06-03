import qunit.QUnit;
import three.src.core.Layers;

class LayersTests {
    public function new() {
        QUnit.module("Core", () -> {
            QUnit.module("Layers", () -> {
                QUnit.test("Instancing", (assert) -> {
                    var object = new Layers();
                    assert.True(object != null, "Can instantiate a Layers.");
                });

                QUnit.test("set", (assert) -> {
                    var a = new Layers();
                    for (i in 0...31) {
                        a.set(i);
                        assert.AreEqual(a.mask, Math.pow(2, i), "Mask has the expected value for channel: " + i);
                    }
                });

                QUnit.test("enable", (assert) -> {
                    var a = new Layers();

                    a.set(0);
                    a.enable(0);
                    assert.AreEqual(a.mask, 1, "Enable channel 0 with mask 0");

                    a.set(0);
                    a.enable(1);
                    assert.AreEqual(a.mask, 3, "Enable channel 1 with mask 0");

                    a.set(1);
                    a.enable(0);
                    assert.AreEqual(a.mask, 3, "Enable channel 0 with mask 1");

                    a.set(1);
                    a.enable(1);
                    assert.AreEqual(a.mask, 2, "Enable channel 1 with mask 1");
                });

                QUnit.test("toggle", (assert) -> {
                    var a = new Layers();

                    a.set(0);
                    a.toggle(0);
                    assert.AreEqual(a.mask, 0, "Toggle channel 0 with mask 0");

                    a.set(0);
                    a.toggle(1);
                    assert.AreEqual(a.mask, 3, "Toggle channel 1 with mask 0");

                    a.set(1);
                    a.toggle(0);
                    assert.AreEqual(a.mask, 3, "Toggle channel 0 with mask 1");

                    a.set(1);
                    a.toggle(1);
                    assert.AreEqual(a.mask, 0, "Toggle channel 1 with mask 1");
                });

                QUnit.test("disable", (assert) -> {
                    var a = new Layers();

                    a.set(0);
                    a.disable(0);
                    assert.AreEqual(a.mask, 0, "Disable channel 0 with mask 0");

                    a.set(0);
                    a.disable(1);
                    assert.AreEqual(a.mask, 1, "Disable channel 1 with mask 0");

                    a.set(1);
                    a.disable(0);
                    assert.AreEqual(a.mask, 2, "Disable channel 0 with mask 1");

                    a.set(1);
                    a.disable(1);
                    assert.AreEqual(a.mask, 0, "Disable channel 1 with mask 1");
                });

                QUnit.test("test", (assert) -> {
                    var a = new Layers();
                    var b = new Layers();

                    assert.True(a.test(b), "Start out true");

                    a.set(1);
                    assert.False(a.test(b), "Set channel 1 in a and fail the test");

                    b.toggle(1);
                    assert.True(a.test(b), "Toggle channel 1 in b and pass again");
                });

                QUnit.test("isEnabled", (assert) -> {
                    var a = new Layers();

                    a.enable(1);
                    assert.True(a.isEnabled(1), "Enable channel 1 and pass the test");

                    a.enable(2);
                    assert.True(a.isEnabled(2), "Enable channel 2 and pass the test");

                    a.toggle(1);
                    assert.False(a.isEnabled(1), "Toggle channel 1 and fail the test");
                    assert.True(a.isEnabled(2), "Channel 2 still enabled and pass the test");
                });
            });
        });
    }
}