import three.animation.AnimationUtils;
import three.animation.KeyframeTrack;
import three.animation.tracks.BooleanKeyframeTrack;
import three.animation.tracks.ColorKeyframeTrack;
import three.animation.tracks.NumberKeyframeTrack;
import three.animation.tracks.QuaternionKeyframeTrack;
import three.animation.tracks.StringKeyframeTrack;
import three.animation.tracks.VectorKeyframeTrack;
import three.math.MathUtils;
import three.constants.NormalAnimationBlendMode;

class AnimationClip {
    
    public var name:String;
    public var tracks:Array<KeyframeTrack>;
    public var duration:Float;
    public var blendMode:NormalAnimationBlendMode;
    public var uuid:String;

    public function new(name:String = '', duration:Float = -1, tracks:Array<KeyframeTrack> = [], blendMode:NormalAnimationBlendMode = NormalAnimationBlendMode.NORMAL) {
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
        var jsonTracks = json.tracks;
        var frameTime:Float = 1.0 / (json.fps != null ? json.fps : 1.0);

        for (i in 0...jsonTracks.length) {
            tracks.push(parseKeyframeTrack(jsonTracks[i]).scale(frameTime));
        }

        var clip = new AnimationClip(json.name, json.duration, tracks, json.blendMode);
        clip.uuid = json.uuid;

        return clip;
    }

    public static function toJSON(clip:AnimationClip):Dynamic {
        var tracks:Array<Dynamic> = [];
        var clipTracks = clip.tracks;

        var json:Dynamic = {
            name: clip.name,
            duration: clip.duration,
            tracks: tracks,
            uuid: clip.uuid,
            blendMode: clip.blendMode
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

            times.push((i + numMorphTargets - 1) % numMorphTargets, i, (i + 1) % numMorphTargets);
            values.push(0, 1, 0);

            var order = AnimationUtils.getKeyframeOrder(times);
            times = AnimationUtils.sortedArray(times, 1, order);
            values = AnimationUtils.sortedArray(values, 1, order);

            if (!noLoop && times[0] == 0) {
                times.push(numMorphTargets);
                values.push(values[0]);
            }

            tracks.push(new NumberKeyframeTrack('.morphTargetInfluences[' + morphTargetSequence[i].name + ']', times, values).scale(1.0 / fps));
        }

        return new AnimationClip(name, -1, tracks);
    }

    public static function findByName(objectOrClipArray:Dynamic, name:String):AnimationClip {
        var clipArray:Array<AnimationClip> = (objectOrClipArray is Array<Dynamic>) ? objectOrClipArray : objectOrClipArray.geometry != null && objectOrClipArray.geometry.animations != null ? objectOrClipArray.geometry.animations : objectOrClipArray.animations;

        for (i in 0...clipArray.length) {
            if (clipArray[i].name == name) {
                return clipArray[i];
            }
        }

        return null;
    }

    public static function CreateClipsFromMorphTargetSequences(morphTargets:Array<Dynamic>, fps:Float, noLoop:Bool):Array<AnimationClip> {
        var animationToMorphTargets:Map<String, Array<Dynamic>> = new Map();
        var pattern:EReg = ~/^([\w-]*?)([\d]+)$/;

        for (morphTarget in morphTargets) {
            var parts = pattern.match(morphTarget.name);

            if (parts != null && parts.matched(1)) {
                var name:String = parts.matched(1);
                if (!animationToMorphTargets.exists(name)) {
                    animationToMorphTargets.set(name, []);
                }
                animationToMorphTargets.get(name).push(morphTarget);
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
            trace('THREE.AnimationClip: No animation in JSONLoader data.');
            return null;
        }

        function addNonemptyTrack(trackType:Class<Dynamic>, trackName:String, animationKeys:Array<Dynamic>, propertyName:String, destTracks:Array<KeyframeTrack>):Void {
            if (animationKeys.length != 0) {
                var times:Array<Float> = [];
                var values:Array<Float> = [];

                AnimationUtils.flattenJSON(animationKeys, times, values, propertyName);

                if (times.length != 0) {
                    destTracks.push(Type.createInstance(trackType, [trackName, times, values]));
                }
            }
        }

        var tracks:Array<KeyframeTrack> = [];
        var clipName:String = animation.name != null ? animation.name : 'default';
        var fps:Float = animation.fps != null ? animation.fps : 30;
        var blendMode:NormalAnimationBlendMode = animation.blendMode;
        var duration:Float = animation.length != null ? animation.length : -1;

        var hierarchyTracks = animation.hierarchy != null ? animation.hierarchy : [];

        for (h in 0...hierarchyTracks.length) {
            var animationKeys = hierarchyTracks[h].keys;
            if (animationKeys == null || animationKeys.length == 0) continue;

            if (animationKeys[0].morphTargets != null) {
                var morphTargetNames:Map<String, Int> = new Map();

                for (k in 0...animationKeys.length) {
                    if (animationKeys[k].morphTargets != null) {
                        for (m in 0...animationKeys[k].morphTargets.length) {
                            morphTargetNames.set(animationKeys[k].morphTargets[m], -1);
                        }
                    }
                }

                for (morphTargetName in morphTargetNames.keys()) {
                    var times:Array<Float> = [];
                    var values:Array<Float> = [];

                    for (k in 0...animationKeys.length) {
                        var animationKey = animationKeys[k];
                        times.push(animationKey.time);
                        values.push(animationKey.morphTarget == morphTargetName ? 1 : 0);
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

        if (tracks.length == 0) {
            return null;
        }

        var clip = new AnimationClip(clipName, duration, tracks, blendMode);
        return clip;
    }

    public function resetDuration():AnimationClip {
        var tracks = this.tracks;
        var duration:Float = 0;

        for (i in 0...tracks.length) {
            var track = this.tracks[i];
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

function getTrackTypeForValueTypeName(typeName:String):Class<Dynamic> {
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
            throw 'THREE.KeyframeTrack: Unsupported typeName: ' + typeName;
    }
}

function parseKeyframeTrack(json:Dynamic):KeyframeTrack {
    if (json.type == null) {
        throw 'THREE.KeyframeTrack: track type undefined, can not parse';
    }

    var trackType = getTrackTypeForValueTypeName(json.type);

    if (json.times == null) {
        var times:Array<Float> = [];
        var values:Array<Float> = [];

        AnimationUtils.flattenJSON(json.keys, times, values, 'value');

        json.times = times;
        json.values = values;
    }

    if (Reflect.hasField(trackType, 'parse')) {
        return Reflect.callMethod(trackType, Reflect.field(trackType, 'parse'), [json]);
    } else {
        return Type.createInstance(trackType, [json.name, json.times, json.values, json.interpolation]);
    }
}