package;

import js.Lib;
import js.Browser.window;

class Interpolant {
    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
        // ...
    }

    public function copySampleValue_(i1:Int):Array<Float> {
        // ...
    }

    public function evaluate(t:Float):Float {
        // ...
    }
}

class Mock extends Interpolant {
    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    public function intervalChanged_(i1:Int, t0:Float, t1:Float):Void {
        // ...
    }

    public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
        // ...
    }
}

class Test {
    static var calls:Array<Dynamic>;

    static function main() {
        // INSTANCING
        var interpolant = new Mock(null, [1, 11, 2, 22, 3, 33], 2, []);
        Lib.assert(interpolant instanceof Interpolant);

        // PROPERTIES
        // ...

        // PUBLIC
        // ...

        // PRIVATE
        // ...

        // EVALUATE
        // ...
    }
}

class Main {
    static function main() {
        window.onload = function() {
            Test.main();
        };
    }
}

Main.main();