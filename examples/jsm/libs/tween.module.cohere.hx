package;

import js.Browser;

class Easing {
    public static function Linear(amount:Float):Float {
        return amount;
    }

    public static function QuadraticIn(amount:Float):Float {
        return amount * amount;
    }

    public static function QuadraticOut(amount:Float):Float {
        return amount * (2.0 - amount);
    }

    public static function QuadraticInOut(amount:Float):Float {
        if ((amount *= 2.0) < 1) {
            return 0.5 * amount * amount;
        }
        return -0.5 * (--amount * (amount - 2) - 1);
    }

    public static function CubicIn(amount:Float):Float {
        return amount * amount * amount;
    }

    public static function CubicOut(amount:Float):Float {
        return --amount * amount * amount + 1;
    }

    public static function CubicInOut(amount:Float):Float {
        if ((amount *= 2) < 1) {
            return 0.5 * amount * amount * amount;
        }
        return 0.5 * ((amount -= 2) * amount * amount + 2);
    }

    public static function QuarticIn(amount:Float):Float {
        return amount * amount * amount * amount;
    }

    public static function QuarticOut(amount:Float):Float {
        return 1 - --amount * amount * amount * amount;
    }

    public static function QuarticInOut(amount:Float):Float {
        if ((amount *= 2) < 1) {
            return 0.5 * amount * amount * amount * amount;
        }
        return -0.5 * ((amount -= 2) * amount * amount * amount - 2);
    }

    public static function QuinticIn(amount:Float):Float {
        return amount * amount * amount * amount * amount;
    }

    public static function QuinticOut(amount:Float):Float {
        return --amount * amount * amount * amount * amount + 1;
    }

    public static function QuinticInOut(amount:Float):Float {
        if ((amount *= 2) < 1) {
            return 0.5 * amount * amount * amount * amount * amount;
        }
        return 0.5 * ((amount -= 2) * amount * amount * amount * amount + 2);
    }

    public static function SinusoidalIn(amount:Float):Float {
        return 1 - Math.sin(((1.0 - amount) * Math.PI) / 2);
    }

    public static function SinusoidalOut(amount:Float):Float {
        return Math.sin((amount * Math.PI) / 2);
    }

    public static function SinusoidalInOut(amount:Float):Float {
        return 0.5 * (1 - Math.sin(Math.PI * (0.5 - amount)));
    }

    public static function ExponentialIn(amount:Float):Float {
        return amount === 0 ? 0 : Math.pow(1024, amount - 1);
    }

    public static function ExponentialOut(amount:Float):Float {
        return amount === 1 ? 1 : 1 - Math.pow(2, -10 * amount);
    }

