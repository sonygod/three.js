import animation.AnimationUtils;
import animation.tracks.KeyframeTrack;
import animation.tracks.BooleanKeyframeTrack;
import animation.tracks.ColorKeyframeTrack;
import animation.tracks.NumberKeyframeTrack;
import animation.tracks.QuaternionKeyframeTrack;
import animation.tracks.StringKeyframeTrack;
import animation.tracks.VectorKeyframeTrack;
import math.MathUtils;
import constants.NormalAnimationBlendMode;

class AnimationClip {
  
  public var name:String;
  public var tracks:Array<KeyframeTrack>;
  public var duration:Float;
  public var blendMode:NormalAnimationBlendMode;
  public var uuid:String;

  public function new(name:String = "", duration:Float = -1, tracks:Array<KeyframeTrack> = [], blendMode:NormalAnimationBlendMode = NormalAnimationBlendMode) {
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
    var frameTime:Float = 1.0 / (json.fps != null ? json.fps : 1.0);

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

  // More code translation here...

}
  
function getTrackTypeForValueTypeName(typeName:String):Dynamic {
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

  throw new Error('THREE.KeyframeTrack: Unsupported typeName: ' + typeName);
}

function parseKeyframeTrack(json:Dynamic):KeyframeTrack {
  if (json.type == null) {
    throw new Error('THREE.KeyframeTrack: track type undefined, can not parse');
  }

  var trackType:Dynamic = getTrackTypeForValueTypeName(json.type);

  if (json.times == null) {
    var times:Array<Float> = [];
    var values:Array<Dynamic> = [];

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