import js.Lib;

class Easing {
    public static var Linear:Dynamic = {
        None: function(amount) {
            return amount;
        },
        In: function(amount) {
            return amount;
        },
        Out: function(amount) {
            return amount;
        },
        InOut: function(amount) {
            return amount;
        }
    };
    public static var Quadratic:Dynamic = {
        In: function(amount) {
            return amount * amount;
        },
        Out: function(amount) {
            return amount * (2 - amount);
        },
        InOut: function(amount) {
            if ((amount *= 2) < 1) {
                return 0.5 * amount * amount;
            }
            return -0.5 * (--amount * (amount - 2) - 1);
        }
    };
    public static var Cubic:Dynamic = {
        In: function(amount) {
            return amount * amount * amount;
        },
        Out: function(amount) {
            return --amount * amount * amount + 1;
        },
        InOut: function(amount) {
            if ((amount *= 2) < 1) {
                return 0.5 * amount * amount * amount;
            }
            return 0.5 * ((amount -= 2) * amount * amount + 2);
        }
    };
    public static var Quartic:Dynamic = {
        In: function(amount) {
            return amount * amount * amount * amount;
        },
        Out: function(amount) {
            return 1 - --amount * amount * amount * amount;
        },
        InOut: function(amount) {
            if ((amount *= 2) < 1) {
                return 0.5 * amount * amount * amount * amount;
            }
            return -0.5 * ((amount -= 2) * amount * amount * amount - 2);
        }
    };
    public static var Quintic:Dynamic = {
        In: function(amount) {
            return amount * amount * amount * amount * amount;
        },
        Out: function(amount) {
            return --amount * amount * amount * amount * amount + 1;
        },
        InOut: function(amount) {
            if ((amount *= 2) < 1) {
                return 0.5 * amount * amount * amount * amount * amount;
            }
            return 0.5 * ((amount -= 2) * amount * amount * amount * amount + 2);
        }
    };
    public static var Sinusoidal:Dynamic = {
        In: function(amount) {
            return 1 - Math.sin(((1.0 - amount) * Math.PI) / 2);
        },
        Out: function(amount) {
            return Math.sin((amount * Math.PI) / 2);
        },
        InOut: function(amount) {
            return 0.5 * (1 - Math.sin(Math.PI * (0.5 - amount)));
        }
    };
    public static var Exponential:Dynamic = {
        In: function(amount) {
            return amount === 0 ? 0 : Math.pow(1024, amount - 1);
        },
        Out: function(amount) {
            return amount === 1 ? 1 : 1 - Math.pow(2, -10 * amount);
        },
        InOut: function(amount) {
            if (amount === 0) {
                return 0;
            }
            if (amount === 1) {
                return 1;
            }
            if ((amount *= 2) < 1) {
                return 0.5 * Math.pow(1024, amount - 1);
            }
            return 0.5 * (-Math.pow(2, -10 * (amount - 1)) + 2);
        }
    };
    public static var Circular:Dynamic = {
        In: function(amount) {
            return 1 - Math.sqrt(1 - amount * amount);
        },
        Out: function(amount) {
            return Math.sqrt(1 - --amount * amount);
        },
        InOut: function(amount) {
            if ((amount *= 2) < 1) {
                return -0.5 * (Math.sqrt(1 - amount * amount) - 1);
            }
            return 0.5 * (Math.sqrt(1 - (amount -= 2) * amount) + 1);
        }
    };
    public static var Elastic:Dynamic = {
        In: function(amount) {
            if (amount === 0) {
                return 0;
            }
            if (amount === 1) {
                return 1;
            }
            return -Math.pow(2, 10 * (amount - 1)) * Math.sin((amount - 1.1) * 5 * Math.PI);
        },
        Out: function(amount) {
            if (amount === 0) {
                return 0;
            }
            if (amount === 1) {
                return 1;
            }
            return Math.pow(2, -10 * amount) * Math.sin((amount - 0.1) * 5 * Math.PI) + 1;
        },
        InOut: function(amount) {
            if (amount === 0) {
                return 0;
            }
            if (amount === 1) {
                return 1;
            }
            amount *= 2;
            if (amount < 1) {
                return -0.5 * Math.pow(2, 10 * (amount - 1)) * Math.sin((amount - 1.1) * 5 * Math.PI);
            }
            return 0.5 * Math.pow(2, -10 * (amount - 1)) * Math.sin((amount - 1.1) * 5 * Math.PI) + 1;
        }
    };
    public static var Back:Dynamic = {
        In: function(amount) {
            var s = 1.70158;
            return amount === 1 ? 1 : amount * amount * ((s + 1) * amount - s);
        },
        Out: function(amount) {
            var s = 1.70158;
            return amount === 0 ? 0 : --amount * amount * ((s + 1) * amount + s) + 1;
        },
        InOut: function(amount) {
            var s = 1.70158 * 1.525;
            if ((amount *= 2) < 1) {
                return 0.5 * (amount * amount * ((s + 1) * amount - s));
            }
            return 0.5 * ((amount -= 2) * amount * ((s + 1) * amount + s) + 2);
        }
    };
    public static var Bounce:Dynamic = {
        In: function(amount) {
            return 1 - Easing.Bounce.Out(1 - amount);
        },
        Out: function(amount) {
            if (amount < 1 / 2.75) {
                return 7.5625 * amount * amount;
            }
            else if (amount < 2 / 2.75) {
                return 7.5625 * (amount -= 1.5 / 2.75) * amount + 0.75;
            }
            else if (amount < 2.5 / 2.75) {
                return 7.5625 * (amount -= 2.25 / 2.75) * amount + 0.9375;
            }
            else {
                return 7.5625 * (amount -= 2.625 / 2.75) * amount + 0.984375;
            }
        },
        InOut: function(amount) {
            if (amount < 0.5) {
                return Easing.Bounce.In(amount * 2) * 0.5;
            }
            return Easing.Bounce.Out(amount * 2 - 1) * 0.5 + 0.5;
        }
    };
    public static function generatePow(power:Float = 4):Dynamic {
        power = power < Number.EPSILON ? Number.EPSILON : power;
        power = power > 10000 ? 10000 : power;
        return {
            In: function(amount) {
                return Math.pow(amount, power);
            },
            Out: function(amount) {
                return 1 - Math.pow((1 - amount), power);
            },
            InOut: function(amount) {
                if (amount < 0.5) {
                    return Math.pow((amount * 2), power) / 2;
                }
                return (1 - Math.pow((2 - amount * 2), power)) / 2 + 0.5;
            }
        };
    }
}

