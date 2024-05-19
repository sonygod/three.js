import three.src.animation.AnimationUtils;
import three.src.animation.KeyframeTrack;
import three.src.animation.tracks.BooleanKeyframeTrack;
import three.src.animation.tracks.ColorKeyframeTrack;
import three.src.animation.tracks.NumberKeyframeTrack;
import three.src.animation.tracks.QuaternionKeyframeTrack;
import three.src.animation.tracks.StringKeyframeTrack;
import three.src.animation.tracks.VectorKeyframeTrack;
import three.src.math.MathUtils;
import three.src.constants.NormalAnimationBlendMode;

class AnimationClip {

    public var name:String;
    public var tracks:Array<KeyframeTrack>;
    public var duration:Float;
    public var blendMode:String;
    public var uuid:String;

    public function new(name:String = '', duration:Float = -1, tracks:Array<KeyframeTrack> = [], blendMode:String = NormalAnimationBlendMode) {
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
        var tracks = [];
        var jsonTracks = json.tracks;
        var frameTime = 1.0 / (json.fps || 1.0);
        for (i in 0...jsonTracks.length) {
            tracks.push(parseKeyframeTrack(jsonTracks[i]).scale(frameTime));
        }
        var clip = new AnimationClip(json.name, json.duration, tracks, json.blendMode);
        clip.uuid = json.uuid;
        return clip;
    }

    public static function toJSON(clip:AnimationClip):Dynamic {
        var tracks = [];
        var clipTracks = clip.tracks;
        var json = {
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

    public static function CreateFromMorphTargetSequence(name:String, morphTargetSequence:Dynamic, fps:Float, noLoop:Bool):AnimationClip {
        var numMorphTargets = morphTargetSequence.length;
        var tracks = [];
        for (i in 0...numMorphTargets) {
            var times = [];
            var values = [];
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
        var clipArray = objectOrClipArray;
        if (!(clipArray is Array<AnimationClip>)) {
            var o = objectOrClipArray;
            clipArray = o.geometry && o.geometry.animations || o.animations;
        }
        for (i in 0...clipArray.length) {
            if (clipArray[i].name == name) {
                return clipArray[i];
            }
        }
        return null;
    }

    public static function CreateClipsFromMorphTargetSequences(morphTargets:Dynamic, fps:Float, noLoop:Bool):Array<AnimationClip> {
        var animationToMorphTargets = {};
        var pattern = /^([\w-]*?)([\d]+)$/;
        for (i in 0...morphTargets.length) {
            var morphTarget = morphTargets[i];
            var parts = morphTarget.name.match(pattern);
            if (parts && parts.length > 1) {
                var name = parts[1];
                var animationMorphTargets = animationToMorphTargets[name];
                if (!animationMorphTargets) {
                    animationToMorphTargets[name] = animationMorphTargets = [];
                }
                animationMorphTargets.push(morphTarget);
            }
        }
        var clips = [];
        for (name in animationToMorphTargets) {
            clips.push(AnimationClip.CreateFromMorphTargetSequence(name, animationToMorphTargets[name], fps, noLoop));
        }
        return clips;
    }

    public static function parseAnimation(animation:Dynamic, bones:Dynamic):AnimationClip {
        if (!animation) {
            trace('THREE.AnimationClip: No animation in JSONLoader data.');
            return null;
        }
        var addNonemptyTrack = function(trackType, trackName, animationKeys, propertyName, destTracks) {
            if (animationKeys.length != 0) {
                var times = [];
                var values = [];
                AnimationUtils.flattenJSON(animationKeys, times, values, propertyName);
                if (times.length != 0) {
                    destTracks.push(new trackType(trackName, times, values));
                }
            }
        };
        var tracks = [];
        var clipName = animation.name || 'default';
        var fps = animation.fps || 30;
        var blendMode = animation.blendMode;
        var duration = animation.length || -1;
        var hierarchyTracks = animation.hierarchy || [];
        for (h in 0...hierarchyTracks.length) {
            var animationKeys = hierarchyTracks[h].keys;
            if (!animationKeys || animationKeys.length == 0) continue;
            if (animationKeys[0].morphTargets) {
                var morphTargetNames = {};
                for (k in 0...animationKeys.length) {
                    if (animationKeys[k].morphTargets) {
                        for (m in 0...animationKeys[k].morphTargets.length) {
                            morphTargetNames[animationKeys[k].morphTargets[m]] = -1;
                        }
                    }
                }
                for (morphTargetName in morphTargetNames) {
                    var times = [];
                    var values = [];
                    for (m in 0...animationKeys[k].morphTargets.length) {
                        var animationKey = animationKeys[k];
                        times.push(animationKey.time);
                        values.push((animationKey.morphTarget == morphTargetName) ? 1 : 0);
                    }
                    tracks.push(new NumberKeyframeTrack('.morphTargetInfluence[' + morphTargetName + ']', times, values));
                }
                duration = morphTargetNames.length * fps;
            } else {
                var boneName = '.bones[' + bones[h].name + ']';
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
        var duration = 0;
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
        var valid = true;
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
        var tracks = [];
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
        case 'scalar':
        case 'double':
        case 'float':
        case 'number':
        case 'integer':
            return NumberKeyframeTrack;
        case 'vector':
        case 'vector2':
        case 'vector3':
        case 'vector4':
            return VectorKeyframeTrack;
        case 'color':
            return ColorKeyframeTrack;
        case 'quaternion':
            return QuaternionKeyframeTrack;
        case 'bool':
        case 'boolean':
            return BooleanKeyframeTrack;
        case 'string':
            return StringKeyframeTrack;
    }
    throw 'THREE.KeyframeTrack: Unsupported typeName: ' + typeName;
}

function parseKeyframeTrack(json:Dynamic):KeyframeTrack {
    if (json.type == null) {
        throw 'THREE.KeyframeTrack: track type undefined, can not parse';
    }
    var trackType = getTrackTypeForValueTypeName(json.type);
    if (json.times == null) {
        var times = [];
        var values = [];
        AnimationUtils.flattenJSON(json.keys, times, values, 'value');
        json.times = times;
        json.values = values;
    }
    if (trackType.parse != null) {
        return trackType.parse(json);
    } else {
        return new trackType(json.name, json.times, json.values, json.interpolation);
    }
}