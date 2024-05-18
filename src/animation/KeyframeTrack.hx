package three.animation;

import haxe.io.BytesBuffer;
import three.math.Interpolant.CubicInterpolant;
import three.math.Interpolant.DiscreteInterpolant;
import three.math.Interpolant.LinearInterpolant;
import three.utils.AnimationUtils;

class KeyframeTrack {
    public var name:String;
    public var times:Float32Array;
    public var values:Float32Array;
    public var createInterpolant:Dynamic;

    public static var TimeBufferType:BytesBuffer = Float32Array;
    public static var ValueBufferType:BytesBuffer = Float32Array;
    public static var DefaultInterpolation:Int = InterpolateLinear;

    public function new(name:String, times:Array<Float>, values:Array<Float>, interpolation:Int) {
        if (name == null) throw new Error('THREE.KeyframeTrack: track name is undefined');
        if (times == null || times.length == 0) throw new Error('THREE.KeyframeTrack: no keyframes in track named ' + name);

        this.name = name;

        this.times = AnimationUtils.convertArray(times, TimeBufferType);
        this.values = AnimationUtils.convertArray(values, ValueBufferType);

        setInterpolation(interpolation == null ? DefaultInterpolation : interpolation);
    }

    public static function toJSON(track:KeyframeTrack):Dynamic {
        var trackType:Dynamic = Type.getClass(track);
        var json:Dynamic;

        if (trackType.toJSON != toJSON) {
            json = trackType.toJSON(track);
        } else {
            json = {
                name: track.name,
                times: AnimationUtils.convertArray(track.times, Array),
                values: AnimationUtils.convertArray(track.values, Array)
            };

            var interpolation:Int = track.getInterpolation();

            if (interpolation != DefaultInterpolation) {
                json.interpolation = interpolation;
            }
        }

        json.type = track.ValueTypeName; // mandatory

        return json;
    }

    public function InterpolantFactoryMethodDiscrete(result:Dynamic):DiscreteInterpolant {
        return new DiscreteInterpolant(this.times, this.values, getValueSize(), result);
    }

    public function InterpolantFactoryMethodLinear(result:Dynamic):LinearInterpolant {
        return new LinearInterpolant(this.times, this.values, getValueSize(), result);
    }

    public function InterpolantFactoryMethodSmooth(result:Dynamic):CubicInterpolant {
        return new CubicInterpolant(this.times, this.values, getValueSize(), result);
    }

    public function setInterpolation(interpolation:Int):KeyframeTrack {
        var factoryMethod:Dynamic;

        switch (interpolation) {
            case InterpolateDiscrete:
                factoryMethod = InterpolantFactoryMethodDiscrete;
            case InterpolateLinear:
                factoryMethod = InterpolantFactoryMethodLinear;
            case InterpolateSmooth:
                factoryMethod = InterpolantFactoryMethodSmooth;
            default:
                if (factoryMethod == null) {
                    var message:String = 'unsupported interpolation for ' + ValueTypeName + ' keyframe track named ' + name;

                    if (createInterpolant == null) {
                        if (interpolation != DefaultInterpolation) {
                            setInterpolation(DefaultInterpolation);
                        } else {
                            throw new Error(message); // fatal, in this case
                        }
                    }

                    Console.warn('THREE.KeyframeTrack:', message);
                    return this;
                }
        }

        createInterpolant = factoryMethod;

        return this;
    }

    public function getInterpolation():Int {
        switch (createInterpolant) {
            case InterpolantFactoryMethodDiscrete:
                return InterpolateDiscrete;
            case InterpolantFactoryMethodLinear:
                return InterpolateLinear;
            case InterpolantFactoryMethodSmooth:
                return InterpolateSmooth;
        }

        return DefaultInterpolation;
    }

    public function getValueSize():Int {
        return values.length / times.length;
    }