class Group {
    private var _tweens:Dynamic;
    private var _tweensAddedDuringUpdate:Dynamic;

    public function new() {
        this._tweens = {};
        this._tweensAddedDuringUpdate = {};
    }

    public function getAll():Array<Dynamic> {
        var keys:Array<String> = Reflect.fields(this._tweens);
        var tweens:Array<Dynamic> = [];
        for (key in keys) {
            tweens.push(this._tweens[key]);
        }
        return tweens;
    }

    public function removeAll():Void {
        this._tweens = {};
    }

    public function add(tween:Dynamic):Void {
        this._tweens[tween.getId()] = tween;
        this._tweensAddedDuringUpdate[tween.getId()] = tween;
    }

    public function remove(tween:Dynamic):Void {
        delete this._tweens[tween.getId()];
        delete this._tweensAddedDuringUpdate[tween.getId()];
    }

    public function update(time:Float = Lib.now(), preserve:Bool = false):Bool {
        var tweenIds:Array<String> = Reflect.fields(this._tweens);
        if (tweenIds.length === 0) {
            return false;
        }
        while (tweenIds.length > 0) {
            this._tweensAddedDuringUpdate = {};
            for (i in 0...tweenIds.length) {
                var tween:Dynamic = this._tweens[tweenIds[i]];
                var autoStart:Bool = !preserve;
                if (tween && tween.update(time, autoStart) === false && !preserve) {
                    delete this._tweens[tweenIds[i]];
                }
            }
            tweenIds = Reflect.fields(this._tweensAddedDuringUpdate);
        }
        return true;
    }
}

