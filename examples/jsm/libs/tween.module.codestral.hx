import js.Math;
import js.html.performance;

class Easing {
    static public var Linear:Dynamic = {
        None: function(amount:Float):Float {
            return amount;
        },
        In: function(amount:Float):Float {
            return amount;
        },
        Out: function(amount:Float):Float {
            return amount;
        },
        InOut: function(amount:Float):Float {
            return amount;
        },
    };

    static public var Quadratic:Dynamic = {
        In: function(amount:Float):Float {
            return amount * amount;
        },
        Out: function(amount:Float):Float {
            return amount * (2 - amount);
        },
        InOut: function(amount:Float):Float {
            if ((amount *= 2) < 1) {
                return 0.5 * amount * amount;
            }
            return -0.5 * (--amount * (amount - 2) - 1);
        },
    };

    static public var Cubic:Dynamic = {
        In: function(amount:Float):Float {
            return amount * amount * amount;
        },
        Out: function(amount:Float):Float {
            return --amount * amount * amount + 1;
        },
        InOut: function(amount:Float):Float {
            if ((amount *= 2) < 1) {
                return 0.5 * amount * amount * amount;
            }
            return 0.5 * ((amount -= 2) * amount * amount + 2);
        },
    };

    static public var Quartic:Dynamic = {
        In: function(amount:Float):Float {
            return amount * amount * amount * amount;
        },
        Out: function(amount:Float):Float {
            return 1 - --amount * amount * amount * amount;
        },
        InOut: function(amount:Float):Float {
            if ((amount *= 2) < 1) {
                return 0.5 * amount * amount * amount * amount;
            }
            return -0.5 * ((amount -= 2) * amount * amount * amount - 2);
        },
    };

    static public var Quintic:Dynamic = {
        In: function(amount:Float):Float {
            return amount * amount * amount * amount * amount;
        },
        Out: function(amount:Float):Float {
            return --amount * amount * amount * amount * amount + 1;
        },
        InOut: function(amount:Float):Float {
            if ((amount *= 2) < 1) {
                return 0.5 * amount * amount * amount * amount * amount;
            }
            return 0.5 * ((amount -= 2) * amount * amount * amount * amount + 2);
        },
    };

    static public var Sinusoidal:Dynamic = {
        In: function(amount:Float):Float {
            return 1 - Math.sin(((1.0 - amount) * Math.PI) / 2);
        },
        Out: function(amount:Float):Float {
            return Math.sin((amount * Math.PI) / 2);
        },
        InOut: function(amount:Float):Float {
            return 0.5 * (1 - Math.sin(Math.PI * (0.5 - amount)));
        },
    };

    static public var Exponential:Dynamic = {
        In: function(amount:Float):Float {
            return amount === 0 ? 0 : Math.pow(1024, amount - 1);
        },
        Out: function(amount:Float):Float {
            return amount === 1 ? 1 : 1 - Math.pow(2, -10 * amount);
        },
        InOut: function(amount:Float):Float {
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
        },
    };

    static public var Circular:Dynamic = {
        In: function(amount:Float):Float {
            return 1 - Math.sqrt(1 - amount * amount);
        },
        Out: function(amount:Float):Float {
            return Math.sqrt(1 - --amount * amount);
        },
        InOut: function(amount:Float):Float {
            if ((amount *= 2) < 1) {
                return -0.5 * (Math.sqrt(1 - amount * amount) - 1);
            }
            return 0.5 * (Math.sqrt(1 - (amount -= 2) * amount) + 1);
        },
    };

    static public var Elastic:Dynamic = {
        In: function(amount:Float):Float {
            if (amount === 0) {
                return 0;
            }
            if (amount === 1) {
                return 1;
            }
            return -Math.pow(2, 10 * (amount - 1)) * Math.sin((amount - 1.1) * 5 * Math.PI);
        },
        Out: function(amount:Float):Float {
            if (amount === 0) {
                return 0;
            }
            if (amount === 1) {
                return 1;
            }
            return Math.pow(2, -10 * amount) * Math.sin((amount - 0.1) * 5 * Math.PI) + 1;
        },
        InOut: function(amount:Float):Float {
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
        },
    };

