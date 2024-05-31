import three.constants.InterpolateLinear;
import three.constants.InterpolateSmooth;
import three.constants.InterpolateDiscrete;
import three.math.interpolants.CubicInterpolant;
import three.math.interpolants.LinearInterpolant;
import three.math.interpolants.DiscreteInterpolant;
import three.utils.AnimationUtils;

class KeyframeTrack {
    public var name:String;
    public var times:Array<Float>;
    public var values:Array<Float>;
    public var createInterpolant:Dynamic;

    public static var TimeBufferType = haxe.ds.Vector<Float>;
    public static var ValueBufferType = haxe.ds.Vector<Float>;
    public static var DefaultInterpolation = InterpolateLinear;

    public function new(name:String, times:Array<Float>, values:Array<Float>, ?interpolation:Dynamic) {
        if (name == null) throw "THREE.KeyframeTrack: track name is undefined";
        if (times == null || times.length == 0) throw "THREE.KeyframeTrack: no keyframes in track named " + name;

        this.name = name;
        this.times = AnimationUtils.convertArray(times, KeyframeTrack.TimeBufferType);
        this.values = AnimationUtils.convertArray(values, KeyframeTrack.ValueBufferType);
        setInterpolation(interpolation != null ? interpolation : KeyframeTrack.DefaultInterpolation);
    }

    public static function toJSON(track:KeyframeTrack):Dynamic {
        var trackType = Type.getClass(track);
        var json:Dynamic;

        if (Reflect.hasField(trackType, "toJSON") && trackType.toJSON != KeyframeTrack.toJSON) {
            json = trackType.toJSON(track);
        } else {
            json = {
                name: track.name,
                times: AnimationUtils.convertArray(track.times, Array),
                values: AnimationUtils.convertArray(track.values, Array)
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

    public function setInterpolation(interpolation:Dynamic):KeyframeTrack {
        var factoryMethod:Dynamic;

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
            default:
                var message = "unsupported interpolation for " + this.ValueTypeName + " keyframe track named " + this.name;
                if (this.createInterpolant == null) {
                    if (interpolation != KeyframeTrack.DefaultInterpolation) {
                        setInterpolation(KeyframeTrack.DefaultInterpolation);
                    } else {
                        throw message;
                    }
                }
                trace("THREE.KeyframeTrack: " + message);
                return this;
        }

        this.createInterpolant = factoryMethod;
        return this;
    }

    public function getInterpolation():Dynamic {
        switch (this.createInterpolant) {
            case InterpolantFactoryMethodDiscrete:
                return InterpolateDiscrete;
            case InterpolantFactoryMethodLinear:
                return InterpolateLinear;
            case InterpolantFactoryMethodSmooth:
                return InterpolateSmooth;
            default:
                return null;
        }
    }

    public function getValueSize():Int {
        return Std.int(values.length / times.length);
    }

    public function shift(timeOffset:Float):KeyframeTrack {
        if (timeOffset != 0) {
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

        while (from < times.length && times[from] < startTime) from++;
        while (to >= 0 && times[to] > endTime) to--;

        to++; // inclusive -> exclusive bound

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
            trace("THREE.KeyframeTrack: Invalid value size in track.");
            valid = false;
        }

        if (times.length == 0) {
            trace("THREE.KeyframeTrack: Track is empty.");
            valid = false;
        }

        var prevTime:Float = null;
        for (i in 0...times.length) {
            var currTime = times[i];

            if (Math.isNaN(currTime)) {
                trace("THREE.KeyframeTrack: Time is not a valid number.");
                valid = false;
                break;
            }

            if (prevTime != null && prevTime > currTime) {
                trace("THREE.KeyframeTrack: Out of order keys.");
                valid = false;
                break;
            }

            prevTime = currTime;
        }

        if (values != null) {
            if (Reflect.is(values, haxe.ds.Vector)) {
                for (i in 0...values.length) {
                    if (Math.isNaN(values[i])) {
                        trace("THREE.KeyframeTrack: Value is not a valid number.");
                        valid = false;
                        break;
                    }
                }
            }
        }

        return valid;
    }

    public function optimize():KeyframeTrack {
        var times = this.times.slice();
        var values = this.values.slice();
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
                        if (values[offset + j] != values[offsetP + j] || values[offset + j] != values[offsetN + j]) {
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

                writeIndex++;
            }
        }

        if (lastIndex > 0) {
            times[writeIndex] = times[lastIndex];
            var readOffset = lastIndex * stride;
            var writeOffset = writeIndex * stride;

            for (j in 0...stride) {
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
        var TypedKeyframeTrack = Type.getClass(this);
        var track = Type.createInstance(TypedKeyframeTrack, [name, times, values]);
        track.createInterpolant = this.createInterpolant;
        return track;
    }
}