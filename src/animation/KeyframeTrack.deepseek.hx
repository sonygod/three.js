import three.js.src.animation.KeyframeTrack.*;
import three.js.src.constants.*;
import three.js.src.math.interpolants.CubicInterpolant.*;
import three.js.src.math.interpolants.LinearInterpolant.*;
import three.js.src.math.interpolants.DiscreteInterpolant.*;
import three.js.src.animation.AnimationUtils.*;

class KeyframeTrack {

    var name:String;
    var times:Float32Array;
    var values:Float32Array;
    var createInterpolant:Dynamic->Interpolant;

    public function new(name:String, times:Array<Float>, values:Array<Float>, interpolation:String) {

        if (name == null) throw 'THREE.KeyframeTrack: track name is undefined';
        if (times == null || times.length == 0) throw 'THREE.KeyframeTrack: no keyframes in track named ' + name;

        this.name = name;

        this.times = convertArray(times, TimeBufferType);
        this.values = convertArray(values, ValueBufferType);

        this.setInterpolation(interpolation != null ? interpolation : DefaultInterpolation);

    }

    static function toJSON(track:KeyframeTrack):Dynamic {

        var trackType = Type.resolveClass(track.constructor);

        var json:Dynamic;

        if (trackType.toJSON != this.toJSON) {

            json = trackType.toJSON(track);

        } else {

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

        json.type = track.ValueTypeName;

        return json;

    }

    function InterpolantFactoryMethodDiscrete(result:Dynamic):Interpolant {

        return new DiscreteInterpolant(this.times, this.values, this.getValueSize(), result);

    }

    function InterpolantFactoryMethodLinear(result:Dynamic):Interpolant {

        return new LinearInterpolant(this.times, this.values, this.getValueSize(), result);

    }

    function InterpolantFactoryMethodSmooth(result:Dynamic):Interpolant {

        return new CubicInterpolant(this.times, this.values, this.getValueSize(), result);

    }

    function setInterpolation(interpolation:String):KeyframeTrack {

        var factoryMethod:Dynamic->Interpolant;

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

                if (interpolation != this.DefaultInterpolation) {

                    this.setInterpolation(this.DefaultInterpolation);

                } else {

                    throw message;

                }

            }

            trace('THREE.KeyframeTrack:', message);
            return this;

        }

        this.createInterpolant = factoryMethod;

        return this;

    }

    function getInterpolation():String {

        switch (this.createInterpolant) {

            case this.InterpolantFactoryMethodDiscrete:

                return InterpolateDiscrete;

            case this.InterpolantFactoryMethodLinear:

                return InterpolateLinear;

            case this.InterpolantFactoryMethodSmooth:

                return InterpolateSmooth;

        }

    }

    function getValueSize():Int {

        return this.values.length / this.times.length;

    }

    function shift(timeOffset:Float):KeyframeTrack {

        if (timeOffset != 0.0) {

            var times = this.times;

            for (i in times) {

                times[i] += timeOffset;

            }

        }

        return this;

    }

    function scale(timeScale:Float):KeyframeTrack {

        if (timeScale != 1.0) {

            var times = this.times;

            for (i in times) {

                times[i] *= timeScale;

            }

        }

        return this;

    }

    function trim(startTime:Float, endTime:Float):KeyframeTrack {

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

        ++to;

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

    function validate():Bool {

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

        var prevTime:Null<Float> = null;

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

    function optimize():KeyframeTrack {

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

            if (time != timeNext && (i != 1 || time != times[0])) {

                if (!smoothInterpolation) {

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

    function clone():KeyframeTrack {

        var times = this.times.slice();
        var values = this.values.slice();

        var TypedKeyframeTrack = Type.resolveClass(this.constructor);
        var track = new TypedKeyframeTrack(this.name, times, values);

        track.createInterpolant = this.createInterpolant;

        return track;

    }

}

class KeyframeTrack {

    static var TimeBufferType:Class<Float32Array> = Float32Array;
    static var ValueBufferType:Class<Float32Array> = Float32Array;
    static var DefaultInterpolation:String = InterpolateLinear;

}