class Interpolation {
    public static function Linear(v:Array<Float>, k:Float):Float {
        var m:Int = v.length - 1;
        var f:Float = m * k;
        var i:Int = Std.int(f);
        var fn:Dynamic = Interpolation.Utils.Linear;
        if (k < 0) {
            return fn(v[0], v[1], f);
        }
        if (k > 1) {
            return fn(v[m], v[m - 1], m - f);
        }
        return fn(v[i], v[i + 1 > m ? m : i + 1], f - i);
    }

    public static function Bezier(v:Array<Float>, k:Float):Float {
        var b:Float = 0;
        var n:Int = v.length - 1;
        var pw:Dynamic = Math.pow;
        var bn:Dynamic = Interpolation.Utils.Bernstein;
        for (i in 0...n + 1) {
            b += pw(1 - k, n - i) * pw(k, i) * v[i] * bn(n, i);
        }
        return b;
    }

    public static function CatmullRom(v:Array<Float>, k:Float):Float {
        var m:Int = v.length - 1;
        var f:Float = m * k;
        var i:Int = Std.int(f);
        var fn:Dynamic = Interpolation.Utils.CatmullRom;
        if (v[0] === v[m]) {
            if (k < 0) {
                i = Std.int((f = m * (1 + k)));
            }
            return fn(v[(i - 1 + m) % m], v[i], v[(i + 1) % m], v[(i + 2) % m], f - i);
        }
        else {
            if (k < 0) {
                return v[0] - (fn(v[0], v[0], v[1], v[1], -f) - v[0]);
            }
            if (k > 1) {
                return v[m] - (fn(v[m], v[m], v[m - 1], v[m - 1], f - m) - v[m]);
            }
            return fn(v[i ? i - 1 : 0], v[i], v[m < i + 1 ? m : i + 1], v[m < i + 2 ? m : i + 2], f - i);
        }
    }

    public static class Utils {
        public static function Linear(p0:Float, p1:Float, t:Float):Float {
            return (p1 - p0) * t + p0;
        }

        public static function Bernstein(n:Int, i:Int):Float {
            var fc:Dynamic = Interpolation.Utils.Factorial;
            return fc(n) / fc(i) / fc(n - i);
        }

        public static var Factorial:Dynamic = (function () {
            var a:Array<Float> = [1];
            return function (n:Int) {
                var s:Float = 1;
                if (a[n]) {
                    return a[n];
                }
                for (i in n...1) {
                    s *= i;
                }
                a[n] = s;
                return s;
            };
        })();

        public static function CatmullRom(p0:Float, p1:Float, p2:Float, p3:Float, t:Float):Float {
            var v0:Float = (p2 - p0) * 0.5;
            var v1:Float = (p3 - p1) * 0.5;
            var t2:Float = t * t;
            var t3:Float = t * t2;
            return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1;
        }
    }
}

class Sequence {
    public static var _nextId:Int = 0;

    public static function nextId():Int {
        return Sequence._nextId++;
    }
}