    static public var Back:Dynamic = {
        In: function(amount:Float):Float {
            var s:Float = 1.70158;
            return amount === 1 ? 1 : amount * amount * ((s + 1) * amount - s);
        },
        Out: function(amount:Float):Float {
            var s:Float = 1.70158;
            return amount === 0 ? 0 : --amount * amount * ((s + 1) * amount + s) + 1;
        },
        InOut: function(amount:Float):Float {
            var s:Float = 1.70158 * 1.525;
            if ((amount *= 2) < 1) {
                return 0.5 * (amount * amount * ((s + 1) * amount - s));
            }
            return 0.5 * ((amount -= 2) * amount * ((s + 1) * amount + s) + 2);
        },
    };

    static public var Bounce:Dynamic = {
        In: function(amount:Float):Float {
            return 1 - Easing.Bounce.Out(1 - amount);
        },
        Out: function(amount:Float):Float {
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
        InOut: function(amount:Float):Float {
            if (amount < 0.5) {
                return Easing.Bounce.In(amount * 2) * 0.5;
            }
            return Easing.Bounce.Out(amount * 2 - 1) * 0.5 + 0.5;
        },
    };

    static public function generatePow(power:Float = 4):Dynamic {
        if (power === js.Browser.NaN) {
            power = 4;
        }
        power = power < Number.EPSILON ? Number.EPSILON : power;
        power = power > 10000 ? 10000 : power;
        return {
            In: function(amount:Float):Float {
                return Math.pow(amount, power);
            },
            Out: function(amount:Float):Float {
                return 1 - Math.pow((1 - amount), power);
            },
            InOut: function(amount:Float):Float {
                if (amount < 0.5) {
                    return Math.pow((amount * 2), power) / 2;
                }
                return (1 - Math.pow((2 - amount * 2), power)) / 2 + 0.5;
            },
        };
    }
}

class TweenUtils {
    static public function now():Float {
        return performance.now();
    }
}

class Group {
    private var _tweens:haxe.ds.StringMap<Tween> = new haxe.ds.StringMap<Tween>();
    private var _tweensAddedDuringUpdate:haxe.ds.StringMap<Tween> = new haxe.ds.StringMap<Tween>();

    public function new() {
    }

    public function getAll():Array<Tween> {
        var tweens:Array<Tween> = [];
        for (tweenId in _tweens.keys()) {
            tweens.push(_tweens.get(tweenId));
        }
        return tweens;
    }

    public function removeAll():Void {
        _tweens = new haxe.ds.StringMap<Tween>();
    }

    public function add(tween:Tween):Void {
        _tweens.set(tween.getId(), tween);
        _tweensAddedDuringUpdate.set(tween.getId(), tween);
    }

    public function remove(tween:Tween):Void {
        _tweens.remove(tween.getId());
        _tweensAddedDuringUpdate.remove(tween.getId());
    }

    public function update(time:Float = TweenUtils.now(), preserve:Bool = false):Bool {
        if (time === js.Browser.NaN) {
            time = TweenUtils.now();
        }
        if (preserve === js.Browser.NaN) {
            preserve = false;
        }
        var tweenIds:Array<String> = _tweens.keys();
        if (tweenIds.length === 0) {
            return false;
        }

        while (tweenIds.length > 0) {
            _tweensAddedDuringUpdate = new haxe.ds.StringMap<Tween>();
            for (i in 0...tweenIds.length) {
                var tween:Tween = _tweens.get(tweenIds[i]);
                var autoStart:Bool = !preserve;
                if (tween != null && tween.update(time, autoStart) === false && !preserve) {
                    _tweens.remove(tweenIds[i]);
                }
            }
            tweenIds = _tweensAddedDuringUpdate.keys();
        }
        return true;
    }
}

class Interpolation {
    static public function Linear(v:Array<Float>, k:Float):Float {
        var m:Int = v.length - 1;
        var f:Float = m * k;
        var i:Int = Math.floor(f);
        var fn:Function = Interpolation.Utils.Linear;
        if (k < 0) {
            return fn(v[0], v[1], f);
        }
        if (k > 1) {
            return fn(v[m], v[m - 1], m - f);
        }
        return fn(v[i], v[i + 1 > m ? m : i + 1], f - i);
    }

