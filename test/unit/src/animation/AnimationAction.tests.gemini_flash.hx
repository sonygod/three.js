import haxe.Timer;
import three.animation.AnimationAction;
import three.animation.AnimationClip;
import three.animation.AnimationMixer;
import three.animation.tracks.NumberKeyframeTrack;
import three.core.Object3D;
import three.constants.LoopOnce;
import three.constants.LoopRepeat;
import three.constants.LoopPingPong;

class AnimationTest {

	public static function main() {
		// INSTANCING
		testInstancing();
		// PROPERTIES
		//testBlendMode();
		//testLoop();
		//testTime();
		//testTimeScale();
		//testWeight();
		//testRepetitions();
		//testPaused();
		//testEnabled();
		//testClampWhenFinished();
		//testZeroSlopeAtStart();
		//testZeroSlopeAtEnd();
		// PUBLIC STUFF
		testPlay();
		testStop();
		testReset();
		testIsRunning();
		testIsScheduled();
		testStartAt();
		testSetLoopLoopOnce();
		testSetLoopLoopRepeat();
		testSetLoopLoopPingPong();
		testSetEffectiveWeight();
		testSetEffectiveWeightDisabled();
		testSetEffectiveWeightOverDuration();
		testGetEffectiveWeight();
		testFadeIn();
		testFadeOut();
		testCrossFadeFrom();
		testCrossFadeTo();
		//testStopFading();
		//testSetEffectiveTimeScale();
		//testGetEffectiveTimeScale();
		//testSetDuration();
		//testSyncWith();
		//testHalt();
		//testWarp();
		//testStopWarping();
		testGetMixer();
		testGetClip();
		testGetRoot();
		// OTHERS
		testStartAtWhenAlreadyExecutedOnce();
	}

	static function createAnimation() : {root:Object3D, mixer:AnimationMixer, track:NumberKeyframeTrack, clip:AnimationClip, animationAction:AnimationAction} {
		var root = new Object3D();
		var mixer = new AnimationMixer(root);
		var track = new NumberKeyframeTrack('.rotation[x]', [0, 1000], [0, 360]);
		var clip = new AnimationClip('clip1', 1000, [track]);
		var animationAction = mixer.clipAction(clip);
		return {root: root, mixer: mixer, track: track, clip: clip, animationAction: animationAction};
	}

	static function createTwoAnimations() : {root:Object3D, mixer:AnimationMixer, track:NumberKeyframeTrack, clip:AnimationClip, animationAction:AnimationAction, track2:NumberKeyframeTrack, clip2:AnimationClip, animationAction2:AnimationAction} {
		var root = new Object3D();
		var mixer = new AnimationMixer(root);
		var track = new NumberKeyframeTrack('.rotation[x]', [0, 1000], [0, 360]);
		var clip = new AnimationClip('clip1', 1000, [track]);
		var animationAction = mixer.clipAction(clip);
		var track2 = new NumberKeyframeTrack('.rotation[y]', [0, 1000], [0, 360]);
		var clip2 = new AnimationClip('clip2', 1000, [track2]);
		var animationAction2 = mixer.clipAction(clip2);
		return {root: root, mixer: mixer, track: track, clip: clip, animationAction: animationAction, track2: track2, clip2: clip2, animationAction2: animationAction2};
	}

	static function testInstancing() {
		var mixer = new AnimationMixer();
		var clip = new AnimationClip('nonname', -1, []);
		var animationAction = new AnimationAction(mixer, clip);
		trace('animationAction instanciated: ${animationAction}');
	}

	static function testPlay() {
		var {mixer, animationAction} = createAnimation();
		var animationAction2 = animationAction.play();
		trace('AnimationAction.play can be chained: ${animationAction == animationAction2}');
		var UserException = function () {
			this.message = 'AnimationMixer must activate AnimationAction on play.';
		};
		mixer._activateAction = function (action) {
			if (action == animationAction) {
				throw new UserException();
			}
		};
		try {
			animationAction.play();
			trace('Error: should throw an exception');
		} catch (e : UserException) {
			trace('Exception caught: ${e.message}');
		}
	}