class Tween {
    private var _object:Dynamic;
    private var _group:Group;
    private var _isPaused:Bool;
    private var _pauseStart:Float;
    private var _valuesStart:Dynamic;
    private var _valuesEnd:Dynamic;
    private var _valuesStartRepeat:Dynamic;
    private var _duration:Float;
    private var _isDynamic:Bool;
    private var _initialRepeat:Int;
    private var _repeat:Int;
    private var _yoyo:Bool;
    private var _isPlaying:Bool;
    private var _reversed:Bool;
    private var _delayTime:Float;
    private var _startTime:Float;
    private var _easingFunction:Dynamic;
    private var _interpolationFunction:Dynamic;
    private var _chainedTweens:Array<Dynamic>;
    private var _onStartCallbackFired:Bool;
    private var _onEveryStartCallbackFired:Bool;
    private var _id:Int;
    private var _isChainStopped:Bool;
    private var _propertiesAreSetUp:Bool;
    private var _goToEnd:Bool;

    public function new(_object:Dynamic, _group:Group = null) {
        this._object = _object;
        this._group = _group;
        this._isPaused = false;
        this._pauseStart = 0;
        this._valuesStart = {};
        this._valuesEnd = {};
        this._valuesStartRepeat = {};
        this._duration = 1000;
        this._isDynamic = false;
        this._initialRepeat = 0;
        this._repeat = 0;
        this._yoyo = false;
        this._isPlaying = false;
        this._reversed = false;
        this._delayTime = 0;
        this._startTime = 0;
        this._easingFunction = Easing.Linear.None;
        this._interpolationFunction = Interpolation.Linear;
        this._chainedTweens = [];
        this._onStartCallbackFired = false;
        this._onEveryStartCallbackFired = false;
        this._id = Sequence.nextId();
        this._isChainStopped = false;
        this._propertiesAreSetUp = false;
        this._goToEnd = false;
    }

    public function getId():Int {
        return this._id;
    }

    public function isPlaying():Bool {
        return this._isPlaying;
    }

    public function isPaused():Bool {
        return this._isPaused;
    }

    public function getDuration():Float {
        return this._duration;
    }

    public function to(target:Dynamic, duration:Float = 1000):Dynamic {
        if (this._isPlaying) {
            throw new Error('Can not call Tween.to() while Tween is already started or paused. Stop the Tween first.');
        }
        this._valuesEnd = target;
        this._propertiesAreSetUp = false;
        this._duration = duration < 0 ? 0 : duration;
        return this;
    }

    public function duration(duration:Float = 1000):Dynamic {
        this._duration = duration < 0 ? 0 : duration;
        return this;
    }

    public function dynamic(dynamic:Bool = false):Dynamic {
        this._isDynamic = dynamic;
        return this;
    }

    public function start(time:Float = Lib.now(), overrideStartingValues:Bool = false):Dynamic {
        if (this._isPlaying) {
            return this;
        }
        this._group.add(this);
        this._repeat = this._initialRepeat;
        if (this._reversed) {
            this._reversed = false;
            for (property in this._valuesStartRepeat) {
                this._swapEndStartRepeatValues(property);
                this._valuesStart[property] = this._valuesStartRepeat[property];
            }
        }
        this._isPlaying = true;
        this._isPaused = false;
        this._onStartCallbackFired = false;
        this._onEveryStartCallbackFired = false;
        this._isChainStopped = false;
        this._startTime = time;
        this._startTime += this._delayTime;
        if (!this._propertiesAreSetUp || overrideStartingValues) {
            this._propertiesAreSetUp = true;
            if (!this._isDynamic) {
                var tmp:Dynamic = {};
                for (prop in this._valuesEnd) {
                    tmp[prop] = this._valuesEnd[prop];
                }
                this._valuesEnd = tmp;
            }
            this._setupProperties(this._object, this._valuesStart, this._valuesEnd, this._valuesStartRepeat, overrideStartingValues);
        }
        return this;
    }

    public function startFromCurrentValues(time:Float):Dynamic {
        return this.start(time, true);
    }