    public function shift(timeOffset:Float):KeyframeTrack {
        if (timeOffset != 0.0) {
            var times:Array<Float> = this.times;

            for (i in 0...times.length) {
                times[i] += timeOffset;
            }
        }

        return this;
    }

    public function scale(timeScale:Float):KeyframeTrack {
        if (timeScale != 1.0) {
            var times:Array<Float> = this.times;

            for (i in 0...times.length) {
                times[i] *= timeScale;
            }
        }

        return this;
    }

    public function trim(startTime:Float, endTime:Float):KeyframeTrack {
        var times:Array<Float> = this.times;
        var nKeys:Int = times.length;

        var from:Int = 0;
        var to:Int = nKeys - 1;

        while (from != nKeys && times[from] < startTime) {
            from++;
        }

        while (to != -1 && times[to] > endTime) {
            to--;
        }

        to++; // inclusive -> exclusive bound

        if (from != 0 || to != nKeys) {
            if (from >= to) {
                to = Math.max(to, 1);
                from = to - 1;
            }

            var stride:Int = getValueSize();
            this.times = times.slice(from, to);
            this.values = this.values.slice(from * stride, to * stride);
        }

        return this;
    }

    public function validate():Bool {
        var valid:Bool = true;

        var valueSize:Int = getValueSize();
        if (valueSize - Math.floor(valueSize) != 0) {
            Console.error('THREE.KeyframeTrack: Invalid value size in track.', this);
            valid = false;
        }

        var times:Array<Float> = this.times;
        var values:Array<Float> = this.values;

        var nKeys:Int = times.length;

        if (nKeys == 0) {
            Console.error('THREE.KeyframeTrack: Track is empty.', this);
            valid = false;
        }

        var prevTime:Float = null;

        for (i in 0...nKeys) {
            var currTime:Float = times[i];

            if (Math.isNaN(currTime)) {
                Console.error('THREE.KeyframeTrack: Time is not a valid number.', this, i, currTime);
                valid = false;
                break;
            }

            if (prevTime != null && prevTime > currTime) {
                Console.error('THREE.KeyframeTrack: Out of order keys.', this, i, currTime, prevTime);
                valid = false;
                break;
            }

            prevTime = currTime;
        }

        if (values != null) {
            if (AnimationUtils.isTypedArray(values)) {
                for (i in 0...values.length) {
                    var value:Float = values[i];

                    if (Math.isNaN(value)) {
                        Console.error('THREE.KeyframeTrack: Value is not a valid number.', this, i, value);
                        valid = false;
                        break;
                    }
                }
            }
        }

        return valid;
    }

    public function optimize():KeyframeTrack {
        var times:Array<Float> = this.times.slice();
        var values:Array<Float> = this.values.slice();
        var stride:Int = getValueSize();

        var lastIndex:Int = times.length - 1;

        var writeIndex:Int = 1;

        for (i in 1...lastIndex) {
            var keep:Bool = false;

            var time:Float = times[i];
            var timeNext:Float = times[i + 1];

            if (time != timeNext && (i != 1 || time != times[0])) {
                if (!smoothInterpolation) {
                    var offset:Int = i * stride;
                    var offsetP:Int = offset - stride;
                    var offsetN:Int = offset + stride;

                    for (j in 0...stride) {
                        var value:Float = values[offset + j];

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

                    var readOffset:Int = i * stride;
                    var writeOffset:Int = writeIndex * stride;

                    for (j in 0...stride) {
                        values[writeOffset + j] = values[readOffset + j];
                    }
                }

                writeIndex++;
            }
        }

        if (lastIndex > 0) {
            times[writeIndex] = times[lastIndex];

            var readOffset:Int = lastIndex * stride;
            var writeOffset:Int = writeIndex * stride;

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
        var times:Array<Float> = this.times.slice();
        var values:Array<Float> = this.values.slice();

        var track:KeyframeTrack = new KeyframeTrack(name, times, values);

        track.createInterpolant = createInterpolant;

        return track;
    }
}