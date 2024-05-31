import three.constants.InterpolateDiscrete;
import three.constants.InterpolateLinear;
import three.constants.InterpolateSmooth;
import three.math.interpolants.CubicInterpolant;
import three.math.interpolants.DiscreteInterpolant;
import three.math.interpolants.LinearInterpolant;
import three.animation.AnimationUtils;

class KeyframeTrack {

  public var name:String;
  public var times:Float32Array;
  public var values:Float32Array;
  public var createInterpolant:Dynamic;

  public function new(name:String, times:Array<Float>, values:Array<Float>, interpolation:Dynamic = null) {
    if (name == null) throw new Error("THREE.KeyframeTrack: track name is undefined");
    if (times == null || times.length == 0) throw new Error("THREE.KeyframeTrack: no keyframes in track named " + name);
    this.name = name;
    this.times = AnimationUtils.convertArray(times, this.TimeBufferType);
    this.values = AnimationUtils.convertArray(values, this.ValueBufferType);
    this.setInterpolation(interpolation != null ? interpolation : this.DefaultInterpolation);
  }

  public static function toJSON(track:KeyframeTrack):Dynamic {
    var trackType = track.constructor;
    var json:Dynamic;
    if (trackType.toJSON != toJSON) {
      json = trackType.toJSON(track);
    } else {
      json = {
        'name': track.name,
        'times': AnimationUtils.convertArray(track.times, Array),
        'values': AnimationUtils.convertArray(track.values, Array)
      };
      var interpolation = track.getInterpolation();
      if (interpolation != track.DefaultInterpolation) {
        json.interpolation = interpolation;
      }
    }
    json.type = track.ValueTypeName; // mandatory
    return json;
  }

  public function InterpolantFactoryMethodDiscrete(result:Dynamic):DiscreteInterpolant {
    return new DiscreteInterpolant(this.times, this.values, this.getValueSize(), result);
  }

  public function InterpolantFactoryMethodLinear(result:Dynamic):LinearInterpolant {
    return new LinearInterpolant(this.times, this.values, this.getValueSize(), result);
  }

  public function InterpolantFactoryMethodSmooth(result:Dynamic):CubicInterpolant {
    return new CubicInterpolant(this.times, this.values, this.getValueSize(), result);
  }

  public function setInterpolation(interpolation:Dynamic):KeyframeTrack {
    var factoryMethod:Dynamic;
    switch (interpolation) {
      case InterpolateDiscrete:
        factoryMethod = this.InterpolantFactoryMethodDiscrete;
        break;
      case InterpolateLinear:
        factoryMethod = this.InterpolantFactoryMethodLinear;
        break;
      case InterpolateSmooth:
        factoryMethod = this.InterpolantFactoryMethodSmooth;
        break;
    }
    if (factoryMethod == null) {
      var message = 'unsupported interpolation for ' +
        this.ValueTypeName + ' keyframe track named ' + this.name;
      if (this.createInterpolant == null) {
        // fall back to default, unless the default itself is messed up
        if (interpolation != this.DefaultInterpolation) {
          this.setInterpolation(this.DefaultInterpolation);
        } else {
          throw new Error(message); // fatal, in this case
        }
      }
      trace('THREE.KeyframeTrack:', message);
      return this;
    }
    this.createInterpolant = factoryMethod;
    return this;
  }

  public function getInterpolation():Dynamic {
    switch (this.createInterpolant) {
      case this.InterpolantFactoryMethodDiscrete:
        return InterpolateDiscrete;
      case this.InterpolantFactoryMethodLinear:
        return InterpolateLinear;
      case this.InterpolantFactoryMethodSmooth:
        return InterpolateSmooth;
    }
  }

  public function getValueSize():Int {
    return this.values.length / this.times.length;
  }

  public function shift(timeOffset:Float):KeyframeTrack {
    if (timeOffset != 0.0) {
      var times = this.times;
      for (var i = 0; i < times.length; i++) {
        times[i] += timeOffset;
      }
    }
    return this;
  }

  public function scale(timeScale:Float):KeyframeTrack {
    if (timeScale != 1.0) {
      var times = this.times;
      for (var i = 0; i < times.length; i++) {
        times[i] *= timeScale;
      }
    }
    return this;
  }

