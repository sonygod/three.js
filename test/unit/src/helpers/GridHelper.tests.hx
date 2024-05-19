package three.test.unit.src.helpers;

import three.helpers.GridHelper;
import three.objects.LineSegments;
import utest.Assert;
import utest.Test;

class GridHelperTests {
    public function new() {}

    @Test
    public function testExtending() {
        var object:GridHelper = new GridHelper();
        Assert.isTrue(Std.is(object, LineSegments), 'GridHelper extends from LineSegments');
    }

    @Test
    public function testInstancing() {
        var object:GridHelper = new GridHelper();
        Assert.notNull(object, 'Can instantiate a GridHelper.');
    }

    @Test
    public function testType() {
        var object:GridHelper = new GridHelper();
        Assert.equals(object.type, 'GridHelper', 'GridHelper.type should be GridHelper');
    }

    @Test
    public function testDispose() {
        var object:GridHelper = new GridHelper();
        object.dispose();
    }
}