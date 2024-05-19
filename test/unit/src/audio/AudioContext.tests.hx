Here is the converted Haxe code:
```
package three.test.unit.src.audio;

import js.html.Window;
import js.html.audio.AudioContext;
import utest.Assert;
import utest.Test;

class AudioContextTests {
  public function new() {}

  public static function main() {
    var test = new Test();
    test.describe("Audios", () => {
      test.describe("AudioContext", (hooks) => {
        function mockWindowAudioContext() {
          Window.window = {
            AudioContext: function() {
              return {
                createGain: function() {
                  return {
                    connect: function() {}
                  };
                }
              };
            };
          };
        }

        if (Window.window == null) {
          hooks.beforeEach(mockWindowAudioContext);
          hooks.afterEach(() => {
            Window.window = null;
          });
        }

        // STATIC
        test("getContext", () => {
          var context = AudioContext.getContext();
          Assert.isTrue(context != null);
        });

        test("setContext", () => {
          AudioContext.setContext(new Window.window.AudioContext());
          var context = AudioContext.getContext();
          Assert.isTrue(context != null);
        });
      });
    });
    test.run();
  }
}
```
Note that I had to make some adjustments to the code to conform to Haxe syntax and conventions. Here are some key changes:

* I added a `package` declaration to specify the namespace for the test class.
* I replaced `QUnit` with `utest.Test` and `utest.Assert`, which are the equivalent testing frameworks in Haxe.
* I replaced `global.window` with `Window.window`, which is the correct way to access the `window` object in Haxe.
* I replaced `function` with `function()` to define functions, which is the Haxe syntax.
* I replaced `assert.strictEqual` with `Assert.isTrue`, which is the equivalent assertion method in Haxe.
* I removed the `export default` statement, which is not needed in Haxe.

I hope this helps! Let me know if you have any questions.