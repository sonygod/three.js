import AnimationUtils from "three/animation/AnimationUtils";
import KeyframeTrack from "three/animation/KeyframeTrack";
import BooleanKeyframeTrack from "three/animation/tracks/BooleanKeyframeTrack";
import ColorKeyframeTrack from "three/animation/tracks/ColorKeyframeTrack";
import NumberKeyframeTrack from "three/animation/tracks/NumberKeyframeTrack";
import QuaternionKeyframeTrack from "three/animation/tracks/QuaternionKeyframeTrack";
import StringKeyframeTrack from "three/animation/tracks/StringKeyframeTrack";
import VectorKeyframeTrack from "three/animation/tracks/VectorKeyframeTrack";
import MathUtils from "three/math/MathUtils";
import NormalAnimationBlendMode from "three/constants";

class AnimationClip {
  public name:String;
  public tracks:Array<KeyframeTrack>;
  public duration:Float;
  public blendMode:NormalAnimationBlendMode;
  public uuid:String;

  public function new(name:String = "", duration:Float = -1, tracks:Array<KeyframeTrack> = [], blendMode:NormalAnimationBlendMode = NormalAnimationBlendMode.NormalAnimationBlendMode) {
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
    var frameTime = 1.0 / (json.fps || 1.0);

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
      "name": clip.name,
      "duration": clip.duration,
      "tracks": tracks,
      "uuid": clip.uuid,
      "blendMode": clip.blendMode
    };

    for (i in 0...clipTracks.length) {
      tracks.push(KeyframeTrack.toJSON(clipTracks[i]));
    }

    return json;
  }

  public static function CreateFromMorphTargetSequence(name:String, morphTargetSequence:Array<Dynamic>, fps:Float, noLoop:Bool):AnimationClip {
    var numMorphTargets = morphTargetSequence.length;
    var tracks:Array<KeyframeTrack> = [];

    for (i in 0...numMorphTargets) {
      var times:Array<Float> = [];
      var values:Array<Float> = [];

      times.push(
        (i + numMorphTargets - 1) % numMorphTargets,
        i,
        (i + 1) % numMorphTargets
      );

      values.push(0, 1, 0);

      var order = AnimationUtils.getKeyframeOrder(times);
      times = AnimationUtils.sortedArray(times, 1, order);
      values = AnimationUtils.sortedArray(values, 1, order);

      if (!noLoop && times[0] == 0) {
        times.push(numMorphTargets);
        values.push(values[0]);
      }

      tracks.push(
        new NumberKeyframeTrack(
          ".morphTargetInfluences[" + morphTargetSequence[i].name + "]",
          times, values
        ).scale(1.0 / fps)
      );
    }

    return new AnimationClip(name, -1, tracks);
  }

  public static function findByName(objectOrClipArray:Dynamic, name:String):AnimationClip {
    var clipArray = objectOrClipArray;

    if (!Std.is(objectOrClipArray, Array)) {
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

  public static function CreateClipsFromMorphTargetSequences(morphTargets:Array<Dynamic>, fps:Float, noLoop:Bool):Array<AnimationClip> {
    var animationToMorphTargets:Dynamic = {};

    for (i in 0...morphTargets.length) {
      var morphTarget = morphTargets[i];
      var parts = morphTarget.name.match(new EReg("^([\w-]*?)([\d]+)$", ""));

      if (parts != null && parts.length > 1) {
        var name = parts[1];

        var animationMorphTargets = animationToMorphTargets[name];

        if (animationMorphTargets == null) {
          animationToMorphTargets[name] = animationMorphTargets = [];
        }

        animationMorphTargets.push(morphTarget);
      }
    }

    var clips:Array<AnimationClip> = [];

    for (name in animationToMorphTargets) {
      clips.push(AnimationClip.CreateFromMorphTargetSequence(name, animationToMorphTargets[name], fps, noLoop));
    }

    return clips;
  }

  // parse the animation.hierarchy format
  public static function parseAnimation(animation:Dynamic, bones:Array<Dynamic>):AnimationClip {
    if (animation == null) {
      console.error("THREE.AnimationClip: No animation in JSONLoader data.");
      return null;
    }

    var addNonemptyTrack = function(trackType:Dynamic, trackName:String, animationKeys:Array<Dynamic>, propertyName:String, destTracks:Array<KeyframeTrack>) {
      if (animationKeys.length != 0) {
        var times:Array<Float> = [];
        var values:Array<Float> = [];

        AnimationUtils.flattenJSON(animationKeys, times, values, propertyName);

        if (times.length != 0) {
          destTracks.push(new trackType(trackName, times, values));
        }
      }
    };

    var tracks:Array<KeyframeTrack> = [];

    var clipName = animation.name || "default";
    var fps = animation.fps || 30;
    var blendMode = animation.blendMode;

    var duration = animation.length || -1;

    var hierarchyTracks = animation.hierarchy || [];

    for (h in 0...hierarchyTracks.length) {
      var animationKeys = hierarchyTracks[h].keys;

      if (animationKeys == null || animationKeys.length == 0) {
        continue;
      }

      if (animationKeys[0].morphTargets != null) {
        var morphTargetNames:Dynamic = {};

        for (k in 0...animationKeys.length) {
          if (animationKeys[k].morphTargets != null) {
            for (m in 0...animationKeys[k].morphTargets.length) {
              morphTargetNames[animationKeys[k].morphTargets[m]] = -1;
            }
          }
        }

        for (morphTargetName in morphTargetNames) {
          var times:Array<Float> = [];
          var values:Array<Float> = [];

          for (m in 0...animationKeys[k].morphTargets.length) {
            var animationKey = animationKeys[k];

            times.push(animationKey.time);
            values.push(animationKey.morphTarget == morphTargetName ? 1 : 0);
          }

          tracks.push(new NumberKeyframeTrack(".morphTargetInfluence[" + morphTargetName + "]", times, values));
        }

        duration = morphTargetNames.length * fps;
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

function getTrackTypeForValueTypeName(typeName:String):Dynamic {
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

    default:
      throw new Error("THREE.KeyframeTrack: Unsupported typeName: " + typeName);
  }
}

function parseKeyframeTrack(json:Dynamic):KeyframeTrack {
  if (json.type == null) {
    throw new Error("THREE.KeyframeTrack: track type undefined, can not parse");
  }

  var trackType = getTrackTypeForValueTypeName(json.type);

  if (json.times == null) {
    var times:Array<Float> = [];
    var values:Array<Float> = [];

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

export default AnimationClip;