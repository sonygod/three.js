import js.QUnit;
import js.AnimationMixer;
import js.EventDispatcher;
import js.AnimationClip;
import js.VectorKeyframeTrack;
import js.Object3D;
import js.math_constants.*;

function getClips(pos1:Float32Array, pos2:Float32Array, scale1:Float32Array, scale2:Float32Array, dur:Float) -> Array<AnimationClip> {
    var clips = [];

    var track = new VectorKeyframeTrack('.scale', [0, dur], [scale1, scale2]);
    clips.push(new AnimationClip('scale', dur, [track]));

    track = new VectorKeyframeTrack('.position', [0, dur], [pos1, pos2]);
    clips.push(new AnimationClip('position', dur, [track]));

    return clips;
}

class _Main {
    static function main() {
        QUnit.module('Animation', function() {
            QUnit.module('AnimationMixer', function() {
                QUnit.test('Extending', function(assert) {
                    var object = new AnimationMixer();
                    assert.strictEqual(object instanceof EventDispatcher, true, 'AnimationMixer extends from EventDispatcher');
                });

                QUnit.test('Instancing', function(assert) {
                    var object = new AnimationMixer();
                    assert.ok(object, 'Can instantiate a AnimationMixer.');
                });

                QUnit.test('stopAllAction', function(assert) {
                    var obj = new Object3D();
                    var animMixer = new AnimationMixer(obj);
                    var clips = getClips(zero3, one3, two3, one3, 1);
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

                QUnit.test('getRoot', function(assert) {
                    var obj = new Object3D();
                    var animMixer = new AnimationMixer(obj);
                    assert.strictEqual(obj, animMixer.getRoot(), 'Get original root object');
                });
            });
        });
    }
}