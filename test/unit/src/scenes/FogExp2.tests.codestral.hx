import js.Browser.document;
import three.FogExp2;

class FogExp2Test {
    public static function main() {
        // INSTANCING
        testInstancing();

        // PUBLIC STUFF
        testIsFogExp2();
    }

    public static function testInstancing() {
        // no params
        var object:FogExp2 = new FogExp2();
        assert(object != null, "Can instantiate a FogExp2.");

        // color
        var object_color:FogExp2 = new FogExp2(0xffffff);
        assert(object_color != null, "Can instantiate a FogExp2 with color.");

        // color, density
        var object_all:FogExp2 = new FogExp2(0xffffff, 0.00030);
        assert(object_all != null, "Can instantiate a FogExp2 with color, density.");
    }

    public static function testIsFogExp2() {
        var object:FogExp2 = new FogExp2();
        assert(object.isFogExp2, "FogExp2.isFogExp2 should be true");
    }

    public static function assert(condition:Bool, message:String) {
        if (!condition) {
            document.write("<p>Assertion failed: " + message + "</p>");
        }
    }
}