import AnimationUtils from './AnimationUtils.hx';
import KeyframeTrack from './KeyframeTrack.hx';
import BooleanKeyframeTrack from './tracks/BooleanKeyframeTrack.hx';
import ColorKeyframeTrack from './tracks/ColorKeyframeTrack.hx';
import NumberKeyframeTrack from './tracks/NumberKeyframeTrack.hx';
import QuaternionKeyframeTrack from './tracks/QuaternionKeyframeTrack.hx';
import StringKeyframeTrack from './tracks/StringKeyframeTrack.hx';
import VectorKeyframeTrack from './tracks/VectorKeyframeTrack.hx';
import MathUtils from '../math/MathUtils.hx';
import { NormalAnimationBlendMode } from '../constants.hx';

class AnimationClip {
    public name: String;
    public tracks: Array<KeyframeTrack>;
    public duration: Float;
    public blendMode: NormalAnimationBlendMode;
    public uuid: String;

    public function new(name: String = " ", duration: Float = -1., tracks: Array<KeyframeTrack> = [], blendMode: NormalAnimationBlendMode = NormalAnimationBlendMode.Normal) {
        this.name = name;
        this.tracks = tracks;
        this.duration = duration;
        this.blendMode = blendMode;
        this.uuid = MathUtils.generateUUID();

        if (this.duration < 0) {
            this.resetDuration();
        }
    }

    public static function parse(json: Dynamic) {
        var tracks = [];
        var jsonTracks = json.tracks;
        var frameTime = 1.0 / (json.fps as Float);

        for (i in 0...jsonTracks.length) {
            var track = parseKeyframeTrack(jsonTracks[i]);
            track.scale(frameTime);
            tracks.push(track);
        }

        var clip = new AnimationClip(json.name, json.duration, tracks, json.blendMode);
        clip.uuid = json.uuid;

        return clip;
    }

