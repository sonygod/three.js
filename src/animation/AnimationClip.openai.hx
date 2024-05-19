import js.AnimationUtils;
import js.KeyframeTrack;
import js.BooleanKeyframeTrack;
import js.ColorKeyframeTrack;
import js.NumberKeyframeTrack;
import js.QuaternionKeyframeTrack;
import js.StringKeyframeTrack;
import js.VectorKeyframeTrack;
import js.MathUtils;
import js.constants.NormalAnimationBlendMode;

class AnimationClip {
  
  public var name:String;
  public var tracks:Array<KeyframeTrack>;
  public var duration:Float;
  public var blendMode:Float;
  public var uuid:String;
  
  public function new(name:String = "", duration:Float = -1, tracks:Array<KeyframeTrack> = [], blendMode:Float = NormalAnimationBlendMode) {
    
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
    
    var clip = new AnimationClip(json.name, Std.parseFloat(json.duration), tracks, json.blendMode);
    clip.uuid = json.uuid;
    
    return clip;
  }
  
  public static function toJSON(clip:AnimationClip):Dynamic {
    
    var tracks:Array<Dynamic> = [];
    var clipTracks:Array<KeyframeTrack> = clip.tracks;
    
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
  
  // Other static methods
  
  private function resetDuration():Void {
    var duration:Float = 0;
    
    for (i in 0...this.tracks.length) {
      var track = this.tracks[i];
      duration = Math.max(duration, track.times[track.times.length - 1]);
    }
    
    this.duration = duration;
  }
  
  private function trim():Void {
    for (i in 0...this.tracks.length) {
      this.tracks[i].trim(0, this.duration);
    }
  }
  
  private function validate():Bool {
    var valid:Bool = true;
    
    for (i in 0...this.tracks.length) {
      valid = valid && this.tracks[i].validate();
    }
    
    return valid;
  }
  
  private function optimize():Void {
    for (i in 0...this.tracks.length) {
      this.tracks[i].optimize();
    }
  }
  
  public function clone():AnimationClip {
    var tracks:Array<KeyframeTrack> = [];
    
    for (i in 0...this.tracks.length) {
      tracks.push(this.tracks[i].clone());
    }
    
    return new AnimationClip(this.name, this.duration, tracks, this.blendMode);
  }
  
  public function toJSON():Dynamic {
    return this.constructor.toJSON(this);
  }
  
}

// Helper functions

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

function parseKeyframeTrack(json:Dynamic):Dynamic {

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

  // derived classes can define a static parse method
  if (trackType.parse != null) {
    return trackType.parse(json);
  } else {
    // by default, we assume a constructor compatible with the base
    return new trackType(json.name, json.times, json.values, json.interpolation);
  }

}