    static public function Bezier(v:Array<Float>, k:Float):Float {
        var b:Float = 0;
        var n:Int = v.length - 1;
        var pw:Function = Math.pow;
        var bn:Function = Interpolation.Utils.Bernstein;
        for (var i:Int = 0; i <= n; i++) {
            b += pw(1 - k, n - i) * pw(k, i) * v[i] * bn(n, i);
        }
        return b;
    }

    static public function CatmullRom(v:Array<Float>, k:Float):Float {
        var m:Int = v.length - 1;
        var f:Float = m * k;
        var i:Int = Math.floor(f);
        var fn:Function = Interpolation.Utils.CatmullRom;
        if (v[0] === v[m]) {
            if (k < 0) {
                i = Math.floor((f = m * (1 + k)));
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

    static public var Utils:Dynamic = {
        Linear: function(p0:Float, p1:Float, t:Float):Float {
            return (p1 - p0) * t + p0;
        },
        Bernstein: function(n:Int, i:Int):Float {
            var fc:Function = Interpolation.Utils.Factorial;
            return fc(n) / fc(i) / fc(n - i);
        },
        Factorial: (function() {
            var a:Array<Float> = [1];
            return function(n:Int):Float {
                var s:Float = 1;
                if (a[n] != null) {
                    return a[n];
                }
                for (var i:Int = n; i > 1; i--) {
                    s *= i;
                }
                a[n] = s;
                return s;
            };
        })(),
        CatmullRom: function(p0:Float, p1:Float, p2:Float, p3:Float, t:Float):Float {
            var v0:Float = (p2 - p0) * 0.5;
            var v1:Float = (p3 - p1) * 0.5;
            var t2:Float = t * t;
            var t3:Float = t * t2;
            return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1;
        },
    };
}

class Sequence {
    private static var _nextId:Int = 0;

    static public function nextId():Int {
        return _nextId++;
    }
}

var mainGroup:Group = new Group();

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
    private var _easingFunction:Function;
    private var _interpolationFunction:Function;
    private var _chainedTweens:Array<Tween>;
    private var _onStartCallbackFired:Bool;
    private var _onEveryStartCallbackFired:Bool;
    private var _id:Int;
    private var _isChainStopped:Bool;
    private var _propertiesAreSetUp:Bool;
    private var _goToEnd:Bool;

    public function new(_object:Dynamic, _group:Group = mainGroup) {
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

    public function to(target:Dynamic, duration:Float = 1000):Tween {
        if (this._isPlaying) {
            throw new js.Error("Can not call Tween.to() while Tween is already started or paused. Stop the Tween first.");
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

    public function start(time:Float = TweenUtils.now(), overrideStartingValues:Bool = false):Tween {
        if (time === js.Browser.NaN) {
            time = TweenUtils.now();
        }
        if (overrideStartingValues === js.Browser.NaN) {
            overrideStartingValues = false;
        }
        if (this._isPlaying) {
            return this;
        }
        if (this._group != null) {
            this._group.add(this);
        }
        this._repeat = this._initialRepeat;
        if (this._reversed) {
            this._reversed = false;
            for (property in Reflect.fields(this._valuesStartRepeat)) {
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
                this._valuesEnd = haxe.lang.Runtime.clone(this._valuesEnd);
            }
            this._setupProperties(this._object, this._valuesStart, this._valuesEnd, this._valuesStartRepeat, overrideStartingValues);
        }
        return this;
    }

    // Rest of the Tween class methods...
}