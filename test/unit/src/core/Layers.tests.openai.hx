package three.core;

import utest.Assert;
import three.core.Layers;

class LayersTest {
  public static function main() {
    utest.Test.createSuite("Core", () => {
      utest.Test.createSuite("Layers", () => {
        // INSTANCING
        utest.Test.addTest("Instancing", () => {
          var object = new Layers();
          Assert.isTrue(object != null, 'Can instantiate a Layers.');
        });

        // PROPERTIES
        utest.Test.addTodo("mask", () => {
          Assert.fail('everything\'s gonna be alright');
        });

        // PUBLIC
        utest.Test.addTest("set", () => {
          var a = new Layers();
          for (i in 0...31) {
            a.set(i);
            Assert.equals(a.mask, Math.pow(2, i), 'Mask has the expected value for channel: $i');
          }
        });

        utest.Test.addTest("enable", () => {
          var a = new Layers();
          a.set(0);
          a.enable(0);
          Assert.equals(a.mask, 1, 'Enable channel 0 with mask 0');

          a.set(0);
          a.enable(1);
          Assert.equals(a.mask, 3, 'Enable channel 1 with mask 0');

          a.set(1);
          a.enable(0);
          Assert.equals(a.mask, 3, 'Enable channel 0 with mask 1');

          a.set(1);
          a.enable(1);
          Assert.equals(a.mask, 2, 'Enable channel 1 with mask 1');
        });

        utest.Test.addTodo("enableAll", () => {
          Assert.fail('everything\'s gonna be alright');
        });

        utest.Test.addTest("toggle", () => {
          var a = new Layers();
          a.set(0);
          a.toggle(0);
          Assert.equals(a.mask, 0, 'Toggle channel 0 with mask 0');

          a.set(0);
          a.toggle(1);
          Assert.equals(a.mask, 3, 'Toggle channel 1 with mask 0');

          a.set(1);
          a.toggle(0);
          Assert.equals(a.mask, 3, 'Toggle channel 0 with mask 1');

          a.set(1);
          a.toggle(1);
          Assert.equals(a.mask, 0, 'Toggle channel 1 with mask 1');
        });

        utest.Test.addTest("disable", () => {
          var a = new Layers();
          a.set(0);
          a.disable(0);
          Assert.equals(a.mask, 0, 'Disable channel 0 with mask 0');

          a.set(0);
          a.disable(1);
          Assert.equals(a.mask, 1, 'Disable channel 1 with mask 0');

          a.set(1);
          a.disable(0);
          Assert.equals(a.mask, 2, 'Disable channel 0 with mask 1');

          a.set(1);
          a.disable(1);
          Assert.equals(a.mask, 0, 'Disable channel 1 with mask 1');
        });

        utest.Test.addTodo("disableAll", () => {
          Assert.fail('everything\'s gonna be alright');
        });

        utest.Test.addTest("test", () => {
          var a = new Layers();
          var b = new Layers();
          Assert.isTrue(a.test(b), 'Start out true');

          a.set(1);
          Assert.isFalse(a.test(b), 'Set channel 1 in a and fail the test');

          b.toggle(1);
          Assert.isTrue(a.test(b), 'Toggle channel 1 in b and pass again');
        });

        utest.Test.addTest("isEnabled", () => {
          var a = new Layers();
          a.enable(1);
          Assert.isTrue(a.isEnabled(1), 'Enable channel 1 and pass the test');

          a.enable(2);
          Assert.isTrue(a.isEnabled(2), 'Enable channel 2 and pass the test');

          a.toggle(1);
          Assert.isFalse(a.isEnabled(1), 'Toggle channel 1 and fail the test');
          Assert.isTrue(a.isEnabled(2), 'Channel 2 still enabled and pass the test');
        });
      });
    });
  }
}