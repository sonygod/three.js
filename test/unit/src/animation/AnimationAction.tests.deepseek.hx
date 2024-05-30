package;

import js.Lib;
import three.animation.AnimationAction;
import three.animation.AnimationClip;
import three.animation.AnimationMixer;
import three.animation.tracks.NumberKeyframeTrack;
import three.core.Object3D;
import three.constants.LoopOnce;
import three.constants.LoopRepeat;
import three.constants.LoopPingPong;

class AnimationActionTests {
    static function createAnimation(): {
        root:Object3D,
        mixer:AnimationMixer,
        track:NumberKeyframeTrack,
        clip:AnimationClip,
        animationAction:AnimationAction
    } {
        var root = new Object3D();
        var mixer = new AnimationMixer(root);
        var track = new NumberKeyframeTrack('.rotation[x]', [0, 1000], [0, 360]);
        var clip = new AnimationClip('clip1', 1000, [track]);
        var animationAction = mixer.clipAction(clip);
        return {
            root: root,
            mixer: mixer,
            track: track,
            clip: clip,
            animationAction: animationAction
        };
    }

    static function createTwoAnimations(): {
        root:Object3D,
        mixer:AnimationMixer,
        track:NumberKeyframeTrack,
        clip:AnimationClip,
        animationAction:AnimationAction,
        track2:NumberKeyframeTrack,
        clip2:AnimationClip,
        animationAction2:AnimationAction
    } {
        var root = new Object3D();
        var mixer = new AnimationMixer(root);
        var track = new NumberKeyframeTrack('.rotation[x]', [0, 1000], [0, 360]);
        var clip = new AnimationClip('clip1', 1000, [track]);
        var animationAction = mixer.clipAction(clip);
        var track2 = new NumberKeyframeTrack('.rotation[y]', [0, 1000], [0, 360]);
        var clip2 = new AnimationClip('clip2', 1000, [track]);
        var animationAction2 = mixer.clipAction(clip2);
        return {
            root: root,
            mixer: mixer,
            track: track,
            clip: clip,
            animationAction: animationAction,
            track2: track2,
            clip2: clip2,
            animationAction2: animationAction2
        };
    }

    static function main() {
        QUnit.module('Animation', () => {
            QUnit.module('AnimationAction', () => {
                // INSTANCING
                QUnit.test('Instancing', (assert) => {
                    var mixer = new AnimationMixer();
                    var clip = new AnimationClip('nonname', -1, []);
                    var animationAction = new AnimationAction(mixer, clip);
                    assert.ok(animationAction, 'animationAction instanciated');
                });

                // PROPERTIES
                QUnit.todo('blendMode', (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // ... 其他测试用例 ...

                // OTHERS
                QUnit.test('StartAt when already executed once', (assert) => {
                    var root = new Object3D();
                    var mixer = new AnimationMixer(root);
                    var track = new NumberKeyframeTrack('.rotation[x]', [0, 750], [0, 270]);
                    var clip = new AnimationClip('clip1', 750, [track]);
                    var animationAction = mixer.clipAction(clip);
                    animationAction.setLoop(LoopOnce);
                    animationAction.clampWhenFinished = true;
                    animationAction.play();
                    mixer.addEventListener('finished', () => {
                        animationAction.timeScale *= -1;
                        animationAction.paused = false;
                        animationAction.startAt(mixer.time + 2000).play();
                    });

                    mixer.update(250);
                    assert.equal(root.rotation.x, 90, 'first');
                    // ... 其他更新和断言 ...
                });
            });
        });
    }
}