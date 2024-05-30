import js.three.constants.InterpolateDiscrete;
import js.three.constants.InterpolateLinear;
import js.three.constants.InterpolateSmooth;
import js.three.math.interpolants.CubicInterpolant;
import js.three.math.interpolants.DiscreteInterpolant;
import js.three.math.interpolants.LinearInterpolant;
import js.three.animation.AnimationUtils;

class KeyframeTrack {

    public var name:String;
    public var times:Array<Float>;
    public var values:Array<Float>;
    public var createInterpolant:Float->Dynamic->Dynamic;
    public var TimeBufferType:Class<Float32Array>;
    public var ValueBufferType:Class<Float32Array>;
    public var DefaultInterpolation:Float;

    public function new(name:String, times:Array<Float>, values:Array<Float>, interpolation:Float = 1) {
        if (name == null) throw new Error('THREE.KeyframeTrack: track name is undefined');
        if (times == null || times.length == 0) throw new Error('THREE.KeyframeTrack: no keyframes in track named ' + name);
        this.name = name;
        this.times = AnimationUtils.convertArray(times, TimeBufferType);
        this.values = AnimationUtils.convertArray(values, ValueBufferType);
        setInterpolation(interpolation != null ? interpolation : DefaultInterpolation);
    }

    public static function toJSON(track:KeyframeTrack):Dynamic {
        var trackType = Type.getClass(track);
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
        json.type = track.ValueTypeName;
        return json;
    }

    public function InterpolantFactoryMethodDiscrete(result:Dynamic):DiscreteInterpolant {
        return new DiscreteInterpolant(times, values, getValueSize(), result);
    }

    public function InterpolantFactoryMethodLinear(result:Dynamic):LinearInterpolant {
        return new LinearInterpolant(times, values, getValueSize(), result);
    }

    public function InterpolantFactoryMethodSmooth(result:Dynamic):CubicInterpolant {
        return new CubicInterpolant(times, values, getValueSize(), result);
    }

    public function setInterpolation(interpolation:Float):KeyframeTrack {
        var factoryMethod:Float->Dynamic->Dynamic;
        switch (interpolation) {
            case InterpolateDiscrete:
                factoryMethod = InterpolantFactoryMethodDiscrete;
                break;
            case InterpolateLinear:
                factoryMethod = InterpolantFactoryMethodLinear;
                break;
            case InterpolateSmooth:
                factoryMethod = InterpolantFactoryMethodSmooth;
                break;
        }
        if (factoryMethod == null) {
            var message = 'unsupported interpolation for ' + ValueTypeName + ' keyframe track named ' + name;
            if (createInterpolant == null) {
                if (interpolation != DefaultInterpolation) {
                    setInterpolation(DefaultInterpolation);
                } else {
                    throw new Error(message);
                }
            }
            trace('THREE.KeyframeTrack:', message);
            return this;
        }
        createInterpolant = factoryMethod;
        return this;
    }

    public function getInterpolation():Float {
        switch (createInterpolant) {
            case InterpolantFactoryMethodDiscrete:
                return InterpolateDiscrete;
            case InterpolantFactoryMethodLinear:
                return InterpolateLinear;
            case InterpolantFactoryMethodSmooth:
                return InterpolateSmooth;
        }
    }

    public function getValueSize():Int {
        return values.length / times.length;
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

    public function trim(startTime:Float, endTime:Float):KeyframeTrack {
        var from = 0;
        var to = times.length - 1;
        while (from != times.length && times[from] < startTime) {
            ++from;
        }
        while (to != -1 && times[to] > endTime) {
            --to;
        }
        ++to;
        if (from != 0 || to != times.length) {
            if (from >= to) {
                to = Math.max(to, 1);
                from = to - 1;
            }
            var stride = getValueSize();
            times = times.slice(from, to);
            values = values.slice(from * stride, to * stride);
        }
        return this;
    }

    public function validate():Bool {
        var valid = true;
        var valueSize = getValueSize();
        if (valueSize - Math.floor(valueSize) != 0) {
            trace('THREE.KeyframeTrack: Invalid value size in track.', this);
            valid = false;
        }
        var nKeys = times.length;
        if (nKeys == 0) {
            trace('THREE.KeyframeTrack: Track is empty.', this);
            valid = false;
        }
        var prevTime = null;
        for (i in 0...nKeys) {
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
            if (Std.is(values, Float32Array)) {
                for (i in 0...values.length) {
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
        var times = this.times.copy();
        var values = this.values.copy();
        var stride = getValueSize();
        var smoothInterpolation = getInterpolation() == InterpolateSmooth;
        var lastIndex = times.length - 1;
        var writeIndex = 1;
        for (i in 1...lastIndex) {
            var keep = false;
            var time = times[i];
            var timeNext = times[i + 1];
            if (time != timeNext && (i != 1 || time != times[0])) {
                if (!smoothInterpolation) {
                    var offset = i * stride;
                    var offsetP = offset - stride;
                    var offsetN = offset + stride;
                    for (j in 0...stride) {
                        var value = values[offset + j];
                        if (value != values[offsetP + j] || value != values[offsetN + j]) {
                            keep = true;
                            break;
                        }
                    }
                } else {
                    keep = true;
                }
            }
            if (keep) {
                if (i != writeIndex) {
                    times[writeIndex] = times[i];
                    var readOffset = i * stride;
                    var writeOffset = writeIndex * stride;
                    for (j in 0...stride) {
                        values[writeOffset + j] = values[readOffset + j];
                    }
                }
                ++writeIndex;
            }
        }
        if (lastIndex > 0) {
            times[writeIndex] = times[lastIndex];
            for (readOffset in lastIndex * stride...values.length) {
                values[writeIndex * stride + j] = values[readOffset + j];
            }
            ++writeIndex;
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
        var times = this.times.copy();
        var values = this.values.copy();
        var TypedKeyframeTrack = Type.getClass(this);
        var track = new TypedKeyframeTrack(this.name, times, values);
        track.createInterpolant = this.createInterpolant;
        return track;
    }
}