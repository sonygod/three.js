package three.animation;

import three.animation.AnimationMixer;
import three.core.EventDispatcher;
import three.animation.AnimationClip;
import three.animation.tracks.VectorKeyframeTrack;
import three.core.Object3D;
import three.utils.MathConstants;

class AnimationMixerTests {

  public static function getClips(pos1:Vector3, pos2:Vector3, scale1:Vector3, scale2:Vector3, dur:Float) {
    var clips = [];
    var track = new VectorKeyframeTrack('.scale', [0, dur], [scale1.x, scale1.y, scale1.z, scale2.x, scale2.y, scale2.z]);
    clips.push(new AnimationClip('scale', dur, [track]));
    track = new VectorKeyframeTrack('.position', [0, dur], [pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z]);
    clips.push(new AnimationClip('position', dur, [track]));
    return clips;
  }

  public function new() {}

  public static function main() {
    #if (js && qunit)
    QUnit.module('Animation', () => {
      QUnit.module('AnimationMixer', () => {
        // INHERITANCE
        QUnit.test('Extending', (assert) => {
          var object = new AnimationMixer();
          assert.ok(object instanceof EventDispatcher, 'AnimationMixer extends from EventDispatcher');
        });

        // INSTANCING
        QUnit.test('Instancing', (assert) => {
          var object = new AnimationMixer();
          assert.ok(object, 'Can instantiate a AnimationMixer.');
        });

        // PROPERTIES
        QUnit.todo('time', (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('timeScale', (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.todo('clipAction', (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('existingAction', (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('stopAllAction', (assert) => {
          var obj = new Object3D();
          var animMixer = new AnimationMixer(obj);
          var clips = getClips(MathConstants.ZERO3, MathConstants.ONE3, MathConstants.TWO3, MathConstants.ONE3, 1);
          var actionA = animMixer.clipAction(clips[0]);
          var actionB = animMixer.clipAction(clips[1]);

          actionA.play();
          actionB.play();
          animMixer.update(0.1);
          animMixer.stopAllAction();

          assert.ok(!actionA.isRunning() && !actionB.isRunning(), 'All actions stopped');
          assert.ok(obj.position.x == 0 && obj.position.y == 0 && obj.position.z == 0, 'Position reset as expected');
          assert.ok(obj.scale.x == 1 && obj.scale.y == 1 && obj.scale.z == 1, 'Scale reset as expected');
        });

        QUnit.todo('update', (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('setTime', (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('getRoot', (assert) => {
          var obj = new Object3D();
          var animMixer = new AnimationMixer(obj);
          assert.strictEqual(obj, animMixer.getRoot(), 'Get original root object');
        });

        QUnit.todo('uncacheClip', (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('uncacheRoot', (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('uncacheAction', (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });
      });
    });
    #end
  }
}