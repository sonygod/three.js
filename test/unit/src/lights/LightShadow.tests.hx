package three.test.unit.src.lights;

import three.lights.LightShadow;
import three.cameras.OrthographicCamera;
import utest.Assert;
import utest.Test;

class LightShadowTest {
    public function new() {}

    public function testInstancing() {
        var camera = new OrthographicCamera(-5, 5, 5, -5, 0.5, 500);
        var object = new LightShadow(camera);
        Assert.notNull(object, 'Can instantiate a LightShadow.');
    }

    public function testCamera() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testBias() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testNormalBias() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testRadius() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testBlurSamples() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testMapSize() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testMap() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testMapPass() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testMatrix() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testAutoUpdate() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testNeedsUpdate() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testGetViewportCount() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testGetFrustum() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testUpdateMatrices() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testGetViewport() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testGetFrameExtents() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testDispose() {
        var object = new LightShadow();
        object.dispose();
    }

    public function testCopy() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testClone() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testToJSON() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testCloneCopy() {
        var a = new LightShadow(new OrthographicCamera(-5, 5, 5, -5, 0.5, 500));
        var b = new LightShadow(new OrthographicCamera(-3, 3, 3, -3, 0.3, 300));

        Assert.notEqual(a, b, 'Newly instanced shadows are not equal');

        var c = a.clone();
        Assert.equals(a, c, 'Shadows are identical after clone()');

        c.mapSize.set(256, 256);
        Assert.notEqual(a, c, 'Shadows are different again after change');

        b.copy(a);
        Assert.equals(a, b, 'Shadows are identical after copy()');

        b.mapSize.set(512, 512);
        Assert.notEqual(a, b, 'Shadows are different again after change');
    }
}