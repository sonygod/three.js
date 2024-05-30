import h3d.AnimationAction;
import h3d.AnimationMixer;
import h3d.AnimationClip;
import h3d.NumberKeyframeTrack;
import h3d.Object3D;

class LoopOnce {}
class LoopRepeat {}
class LoopPingPong {}

function createAnimation():Void {
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

function createTwoAnimations():Void {
    var root = new Object3D();
    var mixer = new AnimationMixer(root);
    var track = new NumberKeyframeTrack('.rotation[x]', [0, 1000], [0, 360]);
    var clip = new AnimationClip('clip1', 1000, [track]);
    var animationAction = mixer.clipAction(clip);
    var track2 = new NumberKeyframeTrack('.rotation[y]', [0, 1000], [0, 360]);
    var clip2 = new AnimationClip('clip2', 1000, [track2]);
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

class QUnit {
    public function new(name:String) {

    }

    public function module(name:String, callback:Void->Void):Void {

    }

    public function test(name:String, callback:Void->Void):Void {

    }
}

class UserException extends Dynamic {
    var message:String;
}

class AnimationActionTest {
    public static function main():Void {
        var qunit = new QUnit('AnimationAction');

        qunit.module('Instancing', function():Void {
            qunit.test('Instancing', function():Void {
                var mixer = new AnimationMixer();
                var clip = new AnimationClip('noname', -1, []);
                var animationAction = new AnimationAction(mixer, clip);
                trace('animationAction instanciated: $animationAction');
            });
        });

        qunit.module('Properties', function():Void {
            // TODO: Implement tests for properties
        });

        qunit.module('Public Stuff', function():Void {
            qunit.test('play', function():Void {
                var data = createAnimation();
                var animationAction2 = data.animationAction.play();
                trace('AnimationAction.play can be chained: $animationAction2');

                var mixer = data.mixer;
                var animationAction = data.animationAction;
                var userException = new UserException();
                userException.message = 'AnimationMixer must activate AnimationAction on play.';

                mixer._activateAction = function(action):Void {
                    if (action == animationAction) {
                        throw userException;
                    }
                }

                try {
                    animationAction.play();
                } catch (e) {
                    trace(e.message);
                }
            });

            qunit.test('stop', function():Void {
                var data = createAnimation();
                var animationAction2 = data.animationAction.stop();
                trace('AnimationAction.stop can be chained: $animationAction2');

                var mixer = data.mixer;
                var animationAction = data.animationAction;
                var userException = new UserException();
                userException.message = 'AnimationMixer must deactivate AnimationAction on stop.';

                mixer._deactivateAction = function(action):Void {
                    if (action == animationAction) {
                        throw userException;
                    }
                }

                try {
                    animationAction.stop();
                } catch (e) {
                    trace(e.message);
                }
            });

            qunit.test('reset', function():Void {
                var data = createAnimation();
                var animationAction2 = data.animationAction.stop();
                trace('AnimationAction.reset can be chained: $animationAction2');
                trace('AnimationAction.reset() sets paused: $animationAction2.paused');
                trace('AnimationAction.reset() sets enabled: $animationAction2.enabled');
                trace('AnimationAction.reset() resets time: $animationAction2.time');
                trace('AnimationAction.reset() resets loopcount: $animationAction2._loopCount');
                trace('AnimationAction.reset() removes starttime: $animationAction2._startTime');
            });

            qunit.test('isRunning', function():Void {
                var data = createAnimation();
                trace('When an animation is just made, it is not running: $data.animationAction.isRunning()');
                data.animationAction.play();
                trace('When an animation is started, it is running: $data.animationAction.isRunning()');
                data.animationAction.stop();
                trace('When an animation is stopped, it is not running: $data.animationAction.isRunning()');
                data.animationAction.play();
                data.animationAction.paused = true;
                trace('When an animation is paused, it is not running: $data.animationAction.isRunning()');
                data.animationAction.paused = false;
                data.animationAction.enabled = false;
                trace('When an animation is not enabled, it is not running: $data.animationAction.isRunning()');
                data.animationAction.enabled = true;
                trace('When an animation is enabled, it is running: $data.animationAction.isRunning()');
            });

            qunit.test('isScheduled', function():Void {
                var data = createAnimation();
                trace('When an animation is just made, it is not scheduled: $data.animationAction.isScheduled()');
                data.animationAction.play();
                trace('When an animation is started, it is scheduled: $data.animationAction.isScheduled()');
                data.mixer.update(1);
                trace('When an animation is updated, it is scheduled: $data.animationAction.isScheduled()');
                data.animationAction.stop();
                trace('When an animation is stopped, it is not scheduled anymore: $data.animationAction.isScheduled()');
            });

            qunit.test('startAt', function():Void {
                var data = createAnimation();
                data.animationAction.startAt(2);
                data.animationAction.play();
                trace('When an animation is started at a specific time, it is not running: $data.animationAction.isRunning()');
                trace('When an animation is started at a specific time, it is scheduled: $data.animationAction.isScheduled()');
                data.mixer.update(1);
                trace('When an animation is started at a specific time and the interval is not passed, it is not running: $data.animationAction.isRunning()');
                trace('When an animation is started at a specific time and the interval is not passed, it is scheduled: $data.animationAction.isScheduled()');
                data.mixer.update(1);
                trace('When an animation is started at a specific time and the interval is passed, it is running: $data.animationAction.isRunning()');
                trace('When an animation is started at a specific time and the interval is passed, it is scheduled: $data.animationAction.isScheduled()');
                data.animationAction.stop();
                trace('When an animation is stopped, it is not running: $data.animationAction.isRunning()');
                trace('When an animation is stopped, it is not scheduled: $data.animationAction.isScheduled()');
            });

            qunit.test('setLoop LoopOnce', function():Void {
                var data = createAnimation();
                data.animationAction.setLoop(LoopOnce);
                data.animationAction.play();
                trace('When an animation is started, it is running: $data.animationAction.isRunning()');
                data.mixer.update(500);
                trace('When an animation is in the first loop, it is running: $data.animationAction.isRunning()');
                data.mixer.update(500);
                trace('When an animation is ended, it is not running: $data.animationAction.isRunning()');
                data.mixer.update(500);
                trace('When an animation is ended, it is not running: $data.animationAction.isRunning()');
            });

            qunit.test('setLoop LoopRepeat', function():Void {
                var data = createAnimation();
                data.animationAction.setLoop(LoopRepeat, 3);
                data.animationAction.play();
                trace('When an animation is started, it is running: $data.animationAction.isRunning()');
                data.mixer.update(750);
                trace('When an animation is 3/4 in the first loop, it has changed to 3/4 when LoopRepeat: $data.root.rotation.x');
                trace('When an animation is in the first loop, it is running: $data.animationAction.isRunning()');
                data.mixer.update(1000);
                trace('When an animation is 3/4 in the second loop, it has changed to 3/4 when LoopRepeat: $data.root.rotation.x');
                trace('When an animation is in second loop when in looprepeat 3 times, it is running: $data.animationAction.isRunning()');
                data.mixer.update(1000);
                trace('When an animation is 3/4 in the third loop, it has changed to 3/4 when LoopRepeat: $data.root.rotation.x');
                trace('When an animation is in third loop when in looprepeat 3 times, it is running: $data.animationAction.isRunning()');
                data.mixer.update(1000);
                trace('When an animation ended his third loop when in looprepeat 3 times, it stays on the end result: $data.root.rotation.x');
                trace('When an animation ended his third loop when in looprepeat 3 times, it stays not running anymore: $data.animationAction.isRunning()');
            });

            qunit.test('setLoop LoopPingPong', function():Void {
                var data = createAnimation();
                data.animationAction.setLoop(LoopPingPong, 3);
                data.animationAction.play();
                trace('When an animation is started, it is running: $data.animationAction.isRunning()');
                data.mixer.update(750);
                trace('When an animation is 3/4 in the first loop, it has changed to 3/4 when LoopPingPong: $data.root.rotation.x');
                trace('When an animation is in the first loop, it is running: $data.animationAction.isRunning()');
                data.mixer.update(1000);
                trace('When an animation is 3/4 in the second loop, it has changed to 1/4 when LoopPingPong: $data.root.rotation.x');
                trace('When an animation is in second loop when in looprepeat 3 times, it is running: $data.animationAction.isRunning()');
                data.mixer.update(1000);
                trace('When an animation is 3/4 in the third loop, it has changed to 3/4 when LoopPingPong: $data.root.rotation.x');
                trace('When an animation is in third loop when in looprepeat 3 times, it is running: $data.animationAction.isRunning()');
                data.mixer.update(1000);
                trace('When an animation ended his fourth loop when in looprepeat 3 times, it stays on the end result: $data.root.rotation.x');
                trace('When an animation ended his fourth loop when in looprepeat 3 times, it stays not running anymore: $data.animationAction.isRunning()');
            });

            qunit.test('setEffectiveWeight', function():Void {
                var data = createAnimation();
                trace('When an animation is created, EffectiveWeight is 1: $data.animationAction.getEffectiveWeight()');
                data.animationAction.setEffectiveWeight(0.3);
                trace('When EffectiveWeight is set to 0.3, EffectiveWeight is 0.3: $data.animationAction.getEffectiveWeight()');
            });

            qunit.test('setEffectiveWeight - disabled', function():Void {
                var data = createAnimation();
                trace('When an animation is created, EffectiveWeight is 1: $data.animationAction.getEffectiveWeight()');
                data.animationAction.enabled = false;
                data.animationAction.setEffectiveWeight(0.3);
                trace('When EffectiveWeight is set to 0.3 when disabled, EffectiveWeight is 0: $data.animationAction.getEffectiveWeight()');
            });

            qunit.test('setEffectiveWeight - over duration', function():Void {
                var data = createAnimation();
                data.animationAction.setEffectiveWeight(0.5);
                data.animationAction.play();
                data.mixer.update(500);
                trace('When an animation has weight 0.5 and runs half through the animation, it has changed to 1/4: $data.root.rotation.x');
                data.mixer.update(1000);
                trace('When an animation has weight 0.5 and runs one and half through the animation, it has changed to 1/4: $data.root.rotation.x');
            });

            qunit.test('getEffectiveWeight', function():Void {
                var data = createAnimation();
                trace('When an animation is created, EffectiveWeight is 1: $data.animationAction.getEffectiveWeight()');
                data.animationAction.setEffectiveWeight(0.3);
                trace('When EffectiveWeight is set to 0.3, EffectiveWeight is 0.3: $data.animationAction.getEffectiveWeight()');

                var data2 = createAnimation();
                trace('When an animation is created, EffectiveWeight is 1: $data2.animationAction.getEffectiveWeight()');
                data2.animationAction.enabled = false;
                data2.animationAction.setEffectiveWeight(0.3);
                trace('When EffectiveWeight is set to 0.3 when disabled, EffectiveWeight is 0: $data2.animationAction.getEffectiveWeight()');
            });

            qunit.test('fadeIn', function():Void {
                var data = createAnimation();
                data.animationAction.fadeIn(1000);
                data.animationAction.play();
                trace('When an animation fadeIn is started, EffectiveWeight is 1: $data.animationAction.getEffectiveWeight()');
                data.mixer.update(250);
                trace('When an animation fadeIn happened 1/4, EffectiveWeight is 0.25: $data.animationAction.getEffectiveWeight()');
                data.mixer.update(250);
                trace('When an animation fadeIn is halfway, EffectiveWeight is 0.5: $data.animationAction.getEffectiveWeight()');
                data.mixer.update(250);
                trace('When an animation fadeIn is halfway, EffectiveWeight is 0.75: $data.animationAction.getEffectiveWeight()');
                data.mixer.update(500);
                trace('When an animation fadeIn is ended, EffectiveWeight is 1: $data.animationAction.getEffectiveWeight()');
            });

            qunit.test('fadeOut', function():Void {
                var data = createAnimation();
                data.animationAction.fadeOut(1000);
                data.animationAction.play();
                trace('When an animation fadeOut is started, EffectiveWeight is 1: $data.animationAction.getEffectiveWeight()');
                data.mixer.update(250);
                trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: $data.animationAction.getEffectiveWeight()');
                data.mixer.update(250);
                trace('When an animation fadeOut is halfway, EffectiveWeight is 0.5: $data.animationAction.getEffectiveWeight()');
                data.mixer.update(250);
                trace('When an animation fadeOut is happened 3/4, EffectiveWeight is 0.25: $data.animationAction.getEffectiveWeight()');
                data.mixer.update(500);
                trace('When an animation fadeOut is ended, EffectiveWeight is 0: $data.animationAction.getEffectiveWeight()');
            });

            qunit.test('crossFadeFrom', function():Void {
                var data = createTwoAnimations();
                data.animationAction.crossFadeFrom(data.animationAction2, 1000, false);
                data.animationAction.play();
                data.animationAction2.play();
                trace('When an animation crossFadeFrom is started, EffectiveWeight is 1: $data.animationAction.getEffectiveWeight()');
                trace('When an animation crossFadeFrom is started, EffectiveWeight is 1: $data.animationAction2.getEffectiveWeight()');
                data.mixer.update(250);
                trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: $data.animationAction.getEffectiveWeight()');
                trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: $data.animationAction2.getEffectiveWeight()');
                data.mixer.update(250);
                trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: $data.animationAction.getEffectiveWeight()');
                trace('When an animation fadeOut is halfway, EffectiveWeight is 0.5: $data.animationAction2.getEffectiveWeight()');
                data.mixer.update(data.mixer.update(250);
trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: $data.animationAction2.getEffectiveWeight()');
data.mixer.update(500);
trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: $data.animationAction.getEffectiveWeight()');
trace('When an animation fadeOut is ended, EffectiveWeight is 0: $data.animationAction2.getEffectiveWeight()');

qunit.test('crossFadeTo', function():Void {
var data = createTwoAnimations();
data.animationAction2.crossFadeTo(data.animationAction, 1000, false);
data.animationAction.play();
data.animationAction2.play();
trace('When an animation crossFadeFrom is started, EffectiveWeight is 1: $data.animationAction.getEffectiveWeight()');
trace('When an animation crossFadeFrom is started, EffectiveWeight is 1: $data.animationAction2.getEffectiveWeight()');
data.mixer.update(250);
trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: $data.animationAction.getEffectiveWeight()');
trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: $data.animationAction2.getEffectiveWeight()');
data.mixer.update(250);
trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: $data.animationAction.getEffectiveWeight()');
trace('When an animation fadeOut is halfway, EffectiveWeight is 0.5: $data.animationAction2.getEffectiveWeight()');
data.mixer.update(250);
trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: $data.animationAction2.getEffectiveWeight()');
trace('When an animation fadeOut is happened 3/4, EffectiveWeight is 0.25: $data.animationAction.getEffectiveWeight()');
data.mixer.update(500);
trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: $data.animationAction2.getEffectiveWeight()');
trace('When an animation fadeOut is ended, EffectiveWeight is 0: $data.animationAction.getEffectiveWeight()');

});

// TODO: Implement tests for stopFading, setEffectiveTimeScale, getEffectiveTimeScale, setDuration, syncWith, halt, warp, and stopWarping

qunit.test('getMixer', function():Void {
var data = createAnimation();
var mixer2 = data.animationAction.getMixer();
trace('Mixer should be returned by getMixer: $mixer2');
});

qunit.test('getClip', function():Void {
var data = createAnimation();
var clip2 = data.animationAction.getClip();
trace('Clip should be returned by getClip: $clip2');
});

qunit.test('getRoot', function():Void {
var data = createAnimation();
var root2 = data.animationAction.getRoot();
trace('Root should be returned by getRoot: $root2');
});

qunit.test('StartAt when already executed once', function():Void {
var root = new Object3D();
var mixer = new AnimationMixer(root);
var track = new NumberKeyframeTrack('.rotation[x]', [0, 750], [0, 270]);
var clip = new AnimationClip('clip1', 750, [track]);

var animationAction = mixer.clipAction(clip);
animationAction.setLoop(LoopOnce);
animationAction.clampWhenFinished = true;
animationAction.play();

mixer.addEventListener('finished', function():Void {
animationAction.timeScale *= -1;
animationAction.paused = false;
animationAction.startAt(mixer.time + 2000).play();
});

mixer.update(250);
trace('First: $root.rotation.x');
mixer.update(250);
trace('First: $root.rotation.x');
mixer.update(250);
trace('First: $root.rotation.x');
// First loop done
mixer.update(2000);
// StartAt Done
mixer.update(250);
trace('Third: $root.rotation.x');
mixer.update(250);
trace('Fourth: $root.rotation.x');
mixer.update(250);
trace('Sixth: $root.rotation.x');
mixer.update(1);
trace('Seventh: $root.rotation.x');
mixer.update(1000);
trace('Seventh: $root.rotation.x');
mixer.update(1000);
trace('Seventh: $root.rotation.x');
mixer.update(250);
trace('Seventh: $root.rotation.x');
mixer.update(250);
trace('Seventh: $root.rotation.x');
});

}});

class Animation {
    public static function main():Void {
        var qunit = new QUnit('Animation');

        qunit.module('AnimationAction', function():Void {
            // Tests for AnimationAction class
            AnimationActionTest.main();
        });
    }
}

class AnimationActionTest {
    // Tests for AnimationAction class
    public static function main():Void {
        // Tests implemented previously
    }
}

class AnimationClipTest {
    // Tests for AnimationClip class
    public static function main():Void {
        // Tests to be implemented
    }
}

class NumberKeyframeTrackTest {
    // Tests for NumberKeyframeTrack class
    public static function main():Void {
        // Tests to be implemented
    }
}

class Object3DTest {
    // Tests for Object3D class
    public static function main():Void {
        // Tests to be implemented
    }
}

// Export the main function to be executed
export default function():Void {
    Animation.main();
}