    public static function toJSON(clip: AnimationClip) {
        var tracks = [];
        var clipTracks = clip.tracks;

        var json = {
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

    public static function CreateFromMorphTargetSequence(name: String, morphTargetSequence: Array<Dynamic>, fps: Float, noLoop: Bool) {
        var numMorphTargets = morphTargetSequence.length;
        var tracks = [];

        for (i in 0...numMorphTargets) {
            var times = [];
            var values = [];

            times.push((i + numMorphTargets - 1) % numMorphTargets);
            times.push(i);
            times.push((i + 1) % numMorphTargets);

            values.push(0);
            values.push(1);
            values.push(0);

            var order = AnimationUtils.getKeyframeOrder(times);
            times = AnimationUtils.sortedArray(times, 1, order);
            values = AnimationUtils.sortedArray(values, 1, order);

            if (!noLoop && times[0] == 0) {
                times.push(numMorphTargets);
                values.push(values[0]);
            }

            tracks.push(new NumberKeyframeTrack(".morphTargetInfluences[" + morphTargetSequence[i].name + "]", times, values)).scale(1.0 / fps);
        }

        return new AnimationClip(name, -1, tracks);
    }

    public static function findByName(objectOrClipArray: Dynamic, name: String) {
        var clipArray = objectOrClipArray;

        if (!Type.enumEq(Type.getClass(objectOrClipArray), Array)) {
            var o = objectOrClipArray;
            clipArray = o.geometry.animations as Array<AnimationClip>;
        }

        for (i in 0...clipArray.length) {
            if (clipArray[i].name == name) {
                return clipArray[i];
            }
        }

        return null;
    }

    public static function CreateClipsFromMorphTargetSequences(morphTargets: Array<Dynamic>, fps: Float, noLoop: Bool) {
        var animationToMorphTargets = new Map<String, Array<Dynamic>>();

        var pattern = ~/([\w-]*?)[(\d)+]/;

        for (i in 0...morphTargets.length) {
            var morphTarget = morphTargets[i];
            var parts = pattern.match(morphTarget.name);

            if (parts != null) {
                var name = parts[1];
                var animationMorphTargets = animationToMorphTargets.get(name);

                if (animationMorphTargets == null) {
                    animationMorphTargets = [];
                    animationToMorphTargets.set(name, animationMorphTargets);
                }

                animationMorphTargets.push(morphTarget);
            }
        }

        var clips = [];

        for (var name in animationToMorphTargets.keys()) {
            clips.push(CreateFromMorphTargetSequence(name, animationToMorphTargets.get(name), fps, noLoop));
        }

        return clips;
    }

    public static function parseAnimation(animation: Dynamic, bones: Array<Dynamic>) {
        if (animation == null) {
            throw "THREE.AnimationClip: No animation in JSONLoader data.";
        }

        function addNonemptyTrack(trackType: KeyframeTrack, trackName: String, animationKeys: Array<Dynamic>, propertyName: String, destTracks: Array<KeyframeTrack>) {
            if (animationKeys.length != 0) {
                var times = [];
                var values = [];

                AnimationUtils.flattenJSON(animationKeys, times, values, propertyName);

                if (times.length != 0) {
                    destTracks.push(new trackType(trackName, times, values));
                }
            }
        }

        var tracks = [];

        var clipName = animation.name;
        var fps = animation.fps;
        var blendMode = animation.blendMode;

        var duration = animation.length;

        var hierarchyTracks = animation.hierarchy;

        for (h in 0...hierarchyTracks.length) {
            var animationKeys = hierarchyTracks[h].keys;

            if (animationKeys == null || animationKeys.length == 0) {
                continue;
            }

            if (animationKeys[0].morphTargets != null) {
                var morphTargetNames = new Map<String, Int>();

                for (k in 0...animationKeys.length) {
                    if (animationKeys[k].morphTargets != null) {
                        for (m in 0...animationKeys[k].morphTargets.length) {
                            var morphTargetName = animationKeys[k].morphTargets[m];
                            morphTargetNames.set(morphTargetName, -1);
                        }
                    }
                }

                for (var morphTargetName in morphTargetNames.keys()) {
                    var times = [];
                    var values = [];

                    for (m in 0...animationKeys.length) {
                        var animationKey = animationKeys[m];

                        times.push(animationKey.time);
                        values.push(animationKey.morphTarget == morphTargetName ? 1 : 0);
                    }

                    tracks.push(new NumberKeyframeTrack(".morphTargetInfluence[" + morphTargetName + "]", times, values));
                }

                duration = morphTargetNames.size() * fps;
            } else {
                var boneName = ".bones[" + bones[h].name + "]";

                addNonemptyTrack(VectorKeyframeTrack, boneName + ".position", animationKeys, "pos", tracks);
                addNonemptyTrack(QuaternionKeyframeTrack, boneName + ".quaternion", animationKeys, "rot", tracks);
                addNonemptyTrack(VectorKeyframeTrack, boneName + ".scale", animationKeys, "scl", tracks);
            }
        }

        if (tracks.length == 0) {
            return null;
        }

        var clip = new AnimationClip(clipName, duration, tracks, blendMode);

        return clip;
    }

    public function resetDuration() {
        var tracks = this.tracks;
        var duration = 0.;

        for (i in 0...tracks.length) {
            var track = tracks[i];
            duration = Math.max(duration, track.times[track.times.length - 1]);
        }

        this.duration = duration;

        return this;
    }

    public function trim() {
        for (i in 0...this.tracks.length) {
            this.tracks[i].trim(0, this.duration);
        }

        return this;
    }

    public function validate() {
        var valid = true;

        for (i in 0...this.tracks.length) {
            valid = valid && this.tracks[i].validate();
        }

        return valid;
    }

    public function optimize() {
        for (i in 0...this.tracks.length) {
            this.tracks[i].optimize();
        }

        return this;
    }

    public function clone() {
        var tracks = [];

        for (i in 0...this.tracks.length) {
            tracks.push(this.tracks[i].clone());
        }

        return new AnimationClip(this.name, this.duration, tracks, this.blendMode);
    }

    public function toJSON() {
        return AnimationClip.toJSON(this);
    }
}

function getTrackTypeForValueTypeName(typeName: String) {
    switch (typeName.toLowerCase()) {
        case "scalar":
        case "double":
        case "float":
        case "number":
        case "integer":
            return NumberKeyframeTrack;

        case "vector":
        case "vector2":
        case "vector3":
        case "vector4":
            return VectorKeyframeTrack;

        case "color":
            return ColorKeyframeTrack;

        case "quaternion":
            return QuaternionKeyframeTrack;

        case "bool":
        case "boolean":
            return BooleanKeyframeTrack;

        case "string":
            return StringKeyframeTrack;
    }

    throw new Error("THREE.KeyframeTrack: Unsupported typeName: " + typeName);
}

function parseKeyframeTrack(json: Dynamic) {
    if (json.type == null) {
        throw new Error("THREE.KeyframeTrack: track type undefined, can not parse");
    }

    var trackType = getTrackTypeForValueTypeName(json.type);

    if (json.times == null) {
        var times = [];
        var values = [];

        AnimationUtils.flattenJSON(json.keys, times, values, "value");

        json.times = times;
        json.values = values;
    }

    if (trackType.parse != null) {
        return trackType.parse(json);
    } else {
        return new trackType(json.name, json.times, json.values, json.interpolation);
    }
}

class AnimationClip {
}

export {
    AnimationClip
}