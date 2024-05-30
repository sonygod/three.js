import js.Browser.window;

class MeshNormalMaterialTest {
    static function main() {
        var module = new Module();
        module.run();
    }
}

class Module {
    public function run() {
        var materialTests = new MaterialTests();
        materialTests.run();
    }
}

class MaterialTests {
    public function run() {
        var meshNormalMaterialTests = new MeshNormalMaterialTests();
        meshNormalMaterialTests.run();
    }
}

class MeshNormalMaterialTests {
    public function run() {
        var test = new MeshNormalMaterialTest();
        test.testExtending();
        test.testInstancing();
        test.testType();
        test.testIsMeshNormalMaterial();
    }
}

class MeshNormalMaterialTest {
    public function testExtending() {
        var object = new MeshNormalMaterial();
        assert(object instanceof Material, "MeshNormalMaterial extends from Material");
    }

    public function testInstancing() {
        var object = new MeshNormalMaterial();
        assert(object != null, "Can instantiate a MeshNormalMaterial.");
    }

    public function testType() {
        var object = new MeshNormalMaterial();
        assert(object.type == "MeshNormalMaterial", "MeshNormalMaterial.type should be MeshNormalMaterial");
    }

    public function testIsMeshNormalMaterial() {
        var object = new MeshNormalMaterial();
        assert(object.isMeshNormalMaterial, "MeshNormalMaterial.isMeshNormalMaterial should be true");
    }
}

class MeshNormalMaterial {
    public var type:String;
    public var isMeshNormalMaterial:Bool;

    public function new() {
        type = "MeshNormalMaterial";
        isMeshNormalMaterial = true;
    }
}

class Material {
}

class Assert {
    public static function assert(condition:Bool, message:String) {
        if (!condition) {
            trace(message);
        }
    }
}

static function trace(message:String) {
    window.console.log(message);
}

@:keep
class QUnit {
    public static function module(name:String, callback:Void->Void) {
        callback();
    }

    public static function test(name:String, callback:Void->Void) {
        callback();
    }

    public static function todo(name:String, callback:Void->Void) {
        // Do nothing
    }
}

class Main {
    static function main() {
        MeshNormalMaterialTest.main();
    }
}