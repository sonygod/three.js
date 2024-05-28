import js.Browser.window;
import js.html.Float32Array;
import js.html.Int16Array;
import js.html.Int32Array;
import js.html.Int8Array;
import js.html.Uint16Array;
import js.html.Uint32Array;
import js.html.Uint8Array;
import js.html.Uint8ClampedArray;

class KeyframeTrack {
    public var name:String;
    public var times:Float32Array;
    public var values:Float32Array;
    public var createInterpolant:Dynamic;
    public static var DefaultInterpolation:Dynamic;
    public static var TimeBufferType:Dynamic;
    public static var ValueBufferType:Dynamic;
    public static var ValueTypeName:String;

    public function new(name:String, times:Float32Array, values:Float32Array, interpolation:Dynamic) {
        if (name == null) {
            throw new Error('THREE.KeyframeTrack: track name is undefined');
        }
        if (times == null || times.length == 0) {
            throw new Error('THREE.KeyframeTrack: no keyframes in track named ' + name);
        }

        this.name = name;
        this.times = AnimationUtils.convertArray(times, KeyframeTrack.TimeBufferType);
        this.values = AnimationUtils.convertArray(values, KeyframeTrack.ValueBufferType);
        this.setInterpolation(interpolation || KeyframeTrack.DefaultInterpolation);
    }

    public static function toJSON(track:KeyframeTrack):Dynamic {
        var trackType = Type.getClass(track);
        var json:Dynamic;

        // derived classes can define a static toJSON method
        if (trackType.fields.toJSON != KeyframeTrack.toJSON) {
            json = trackType.fields.toJSON(track);
        } else {
            // by default, we assume the data can be serialized as-is
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

    public function InterpolantFactoryMethodDiscrete(result:Dynamic):Dynamic {
        return new DiscreteInterpolant(this.times, this.values, this.getValueSize(), result);
    }

    public function InterpolantFactoryMethodLinear(result:Dynamic):Dynamic {
        return new LinearInterpolant(this.times, this.values, this.getValueSize(), result);
    }

    public function InterpolantFactoryMethodSmooth(result:Dynamic):Dynamic {
        return new CubicInterpolant(this.times, this.values, this.getValueSize(), result);
    }

    public function setInterpolation(interpolation:Dynamic):KeyframeTrack {
        var factoryMethod:Dynamic;
        switch (interpolation) {
            case InterpolateDiscrete:
                factoryMethod = $bind(this, this.InterpolantFactoryMethodDiscrete);
                break;
            case InterpolateLinear:
                factoryMethod = $bind(this, this.InterpolantFactoryMethodLinear);
                break;
            case InterpolateSmooth:
                factoryMethod = $bind(this, this.InterpolantFactoryMethodSmooth);
                break;
        }

        if (factoryMethod == null) {
            var message = 'unsupported interpolation for ' + this.ValueTypeName + ' keyframe track named ' + this.name;
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
            case $bind(this, this.InterpolantFactoryMethodDiscrete):
                return InterpolateDiscrete;
            case $bind(this, this.InterpolantFactoryMethodLinear):
                return InterpolateLinear;
            case $bind(this, this.InterpolantFactoryMethodSmooth):
                return InterpolateSmooth;
        }
        return null;
    }

    public function getValueSize():Int {
        return Std.int(this.values.length / this.times.length);
    }

    public function shift(timeOffset:Float):KeyframeTrack {
        if (timeOffset != 0.0) {
            var times = this.times;
            var n = times.length;
            for (i in 0...n) {
                times[i] += timeOffset;
            }
        }
        return this;
    }

    public function scale(timeScale:Float):KeyframeTrack {
        if (timeScale != 1.0) {
            var times = this.times;
            var n = times.length;
            for (i in 0...n) {
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
            ++from;
        }

        while (to > -1 && times[to] > endTime) {
            --to;
        }

        ++to; // inclusive -> exclusive bound

        if (from != 0 || to != nKeys) {
            // empty tracks are forbidden, so keep at least one keyframe
            if (from >= to) {
                to = max(to, 1);
                from = to - 1;
            }

            var stride = this.getValueSize();
            this.times = times.slice(from, to);
            this.values = this.values.slice(from * stride, to * stride);
        }

        return this;
    }

    public function validate():Bool {
        var valueSize = this.getValueSize();
        if (valueSize - Std.int(valueSize) != 0) {
            trace('THREE.KeyframeTrack: Invalid value size in track.');
            return false;
        }

        var times = this.times;
        var values = this.values;
        var nKeys = times.length;

        if (nKeys == 0) {
            trace('THREE.KeyframeTrack: Track is empty.');
            return false;
        }

        var prevTime:Float = null;

        for (i in 0...nKeys) {
            var currTime = times[i];
            if (typeof currTime == 'number' && js.Boot.isNaN(currTime)) {
                trace('THREE.KeyframeTrack: Time is not a valid number.');
                return false;
            }

            if (prevTime != null && prevTime > currTime) {
                trace('THREE.KeyframeTrack: Out of order keys.');
                return false;
            }

            prevTime = currTime;
        }

        if (values != null) {
            if (AnimationUtils.isTypedArray(values)) {
                var n = values.length;
                for (i in 0...n) {
                    var value = values[i];
                    if (js.Boot.isNaN(value)) {
                        trace('THREE.KeyframeTrack: Value is not a valid number.');
                        return false;
                    }
                }
            }
        }

        return true;
    }

    public function optimize():KeyframeTrack {
        // times or values may be shared with other tracks, so overwriting is unsafe
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

            // remove adjacent keyframes scheduled at the same time
            if (time != timeNext && (i != 1 || time != times[0])) {
                if (!smoothInterpolation) {
                    // remove unnecessary keyframes same as their neighbors
                    var offset = i * stride;
                    var offsetP = offset - stride;
                    var offsetN = offset + stride;
                    var j = 0;
                    while (j < stride) {
                        var value = values[offset + j];
                        if (value != values[offsetP + j] || value != values[offsetN + j]) {
                            keep = true;
                            break;
                        }
                        ++j;
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
                    var j = 0;
                    while (j < stride) {
                        values[writeOffset + j] = values[readOffset + j];
                        ++j;
                    }
                }
                ++writeIndex;
            }
        }

        // flush last keyframe (compaction looks ahead)
        if (lastIndex > 0) {
            times[writeIndex] = times[lastIndex];
            var readOffset = lastIndex * stride;
            var writeOffset = writeIndex * stride;
            var j = 0;
            while (j < stride) {
                values[writeOffset + j] = values[readOffset + j];
                ++j;
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
        var times = this.times.slice();
        var values = this.values.slice();
        var TypedKeyframeTrack = Type.getClass(this);
        var track = new TypedKeyframeTrack(this.name, times, values);
        // Interpolant argument to constructor is not saved, so copy the factory method directly.
        track.createInterpolant = this.createInterpolant;
        return track;
    }
}

KeyframeTrack.TimeBufferType = Float32Array;
KeyframeTrack.ValueBufferType = Float32Array;
KeyframeTrack.DefaultInterpolation = InterpolateLinear;