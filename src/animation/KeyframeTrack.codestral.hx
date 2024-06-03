import js.html.ArrayBufferView;
import js.html.Float32Array;
import three.constants.InterpolateLinear;
import three.constants.InterpolateSmooth;
import three.constants.InterpolateDiscrete;
import three.math.interpolants.CubicInterpolant;
import three.math.interpolants.LinearInterpolant;
import three.math.interpolants.DiscreteInterpolant;
import three.animation.AnimationUtils;

class KeyframeTrack {
    public var name:String;
    public var times:Array<Float>;
    public var values:Array<Float>;
    public var createInterpolant:Dynamic;
    public var TimeBufferType:Class<ArrayBufferView<Float>> = Float32Array;
    public var ValueBufferType:Class<ArrayBufferView<Float>> = Float32Array;
    public var DefaultInterpolation:Int = InterpolateLinear;

    public function new(name:String, times:Array<Float>, values:Array<Float>, interpolation?:Int) {
        if (name == null) throw new Error("THREE.KeyframeTrack: track name is undefined");
        if (times == null || times.length == 0) throw new Error("THREE.KeyframeTrack: no keyframes in track named " + name);

        this.name = name;
        this.times = AnimationUtils.convertArray(times, this.TimeBufferType);
        this.values = AnimationUtils.convertArray(values, this.ValueBufferType);

        this.setInterpolation(interpolation != null ? interpolation : this.DefaultInterpolation);
    }

    public static function toJSON(track:KeyframeTrack):Dynamic {
        var trackType = Type.getClass(track);
        var json:Dynamic;

        if (trackType.toJSON != KeyframeTrack.toJSON) {
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

    private function InterpolantFactoryMethodDiscrete(result:Dynamic):DiscreteInterpolant {
        return new DiscreteInterpolant(this.times, this.values, this.getValueSize(), result);
    }

    private function InterpolantFactoryMethodLinear(result:Dynamic):LinearInterpolant {
        return new LinearInterpolant(this.times, this.values, this.getValueSize(), result);
    }

    private function InterpolantFactoryMethodSmooth(result:Dynamic):CubicInterpolant {
        return new CubicInterpolant(this.times, this.values, this.getValueSize(), result);
    }

    public function setInterpolation(interpolation:Int):KeyframeTrack {
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
            var message = "unsupported interpolation for " + this.ValueTypeName + " keyframe track named " + this.name;

            if (this.createInterpolant == null) {
                if (interpolation != this.DefaultInterpolation) {
                    this.setInterpolation(this.DefaultInterpolation);
                } else {
                    throw new Error(message);
                }
            }

            trace("THREE.KeyframeTrack: " + message);
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
            default:
                return -1;
        }
    }

    public function getValueSize():Int {
        return this.values.length / this.times.length;
    }

    public function shift(timeOffset:Float):KeyframeTrack {
        if (timeOffset != 0.0) {
            var times = this.times;
            for (i in 0...times.length) {
                times[i] += timeOffset;
            }
        }
        return this;
    }

    public function scale(timeScale:Float):KeyframeTrack {
        if (timeScale != 1.0) {
            var times = this.times;
            for (i in 0...times.length) {
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

        while (from != nKeys && times[from] < startTime) {
            from++;
        }

        while (to != -1 && times[to] > endTime) {
            to--;
        }

        to++;

        if (from != 0 || to != nKeys) {
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
            trace("THREE.KeyframeTrack: Invalid value size in track.", this);
            valid = false;
        }

        var times = this.times;
        var values = this.values;

        var nKeys = times.length;

        if (nKeys == 0) {
            trace("THREE.KeyframeTrack: Track is empty.", this);
            valid = false;
        }

        var prevTime = null;

        for (i in 0...nKeys) {
            var currTime = times[i];

            if (Std.is(currTime, Float) && isNaN(currTime)) {
                trace("THREE.KeyframeTrack: Time is not a valid number.", this, i, currTime);
                valid = false;
                break;
            }

            if (prevTime != null && prevTime > currTime) {
                trace("THREE.KeyframeTrack: Out of order keys.", this, i, currTime, prevTime);
                valid = false;
                break;
            }

            prevTime = currTime;
        }

        if (values != null) {
            if (AnimationUtils.isTypedArray(values)) {
                for (i in 0...values.length) {
                    var value = values[i];

                    if (isNaN(value)) {
                        trace("THREE.KeyframeTrack: Value is not a valid number.", this, i, value);
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
        var stride = this.getValueSize();

        var smoothInterpolation = this.getInterpolation() == InterpolateSmooth;

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
        var track = new TypedKeyframeTrack(this.name, times, values);

        track.createInterpolant = this.createInterpolant;

        return track;
    }
}