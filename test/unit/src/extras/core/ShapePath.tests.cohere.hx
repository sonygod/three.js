import haxe.unit.TestCase;
import haxe.unit.Test;
import js.QUnit;

import extras.core.ShapePath;

class TestShapePath extends TestCase {
    public function testInstancing():Void {
        var object = new ShapePath();
        var ok = object != null;
        QUnit.ok(ok, "Can instantiate a ShapePath.");
    }

    public function testType():Void {
        var object = new ShapePath();
        var ok = object.getType() == "ShapePath";
        QUnit.ok(ok, "ShapePath.type should be ShapePath");
    }

    public function testColor():Void {
        // TODO: Implement test for color property.
        var ok = false; // Replace with actual test code.
        QUnit.ok(ok, "everything's gonna be alright");
    }

    public function testSubPaths():Void {
        // TODO: Implement test for subPaths property.
        var ok = false; // Replace with actual test code.
        QUnit.ok(ok, "everything's gonna be alright");
    }

    public function testCurrentPath():Void {
        // TODO: Implement test for currentPath property.
        var ok = false; // Replace with actual test code.
        QUnit.ok(ok, "everything's gonna be alright");
    }

    public function testMoveTo():Void {
        // TODO: Implement test for moveTo method.
        var ok = false; // Replace with actual test code.
        QUnit.ok(ok, "everything's gonna be alright");
    }

    public function testLineTo():Void {
        // TODO: Implement test for lineTo method.
        var ok = false; // Replace with actual test code.
        QUnit.ok(ok, "everything's gonna be alright");
    }

    public function testQuadraticCurveTo():Void {
        // TODO: Implement test for quadraticCurveTo method.
        var ok = false; // Replace with actual test code.
        QUnit.ok(ok, "everything's gonna be alright");
    }

    public function testBezierCurveTo():Void {
        // TODO: Implement test for bezierCurveTo method.
        var ok = false; // Replace with actual test code.
        QUnit.ok(ok, "everything's gonna be alright");
    }

    public function testSplineThru():Void {
        // TODO: Implement test for splineThru method.
        var ok = false; // Replace with actual test code.
        QUnit.ok(ok, "everything's gonna be alright");
    }

    public function testToShapes():Void {
        // TODO: Implement test for toShapes method.
        var ok = false; // Replace with actual test code.
        QUnit.ok(ok, "everything's gonna be alright");
    }

    static function main():Void {
        #if sys
        var suite = new TestSuite("Extras");
        suite.add(new TestShapePath());
        #end
    }
}