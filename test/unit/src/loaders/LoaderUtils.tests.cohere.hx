import js.QUnit;
import js.Uint8Array;

class LoaderUtils {
    public static function decodeText(array:Uint8Array):String {
        // implementation...
    }

    public static function extractUrlBase(url:String):String {
        // implementation...
    }
}

class LoaderUtilsTest {
    public static function test():Void {
        var jsonArray = new Uint8Array([ 123, 34, 106, 115, 111, 110, 34, 58, 32, 116, 114, 117, 101, 125 ]);
        var multibyteArray = new Uint8Array([ 230, 151, 165, 230, 156, 172, 229, 155, 189 ]);

        QUnit.equal(LoaderUtils.decodeText(jsonArray), '{"json": true}');
        QUnit.equal(LoaderUtils.decodeText(multibyteArray), '日本国');

        QUnit.equal(LoaderUtils.extractUrlBase("/path/to/model.glb"), "/path/to/");
        QUnit.equal(LoaderUtils.extractUrlBase("model.glb"), "./");
        QUnit.equal(LoaderUtils.extractUrlBase("/model.glb"), "/");
    }
}

// Run the test
LoaderUtilsTest.test();