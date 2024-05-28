package three.animation;

import three.math.Interpolant;
import three.math.CubicInterpolant;
import three.math.LinearInterpolant;
import three.math.DiscreteInterpolant;

class KeyframeTrack {
    public var name:String;
    public var times:Array<Float>;
    public var values:Array<Float>;
    public var createInterpolant:Dynamic->Void;

    public static var TimeBufferType:Class<array> = Float32Array;
    public static var ValueBufferType:Class<array> = Float32Array;
    public static var DefaultInterpolation:Int = InterpolateLinear;

    public function new(name:String, times:Array<Float>, values:Array<Float>, interpolation:Int = DefaultInterpolation) {
        if (name == null) throw new Error('THREE.KeyframeTrack: track name is undefined');
        if (times == null || times.length == 0) throw new Error('THREE.KeyframeTrack: no keyframes in track named ' + name);

        this.name = name;

        times = AnimationUtils.convertArray(times, TimeBufferType);
        values = AnimationUtils.convertArray(values, ValueBufferType);

        setInterpolation(interpolation);
    }

    public static function toJSON(track:KeyframeTrack):Dynamic {
        var trackType = Type.getClassName(Type.getClass(track));
        var json:Dynamic;

        if (trackType.toJSONString != toJSON) {
            json = trackType.toJSONString(track);
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

    public function InterpolantFactoryMethodDiscrete(result:Dynamic) {
        return new DiscreteInterpolant(times, values, getValueSize(), result);
    }

    public function InterpolantFactoryMethodLinear(result:Dynamic) {
        return new LinearInterpolant(times, values, getValueSize(), result);
    }

    public function InterpolantFactoryMethodSmooth(result:Dynamic) {
        return new CubicInterpolant(times, values, getValueSize(), result);
    }

    public function setInterpolation(interpolation:Int) {
        var factoryMethod:Dynamic;

        switch (interpolation) {
            case InterpolateDiscrete:
                factoryMethod = InterpolantFactoryMethodDiscrete;
            case InterpolateLinear:
                factoryMethod = InterpolantFactoryMethodLinear;
            case InterpolateSmooth:
                factoryMethod = InterpolantFactoryMethodSmooth;
        }

        if (factoryMethod == null) {
            var message:String = 'unsupported interpolation for ' + ValueTypeName + ' keyframe track named ' + name;

            if (createInterpolant == null) {
                if (interpolation != DefaultInterpolation) {
                    setInterpolation(DefaultInterpolation);
                } else {
                    throw new Error(message); // fatal, in this case
                }
            }

            console.warn('THREE.KeyframeTrack:', message);
            return this;
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

        return 0;
    }

    public function getValueSize():Int {
        return values.length / times.length;
    }

    public function shift(timeOffset:Float) {
        if (timeOffset != 0.0) {
            for (i in 0...times.length) {
                times[i] += timeOffset;
            }
        }

        return this;
    }

    public function scale(timeScale:Float) {
        if (timeScale != 1.0) {
            for (i in 0...times.length) {
                times[i] *= timeScale;
            }
        }

        return this;
    }

    public function trim(startTime:Float, endTime:Float) {
        var from:Int = 0;
        var to:Int = times.length - 1;

        while (from < times.length && times[from] < startTime) {
            from++;
        }

        while (to >= 0 && times[to] > endTime) {
            to--;
        }

        to++; // inclusive -> exclusive bound

        if (from != 0 || to != times.length) {
            // empty tracks are forbidden, so keep at least one keyframe
            if (from >= to) {
                to = Math.max(to, 1);
                from = to - 1;
            }

            times = times.slice(from, to);
            values = values.slice(from * getValueSize(), to * getValueSize());
        }

        return this;
    }

    public function validate():Bool {
        var valid:Bool = true;

        var valueSize:Int = getValueSize();
        if (valueSize - Math.floor(valueSize) != 0) {
            console.error('THREE.KeyframeTrack: Invalid value size in track.', this);
            valid = false;
        }

        var prevTime:Null<Float> = null;

        for (i in 0...times.length) {
            var currTime:Float = times[i];

            if (Math.isNaN(currTime)) {
                console.error('THREE.KeyframeTrack: Time is not a valid number.', this, i, currTime);
                valid = false;
                break;
            }

            if (prevTime != null && prevTime > currTime) {
                console.error('THREE.KeyframeTrack: Out of order keys.', this, i, currTime, prevTime);
                valid = false;
                break;
            }

            prevTime = currTime;
        }

        if (values != null) {
            for (i in 0...values.length) {
                var value:Float = values[i];

                if (Math.isNaN(value)) {
                    console.error('THREE.KeyframeTrack: Value is not a valid number.', this, i, value);
                    valid = false;
                    break;
                }
            }
        }

        return valid;
    }

    public function optimize() {
        var times:Array<Float> = times.slice();
        var values:Array<Float> = values.slice();
        var stride:Int = getValueSize();

        var lastIndex:Int = times.length - 1;

        var writeIndex:Int = 1;

        for (i in 1...lastIndex) {
            var keep:Bool = false;

            var time:Float = times[i];
            var timeNext:Float = times[i + 1];

            if (time != timeNext && (i != 1 || time != times[0])) {
                if (!smoothInterpolation) {
                    for (j in 0...stride) {
                        var value:Float = values[i * stride + j];

                        if (value != values[(i - 1) * stride + j] || value != values[(i + 1) * stride + j]) {
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

                    for (j in 0...stride) {
                        values[writeIndex * stride + j] = values[i * stride + j];
                    }
                }

                writeIndex++;
            }
        }

        if (writeIndex != times.length) {
            times = times.slice(0, writeIndex);
            values = values.slice(0, writeIndex * stride);
        }

        return this;
    }

    public function clone():KeyframeTrack {
        var times:Array<Float> = times.slice();
        var values:Array<Float> = values.slice();

        var track:KeyframeTrack = new KeyframeTrack(name, times, values);

        track.createInterpolant = createInterpolant;

        return track;
    }
}