import haxe.unit.TestCase;
import haxe.unit.TestContext;

import js.Browser;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;

class TestMeshStandardMaterial extends TestCase {
    public function new() {
        super();
    }

    override public function setUp(context: TestContext):Void {
        super.setUp(context);
        // ...
    }

    public function testExtending():Void {
        var material = new openfl.display3D.materials.MeshStandardMaterial();
        var isInstanceOfMaterial = material instanceof openfl.display3D.materials.Material;
        var expected = true;
        this.assertTrue(isInstanceOfMaterial == expected);
    }

    public function testInstancing():Void {
        var material = new openfl.display3D.materials.MeshStandardMaterial();
        this.assertNotNull(material);
    }

    public function testType():Void {
        var material = new openfl.display3D.materials.MeshStandardMaterial();
        var expected = "MeshStandardMaterial";
        this.assertEquals(material.type, expected);
    }

    public function testIsMeshStandardMaterial():Void {
        var material = new openfl.display3D.materials.MeshStandardMaterial();
        this.assertTrue(material.isMeshStandardMaterial);
    }
}

class TestRunner {
    public static function main() {
        var runner = new openfl.display.Sprite();
        var context = new TestContext();
        context.registerClass(new TestMeshStandardMaterial());
        runner.addChild(context);
    }
}

TestRunner.main();