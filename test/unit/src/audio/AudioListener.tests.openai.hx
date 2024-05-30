import three.audio.AudioListener;
import three.core.Object3D;

class AudioListenerTests {
  public static function testAll() {
    Suite.asyncTest("Audios", () => {
      Suite.test("AudioListener", () => {
        // mock window.AudioContext
        var _window:Dynamic = {
          get_AudioContext: () -> {
            return {
              createGain: () -> {
                return {
                  connect: () -> {}
                };
              }
            };
          }
        };

        if (window == null) {
          Before(() -> {
            window = _window;
          });

          After(() -> {
            window = null;
          });
        }

        // INHERITANCE
        Test("Extending", () -> {
          var object = new AudioListener();
          Assert.isTrue(object instanceof Object3D, "AudioListener extends from Object3D");
        });

        // INSTANCING
        Test("Instancing", () -> {
          var object = new AudioListener();
          Assert.isTrue(object != null, "Can instantiate an AudioListener.");
        });

        // PROPERTIES
        Test("type", () -> {
          var object = new AudioListener();
          Assert.equals(object.type, "AudioListener", "AudioListener.type should be AudioListener");
        });

        Todo("context", () -> {
          Assert.fail("everything's gonna be alright");
        });

        Todo("gain", () -> {
          Assert.fail("everything's gonna be alright");
        });

        Todo("filter", () -> {
          Assert.fail("everything's gonna be alright");
        });

        Todo("timeDelta", () -> {
          Assert.fail("everything's gonna be alright");
        });

        // PUBLIC
        Todo("getInput", () -> {
          Assert.fail("everything's gonna be alright");
        });

        Todo("removeFilter", () -> {
          Assert.fail("everything's gonna be alright");
        });

        Todo("getFilter", () -> {
          Assert.fail("everything's gonna be alright");
        });

        Todo("setFilter", () -> {
          Assert.fail("everything's gonna be alright");
        });

        Todo("getMasterVolume", () -> {
          Assert.fail("everything's gonna be alright");
        });

        Todo("setMasterVolume", () -> {
          Assert.fail("everything's gonna be alright");
        });

        Todo("updateMatrixWorld", () -> {
          Assert.fail("everything's gonna be alright");
        });
      });
    });
  }
}