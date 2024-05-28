package three.animation;

import three.animation.AnimationUtils;
import three.animation.KeyframeTrack;
import three.animation.BooleanKeyframeTrack;
import three.animation.ColorKeyframeTrack;
import three.animation.NumberKeyframeTrack;
import three.animation.QuaternionKeyframeTrack;
import three.animation.StringKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.math.MathUtils;
import three.constants.NormalAnimationBlendMode;

class AnimationClip {
    public var name:String;
    public var tracks:Array<KeyframeTrack>;
    public var duration:Float;
    public var blendMode:Int;
    public var uuid:String;

    public function new(?name:String = '', ?duration:Float = -1, ?tracks:Array<KeyframeTrack> = null, ?blendMode:Int = NormalAnimationBlendMode) {
        this.name = name;
        this.tracks = tracks;
        this.duration = duration;
        this.blendMode = blendMode;

        this.uuid = MathUtils.generateUUID();

        if (this.duration < 0) {
            this.resetDuration();
        }
    }

    public static function parse(json:Dynamic):AnimationClip {
        var tracks:Array<KeyframeTrack> = [];
        var jsonTracks:Array<Dynamic> = json.tracks;
        var frameTime:Float = 1.0 / (json.fps || 1.0);

        for (i in 0...jsonTracks.length) {
            tracks.push(parseKeyframeTrack(jsonTracks[i]).scale(frameTime));
        }

        var clip:AnimationClip = new AnimationClip(json.name, json.duration, tracks, json.blendMode);
        clip.uuid = json.uuid;

        return clip;
    }

    public static function toJSON(clip:AnimationClip):Dynamic {
        var tracks:Array<Dynamic> = [];
        var clipTracks:Array<KeyframeTrack> = clip.tracks;

        var json:Dynamic = {
            'name': clip.name,
            'duration': clip.duration,
            'tracks': tracks,
            'uuid': clip.uuid,
            'blendMode': clip.blendMode
        };

        for (i in 0...clipTracks.length) {
            tracks.push(KeyframeTrack.toJSON(clipTracks[i]));
        }

        return json;
    }

    public static function CreateFromMorphTargetSequence(name:String, morphTargetSequence:Array<Dynamic>, fps:Float, noLoop:Bool):AnimationClip {
        var numMorphTargets:Int = morphTargetSequence.length;
        var tracks:Array<KeyframeTrack> = [];

        for (i in 0...numMorphTargets) {
            var times:Array<Float> = [];
            var values:Array<Float> = [];

            times.push((i + numMorphTargets - 1) % numMorphTargets);
            times.push(i);
            times.push((i + 1) % numMorphTargets);

            values.push(0);
            values.push(1);
            values.push(0);

            var order:Array<Int> = AnimationUtils.getKeyframeOrder(times);
            times = AnimationUtils.sortedArray(times, 1, order);
            values = AnimationUtils.sortedArray(values, 1, order);

            if (!noLoop && times[0] === 0) {
                times.push(numMorphTargets);
                values.push(values[0]);
            }

            tracks.push(new NumberKeyframeTrack('.morphTargetInfluences[' + morphTargetSequence[i].name + ']', times, values).scale(1.0 / fps));
        }

        return new AnimationClip(name, -1, tracks);
    }

    public static function findByName(objectOrClipArray:Dynamic, name:String):AnimationClip {
        var clipArray:Array<Dynamic> = objectOrClipArray;

        if (!Std.isOfType(objectOrClipArray, Array)) {
            var o:Dynamic = objectOrClipArray;
            clipArray = o.geometry.animations || o.animations;
        }

        for (i in 0...clipArray.length) {
            if (clipArray[i].name === name) {
                return clipArray[i];
            }
        }

        return null;
    }

    public static function CreateClipsFromMorphTargetSequences(morphTargets:Array<Dynamic>, fps:Float, noLoop:Bool):Array<AnimationClip> {
        var animationToMorphTargets:Map<String, Array<Dynamic>> = {};

        var pattern:EReg = ~/^([\w-]*?)([\d]+)$/;

        for (i in 0...morphTargets.length) {
            var morphTarget:Dynamic = morphTargets[i];
            var parts:Array<String> = morphTarget.name.match(pattern);

            if (parts && parts.length > 1) {
                var name:String = parts[1];

                var animationMorphTargets:Array<Dynamic> = animationToMorphTargets.get(name);

                if (animationMorphTargets == null) {
                    animationToMorphTargets.set(name, animationMorphTargets = []);
                }

                animationMorphTargets.push(morphTarget);
            }
        }

        var clips:Array<AnimationClip> = [];

        for (name in animationToMorphTargets.keys()) {
            clips.push(CreateFromMorphTargetSequence(name, animationToMorphTargets.get(name), fps, noLoop));
        }

        return clips;
    }