    public static function ExponentialInOut(amount:Float):Float {
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

    public static function CircularIn(amount:Float):Float {
        return 1 - Math.sqrt(1 - amount * amount);
    }

    public static function CircularOut(amount:Float):Float {
        return Math.sqrt(1 --amount * amount);
    }

    public static function CircularInOut(amount:Float):Float {
        if ((amount *= 0.5) < 1) {
            return -0.5 * (Math.sqrt(1 - amount * amount) - 1);
        }
        return 0.5 * (Math.sqrt(1 - (amount -= 2) * amount) + 1);
    }

    public static function ElasticIn(amount:Float):Float {
        if (amount === 0) {
            return 0;
        }
        if (amount === 1) {
            return 1;
        }
        return -Math.pow(2, 10 * (amount - 1)) * Math.sin((amount - 1.1) * 5 * Math.PI);
    }

    public static function ElasticOut(amount:Float):Float {
        if (amount === 0) {
            return 0;
        }
        if (amount === 1) {
            return 1;
        }
        return Math.pow(2, -10 * amount) * Math.sin((amount - 0.1) * 5 * Math.PI) + 1;
    }

    public static function ElasticInOut(amount:Float):Float {
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

    public static function BackIn(amount:Float):Float {
        var s = 1.70158;
        return amount === 1 ? 1 : amount * amount * ((s + 1) * amount - s);
    }

    public static function BackOut(amount:Float):Float {
        var s = 1.70158;
        return amount === 0 ? 0 : --amount * amount * ((s + 1) * amount + s) + 1;
    }

    public static function BackInOut(amount:Float):Float {
        var s = 1.70158 * 1.525;
        if ((amount *= 2) < 1) {
            return 0.5 * (amount * amount * ((s + 1) * amount - s));
        }
        return 0.5 * ((amount -= 2) * amount * ((s + 1) * amount + s) + 2);
    }

    public static function BounceIn(amount:Float):Float {
        return 1 - Easing.BounceOut(1 - amount);
    }

    public static function BounceOut(amount:Float):Float {
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
    }

    public static function BounceInOut(amount:Float):Float {
        if (amount < 0.5) {
            return Easing.BounceIn(amount * 2) * 0.5;
        }
        return Easing.BounceOut(amount * 2 - 1) * 0.5 + 0.5;
    }

    public static function generatePow(power:Float = 4):Dynamic {
        power = power < Number.EPSILON ? Number.EPSILON : power;
        power = power > 10000 ? 10000 : power;
        return {
            in: function(amount:Float):Float {
                return Math.pow(amount, power);
            },
            out: function(amount:Float):Float {
                return 1 - Math.pow((1 - amount), power);
            },
            inOut: function(amount:Float):Float {
                if (amount < 0.5) {
                    return Math.pow((amount * 2), power) / 2;
                }
                return (1 - Math.pow((2 - amount * 2), power)) / 2 + 0.5;
            }
        };
    }
}

class Group {
    private var _tweens:Map<Tween, Bool>;
    private var _tweensAddedDuringUpdate:Map<Tween, Bool>;

    public function new() {
        this._tweens = new Map();
        this._tweensAddedDuringUpdate = new Map();
    }

    public function getAll():Array<Tween> {
        var tweens = [];
        for (tween in this._tweens.keys()) {
            tweens.push(tween);
        }
        return tweens;
    }

    public function removeAll() {
        this._tweens = new Map();
    }

    public function add(tween:Tween) {
        this._tweens.set(tween, true);
        this._tweensAddedDuringUpdate.set(tween, true);
    }

    public function remove(tween:Tween) {
        this._tweens.remove(tween);
        this._tweensAddedDuringUpdate.remove(tween);
    }

    public function update(time:Float = js.Browser.performance.now(), preserve:Bool = false):Bool {
        var tweenIds = this._tweens.keys();
        if (tweenIds.length == 0) {
            return false;
        }

        while (tweenIds.length > 0) {
            this._tweensAddedDuringUpdate = new Map();
            for (i in 0...tweenIds.length) {
                var tween = tweenIds[i];
                var autoStart = !preserve;
                if (tween && tween.update(time, autoStart) == false && !preserve) {
                    this._tweens.remove(tween);
                }
            }
            tweenIds = this._tweensAddedDuringUpdate.keys();
        }
        return true;
    }
}

class Interpolation {
    public static function Linear(v:Array<Float>, k:Float):Float {
        var m = v.length - 1;
        var f = m * k;
        var i = Std.int(f);
        if (k < 0) {
            return Std.int(v[0] + (v[1] - v[0]) * f);
        }
        if (k > 1) {
            return Std.int(v[m] + (v[m - 1] - v[m]) * (m - f));
        }
        return Std.int(v[i] + (v[i + 1 > m ? m : i + 1] - v[i]) * (f - i));
    }

    public static function Bezier(v:Array<Float>, k:Float):Float {
        var b = 0;
        var n = v.length - 1;
        var pw = Math.pow;
        var bn = Interpolation.Utils.Bernstein;
        for (i in 0...n) {
            b += pw(1 - k, n - i) * pw(k, i) * v[i] * bn(n, i);
        }
        return b;
    }

    public static function CatmullRom(v:Array<Float>, k:Float):Float {
        var m = v.length - 1;
        var f = m * k;
        var i = Std.int(f);
        if (v[0] == v[m]) {
            if (k < 0) {
                i = Std.int((f = m * (1 + k)));
            }
            return Std.int(v[(i - 1 + m) % m] + (v[i] - v[i - 1 + m]) * (f - i) + (v[(i + 1) % m] - v[i]) * (f - i) ** 2 + (v[(i + 2) % m] - v[(i + 1) % m]) * (f - i) ** 3);
        }
        else {
            if (k < 0) {
                return v[0] - (Std.int(v[0] + (v[0] - v[1]) * (1 - f)) - v[0]);
            }
            if (k > 1) {
                return v[m] - (Std.int(v[m] + (v[m] - v[m - 1]) * (f - m)) - v[m]);
            }
            return Std.int(v[i ? i - 1 : 0] + (v[i] - v[i ? i - 1 : 0]) * (f - i) + (v[m < i + 1 ? m : i + 1] - v[i]) * (f - i) ** 2 + (v[m < i + 2 ? m : i + 2] - v[m < i + 1 ? m : i + 1]) * (f - i) ** 3);
        }
    }

    public static class Utils {
        public static function Linear(p0:Float, p1:Float, t:Float):Float {
            return (p1 - p0) * t + p0;
        }

        public static function Bernstein(n:Int, i:Int):Float {
            var fc = Interpolation.Utils.Factorial;
            return fc(n) / fc(i) / fc(n - i);
        }

        public static function Factorial(n:Int):Float {
            var a = [1];
            return function(n:Int):Float {
                var s = 1;
                if (a.exists(n)) {
                    return a[n];
                }
                for (i in n...1) {
                    s *= i;
                }
                a[n] = s;
                return s;
            }
        }

        public static function CatmullRom(p0:Float, p1:Float, p2:Float, p3:Float, t:Float):Float {
            var v0 = (p2 - p0) / 2;
            var v1 = (p3 - p1) / 2;
            var t2 = t * t;
            var t3 = t * t2;
            return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1;
        }
    }
}

class Sequence {
    private static var _nextId:Int = 0;

    public static function nextId():Int {
        return _nextId++;
    }
}

class Tween {
    private var _object:Dynamic;
    private var _group:Group;
    private var _isPaused:Bool;
    private var _pauseStart:Float;
    private var _valuesStart:Map<String, Float>;
    private var _valuesEnd:Map<String, Float>;
    private var _valuesStartRepeat:Map<String, Float>;
    private var _duration:Float;
    private var _isDynamic:Bool;
    private var _initialRepeat:Int;
    private var _repeat:Int;
    private var _yoyo:Bool;
    private var _isPlaying:Bool;
    private var _reversed:Bool;
    private var _delayTime:Float;
    private var _startTime:Float;
    private var _easingFunction:Dynamic -> Float;
    private var _interpolationFunction:Dynamic -> Float;
    private var _chainedTweens:Array<Tween>;
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
        this._valuesStart = new Map();
        this._valuesEnd = new Map();
        this._valuesStartRepeat = new Map();
        this._duration = 1000;
        this._isDynamic = false;
        this._initialRepeat = 0;
        this._repeat = 0;
        this._yoyo = false;
        this._isPlaying = false;
        this._reversed = false;
        this._delayTime = 0;
        this._startTime = 0;
        this._easingFunction = Easing.Linear;
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
        return
    public function isPaused():Bool {
        return this._isPaused;
    }

    public function getDuration():Float {
        return this._duration;
    }

    public function to(target:Dynamic, duration:Float = 1000):Tween {
        if (this._isPlaying) {
            throw new Error('Can not call Tween.to() while Tween is already started or paused. Stop the Tween first.');
        }
        this._valuesEnd = target;
        this._propertiesAreSetUp = false;
        this._duration = duration < 0 ? 0 : duration;
        return this;
    }

    public function duration(duration:Float = 1000):Tween {
        this._duration = duration < 0 ? 0 : duration;
        return this;
    }

    public function dynamic(dynamic:Bool = false):Tween {
        this._isDynamic = dynamic;
        return this;
    }

    public function start(time:Float = js.Browser.performance.now(), overrideStartingValues:Bool = false):Tween {
        if (this._isPlaying) {
            return this;
        }
        if (this._group) {
            this._group.add(this);
        }
        this._repeat = this._initialRepeat;
        if (this._reversed) {
            this._reversed = false;
            for (property in this._valuesStartRepeat) {
                this._swapEndStartRepeatValues(property);
                this._valuesStart.set(property, this._valuesStartRepeat.get(property));
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
                var tmp = {};
                for (property in this._valuesEnd) {
                    tmp[property] = this._valuesEnd.get(property);
                }
                this._valuesEnd = tmp;
            }
            this._setupProperties(this._object, this._valuesStart, this._valuesEnd, this._valuesStartRepeat, overrideStartingValues);
        }
        return this;
    }

    public function startFromCurrentValues(time:Float):Tween {
        return this.start(time, true);
    }

    private function _setupProperties(_object:Dynamic, _valuesStart:Map<String, Float>, _valuesEnd:Map<String, Float>, _valuesStartRepeat:Map<String, Float>, overrideStartingValues:Bool) {
        for (property in _valuesEnd) {
            var startValue = Reflect.field(_object, property);
            var startValueIsArray = Type.enumIndex(startValue) != null;
            var propType = startValueIsArray ? 'array' : Type.enumIndex(startValue);
            var isInterpolationList = !startValueIsArray && Type.enumIndex(_valuesEnd.get(property)) != null;
            if (propType == 'undefined' || propType == 'function') {
                continue;
            }
            if (isInterpolationList) {
                var endValues = _valuesEnd.get(property);
                if (endValues.length == 0) {
                    continue;
                }
                var temp = [startValue];
                for (i in 0...endValues.length) {
                    var value = this._handleRelativeValue(startValue, endValues[i]);
                    if (isNaN(value)) {
                        isInterpolationList = false;
                        trace('Found invalid interpolation list. Skipping.');
                        break;
                    }
                    temp.push(value);
                }
                if (isInterpolationList) {
                    _valuesEnd.set(property, temp);
                }
            }
            if (Type.enumIndex(startValue) != null || Type.enumIndex(_valuesEnd.get(property)) != null) {
                _valuesStart.set(property, startValue);
                if (!startValueIsArray) {
                    _valuesStart.set(property, Std.parseFloat(_valuesStart.get(property)));
                }
                if (isInterpolationList) {
                    _valuesStartRepeat.set(property, _valuesEnd.get(property).slice().reverse());
                }
                else {
                    _valuesStartRepeat.set(property, _valuesStart.get(property) || 0);
                }
            }
            else {
                _valuesStart.set(property, startValue);
                if (!startValueIsArray) {
                    var nestedObject = startValue;
                    for (prop in nestedObject) {
                        _valuesStart.set(property + '.' + prop, Reflect.field(nestedObject, prop));
                    }
                    _valuesStartRepeat.set(property, startValueIsArray ? [] : {});
                    var endValues = _valuesEnd.get(property);
                    if (!this._isDynamic) {
                        var tmp = {};
                        for (prop in endValues) {
                            tmp[prop] = endValues[prop];
                        }
                        _valuesEnd.set(property, endValues = tmp);
                    }
                    this._setupProperties(nestedObject, _valuesStart.get(property), endValues, _valuesStartRepeat.get(property), overrideStartingValues);
                }
            }
        }
    }

    public function stop():Tween {
        if (!this._isChainStopped) {
            this._isChainStopped = true;
            this.stopChainedTweens();
        }
        if (!this._isPlaying) {
            return this;
        }
        if (this._group) {
            this._group.remove(this);
        }
        this._isPlaying = false;
        this._isPaused = false;
        if (this._onStopCallback) {
            this._onStopCallback(this._object);
        }
        return this;
    }

    public function end():Tween {
        this._goToEnd = true;
        this.update(Infinity);
        return this;
    }

    public function pause(time:Float = js.Browser.performance.now()):Tween {
        if (this._isPaused || !this._isPlaying) {
            return this;
        }
        this._isPaused = true;
        this._pauseStart = time;
        if (this._group) {
            this._group.remove(this);
        }
        return this;
    }

    public function resume(time:Float = js.Browser.performance.now()):Tween {
        if (!this._isPaused || !this._isPlaying) {
            return this;
        }
        this._isPaused = false;
        this._startTime += time - this._pauseStart;
        this._pauseStart = 0;
        if (this._group) {
            this._group.add(this);
        }
        return this;
    }

    public function stopChainedTweens():Tween {
        for (i in 0...this._chainedTweens.length) {
            this._chainedTweens[i].stop();
        }
        return this;
    }

    public function group(group:Group):Tween {
        this._group = group;
        return this;
    }

    public function delay(amount:Float):Tween {
        this._delayTime = amount;
        return this;
    }

    public function repeat(times:Int):Tween {
        this._initialRepeat = times;
        this._repeat = times;
        return this;
    }

    public function repeatDelay(amount:Float):Tween {
        this._repeatDelayTime = amount;
        return this;
    }

    public function yoyo(yoyo:Bool):Tween {
        this._yoyo = yoyo;
        return this;
    }

    public function easing(easingFunction:Dynamic -> Float):Tween {
        this._easingFunction = easingFunction;
        return this;
    }

    public function interpolation(interpolationFunction:Dynamic -> Float):Tween {
        this._interpolationFunction = interpolationFunction;
        return this;
    }

    public function chain(...tweens:Array<Tween>):Tween {
        this._chainedTweens = tweens;
        return this;
    }

    public function onStart(callback:Dynamic -> Void):Tween {
        this._onStartCallback = callback;
        return this;
    }

    public function onEveryStart(callback:Dynamic -> Void):Tween {
        this._onEveryStartCallback = callback;
        return this;
    }

    public function onUpdate(callback:Dynamic -> Float -> Void):Tween {
        this._onUpdateCallback = callback;
        return this;
    }

    public function onRepeat(callback:Dynamic -> Void):Tween {
        this._onRepeatCallback = callback;
        return this;
    }

    public function onComplete(callback:Dynamic -> Void):Tween {
        this._onCompleteCallback = callback;
        return this;
    }

    public function onStop(callback:Dynamic -> Void):Tween {
        this._onStopCallback = callback;
        return this;
    }

    public function update(time:Float = js.Browser.performance.now(), autoStart:Bool = true):Bool {
        if (this._isPaused) {
            return true;
        }
        var endTime = this._startTime + this._duration;
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
        if (!this._onStartCallbackFired) {
            if (this._onStartCallback) {
                this._onStartCallback(this._object);
            }
            this._onStartCallbackFired = true;
        }
        if (!this._onEveryStartCallbackFired) {
            if (this._onEveryStartCallback) {
                this._onEveryStartCallback(this._object);
            }
            this._onEveryStartCallbackFired = true;
        }
        var elapsedTime = time - this._startTime;
        var durationAndDelay = this._duration + (this._repeatDelayTime != null ? this._repeatDelayTime : this._delayTime);
        var totalTime = this._duration + this._repeat * durationAndDelay;
        var elapsed = this._calculateElapsedPortion(elapsedTime, durationAndDelay, totalTime);
        var value = this._easingFunction(elapsed);
        var status = this._calculateCompletionStatus(elapsedTime, durationAndDelay);
        if (status == 'repeat') {
            this._processRepetition(elapsedTime, durationAndDelay);
        }
        this._updateProperties(this._object, this._valuesStart, this._valuesEnd, value);
        if (status == 'about-to-repeat') {
            this._processRepetition(elapsedTime, durationAndDelay);
        }
        if (this._onUpdateCallback) {
            this._onUpdateCallback(this._object, elapsed);
        }
        if (status == 'repeat' || status == 'about-to-repeat') {
            if (this._onRepeatCallback) {
                this._onRepeatCallback(this._object);
            }
            this._onEveryStartCallbackFired = false;
        }
        else if (status == 'completed') {
            this._isPlaying = false;
            if (this._onCompleteCallback) {
                this._onCompleteCallback(this._object);
            }
            for (i in 0...this._chainedTweens.length) {
                this._chainedTweens[i].start(this._startTime + this._duration, false);
            }
        }
        return status != 'completed';
    }

    private function _calculateElapsedPortion(elapsedTime:Float, durationAndDelay:Float, totalTime:Float):Float {
        if (this._duration == 0 || elapsedTime > totalTime) {
            return 1;
        }
        var timeIntoCurrentRepeat = elapsedTime % durationAndDelay;
        var portion = Math.min(timeIntoCurrentRepeat / this._duration, 1);
        if (portion == 0 && elapsedTime != 0 && elapsedTime % this._duration == 0) {
            return 1;
        }
        return portion;
    }

    private function _calculateCompletionStatus(elapsedTime:Float, durationAndDelay:Float):String {
        if (this._duration != 0 && elapsedTime < this._duration) {
            return 'playing';
        }
        if (this._repeat <= 0) {
            return 'completed';
        }
        if (elapsedTime == this._duration) {
            return 'about-to-repeat';
        }
        return 'repeat';
    }

    private function _processRepetition(elapsedTime:Float, durationAndDelay:Float) {
        var completeCount = Std.int(Math.min(Math.floor((elapsedTime - this._duration) / durationAndDelay) + 1, this._repeat));
        if (isFinite(this._repeat)) {
            this._repeat -= completeCount;
        }
        for (property in this._valuesStartRepeat) {
            var valueEnd = this._valuesEnd.get(property);
            if (!this._yoyo && Type.enumIndex(valueEnd) != null) {
                this._valuesStartRepeat.set(property, Std.parseFloat(this._valuesStartRepeat.get(property)) + Std.parseFloat(valueEnd));
            }
            if (this._yoyo) {
                this._swapEndStartRepeatValues(property);
            }
            this._valuesStart.set(property, this._valuesStartRepeat.get(property));
        }
        if (this._yoyo) {
            this._reversed = !this._reversed;
        }
        this._startTime += durationAndDelay * completeCount;
    }

    private function _updateProperties(_object:Dynamic, _valuesStart:Map<String, Float>, _valuesEnd:Map<String, Float>, value:Float) {
        for (property in _valuesEnd) {
            if (!_valuesStart.exists(property)) {
                continue;
            }
            var start = _valuesStart.get(property);
            var end = _valuesEnd.get(property);
            var startIsArray = Type.enumIndex(Reflect.field(_object, property)) != null;
            var endIsArray = Type.enumIndex(end) != null;
            var isInterpolationList = !startIsArray && endIsArray;
            if (isInterpolationList) {
                Reflect.setField(_object, property, this._interpolationFunction(end, value));
            }
            else if (Type.enumIndex(end) != null && Type.enumIndex(end) == Type.OBJECT && end && !isInterpolationList) {
                this._updateProperties(Reflect.field(_object, property), start, end, value);
            }
            else {
                end = this._handleRelativeValue(start, end);
                if (Type.enumIndex(end) == Type.FLOAT) {
                    Reflect.setField(_object, property, start + (end - start) * value);
                }
            }
        }
    }

    private function _handleRelativeValue(start:Float, end:Dynamic):Float {
        if (Type.enumIndex(end) == Type.STRING) {
            if (end.charAt(0) == '+' || end.charAt(0) == '-') {
                return start + Std.parseFloat(end);
            }
            return Std.parseFloat(end);
        }
        return end;
    }

    private function _swapEndStartRepeatValues(property:String) {
        var tmp = this._valuesStartRepeat.get(property);
        var endValue = this._valuesEnd.get(property);
        if (Type.enumIndex(endValue) == Type.STRING) {
            this._valuesStartRepeat.set(property, Std.parseFloat(this._valuesStartRepeat.get(property)) + Std.parseFloat(endValue));
        }
        else {
            this._valuesStartRepeat.set(property, this._valuesEnd.get(property));
        }
        this._valuesEnd.set(property, tmp);
    }
}

class Main {
    static function main() {
        var VERSION = '23.1.2';

        var TWEEN = new Group();
        var nextId = Sequence.nextId;

        class Exports {
            public static var Easing:Dynamic;
            public static var Group:Dynamic;
            public static var Interpolation:Dynamic;
            public static var Sequence:Dynamic;
            public static var Tween:Dynamic;
            public static var VERSION:Dynamic;
            public static function getAll():Dynamic {
                return TWEEN.getAll();
            }
            public static function removeAll():Dynamic {
                return TWEEN.removeAll();
            }
            public static function add(tween:Tween):Void {
                TWEEN.add(tween);
            }
            public static function remove(tween:Tween):Void {
                TWEEN.remove(tween);
            }
            public static function update(time:Float = js.Browser.performance.now()):Void {
                TWEEN.update(time);
            }
        }

        Exports.Easing = Easing;
        Exports.Group = Group;
        Exports.Interpolation = Interpolation;
        Exports.Sequence = Sequence;
        Exports.Tween = Tween;
        Exports.VERSION = VERSION;

        #if js
        js.Browser.window.exports = Exports;
        #end
    }
}