import haxe.unit.TestRunner;
import Math;

using Math;

class Vector2Tests {
    public static function main() {
        var runner = new TestRunner();
        runner.add(new Vector2TestSuite());
        runner.run();
    }
}

class Vector2TestSuite {
    public function new() {}

    public function testInstancing() {
        var a = new Vector2();
        Assert.isTrue(a.x == 0);
        Assert.isTrue(a.y == 0);

        a = new Vector2(x, y);
        Assert.isTrue(a.x == x);
        Assert.isTrue(a.y == y);
    }

    // PROPERTIES
    public function testProperties() {
        var a = new Vector2(0, 0);
        var width = 100;
        var height = 200;

        a.width = width;
        a.height = height;

        a.set(width, height);
        Assert.isTrue(a.width == width);
        Assert.isTrue(a.height == height);
    }

    // PUBLIC STUFF
    public function testIsVector2() {
        var object = new Vector2();
        Assert.isTrue(object.isVector2);
    }

    public function testSet() {
        var a = new Vector2();
        Assert.isTrue(a.x == 0);
        Assert.isTrue(a.y == 0);

        a.set(x, y);
        Assert.isTrue(a.x == x);
        Assert.isTrue(a.y == y);
    }

    // ... (rest of the test functions)

    // LERP
    public function testLerp() {
        var a = new Vector2(x, 0);
        var b = new Vector2(0, -y);

        Assert.isTrue(a.lerp(a, 0).equals(a.lerp(a, 0.5)));
        Assert.isTrue(a.lerp(a, 0).equals(a.lerp(a, 1)));

        Assert.isTrue(a.clone().lerp(b, 0).equals(a));
        Assert.isTrue(a.clone().lerp(b, 0.5).x == x * 0.5);
        Assert.isTrue(a.clone().lerp(b, 0.5).y == -y * 0.5);
        Assert.isTrue(a.clone().lerp(b, 1).equals(b));
    }

    // ... (rest of the test functions)
}