    public function _setupProperties(_object:Dynamic, _valuesStart:Dynamic, _valuesEnd:Dynamic, _valuesStartRepeat:Dynamic, overrideStartingValues:Bool):Void {
        for (property in _valuesEnd) {
            var startValue:Dynamic = _object[property];
            var startValueIsArray:Bool = Array.isArray(startValue);
            var propType:String = startValueIsArray ? 'array' : Std.string(Std.typeof(startValue));
            var isInterpolationList:Bool = !startValueIsArray && Array.isArray(_valuesEnd[property]);
            if (propType === 'undefined' || propType === 'function') {
                continue;
            }
            if (isInterpolationList) {
                var endValues:Array<Float> = _valuesEnd[property];
                if (endValues.length === 0) {
                    continue;
                }
                var temp:Array<Float> = [startValue];
                for (i in 0...endValues.length) {
                    var value:Float = this._handleRelativeValue(startValue, endValues[i]);
                    if (isNaN(value)) {
                        isInterpolationList = false;
                        trace('Found invalid interpolation list. Skipping.');
                        break;
                    }
                    temp.push(value);
                }
                if (isInterpolationList) {
                    _valuesEnd[property] = temp;
                }
            }
            if ((propType === 'object' || startValueIsArray) && startValue && !isInterpolationList) {
                _valuesStart[property] = startValueIsArray ? [] : {};
                var nestedObject:Dynamic = startValue;
                for (prop in nestedObject) {
                    _valuesStart[property][prop] = nestedObject[prop];
                }
                this._setupProperties(nestedObject, _valuesStart[property], _valuesEnd[property], _valuesStartRepeat[property], overrideStartingValues);
            }
            else {
                if (Std.typeof(_valuesStart[property]) === 'undefined' || overrideStartingValues) {
                    _valuesStart[property] = startValue;
                }
                if (!startValueIsArray) {
                    _valuesStart[property] *= 1.0;
                }
                if (isInterpolationList) {
                    _valuesStartRepeat[property] = _valuesEnd[property].slice().reverse();
                }
                else {
                    _valuesStartRepeat[property] = _valuesStart[property] || 0;
                }
            }
        }
    }

    public function stop():Dynamic {
        if (!this._isChainStopped) {
            this._isChainStopped = true;
            this.stopChainedTweens();
        }
        if (!this._isPlaying) {
            return this;
        }
        this._group.remove(this);
        this._isPlaying = false;
        this._isPaused = false;
        if (this._onStopCallback) {
            this._onStopCallback(this._object);
        }
        return this;
    }

    public function end():Dynamic {
        this._goToEnd = true;
        this.update(Infinity);
        return this;
    }

    public function pause(time:Float = Lib.now()):Dynamic {
        if (this._isPaused || !this._isPlaying) {
            return this;
        }
        this._isPaused = true;
        this._pauseStart = time;
        this._group.remove(this);
        return this;
    }

    public function resume(time:Float = Lib.now()):Dynamic {
        if (!this._isPaused || !this._isPlaying) {
            return this;
        }
        this._isPaused = false;
        this._startTime += time - this._pauseStart;
        this._pauseStart = 0;
        this._group.add(this);
        return this;
    }

    public function stopChainedTweens():Dynamic {
        for (i in 0...this._chainedTweens.length) {
            this._chainedTweens[i].stop();
        }
        return this;
    }

    public function group(group:Group = null):Dynamic {
        this._group = group;
        return this;
    }

    public function delay(amount:Float = 0):Dynamic {
        this._delayTime = amount;
        return this;
    }

    public function repeat(times:Int = 0):Dynamic {
        this._initialRepeat = times;
        this._repeat = times;
        return this;
    }

    public function repeatDelay(amount:Float):Dynamic {
        this._repeatDelayTime = amount;
        return this;
    }

    public function yoyo(yoyo:Bool = false):Dynamic {
        this._yoyo = yoyo;
        return this;
    }

    public function easing(easingFunction:Dynamic = Easing.Linear.None):Dynamic {
        this._easingFunction = easingFunction;
        return this;
    }

    public function interpolation(interpolationFunction:Dynamic = Interpolation.Linear):Dynamic {
        this._interpolationFunction = interpolationFunction;
        return this;
    }

