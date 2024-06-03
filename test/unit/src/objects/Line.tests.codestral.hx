// Haxe doesn't have a direct equivalent of QUnit, so instead we'll use a simple console-based test framework.

import three.objects.Line;
import three.core.Object3D;
import three.materials.Material;

class LineTests {
    public function new() {
        this.testExtending();
        this.testInstancing();
        this.testType();
        this.testIsLine();
        this.testCopyMaterial();
    }

    private function assert(condition:Bool, message:String):Void {
        if(!condition) throw new Error(message);
    }

    private function testExtending():Void {
        var line:Line = new Line();
        assert(line is Object3D, 'Line extends from Object3D');
    }

    private function testInstancing():Void {
        var object:Line = new Line();
        assert(object != null, 'Can instantiate a Line.');
    }

    private function testType():Void {
        var object:Line = new Line();
        assert(object.type == 'Line', 'Line.type should be Line');
    }

    private function testIsLine():Void {
        var object:Line = new Line();
        assert(object.isLine, 'Line.isLine should be true');
    }

    private function testCopyMaterial():Void {
        var mesh1:Line = new Line();
        mesh1.material = [new Material()];

        var copy1:Line = mesh1.clone();
        assert(mesh1.material != copy1.material, 'Material arrays are cloned');

        var mesh2:Line = new Line();
        mesh2.material = new Material();
        var copy2:Line = mesh2.clone();
        assert(mesh2.material == copy2.material, 'Non arrays are not cloned');
    }
}

new LineTests();