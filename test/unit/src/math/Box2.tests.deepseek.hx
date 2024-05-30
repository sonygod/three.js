package;

import three.js.test.unit.src.math.Box2;
import three.js.test.unit.src.math.Vector2;
import three.js.test.unit.utils.math_constants;

class Box2Tests {

    static function main() {

        var a = new Box2();
        trace(a.min.equals(math_constants.posInf2), 'Passed!');
        trace(a.max.equals(math_constants.negInf2), 'Passed!');

        a = new Box2(math_constants.zero2.clone(), math_constants.zero2.clone());
        trace(a.min.equals(math_constants.zero2), 'Passed!');
        trace(a.max.equals(math_constants.zero2), 'Passed!');

        a = new Box2(math_constants.zero2.clone(), math_constants.one2.clone());
        trace(a.min.equals(math_constants.zero2), 'Passed!');
        trace(a.max.equals(math_constants.one2), 'Passed!');

        // ... 其他测试代码 ...

    }

}