    public function chain(...tweens:Array<Dynamic>):Dynamic {
        this._chainedTweens = tweens;
        return this;
    }

    public function onStart(callback:Dynamic):Dynamic {
        this._onStartCallback = callback;
        return this;
    }

    public function onEveryStart(callback:Dynamic):Dynamic {
        this._onEveryStartCallback = callback;
        return this;
    }

    public function onUpdate(callback:Dynamic):Dynamic {
        this._onUpdateCallback = callback;
        return this;
    }

    public function onRepeat(callback:Dynamic):Dynamic {
        this._onRepeatCallback = callback;
        return this;
    }

    public function onComplete(callback:Dynamic):Dynamic {
        this._onCompleteCallback = callback;
        return this;
    }

    public function onStop(callback:Dynamic):Dynamic {
        this._onStopCallback = callback;
        return this;
    }

    public function update(time:Float = Lib.now(), autoStart:Bool = true):Bool {
        if (this._isPaused) {
            return true;
        }
        var endTime:Float = this._startTime + this._duration;
        if (!this._goToEnd && !this._isPlaying) {
            if (time > endTime) {
                return false;
            }
            if (autoStart) {
                this.start(time, true);
            }
        }
        this._goToEnd = false;
        if (time < this._startTime) {
            return true;
        }
        if (this._onStartCallbackFired === false) {
            if (this._onStartCallback) {
                this._onStartCallback(this._object);
            }
            this._onStartCallbackFired = true;
        }
        if (this._onEveryStartCallbackFired === false) {
            if (this._onEveryStartCallback) {
                this._onEveryStartCallback(this._object);
            }
            this._onEveryStartCallbackFired = true;
        }
        var elapsedTime:Float = time - this._startTime;
        var durationAndDelay:Float = this._duration + (this._repeatDelayTime !== null ? this._repeatDelayTime : this._delayTime);
        var totalTime:Float = this._duration + this._repeat * durationAndDelay;
        var elapsed:Float = this._calculateElapsedPortion(elapsedTime, durationAndDelay, totalTime);
        var value:Float = this._easingFunction(elapsed);
        var status:String = this._calculateCompletionStatus(elapsedTime, durationAndDelay);
        if (status === 'repeat') {
            this._processRepetition(elapsedTime, durationAndDelay);
        }
        this._updateProperties(this._object, this._valuesStart, this._valuesEnd, value);
        if (status === 'about-to-repeat') {
            this._processRepetition(elapsedTime, durationAndDelay);
        }
        if (this._onUpdateCallback) {
            this._onUpdateCallback(this._object, elapsed);
        }
        if (status === 'repeat' || status === 'about-to-repeat') {
            if (this._onRepeatCallback) {
                this._onRepeatCallback(this._object);
            }
            this._onEveryStartCallbackFired = false;
        }
        else if (status === 'completed') {
            this._isPlaying = false;
            if (this._onCompleteCallback) {
                this._onCompleteCallback(this._object);
            }
            for (i in 0...this._chainedTweens.length) {
                this._chainedTweens[i].start(this._startTime + this._duration, false);
            }
        }
        return status !== 'completed';
    }

    public function _calculateElapsedPortion(elapsedTime:Float, durationAndDelay:Float, totalTime:Float):Float {
        if (this._duration === 0 || elapsedTime > totalTime) {
            return 1;
        }
        var timeIntoCurrentRepeat:Float = elapsedTime % durationAndDelay;
        var portion:Float = Math.min(timeIntoCurrentRepeat / this._duration, 1);
        if (portion === 0 && elapsedTime !== 0 && elapsedTime % this._duration === 0) {
            return 1;
        }
        return portion;
    }

