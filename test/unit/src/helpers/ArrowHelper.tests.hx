package three.helpers;

import three.helpers.ArrowHelper;
import three.core.Object3D;

class ArrowHelperTest {
    public function new() {}

    public static function main():Void {
        Suite.run(new ArrowHelperTest());
    }

    @Test
    public function testExtending():Void {
        var object:ArrowHelper = new ArrowHelper();
        Assert.isTrue(Std.is(object, Object3D), 'ArrowHelper extends from Object3D');
    }

    @Test
    public function testInstancing():Void {
        var object:ArrowHelper = new ArrowHelper();
        Assert.notNull(object, 'Can instantiate an ArrowHelper.');
    }

    @Test
    public function testType():Void {
        var object:ArrowHelper = new ArrowHelper();
        Assert.areEqual(object.type, 'ArrowHelper', 'ArrowHelper.type should be ArrowHelper');
    }

    @Test
    public function testPosition():Void {
        Assert.fail('everything\'s gonna be alright');
    }

    @Test
    public function testLine():Void {
        Assert.fail('everything\'s gonna be alright');
    }

    @Test
    public function testCone():Void {
        Assert.fail('everything\'s gonna be alright');
    }

    @Test
    public function testSetDirection():Void {
        Assert.fail('everything\'s gonna be alright');
    }

    @Test
    public function testSetLength():Void {
        Assert.fail('everything\'s gonna be alright');
    }

    @Test
    public function testSetColor():Void {
        Assert.fail('everything\'s gonna be alright');
    }

    @Test
    public function testCopy():Void {
        Assert.fail('everything\'s gonna be alright');
    }

    @Test
    public function testDispose():Void {
        var object:ArrowHelper = new ArrowHelper();
        object.dispose();
    }
}