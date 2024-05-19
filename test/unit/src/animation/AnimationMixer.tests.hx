package three.test.unit.src.animation;

import three.animation.AnimationMixer;
import three.core.EventDispatcher;
import three.animation.AnimationClip;
import three.animation.tracks.VectorKeyframeTrack;
import three.core.Object3D;
import three.utils.MathConstants;

class AnimationMixerTests {

    function getClips(pos1:Vector3, pos2:Vector3, scale1:Vector3, scale2:Vector3, dur:Float) : Array<AnimationClip> {
        var clips = new Array<AnimationClip>();

        var track = new VectorKeyframeTrack('.scale', [0, dur], [scale1.x, scale1.y, scale1.z, scale2.x, scale2.y, scale2.z]);
        clips.push(new AnimationClip('scale', dur, [track]));

        track = new VectorKeyframeTrack('.position', [0, dur], [pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z]);
        clips.push(new AnimationClip('position', dur, [track]));

        return clips;
    }

    public function new() {}

    public function test() {
        suite("Animation", () => {
            suite("AnimationMixer", () => {
                test("Extending", () => {
                    var object = new AnimationMixer();
                    Assert.isTrue(object instanceof EventDispatcher, 'AnimationMixer extends from EventDispatcher');
                });

                test("Instancing", () => {
                    var object = new AnimationMixer();
                    Assert.isTrue(object != null, 'Can instantiate a AnimationMixer.');
                });

                todo("time", () => {
                    Assert.fail("everything's gonna be alright");
                });

                todo("timeScale", () => {
                    Assert.fail("everything's gonna be alright");
                });

                todo("clipAction", () => {
                    Assert.fail("everything's gonna be alright");
                });

                todo("existingAction", () => {
                    Assert.fail("everything's gonna be alright");
                });

                test("stopAllAction", () => {
                    var obj = new Object3D();
                    var animMixer = new AnimationMixer(obj);
                    var clips = getClips(MathConstants.ZERO3, MathConstants.ONE3, MathConstants.TWO3, MathConstants.ONE3, 1);
                    var actionA = animMixer.clipAction(clips[0]);
                    var actionB = animMixer.clipAction(clips[1]);

                    actionA.play();
                    actionB.play();
                    animMixer.update(0.1);
                    animMixer.stopAllAction();

                    Assert.isTrue(!actionA.isRunning() && !actionB.isRunning(), 'All actions stopped');
                    Assert.isTrue(obj.position.x == 0 && obj.position.y == 0 && obj.position.z == 0, 'Position reset as expected');
                    Assert.isTrue(obj.scale.x == 1 && obj.scale.y == 1 && obj.scale.z == 1, 'Scale reset as expected');
                });

                todo("update", () => {
                    Assert.fail("everything's gonna be alright");
                });

                todo("setTime", () => {
                    Assert.fail("everything's gonna be alright");
                });

                test("getRoot", () => {
                    var obj = new Object3D();
                    var animMixer = new AnimationMixer(obj);
                    Assert.areEqual(obj, animMixer.getRoot(), 'Get original root object');
                });

                todo("uncacheClip", () => {
                    Assert.fail("everything's gonna be alright");
                });

                todo("uncacheRoot", () => {
                    Assert.fail("everything's gonna be alright");
                });

                todo("uncacheAction", () => {
                    Assert.fail("everything's gonna be alright");
                });
            });
        });
    }
}