    public function _calculateCompletionStatus(elapsedTime:Float, durationAndDelay:Float):String {
        if (this._duration !== 0 && elapsedTime < this._duration) {
            return 'playing';
        }
        if (this._repeat <= 0) {
            return 'completed';
        }
        if (elapsedTime === this._duration) {
            return 'about-to-repeat';
        }
        return 'repeat';
    }

    public function _processRepetition(elapsedTime:Float, durationAndDelay:Float):Void {
        var completeCount:Int = Math.min(Std.int((elapsedTime - this._duration) / durationAndDelay) + 1, this._repeat);
        if (Std.isFinite(this._repeat)) {
            this._repeat -= completeCount;
        }
        for (property in this._valuesStartRepeat) {
            var valueEnd:Dynamic = this._valuesEnd[property];
            if (!this._yoyo && Std.string(Std.typeof(valueEnd)) === 'string') {
                this._valuesStartRepeat[property] = this._valuesStartRepeat[property] + Std.parseFloat(valueEnd);
            }
            if (this._yoyo) {
                this._swapEndStartRepeatValues(property);
            }
            this._valuesStart[property] = this._valuesStartRepeat[property];
        }
        if (this._yoyo) {
            this._reversed = !this._reversed;
        }
        this._startTime += durationAndDelay * completeCount;
    }

    public function _updateProperties(_object:Dynamic, _valuesStart:Dynamic, _valuesEnd:Dynamic, value:Float):Void {
        for (property in _valuesEnd) {
            if (_valuesStart[property] === undefined) {
                continue;
            }
            var start:Dynamic = _valuesStart[property] || 0;
            var end:Dynamic = _valuesEnd[property];
            var startIsArray:Bool = Array.isArray(_object[property]);
            var endIsArray:Bool = Array.isArray(end);
            var isInterpolationList:Bool = !startIsArray && endIsArray;
            if (isInterpolationList) {
                _object[property] = this._interpolationFunction(end, value);
            }
            else if (Std.typeof(end) === 'object' && end) {
                this._updateProperties(_object[property], start, end, value);
            }
            else {
                end = this._handleRelativeValue(start, end);
                if (Std.typeof(end) === 'number') {
                    _object[property] = start + (end - start) * value;
                }
            }
        }
    }

    public function _handleRelativeValue(start:Dynamic, end:Dynamic):Float {
        if (Std.typeof(end) !== 'string') {
            return Std.parseFloat(end);
        }
        if (end.charAt(0) === '+' || end.charAt(0) === '-') {
            return start + Std.parseFloat(end);
        }
        return Std.parseFloat(end);
    }

    public function _swapEndStartRepeatValues(property:String):Void {
        var tmp:Dynamic = this._valuesStartRepeat[property];
        var endValue:Dynamic = this._valuesEnd[property];
        if (Std.string(Std.typeof(endValue)) === 'string') {
            this._valuesStartRepeat[property] = this._valuesStartRepeat[property] + Std.parseFloat(endValue);
        }
        else {
            this._valuesStartRepeat[property] = this._valuesEnd[property];
        }
        this._valuesEnd[property] = tmp;
    }
}

class TWEEN {
    public static var VERSION:String = '23.1.2';
    public static var mainGroup:Group = new Group();
    public static var nextId:Int = Sequence.nextId;
    public static var now:Float = Lib.now;
    public static var Easing:Dynamic = Easing;
    public static var Group:Dynamic = Group;
    public static var Interpolation:Dynamic = Interpolation;
    public static var Sequence:Dynamic = Sequence;
    public static var Tween:Dynamic = Tween;
    public static function getAll():Array<Dynamic> {
        return mainGroup.getAll();
    }
    public static function removeAll():Void {
        mainGroup.removeAll();
    }
    public static function add(tween:Dynamic):Void {
        mainGroup.add(tween);
    }
    public static function remove(tween:Dynamic):Void {
        mainGroup.remove(tween);
    }
    public static function update(time:Float = Lib.now(), preserve:Bool = false):Bool {
        return mainGroup.update(time, preserve);
    }
}