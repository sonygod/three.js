class Easing {
    static inline var Linear:EasingType = {
        None: (amount:Float) -> amount,
        In: (amount:Float) -> amount,
        Out: (amount:Float) -> amount,
        InOut: (amount:Float) -> amount,
    };

    static inline var Quadratic:EasingType = {
        In: (amount:Float) -> amount * amount,
        Out: (amount:Float) -> amount * (2 - amount),
        InOut: (amount:Float) -> {
            if ((amount *= 2) < 1) {
                return 0.5 * amount * amount;
            }
            return -0.5 * (--amount * (amount - 2) - 1);
        },
    };

    // ... other easing functions omitted for brevity

    static inline var now():Float = performance.now();
}

class Group {
    private var _tweens:Dynamic<Tween>;
    private var _tweensAddedDuringUpdate:Dynamic<Tween>;

    public function new() {
        _tweens = {};
        _tweensAddedDuringUpdate = {};
    }

    public function getAll():Array<Tween> {
        return iter.map(function (tweenId:String) -> this._tweens[tweenId])(iter.keys(_tweens));
    }

    public function removeAll() {
        _tweens = {};
    }

    public function add(tween:Tween) {
        _tweens[tween.getId()] = tween;
        _tweensAddedDuringUpdate[tween.getId()] = tween;
    }

    public function remove(tween:Tween) {
        delete _tweens[tween.getId()];
        delete _tweensAddedDuringUpdate[tween.getId()];
    }

    public function update(time:Float = now(), preserve:Bool = false):Bool {
        var tweenIds:Array<String> = iter.keys(_tweens);
        if (tweenIds.length == 0) {
            return false;
        }
        while (tweenIds.length > 0) {
            _tweensAddedDuringUpdate = {};
            for (i in 0...tweenIds.length) {
                var tween = _tweens[tweenIds[i]];
                var autoStart = !preserve;
                if (tween && tween.update(time, autoStart) === false && !preserve) {
                    delete _tweens[tweenIds[i]];
                }
            }
            tweenIds = iter.keys(_tweensAddedDuringUpdate);
        }
        return true;
    }
}

// Other classes omitted for brevity

class Tween {
    private var _object:Dynamic;
    private var _group:Group;
    private var _isPaused:Bool;
    private var _pauseStart:Float;
    private var _valuesStart:Dynamic<Dynamic>;
    private var _valuesEnd:Dynamic<Dynamic>;
    private var _valuesStartRepeat:Dynamic<Dynamic>;
    private var _duration:Int;
    private var _isDynamic:Bool;
    private var _initialRepeat:Int;
    private var _repeat:Int;
    private var _yoyo:Bool;
    private var _isPlaying:Bool;
    private var _reversed:Bool;
    private var _delayTime:Int;
    private var _startTime:Int;
    private var _easingFunction:EasingFunc;
    private var _interpolationFunction:InterpolationFunc;
    // eslint-disable-next-line
    private var _chainedTweens:Array<Tween>;
    private var _onStartCallbackFired:Bool;
    private var _onEveryStartCallbackFired:Bool;
    private var _id:Int;
    private var _isChainStopped:Bool;
    private var _propertiesAreSetUp:Bool;
    private var _goToEnd:Bool;

    public function new(_object:Dynamic, _group:Group = null) {
        // ... constructor implementation omitted for brevity
    }

    // ... other methods omitted for brevity
}

class Interpolation {
    static inline function Linear(v:Array<Dynamic>, k:Float):Dynamic {
        var m = v.length - 1;
        var f = m * k;
        var i = Math.floor(f);
        var fn = Interpolation.Utils.Linear;
        if (k < 0) {
            return fn(v[0], v[1], f);
        }
        if (k > 1) {
            return fn(v[m], v[m - 1], m - f);
        }
        return fn(v[i], v[i + 1 > m ? m : i + 1], f - i);
    }

    // ... other interpolation functions omitted for brevity

    static inline class Utils {
        static inline function Linear(p0:Dynamic, p1:Dynamic, t:Float):Dynamic {
            return (p1 - p0) * t + p0;
        }

        // ... other utility functions omitted for brevity
    }
}

// Other classes omitted for brevity

class Sequence {
    private static var _nextId:Int;

    public static function new():Void {
        _nextId = 0;
    }

    public static function nextId():Int {
        return _nextId++;
    }
}

// Initialize the TWEEN singleton
TWEEN = new Group();