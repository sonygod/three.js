import AnimationUtils;
import KeyframeTrack;
import BooleanKeyframeTrack;
import ColorKeyframeTrack;
import NumberKeyframeTrack;
import QuaternionKeyframeTrack;
import StringKeyframeTrack;
import VectorKeyframeTrack;
import MathUtils;
import NormalAnimationBlendMode;

class AnimationClip {

    public var name: String;
    public var duration: Float;
    public var tracks: Array<KeyframeTrack>;
    public var blendMode: Int;
    public var uuid: String;

    public function new(name: String = "", duration: Float = -1, tracks: Array<KeyframeTrack> = [], blendMode: Int = NormalAnimationBlendMode) {
        this.name = name;
        this.tracks = tracks;
        this.duration = duration;
        this.blendMode = blendMode;
        this.uuid = MathUtils.generateUUID();

        if (this.duration < 0) {
            this.resetDuration();
        }
    }

    static public function parse(json: Dynamic): AnimationClip {
        var tracks: Array<KeyframeTrack> = [];
        var jsonTracks: Array<Dynamic> = json.tracks;
        var frameTime: Float = 1.0 / (json.fps || 1.0);

        for (i in 0...jsonTracks.length) {
            tracks.push(parseKeyframeTrack(jsonTracks[i]).scale(frameTime));
        }

        var clip: AnimationClip = new AnimationClip(json.name, json.duration, tracks, json.blendMode);
        clip.uuid = json.uuid;

        return clip;
    }

    static public function toJSON(clip: AnimationClip): Dynamic {
        var tracks: Array<Dynamic> = [];
        var clipTracks: Array<KeyframeTrack> = clip.tracks;

        var json: Dynamic = {
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

    static public function CreateFromMorphTargetSequence(name: String, morphTargetSequence: Array<Dynamic>, fps: Float, noLoop: Bool): AnimationClip {
        // implementation here...
    }

    static public function findByName(objectOrClipArray: Dynamic, name: String): AnimationClip {
        // implementation here...
    }

    static public function CreateClipsFromMorphTargetSequences(morphTargets: Array<Dynamic>, fps: Float, noLoop: Bool): Array<AnimationClip> {
        // implementation here...
    }

    static public function parseAnimation(animation: Dynamic, bones: Array<Dynamic>): AnimationClip {
        // implementation here...
    }

    public function resetDuration(): AnimationClip {
        var duration: Float = 0;

        for (i in 0...this.tracks.length) {
            var track: KeyframeTrack = this.tracks[i];
            duration = Math.max(duration, track.times[track.times.length - 1]);
        }

        this.duration = duration;

        return this;
    }

    public function trim(): AnimationClip {
        for (i in 0...this.tracks.length) {
            this.tracks[i].trim(0, this.duration);
        }

        return this;
    }

    public function validate(): Bool {
        var valid: Bool = true;

        for (i in 0...this.tracks.length) {
            valid = valid && this.tracks[i].validate();
        }

        return valid;
    }

    public function optimize(): AnimationClip {
        for (i in 0...this.tracks.length) {
            this.tracks[i].optimize();
        }

        return this;
    }

    public function clone(): AnimationClip {
        var tracks: Array<KeyframeTrack> = [];

        for (i in 0...this.tracks.length) {
            tracks.push(this.tracks[i].clone());
        }

        return new AnimationClip(this.name, this.duration, tracks, this.blendMode);
    }

    public function toJSON(): Dynamic {
        return AnimationClip.toJSON(this);
    }
}

function getTrackTypeForValueTypeName(typeName: String): Class<KeyframeTrack> {
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

    throw 'Unsupported typeName: ' + typeName;
}

function parseKeyframeTrack(json: Dynamic): KeyframeTrack {
    if (json.type == null) {
        throw 'track type undefined, can not parse';
    }

    var trackType: Class<KeyframeTrack> = getTrackTypeForValueTypeName(json.type);

    if (json.times == null) {
        var times: Array<Float> = [];
        var values: Array<Dynamic> = [];

        AnimationUtils.flattenJSON(json.keys, times, values, 'value');

        json.times = times;
        json.values = values;
    }

    if (Reflect.hasField(trackType, 'parse')) {
        return Reflect.callMethod(trackType, trackType.parse, [json]);
    } else {
        return Reflect.construct(trackType, [json.name, json.times, json.values, json.interpolation]);
    }
}