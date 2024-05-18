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

    public function new(name:String = '', duration:Float = -1, tracks:Array<KeyframeTrack> = [], blendMode:Int = NormalAnimationBlendMode) {
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

    // ... other static methods ...

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

    // ... other instance methods ...
}

// ... other functions ...