import three.Mesh;
import js.Math;

class MorphBlendMesh extends Mesh {

	var animationsMap:Map<String, Dynamic>;
	var animationsList:Array<Dynamic>;

	public function new(geometry:Dynamic, material:Dynamic) {
		super(geometry, material);

		animationsMap = new Map();
		animationsList = [];

		var numFrames = Reflect.fields(this.morphTargetDictionary).length;

		var name = '__default';

		var startFrame = 0;
		var endFrame = numFrames - 1;

		var fps = numFrames / 1;

		createAnimation(name, startFrame, endFrame, fps);
		setAnimationWeight(name, 1);
	}

	public function createAnimation(name:String, start:Int, end:Int, fps:Float) {
		var animation = {
			start: start,
			end: end,
			length: end - start + 1,
			fps: fps,
			duration: (end - start) / fps,
			lastFrame: 0,
			currentFrame: 0,
			active: false,
			time: 0,
			direction: 1,
			weight: 1,
			directionBackwards: false,
			mirroredLoop: false
		};

		animationsMap.set(name, animation);
		animationsList.push(animation);
	}

	public function autoCreateAnimations(fps:Float) {
		var pattern = /([a-z]+)_?(\d+)/i;

		var firstAnimation:String;

		var frameRanges:Map<String, Dynamic> = new Map();

		var i = 0;

		for (key in Reflect.fields(this.morphTargetDictionary)) {
			var chunks = key.match(pattern);

			if (chunks != null && chunks.length > 1) {
				var name = chunks[1];

				if (!frameRanges.exists(name)) frameRanges.set(name, {start: Infinity, end: -Infinity});

				var range = frameRanges.get(name);

				if (i < range.start) range.start = i;
				if (i > range.end) range.end = i;

				if (firstAnimation == null) firstAnimation = name;
			}

			i++;
		}

		for (name in frameRanges.keys()) {
			var range = frameRanges.get(name);
			createAnimation(name, range.start, range.end, fps);
		}

		this.firstAnimation = firstAnimation;
	}

	public function setAnimationDirectionForward(name:String) {
		var animation = animationsMap.get(name);

		if (animation != null) {
			animation.direction = 1;
			animation.directionBackwards = false;
		}
	}

	public function setAnimationDirectionBackward(name:String) {
		var animation = animationsMap.get(name);

		if (animation != null) {
			animation.direction = -1;
			animation.directionBackwards = true;
		}
	}

	public function setAnimationFPS(name:String, fps:Float) {
		var animation = animationsMap.get(name);

		if (animation != null) {
			animation.fps = fps;
			animation.duration = (animation.end - animation.start) / animation.fps;
		}
	}

	public function setAnimationDuration(name:String, duration:Float) {
		var animation = animationsMap.get(name);

		if (animation != null) {
			animation.duration = duration;
			animation.fps = (animation.end - animation.start) / animation.duration;
		}
	}

	public function setAnimationWeight(name:String, weight:Float) {
		var animation = animationsMap.get(name);

		if (animation != null) {
			animation.weight = weight;
		}
	}

	public function setAnimationTime(name:String, time:Float) {
		var animation = animationsMap.get(name);

		if (animation != null) {
			animation.time = time;
		}
	}

	public function getAnimationTime(name:String):Float {
		var time = 0;

		var animation = animationsMap.get(name);

		if (animation != null) {
			time = animation.time;
		}

		return time;
	}

	public function getAnimationDuration(name:String):Float {
		var duration = -1;

		var animation = animationsMap.get(name);

		if (animation != null) {
			duration = animation.duration;
		}

		return duration;
	}

	public function playAnimation(name:String) {
		var animation = animationsMap.get(name);

		if (animation != null) {
			animation.time = 0;
			animation.active = true;
		} else {
			trace('THREE.MorphBlendMesh: animation[' + name + '] undefined in .playAnimation()');
		}
	}

	public function stopAnimation(name:String) {
		var animation = animationsMap.get(name);

		if (animation != null) {
			animation.active = false;
		}
	}

	public function update(delta:Float) {
		for (i in 0...animationsList.length) {
			var animation = animationsList[i];

			if (!animation.active) continue;

			var frameTime = animation.duration / animation.length;

			animation.time += animation.direction * delta;

			if (animation.mirroredLoop) {
				if (animation.time > animation.duration || animation.time < 0) {
					animation.direction *= -1;

					if (animation.time > animation.duration) {
						animation.time = animation.duration;
						animation.directionBackwards = true;
					}

					if (animation.time < 0) {
						animation.time = 0;
						animation.directionBackwards = false;
					}
				}
			} else {
				animation.time = animation.time % animation.duration;

				if (animation.time < 0) animation.time += animation.duration;
			}

			var keyframe = animation.start + Math.clamp(Math.floor(animation.time / frameTime), 0, animation.length - 1);
			var weight = animation.weight;

			if (keyframe != animation.currentFrame) {
				this.morphTargetInfluences[animation.lastFrame] = 0;
				this.morphTargetInfluences[animation.currentFrame] = 1 * weight;

				this.morphTargetInfluences[keyframe] = 0;

				animation.lastFrame = animation.currentFrame;
				animation.currentFrame = keyframe;
			}

			var mix = (animation.time % frameTime) / frameTime;

			if (animation.directionBackwards) mix = 1 - mix;

			if (animation.currentFrame != animation.lastFrame) {
				this.morphTargetInfluences[animation.currentFrame] = mix * weight;
				this.morphTargetInfluences[animation.lastFrame] = (1 - mix) * weight;
			} else {
				this.morphTargetInfluences[animation.currentFrame] = weight;
			}
		}
	}
}