    public static function parseAnimation(animation:Dynamic, bones:Array<Dynamic>):AnimationClip {
        if (animation == null) {
            Console.error('THREE.AnimationClip: No animation in JSONLoader data.');
            return null;
        }

        var addNonemptyTrack:Void->Void = function(trackType:Class<KeyframeTrack>, trackName:String, animationKeys:Array<Dynamic>, propertyName:String, destTracks:Array<KeyframeTrack>) {
            if (animationKeys.length !== 0) {
                var times:Array<Float> = [];
                var values:Array<Dynamic> = [];

                AnimationUtils.flattenJSON(animationKeys, times, values, propertyName);

                if (times.length !== 0) {
                    destTracks.push(new trackType(trackName, times, values));
                }
            }
        };

        var tracks:Array<KeyframeTrack> = [];

        var clipName:String = animation.name || 'default';
        var fps:Float = animation.fps || 30;
        var blendMode:Int = animation.blendMode;

        var duration:Float = animation.length || -1;

        var hierarchyTracks:Array<Dynamic> = animation.hierarchy || [];

        for (h in 0...hierarchyTracks.length) {
            var animationKeys:Array<Dynamic> = hierarchyTracks[h].keys;

            if (animationKeys == null || animationKeys.length === 0) continue;

            if (animationKeys[0].morphTargets) {
                var morphTargetNames:Map<String, Int> = {};

                for (k in 0...animationKeys.length) {
                    if (animationKeys[k].morphTargets) {
                        for (m in 0...animationKeys[k].morphTargets.length) {
                            morphTargetNames.set(animationKeys[k].morphTargets[m], -1);
                        }
                    }
                }

                for (morphTargetName in morphTargetNames.keys()) {
                    var times:Array<Float> = [];
                    var values:Array<Float> = [];

                    for (m in 0...animationKeys[k].morphTargets.length) {
                        var animationKey:Dynamic = animationKeys[k];

                        times.push(animationKey.time);
                        values.push((animationKey.morphTarget === morphTargetName) ? 1 : 0);
                    }

                    tracks.push(new NumberKeyframeTrack('.morphTargetInfluence[' + morphTargetName + ']', times, values));
                }

                duration = morphTargetNames.keys().length * fps;
            } else {
                var boneName:String = '.bones[' + bones[h].name + ']';

                addNonemptyTrack(VectorKeyframeTrack, boneName + '.position', animationKeys, 'pos', tracks);

                addNonemptyTrack(QuaternionKeyframeTrack, boneName + '.quaternion', animationKeys, 'rot', tracks);

                addNonemptyTrack(VectorKeyframeTrack, boneName + '.scale', animationKeys, 'scl', tracks);
            }
        }

        if (tracks.length === 0) {
            return null;
        }

        var clip:AnimationClip = new AnimationClip(clipName, duration, tracks, blendMode);

        return clip;
    }

    public function resetDuration():AnimationClip {
        var tracks:Array<KeyframeTrack> = this.tracks;
        var duration:Float = 0;

        for (i in 0...tracks.length) {
            var track:KeyframeTrack = tracks[i];

            duration = Math.max(duration, track.times[track.times.length - 1]);
        }

        this.duration = duration;

        return this;
    }

    public function trim():AnimationClip {
        for (i in 0...this.tracks.length) {
            this.tracks[i].trim(0, this.duration);
        }

        return this;
    }

    public function validate():Bool {
        var valid:Bool = true;

        for (i in 0...this.tracks.length) {
            valid = valid && this.tracks[i].validate();
        }

        return valid;
    }

    public function optimize():AnimationClip {
        for (i in 0...this.tracks.length) {
            this.tracks[i].optimize();
        }

        return this;
    }

    public function clone():AnimationClip {
        var tracks:Array<KeyframeTrack> = [];

        for (i in 0...this.tracks.length) {
            tracks.push(this.tracks[i].clone());
        }

        return new AnimationClip(this.name, this.duration, tracks, this.blendMode);
    }

    public function toJSON():Dynamic {
        return AnimationClip.toJSON(this);
    }
}

function getTrackTypeForValueTypeName(typeName:String):Class<KeyframeTrack> {
    switch (typeName.toLowerCase()) {
        case 'scalar', 'double', 'float', 'number', 'integer':
            return NumberKeyframeTrack;
        case 'vector', 'vector2', 'vector3', 'vector4':
            return VectorKeyframeTrack;
        case 'color':
            return ColorKeyframeTrack;
        case 'quaternion':
            return QuaternionKeyframeTrack;
        case 'bool', 'boolean':
            return BooleanKeyframeTrack;
        case 'string':
            return StringKeyframeTrack;
        default:
            throw new Error('THREE.KeyframeTrack: Unsupported typeName: ' + typeName);
    }
}

function parseKeyframeTrack(json:Dynamic):KeyframeTrack {
    if (json.type === undefined) {
        throw new Error('THREE.KeyframeTrack: track type undefined, can not parse');
    }

    var trackType:Class<KeyframeTrack> = getTrackTypeForValueTypeName(json.type);

    if (json.times === undefined) {
        var times:Array<Float> = [];
        var values:Array<Dynamic> = [];

        AnimationUtils.flattenJSON(json.keys, times, values, 'value');

        json.times = times;
        json.values = values;
    }

    if (trackType.parse !== undefined) {
        return trackType.parse(json);
    } else {
        return new trackType(json.name, json.times, json.values, json.interpolation);
    }
}