	static function testStop() {
		var {mixer, animationAction} = createAnimation();
		var animationAction2 = animationAction.stop();
		trace('AnimationAction.stop can be chained: ${animationAction == animationAction2}');
		var UserException = function () {
			this.message = 'AnimationMixer must deactivate AnimationAction on stop.';
		};
		mixer._deactivateAction = function (action) {
			if (action == animationAction) {
				throw new UserException();
			}
		};
		try {
			animationAction.stop();
			trace('Error: should throw an exception');
		} catch (e : UserException) {
			trace('Exception caught: ${e.message}');
		}
	}

	static function testReset() {
		var {animationAction} = createAnimation();
		var animationAction2 = animationAction.reset();
		trace('AnimationAction.reset can be chained: ${animationAction == animationAction2}');
		trace('AnimationAction.reset() sets paused false: ${animationAction2.paused == false}');
		trace('AnimationAction.reset() sets enabled true: ${animationAction2.enabled == true}');
		trace('AnimationAction.reset() resets time: ${animationAction2.time == 0}');
		trace('AnimationAction.reset() resets loopcount: ${animationAction2._loopCount == -1}');
		trace('AnimationAction.reset() removes starttime: ${animationAction2._startTime == null}');
	}

	static function testIsRunning() {
		var {animationAction} = createAnimation();
		trace('When an animation is just made, it is not running: ${animationAction.isRunning() == false}');
		animationAction.play();
		trace('When an animation is started, it is running: ${animationAction.isRunning() == true}');
		animationAction.stop();
		trace('When an animation is stopped, it is not running: ${animationAction.isRunning() == false}');
		animationAction.play();
		animationAction.paused = true;
		trace('When an animation is paused, it is not running: ${animationAction.isRunning() == false}');
		animationAction.paused = false;
		animationAction.enabled = false;
		trace('When an animation is not enabled, it is not running: ${animationAction.isRunning() == false}');
		animationAction.enabled = true;
		trace('When an animation is enabled, it is running: ${animationAction.isRunning() == true}');
	}

	static function testIsScheduled() {
		var {mixer, animationAction} = createAnimation();
		trace('When an animation is just made, it is not scheduled: ${animationAction.isScheduled() == false}');
		animationAction.play();
		trace('When an animation is started, it is scheduled: ${animationAction.isScheduled() == true}');
		mixer.update(1);
		trace('When an animation is updated, it is scheduled: ${animationAction.isScheduled() == true}');
		animationAction.stop();
		trace('When an animation is stopped, it isn\'t scheduled anymore: ${animationAction.isScheduled() == false}');
	}

	static function testStartAt() {
		var {mixer, animationAction} = createAnimation();
		animationAction.startAt(2);
		animationAction.play();
		trace('When an animation is started at a specific time, it is not running: ${animationAction.isRunning() == false}');
		trace('When an animation is started at a specific time, it is scheduled: ${animationAction.isScheduled() == true}');
		mixer.update(1);
		trace('When an animation is started at a specific time and the interval is not passed, it is not running: ${animationAction.isRunning() == false}');
		trace('When an animation is started at a specific time and the interval is not passed, it is scheduled: ${animationAction.isScheduled() == true}');
		mixer.update(1);
		trace('When an animation is started at a specific time and the interval is passed, it is running: ${animationAction.isRunning() == true}');
		trace('When an animation is started at a specific time and the interval is passed, it is scheduled: ${animationAction.isScheduled() == true}');
		animationAction.stop();
		trace('When an animation is stopped, it is not running: ${animationAction.isRunning() == false}');
		trace('When an animation is stopped, it is not scheduled: ${animationAction.isScheduled() == false}');
	}

	static function testSetLoopLoopOnce() {
		var {mixer, animationAction} = createAnimation();
		animationAction.setLoop(LoopOnce);
		animationAction.play();
		trace('When an animation is started, it is running: ${animationAction.isRunning() == true}');
		mixer.update(500);
		trace('When an animation is in the first loop, it is running: ${animationAction.isRunning() == true}');
		mixer.update(500);
		trace('When an animation is ended, it is not running: ${animationAction.isRunning() == false}');
		mixer.update(500);
		trace('When an animation is ended, it is not running: ${animationAction.isRunning() == false}');
	}

