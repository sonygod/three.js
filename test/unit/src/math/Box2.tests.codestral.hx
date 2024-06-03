// haxe

import three.js.src.math.Box2;
import three.js.src.math.Vector2;
import three.js.utils.MathConstants;

class Box2Tests {

    static function testInstancing(): Void {
        var a = new Box2();
        haxe.unit.Assert.isTrue(a.min.equals(MathConstants.posInf2), "Passed!");
        haxe.unit.Assert.isTrue(a.max.equals(MathConstants.negInf2), "Passed!");

        a = new Box2(MathConstants.zero2.clone(), MathConstants.zero2.clone());
        haxe.unit.Assert.isTrue(a.min.equals(MathConstants.zero2), "Passed!");
        haxe.unit.Assert.isTrue(a.max.equals(MathConstants.zero2), "Passed!");

        // ... continue in similar fashion for other tests
    }

    // ... continue in similar fashion for other test methods
}