import three.MathUtils;
import three.Mesh;

class MorphBlendMesh extends Mesh {

    public var animationsMap:haxe.ds.StringMap<Dynamic>;
    public var animationsList:Array<Dynamic>;

    public function new(geometry:three.BufferGeometry, material:three.Material) {
        super(geometry, material);

        this.animationsMap = new haxe.ds.StringMap();
        this.animationsList = [];

        var numFrames:Int = Reflect.fields(this.morphTargetDictionary).length;

        var name:String = '__default';

        var startFrame:Int = 0;
        var endFrame:Int = numFrames - 1;

        var fps:Float = numFrames / 1.0;

        this.createAnimation(name, startFrame, endFrame, fps);
        this.setAnimationWeight(name, 1);
    }

    public function createAnimation(name:String, start:Int, end:Int, fps:Float):Void {
        var animation:Dynamic = {
            start: start,
            end: end,
            length: end - start + 1,
            fps: fps,
            duration: (end - start) / fps,
            lastFrame: 0,
            currentFrame: 0,
            active: false,
            time: 0.0,
            direction: 1,
            weight: 1.0,
            directionBackwards: false,
            mirroredLoop: false
        };

        this.animationsMap.set(name, animation);
        this.animationsList.push(animation);
    }

    public function setAnimationDirectionForward(name:String):Void {
        var animation = this.animationsMap.get(name);

        if (animation != null) {
            animation.direction = 1;
            animation.directionBackwards = false;
        }
    }

    public function setAnimationDirectionBackward(name:String):Void {
        var animation = this.animationsMap.get(name);

        if (animation != null) {
            animation.direction = -1;
            animation.directionBackwards = true;
        }
    }

    public function setAnimationFPS(name:String, fps:Float):Void {
        var animation = this.animationsMap.get(name);

        if (animation != null) {
            animation.fps = fps;
            animation.duration = (animation.end - animation.start) / animation.fps;
        }
    }

    public function setAnimationWeight(name:String, weight:Float):Void {
        var animation = this.animationsMap.get(name);

        if (animation != null) {
            animation.weight = weight;
        }
    }

    public function setAnimationTime(name:String, time:Float):Void {
        var animation = this.animationsMap.get(name);

        if (animation != null) {
            animation.time = time;
        }
    }

    public function getAnimationTime(name:String):Float {
        var animation = this.animationsMap.get(name);

        if (animation != null) {
            return animation.time;
        }

        return 0;
    }

    public function getAnimationDuration(name:String):Float {
        var animation = this.animationsMap.get(name);

        if (animation != null) {
            return animation.duration;
        }

        return -1;
    }

    public function playAnimation(name:String):Void {
        var animation = this.animationsMap.get(name);

        if (animation != null) {
            animation.time = 0;
            animation.active = true;
        }
    }

    public function stopAnimation(name:String):Void {
        var animation = this.animationsMap.get(name);

        if (animation != null) {
            animation.active = false;
        }
    }

    public function update(delta:Float):Void {
        for (animation in this.animationsList) {
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

            var keyframe:Int = animation.start + Math.floor(Math.max(Math.min(animation.time / frameTime, animation.length - 1), 0));
            var weight:Float = animation.weight;

            if (keyframe != animation.currentFrame) {
                this.morphTargetInfluences[animation.lastFrame] = 0;
                this.morphTargetInfluences[animation.currentFrame] = 1 * weight;

                this.morphTargetInfluences[keyframe] = 0;

                animation.lastFrame = animation.currentFrame;
                animation.currentFrame = keyframe;
            }

            var mix:Float = (animation.time % frameTime) / frameTime;

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