	static function testSetLoopLoopRepeat() {
		var {root, mixer, animationAction} = createAnimation();
		animationAction.setLoop(LoopRepeat, 3);
		animationAction.play();
		trace('When an animation is started, it is running: ${animationAction.isRunning() == true}');
		mixer.update(750);
		trace('When an animation is 3/4 in the first loop, it has changed to 3/4 when LoopRepeat: ${root.rotation.x == 270}');
		trace('When an animation is in the first loop, it is running: ${animationAction.isRunning() == true}');
		mixer.update(1000);
		trace('When an animation is 3/4 in the second loop, it has changed to 3/4 when LoopRepeat: ${root.rotation.x == 270}');
		trace('When an animation is in second loop when in looprepeat 3 times, it is running: ${animationAction.isRunning() == true}');
		mixer.update(1000);
		trace('When an animation is 3/4 in the third loop, it has changed to 3/4 when LoopRepeat: ${root.rotation.x == 270}');
		trace('When an animation is in third loop when in looprepeat 3 times, it is running: ${animationAction.isRunning() == true}');
		mixer.update(1000);
		trace('When an animation ended his third loop when in looprepeat 3 times, it stays on the end result: ${root.rotation.x == 0}');
		trace('When an animation ended his third loop when in looprepeat 3 times, it stays not running anymore: ${animationAction.isRunning() == false}');
	}

	static function testSetLoopLoopPingPong() {
		var {root, mixer, animationAction} = createAnimation();
		animationAction.setLoop(LoopPingPong, 3);
		animationAction.play();
		trace('When an animation is started, it is running: ${animationAction.isRunning() == true}');
		mixer.update(750);
		trace('When an animation is 3/4 in the first loop, it has changed to 3/4 when LoopPingPong: ${root.rotation.x == 270}');
		trace('When an animation is in the first loop, it is running: ${animationAction.isRunning() == true}');
		mixer.update(1000);
		trace('When an animation is 3/4 in the second loop, it has changed to 1/4 when LoopPingPong: ${root.rotation.x == 90}');
		trace('When an animation is in second loop when in looprepeat 3 times, it is running: ${animationAction.isRunning() == true}');
		mixer.update(1000);
		trace('When an animation is 3/4 in the third loop, it has changed to 3/4 when LoopPingPong: ${root.rotation.x == 270}');
		trace('When an animation is in third loop when in looprepeat 3 times, it is running: ${animationAction.isRunning() == true}');
		mixer.update(1000);
		trace('When an animation ended his fourth loop when in looprepeat 3 times, it stays on the end result: ${root.rotation.x == 0}');
		trace('When an animation ended his fourth loop when in looprepeat 3 times, it stays not running anymore: ${animationAction.isRunning() == false}');
	}

	static function testSetEffectiveWeight() {
		var {animationAction} = createAnimation();
		trace('When an animation is created, EffectiveWeight is 1: ${animationAction.getEffectiveWeight() == 1}');
		animationAction.setEffectiveWeight(0.3);
		trace('When EffectiveWeight is set to 0.3 , EffectiveWeight is 0.3: ${animationAction.getEffectiveWeight() == 0.3}');
	}

	static function testSetEffectiveWeightDisabled() {
		var {animationAction} = createAnimation();
		trace('When an animation is created, EffectiveWeight is 1: ${animationAction.getEffectiveWeight() == 1}');
		animationAction.enabled = false;
		animationAction.setEffectiveWeight(0.3);
		trace('When EffectiveWeight is set to 0.3 when disabled , EffectiveWeight is 0: ${animationAction.getEffectiveWeight() == 0}');
	}