  public function trim(startTime:Float, endTime:Float):KeyframeTrack {
    var times = this.times;
    var nKeys = times.length;
    var from = 0;
    var to = nKeys - 1;
    while (from < nKeys && times[from] < startTime) {
      from++;
    }
    while (to != -1 && times[to] > endTime) {
      to--;
    }
    to++; // inclusive -> exclusive bound
    if (from != 0 || to != nKeys) {
      // empty tracks are forbidden, so keep at least one keyframe
      if (from >= to) {
        to = Math.max(to, 1);
        from = to - 1;
      }
      var stride = this.getValueSize();
      this.times = times.slice(from, to);
      this.values = this.values.slice(from * stride, to * stride);
    }
    return this;
  }

  public function validate():Bool {
    var valid = true;
    var valueSize = this.getValueSize();
    if (valueSize - Math.floor(valueSize) != 0) {
      trace('THREE.KeyframeTrack: Invalid value size in track.', this);
      valid = false;
    }
    var times = this.times;
    var values = this.values;
    var nKeys = times.length;
    if (nKeys == 0) {
      trace('THREE.KeyframeTrack: Track is empty.', this);
      valid = false;
    }
    var prevTime:Null<Float> = null;
    for (var i = 0; i < nKeys; i++) {
      var currTime = times[i];
      if (Std.is(currTime, Float) && Math.isNaN(currTime)) {
        trace('THREE.KeyframeTrack: Time is not a valid number.', this, i, currTime);
        valid = false;
        break;
      }
      if (prevTime != null && prevTime > currTime) {
        trace('THREE.KeyframeTrack: Out of order keys.', this, i, currTime, prevTime);
        valid = false;
        break;
      }
      prevTime = currTime;
    }
    if (values != null) {
      if (AnimationUtils.isTypedArray(values)) {
        for (var i = 0; i < values.length; i++) {
          var value = values[i];
          if (Math.isNaN(value)) {
            trace('THREE.KeyframeTrack: Value is not a valid number.', this, i, value);
            valid = false;
            break;
          }
        }
      }
    }
    return valid;
  }

  public function optimize():KeyframeTrack {
    // times or values may be shared with other tracks, so overwriting is unsafe
    var times = this.times.slice();
    var values = this.values.slice();
    var stride = this.getValueSize();
    var smoothInterpolation = this.getInterpolation() == InterpolateSmooth;
    var lastIndex = times.length - 1;
    var writeIndex = 1;
    for (var i = 1; i < lastIndex; i++) {
      var keep = false;
      var time = times[i];
      var timeNext = times[i + 1];
      // remove adjacent keyframes scheduled at the same time
      if (time != timeNext && (i != 1 || time != times[0])) {
        if (!smoothInterpolation) {
          // remove unnecessary keyframes same as their neighbors
          var offset = i * stride;
          var offsetP = offset - stride;
          var offsetN = offset + stride;
          for (var j = 0; j < stride; j++) {
            var value = values[offset + j];
            if (value != values[offsetP + j] ||
              value != values[offsetN + j]) {
              keep = true;
              break;
            }
          }
        } else {
          keep = true;
        }
      }
      // in-place compaction
      if (keep) {
        if (i != writeIndex) {
          times[writeIndex] = times[i];
          var readOffset = i * stride;
          var writeOffset = writeIndex * stride;
          for (var j = 0; j < stride; j++) {
            values[writeOffset + j] = values[readOffset + j];
          }
        }
        writeIndex++;
      }
    }
    // flush last keyframe (compaction looks ahead)
    if (lastIndex > 0) {
      times[writeIndex] = times[lastIndex];
      for (var readOffset = lastIndex * stride, writeOffset = writeIndex * stride, j = 0; j < stride; j++) {
        values[writeOffset + j] = values[readOffset + j];
      }
      writeIndex++;
    }
    if (writeIndex != times.length) {
      this.times = times.slice(0, writeIndex);
      this.values = values.slice(0, writeIndex * stride);
    } else {
      this.times = times;
      this.values = values;
    }
    return this;
  }

  public function clone():KeyframeTrack {
    var times = this.times.slice();
    var values = this.values.slice();
    var TypedKeyframeTrack = this.constructor;
    var track = new TypedKeyframeTrack(this.name, times, values);
    // Interpolant argument to constructor is not saved, so copy the factory method directly.
    track.createInterpolant = this.createInterpolant;
    return track;
  }

  public static var TimeBufferType:Class<Float32Array> = Float32Array;
  public static var ValueBufferType:Class<Float32Array> = Float32Array;
  public static var DefaultInterpolation:Dynamic = InterpolateLinear;
  public var ValueTypeName:String = "float";
}