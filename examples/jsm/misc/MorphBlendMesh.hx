package three.js.examples.jsm.misc;

import three.MathUtils;
import three.Mesh;

class MorphBlendMesh extends Mesh {
    public var animationsMap:Map<String, Dynamic>;
    public var animationsList:Array<Dynamic>;

    public function new(geometry:Geometry, material:Material) {
        super(geometry, material);

        animationsMap = new Map<String, Dynamic>();
        animationsList = new Array<Dynamic>();

        // prepare default animation
        // (all frames played together in 1 second)

        var numFrames = Lambda.count(morphTargetDictionary);

        var name:String = '__default';

        var startFrame:Int = 0;
        var endFrame:Int = numFrames - 1;

        var fps:Float = numFrames / 1;

        createAnimation(name, startFrame, endFrame, fps);
        setAnimationWeight(name, 1);
    }

    public function createAnimation(name:String, start:Int, end:Int, fps:Float) {
        var animation:Dynamic = {
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

        animationsMap[name] = animation;
        animationsList.push(animation);
    }

    public function autoCreateAnimations(fps:Float) {
        var pattern:EReg = ~/([a-z]+)_?(\d+)/i;

        var firstAnimation:String;

        var frameRanges:Map<String, Dynamic> = new Map();

        var i:Int = 0;

        for (key in morphTargetDictionary.keys()) {
            var chunks:Array<String> = pattern.match(key);

            if (chunks != null && chunks.length > 1) {
                var name:String = chunks[1];

                if (!frameRanges.exists(name)) {
                    frameRanges[name] = { start: Math.POSITIVE_INFINITY, end: Math.NEGATIVE_INFINITY };
                }

                var range:Dynamic = frameRanges[name];

                if (i < range.start) range.start = i;
                if (i > range.end) range.end = i;

                if (firstAnimation == null) firstAnimation = name;
            }

            i++;
        }

        for (name in frameRanges.keys()) {
            var range:Dynamic = frameRanges[name];
            createAnimation(name, range.start, range.end, fps);
        }

        firstAnimation = firstAnimation;
    }

    public function setAnimationDirectionForward(name:String) {
        var animation:Dynamic = animationsMap[name];

        if (animation != null) {
            animation.direction = 1;
            animation.directionBackwards = false;
        }
    }

    public function setAnimationDirectionBackward(name:String) {
        var animation:Dynamic = animationsMap[name];

        if (animation != null) {
            animation.direction = -1;
            animation.directionBackwards = true;
        }
    }

    public function setAnimationFPS(name:String, fps:Float) {
        var animation:Dynamic = animationsMap[name];

        if (animation != null) {
            animation.fps = fps;
            animation.duration = (animation.end - animation.start) / fps;
        }
    }

    public function setAnimationDuration(name:String, duration:Float) {
        var animation:Dynamic = animationsMap[name];

        if (animation != null) {
            animation.duration = duration;
            animation.fps = (animation.end - animation.start) / duration;
        }
    }

    public function setAnimationWeight(name:String, weight:Float) {
        var animation:Dynamic = animationsMap[name];

        if (animation != null) {
            animation.weight = weight;
        }
    }

    public function setAnimationTime(name:String, time:Float) {
        var animation:Dynamic = animationsMap[name];

        if (animation != null) {
            animation.time = time;
        }
    }

    public function getAnimationTime(name:String):Float {
        var time:Float = 0;

        var animation:Dynamic = animationsMap[name];

        if (animation != null) {
            time = animation.time;
        }

        return time;
    }

    public function getAnimationDuration(name:String):Float {
        var duration:Float = -1;

        var animation:Dynamic = animationsMap[name];

        if (animation != null) {
            duration = animation.duration;
        }

        return duration;
    }

    public function playAnimation(name:String) {
        var animation:Dynamic = animationsMap[name];

        if (animation != null) {
            animation.time = 0;
            animation.active = true;
        } else {
            trace('THREE.MorphBlendMesh: animation[$name] undefined in .playAnimation()');
        }
    }

    public function stopAnimation(name:String) {
        var animation:Dynamic = animationsMap[name];

        if (animation != null) {
            animation.active = false;
        }
    }

    public function update(delta:Float) {
        for (i in 0...animationsList.length) {
            var animation:Dynamic = animationsList[i];

            if (!animation.active) continue;

            var frameTime:Float = animation.duration / animation.length;

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

            var keyframe:Int = animation.start + Math.floor(animation.time / frameTime);
            var weight:Float = animation.weight;

            if (keyframe != animation.currentFrame) {
                morphTargetInfluences[animation.lastFrame] = 0;
                morphTargetInfluences[animation.currentFrame] = 1 * weight;

                morphTargetInfluences[keyframe] = 0;

                animation.lastFrame = animation.currentFrame;
                animation.currentFrame = keyframe;
            }

            var mix:Float = (animation.time % frameTime) / frameTime;

            if (animation.directionBackwards) mix = 1 - mix;

            if (animation.currentFrame != animation.lastFrame) {
                morphTargetInfluences[animation.currentFrame] = mix * weight;
                morphTargetInfluences[animation.lastFrame] = (1 - mix) * weight;
            } else {
                morphTargetInfluences[animation.currentFrame] = weight;
            }
        }
    }
}