	static function testSetEffectiveWeightOverDuration() {
		var {root, mixer, animationAction} = createAnimation();
		animationAction.setEffectiveWeight(0.5);
		animationAction.play();
		mixer.update(500);
		trace('When an animation has weight 0.5 and runs half through the animation, it has changed to 1/4: ${root.rotation.x == 90}');
		mixer.update(1000);
		trace('When an animation has weight 0.5 and runs one and half through the animation, it has changed to 1/4: ${root.rotation.x == 90}');
	}

	static function testGetEffectiveWeight() {
		var {animationAction} = createAnimation();
		trace('When an animation is created, EffectiveWeight is 1: ${animationAction.getEffectiveWeight() == 1}');
		animationAction.setEffectiveWeight(0.3);
		trace('When EffectiveWeight is set to 0.3 , EffectiveWeight is 0.3: ${animationAction.getEffectiveWeight() == 0.3}');
		var {animationAction} = createAnimation();
		trace('When an animation is created, EffectiveWeight is 1: ${animationAction.getEffectiveWeight() == 1}');
		animationAction.enabled = false;
		animationAction.setEffectiveWeight(0.3);
		trace('When EffectiveWeight is set to 0.3 when disabled , EffectiveWeight is 0: ${animationAction.getEffectiveWeight() == 0}');
	}

	static function testFadeIn() {
		var {mixer, animationAction} = createAnimation();
		animationAction.fadeIn(1000);
		animationAction.play();
		trace('When an animation fadeIn is started, EffectiveWeight is 1: ${animationAction.getEffectiveWeight() == 1}');
		mixer.update(250);
		trace('When an animation fadeIn happened 1/4, EffectiveWeight is 0.25: ${animationAction.getEffectiveWeight() == 0.25}');
		mixer.update(250);
		trace('When an animation fadeIn is halfway , EffectiveWeight is 0.5: ${animationAction.getEffectiveWeight() == 0.5}');
		mixer.update(250);
		trace('When an animation fadeIn is halfway , EffectiveWeight is 0.75: ${animationAction.getEffectiveWeight() == 0.75}');
		mixer.update(500);
		trace('When an animation fadeIn is ended , EffectiveWeight is 1: ${animationAction.getEffectiveWeight() == 1}');
	}

	static function testFadeOut() {
		var {mixer, animationAction} = createAnimation();
		animationAction.fadeOut(1000);
		animationAction.play();
		trace('When an animation fadeOut is started, EffectiveWeight is 1: ${animationAction.getEffectiveWeight() == 1}');
		mixer.update(250);
		trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: ${animationAction.getEffectiveWeight() == 0.75}');
		mixer.update(250);
		trace('When an animation fadeOut is halfway , EffectiveWeight is 0.5: ${animationAction.getEffectiveWeight() == 0.5}');
		mixer.update(250);
		trace('When an animation fadeOut is happened 3/4 , EffectiveWeight is 0.25: ${animationAction.getEffectiveWeight() == 0.25}');
		mixer.update(500);
		trace('When an animation fadeOut is ended , EffectiveWeight is 0: ${animationAction.getEffectiveWeight() == 0}');
	}

	static function testCrossFadeFrom() {
		var {mixer, animationAction, animationAction2} = createTwoAnimations();
		animationAction.crossFadeFrom(animationAction2, 1000, false);
		animationAction.play();
		animationAction2.play();
		trace('When an animation crossFadeFrom is started, EffectiveWeight is 1: ${animationAction.getEffectiveWeight() == 1}');
		trace('When an animation crossFadeFrom is started, EffectiveWeight is 1: ${animationAction2.getEffectiveWeight() == 1}');
		mixer.update(250);
		trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: ${animationAction.getEffectiveWeight() == 0.25}');
		trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: ${animationAction2.getEffectiveWeight() == 0.75}');
		mixer.update(250);
		trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: ${animationAction.getEffectiveWeight() == 0.5}');
		trace('When an animation fadeOut is halfway , EffectiveWeight is 0.5: ${animationAction2.getEffectiveWeight() == 0.5}');
		mixer.update(250);
		trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: ${animationAction.getEffectiveWeight() == 0.75}');
		trace('When an animation fadeOut is happened 3/4 , EffectiveWeight is 0.25: ${animationAction2.getEffectiveWeight() == 0.25}');
		mixer.update(500);
		trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: ${animationAction.getEffectiveWeight() == 1}');
		trace('When an animation fadeOut is ended , EffectiveWeight is 0: ${animationAction2.getEffectiveWeight() == 0}');
	}

