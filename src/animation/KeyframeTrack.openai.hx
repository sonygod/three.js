package animation;

import InterpolateLinear;
import InterpolateSmooth;
import InterpolateDiscrete;
import CubicInterpolant;
import LinearInterpolant;
import DiscreteInterpolant;
import AnimationUtils;

class KeyframeTrack {

  public var name:String;
  public var times:Float32Array;
  public var values:Float32Array;
  public var createInterpolant:Dynamic;

  public function new(name:String, times:Array<Float>, values:Array<Float>, interpolation:Int) {
    if (name == null) throw new Error('THREE.KeyframeTrack: track name is undefined');
    if (times == null || times.length == 0) throw new Error('THREE.KeyframeTrack: no keyframes in track named ' + name);

    this.name = name;

    this.times = AnimationUtils.convertArray(times, this.TimeBufferType);
    this.values = AnimationUtils.convertArray(values, this.ValueBufferType);

    this.setInterpolation(interpolation != null ? interpolation : this.DefaultInterpolation);
  }

  public static function toJSON(track:KeyframeTrack):Dynamic {
    var trackType = Type.getClass(track);

    var json:Dynamic;

    if (Reflect.hasField(trackType, "toJSON") && Reflect.field(trackType, "toJSON") != KeyframeTrack.toJSON) {
      json = Reflect.field(trackType, "toJSON")(track);
    } else {
      json = {
        name: track.name,
        times: AnimationUtils.convertArray(track.times, Array<Float>),
        values: AnimationUtils.convertArray(track.values, Array<Float>)
      };

      var interpolation = track.getInterpolation();
      if (interpolation != track.DefaultInterpolation) {
        json.interpolation = interpolation;
      }
    }

    json.type = track.ValueTypeName;

    return json;
  }

  private function InterpolantFactoryMethodDiscrete(result:CubicInterpolant):DiscreteInterpolant {
    return new DiscreteInterpolant(this.times, this.values, this.getValueSize(), result);
  }

  private function InterpolantFactoryMethodLinear(result:LinearInterpolant):LinearInterpolant {
    return new LinearInterpolant(this.times, this.values, this.getValueSize(), result);
  }

  private function InterpolantFactoryMethodSmooth(result:CubicInterpolant):CubicInterpolant {
    return new CubicInterpolant(this.times, this.values, this.getValueSize(), result);
  }

  public function setInterpolation(interpolation:Int):KeyframeTrack {
    var factoryMethod:Dynamic;

    switch (interpolation) {
      case InterpolateDiscrete:
        factoryMethod = this.InterpolantFactoryMethodDiscrete;
      case InterpolateLinear:
        factoryMethod = this.InterpolantFactoryMethodLinear;
      case InterpolateSmooth:
        factoryMethod = this.InterpolantFactoryMethodSmooth;
    }

    if (factoryMethod == null) {
      var message = 'unsupported interpolation for ' + this.ValueTypeName + ' keyframe track named ' + this.name;

      if (this.createInterpolant == null) {
        if (interpolation != this.DefaultInterpolation) {
          this.setInterpolation(this.DefaultInterpolation);
        } else {
          throw new Error(message);
        }
      }

      trace('THREE.KeyframeTrack: ' + message);
      return this;
    }

    this.createInterpolant = factoryMethod;

    return this;
  }

  public function getInterpolation():Int {
    switch (this.createInterpolant) {
      case this.InterpolantFactoryMethodDiscrete:
        return InterpolateDiscrete;
      case this.InterpolantFactoryMethodLinear:
        return InterpolateLinear;
      case this.InterpolantFactoryMethodSmooth:
        return InterpolateSmooth;
    }

    return 0;
  }

  public function getValueSize():Int {
    return this.values.length / this.times.length;
  }

  public function shift(timeOffset:Float):KeyframeTrack {
    if (timeOffset != 0.0) {
      for (i in 0...times.length) {
        times[i] += timeOffset;
      }
    }

    return this;
  }

  public function scale(timeScale:Float):KeyframeTrack {
    if (timeScale != 1.0) {
      for (i in 0...times.length) {
        times[i] *= timeScale;
      }
    }

    return this;
  }

  // Implement the rest of the methods here

}