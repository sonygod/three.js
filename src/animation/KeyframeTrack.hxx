import three.src.animation.KeyframeTrack.*;
import three.src.constants.*;
import three.src.math.interpolants.CubicInterpolant.*;
import three.src.math.interpolants.LinearInterpolant.*;
import three.src.math.interpolants.DiscreteInterpolant.*;
import three.src.animation.AnimationUtils.*;

class KeyframeTrack {

    public var name:String;
    public var times:Float32Array;
    public var values:Float32Array;
    public var createInterpolant:Dynamic;

    public function new(name:String, times:Float32Array, values:Float32Array, interpolation:String) {

        if (name == null) throw 'THREE.KeyframeTrack: track name is undefined';
        if (times == null || times.length == 0) throw 'THREE.KeyframeTrack: no keyframes in track named ' + name;

        this.name = name;

        this.times = convertArray(times, TimeBufferType);
        this.values = convertArray(values, ValueBufferType);

        this.setInterpolation(interpolation ? interpolation : DefaultInterpolation);

    }

    // Serialization (in static context, because of constructor invocation
    // and automatic invocation of .toJSON):

    public static function toJSON(track:KeyframeTrack):Dynamic {

        var trackType = Type.getClass(track);

        var json:Dynamic;

        // derived classes can define a static toJSON method
        if (trackType.toJSON != this.toJSON) {

            json = trackType.toJSON(track);

        } else {

            // by default, we assume the data can be serialized as-is
            json = {

                'name': track.name,
                'times': convertArray(track.times, Array),
                'values': convertArray(track.values, Array)

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

    public function setInterpolation(interpolation:String):KeyframeTrack {

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

                    throw message; // fatal, in this case

                }

            }

            trace('THREE.KeyframeTrack:', message);
            return this;

        }

        this.createInterpolant = factoryMethod;

        return this;

    }

    public function getInterpolation():String {

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

    // move all keyframes either forwards or backwards in time
    public function shift(timeOffset:Float):KeyframeTrack {

        if (timeOffset != 0.0) {

            var times = this.times;

            for (i in times) {

                times[i] += timeOffset;

            }

        }

        return this;

    }

    // scale all keyframe times by a factor (useful for frame <-> seconds conversions)
    public function scale(timeScale:Float):KeyframeTrack {

        if (timeScale != 1.0) {

            var times = this.times;

            for (i in times) {

                times[i] *= timeScale;

            }

        }

        return this;

    }

    // removes keyframes before and after animation without changing any values within the range [startTime, endTime].
    // IMPORTANT: We do not shift around keys to the start of the track time, because for interpolated keys this will change their values
    public function trim(startTime:Float, endTime:Float):KeyframeTrack {

        var times = this.times,
            nKeys = times.length;

        var from = 0,
            to = nKeys - 1;

        while (from != nKeys && times[from] < startTime) {

            ++from;

        }

        while (to != -1 && times[to] > endTime) {

            --to;

        }

        ++to; // inclusive -> exclusive bound

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

    // ensure we do not get a GarbageInGarbageOut situation, make sure tracks are at least minimally viable
    public function validate():Bool {

        var valid = true;

        var valueSize = this.getValueSize();
        if (valueSize - Math.floor(valueSize) != 0) {

            trace('THREE.KeyframeTrack: Invalid value size in track.', this);
            valid = false;

        }

        var times = this.times,
            values = this.values,

            nKeys = times.length;

        if (nKeys == 0) {

            trace('THREE.KeyframeTrack: Track is empty.', this);
            valid = false;

        }

        var prevTime:Float = null;

        for (i in times) {

            var currTime = times[i];

            if (isNaN(currTime)) {

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

            if (isTypedArray(values)) {

                for (i in values) {

                    var value = values[i];

                    if (isNaN(value)) {

                        trace('THREE.KeyframeTrack: Value is not a valid number.', this, i, value);
                        valid = false;
                        break;

                    }

                }

            }

        }

        return valid;

    }

    // removes equivalent sequential keys as common in morph target sequences
    // (0,0,0,0,1,1,1,0,0,0,0,0,0,0) --> (0,0,1,1,0,0)
    public function optimize():KeyframeTrack {

        // times or values may be shared with other tracks, so overwriting is unsafe
        var times = this.times.slice(),
            values = this.values.slice(),
            stride = this.getValueSize(),

            smoothInterpolation = this.getInterpolation() == InterpolateSmooth,

            lastIndex = times.length - 1;

        var writeIndex = 1;

        for (i in times) {

            var keep = false;

            var time = times[i];
            var timeNext = times[i + 1];

            // remove adjacent keyframes scheduled at the same time

            if (time != timeNext && (i != 1 || time != times[0])) {

                if (!smoothInterpolation) {

                    // remove unnecessary keyframes same as their neighbors

                    var offset = i * stride,
                        offsetP = offset - stride,
                        offsetN = offset + stride;

                    for (j in values) {

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

                    var readOffset = i * stride,
                        writeOffset = writeIndex * stride;

                    for (j in values) {

                        values[writeOffset + j] = values[readOffset + j];

                    }

                }

                ++writeIndex;

            }

        }

        // flush last keyframe (compaction looks ahead)

        if (lastIndex > 0) {

            times[writeIndex] = times[lastIndex];

            for (readOffset in lastIndex * stride, writeOffset in writeIndex * stride, j in values) {

                values[writeOffset + j] = values[readOffset + j];

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

        var track = new KeyframeTrack(this.name, times, values);

        // Interpolant argument to constructor is not saved, so copy the factory method directly.
        track.createInterpolant = this.createInterpolant;

        return track;

    }

    static var TimeBufferType:Class<Float32Array> = Float32Array;
    static var ValueBufferType:Class<Float32Array> = Float32Array;
    static var DefaultInterpolation:String = InterpolateLinear;

}