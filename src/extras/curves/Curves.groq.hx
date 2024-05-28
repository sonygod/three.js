Here is the equivalent Haxe code:
```
@:keep
@:nativeGen
@:jsRequire('threejs', 'threejs/extras/curves/ArcCurve')
extern class ArcCurve {}

@:keep
@:nativeGen
@:jsRequire('threejs', 'threejs/extras/curves/CatmullRomCurve3')
extern class CatmullRomCurve3 {}

@:keep
@:nativeGen
@:jsRequire('threejs', 'threejs/extras/curves/CubicBezierCurve')
extern class CubicBezierCurve {}

@:keep
@:nativeGen
@:jsRequire('threejs', 'threejs/extras/curves/CubicBezierCurve3')
extern class CubicBezierCurve3 {}

@:keep
@:nativeGen
@:jsRequire('threejs', 'threejs/extras/curves/EllipseCurve')
extern class EllipseCurve {}

@:keep
@:nativeGen
@:jsRequire('threejs', 'threejs/extras/curves/LineCurve')
extern class LineCurve {}

@:keep
@:nativeGen
@:jsRequire('threejs', 'threejs/extras/curves/LineCurve3')
extern class LineCurve3 {}

@:keep
@:nativeGen
@:jsRequire('threejs', 'threejs/extras/curves/QuadraticBezierCurve')
extern class QuadraticBezierCurve {}

@:keep
@:nativeGen
@:jsRequire('threejs', 'threejs/extras/curves/QuadraticBezierCurve3')
extern class QuadraticBezierCurve3 {}

@:keep
@:nativeGen
@:jsRequire('threejs', 'threejs/extras/curves/SplineCurve')
extern class SplineCurve {}

class Curves {
    public static function __init__() {
        js.Lib.require('threejs/extras/curves/ArcCurve');
        js.Lib.require('threejs/extras/curves/CatmullRomCurve3');
        js.Lib.require('threejs/extras/curves/CubicBezierCurve');
        js.Lib.require('threejs/extras/curves/CubicBezierCurve3');
        js.Lib.require('threejs/extras/curves/EllipseCurve');
        js.Lib.require('threejs/extras/curves/LineCurve');
        js.Lib.require('threejs/extras/curves/LineCurve3');
        js.Lib.require('threejs/extras/curves/QuadraticBezierCurve');
        js.Lib.require('threejs/extras/curves/QuadraticBezierCurve3');
        js.Lib.require('threejs/extras/curves/SplineCurve');
    }
}
```
Note that in Haxe, we use the `extern` keyword to declare external classes, and the `@:keep` and `@:nativeGen` metadata to ensure that the classes are preserved and generated correctly. We also use the `js.Lib.require` function to load the required JavaScript files.