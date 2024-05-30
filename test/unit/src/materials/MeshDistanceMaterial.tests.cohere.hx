import haxe.unit.TestCase;
import haxe.unit.Test;
import js.Browser;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;

class TestMaterials extends TestCase {
    public function testMeshDistanceMaterial():Void {
        var material = new openfl.display3D.MeshDistanceMaterial();

        var isExtending = material instanceof openfl.display3D.Material;
        var isInstancing = material != null;
        var isTypeCorrect = material.type == "MeshDistanceMaterial";
        var isMeshDistanceMaterial = material.isMeshDistanceMaterial;

        // QUnit.todo
        // map, alphaMap, displacementMap, displacementScale, displacementBias, copy

        this.assertTrue(isExtending);
        this.assertTrue(isInstancing);
        this.assertTrue(isTypeCorrect);
        this.assertTrue(isMeshDistanceMaterial);
    }
}

class TestRunner {
    public static function main():Void {
        #if js
        Browser.window.onload = function() {
            Test.run();
        };
        #end

        Test.suite(TestMaterials);
    }
}

TestRunner.main();