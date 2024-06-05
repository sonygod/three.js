import qunit.QUnit;
import three.core.Object3D;
import three.audio.AudioListener;

class AudiosTest extends QUnit.Module {
  override function setUp() {
    if (js.html.Window.typeof == "undefined") {
      js.Global.window = {
        AudioContext: function() {
          return {
            createGain: function() {
              return {
                connect: function() {}
              };
            }
          };
        }
      };
    }
  }

  override function tearDown() {
    if (js.html.Window.typeof == "undefined") {
      js.Global.window = null;
    }
  }

  public function testInheritance() {
    var object = new AudioListener();
    QUnit.assert.isTrue(object.is(Object3D), "AudioListener extends from Object3D");
  }

  public function testInstancing() {
    var object = new AudioListener();
    QUnit.assert.ok(object, "Can instantiate an AudioListener.");
  }

  public function testType() {
    var object = new AudioListener();
    QUnit.assert.equal(object.type, "AudioListener", "AudioListener.type should be AudioListener");
  }

  public function testContext() {
    QUnit.todo("AudioListener.context is not tested.");
  }

  public function testGain() {
    QUnit.todo("AudioListener.gain is not tested.");
  }

  public function testFilter() {
    QUnit.todo("AudioListener.filter is not tested.");
  }

  public function testTimeDelta() {
    QUnit.todo("AudioListener.timeDelta is not tested.");
  }

  public function testGetInput() {
    QUnit.todo("AudioListener.getInput is not tested.");
  }

  public function testRemoveFilter() {
    QUnit.todo("AudioListener.removeFilter is not tested.");
  }

  public function testGetFilter() {
    QUnit.todo("AudioListener.getFilter is not tested.");
  }

  public function testSetFilter() {
    QUnit.todo("AudioListener.setFilter is not tested.");
  }

  public function testGetMasterVolume() {
    QUnit.todo("AudioListener.getMasterVolume is not tested.");
  }

  public function testSetMasterVolume() {
    QUnit.todo("AudioListener.setMasterVolume is not tested.");
  }

  public function testUpdateMatrixWorld() {
    QUnit.todo("AudioListener.updateMatrixWorld is not tested.");
  }
}

class Audios extends QUnit.Module {
  override function setUp() {
    var listenerModule = new AudioListenerTest();
    listenerModule.name = "AudioListener";
    addModule(listenerModule);
  }
}

var audios = new Audios();
audios.name = "Audios";