	static function testCrossFadeTo() {
		var {mixer, animationAction, animationAction2} = createTwoAnimations();
		animationAction2.crossFadeTo(animationAction, 1000, false);
		animationAction.play();
		animationAction2.play();
		trace('When an animation crossFadeFrom is started, EffectiveWeight is 1: ${animationAction.getEffectiveWeight() == 1}');
		trace('When an animation crossFadeFrom is started, EffectiveWeight is 1: ${animationAction2.getEffectiveWeight() == 1}');
		mixer.update(250);
		trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: ${animationAction.getEffectiveWeight() == 0.25}');
		trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: ${animationAction2.getEffectiveWeight() == 0.75}');
		mixer.update(250);
		trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: ${animationAction.getEffectiveWeight() == 0.5}');
		trace('When an animation fadeOut is halfway , EffectiveWeight is 0.5: ${animationAction2.getEffectiveWeight() == 0.5}');
		mixer.update(250);
		trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: ${animationAction.getEffectiveWeight() == 0.75}');
		trace('When an animation fadeOut is happened 3/4 , EffectiveWeight is 0.25: ${animationAction2.getEffectiveWeight() == 0.25}');
		mixer.update(500);
		trace('When an animation fadeOut happened 1/4, EffectiveWeight is 0.75: ${animationAction.getEffectiveWeight() == 1}');
		trace('When an animation fadeOut is ended , EffectiveWeight is 0: ${animationAction2.getEffectiveWeight() == 0}');
	}

	static function testGetMixer() {
		var {mixer, animationAction} = createAnimation();
		var mixer2 = animationAction.getMixer();
		trace('mixer should be returned by getMixer: ${mixer == mixer2}');
	}

	static function testGetClip() {
		var {clip, animationAction} = createAnimation();
		var clip2 = animationAction.getClip();
		trace('clip should be returned by getClip: ${clip == clip2}');
	}

	static function testGetRoot() {
		var {root, animationAction} = createAnimation();
		var root2 = animationAction.getRoot();
		trace('root should be returned by getRoot: ${root == root2}');
	}

	static function testStartAtWhenAlreadyExecutedOnce() {
		var root = new Object3D();
		var mixer = new AnimationMixer(root);
		var track = new NumberKeyframeTrack('.rotation[x]', [0, 750], [0, 270]);
		var clip = new AnimationClip('clip1', 750, [track]);
		var animationAction = mixer.clipAction(clip);
		animationAction.setLoop(LoopOnce);
		animationAction.clampWhenFinished = true;
		animationAction.play();
		mixer.addEventListener('finished', function() {
			animationAction.timeScale *= -1;
			animationAction.paused = false;
			animationAction.startAt(mixer.time + 2000).play();
		});
		mixer.update(250);
		trace('first: ${root.rotation.x == 90}');
		mixer.update(250);
		trace('first: ${root.rotation.x == 180}');
		mixer.update(250);
		trace('first: ${root.rotation.x == 270}');
		//first loop done
		mixer.update(2000);
		// startAt Done
		trace('third: ${root.rotation.x == 270}');
		mixer.update(250);
		trace('fourth: ${root.rotation.x == 180}');
		mixer.update(250);
		trace('fourth: ${root.rotation.x == 90}');
		mixer.update(250);
		trace('sixth: ${root.rotation.x == 0}');
		mixer.update(1);
		trace('seventh: ${root.rotation.x == 0}');
		mixer.update(1000);
		trace('seventh: ${root.rotation.x == 0}');
		mixer.update(1000);
		trace('seventh: ${root.rotation.x == 0}');
		mixer.update(250);
		trace('seventh: ${root.rotation.x == 90}');
		mixer.update(250);
		trace('seventh: ${root.rotation.x == 180}');
		//trace(mixer.time);
	}

}