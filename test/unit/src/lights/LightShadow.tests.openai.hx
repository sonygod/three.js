package three;

import three.lights.LightShadow;
import three.cameras.OrthographicCamera;
import utest.Assert;

class LightShadowTests {
    public function new() {}

    public static function main(): Void {
        utest.Test.createSuite("Lights", {
            var suite = new utest.TestSuite();
            suite.add(new LightShadowTests());
            return suite;
        });
    }

    public function testLightShadow(): Void {
        testInstancing();
        testProperties();
        testPublic();
        testOthers();
    }

    private function testInstancing(): Void {
        var camera: OrthographicCamera = new OrthographicCamera(-5, 5, 5, -5, 0.5, 500);
        var object: LightShadow = new LightShadow(camera);
        Assert.notNull(object, 'Can instantiate a LightShadow.');
    }

    private function testProperties(): Void {
        todo('camera');
        todo('bias');
        todo('normalBias');
        todo('radius');
        todo('blurSamples');
        todo('mapSize');
        todo('map');
        todo('mapPass');
        todo('matrix');
        todo('autoUpdate');
        todo('needsUpdate');
    }

    private function testPublic(): Void {
        todo('getViewportCount');
        todo('getFrustum');
        todo('updateMatrices');
        todo('getViewport');
        todo('getFrameExtents');

        testDispose();
        todo('copy');
        todo('clone');
        todo('toJSON');
    }

    private function testDispose(): Void {
        var object: LightShadow = new LightShadow();
        object.dispose();
    }

    private function testOthers(): Void {
        testCloneCopy();
    }

    private function testCloneCopy(): Void {
        var a: LightShadow = new LightShadow(new OrthographicCamera(-5, 5, 5, -5, 0.5, 500));
        var b: LightShadow = new LightShadow(new OrthographicCamera(-3, 3, 3, -3, 0.3, 300));

        Assert.notEquals(a, b, 'Newly instanced shadows are not equal');

        var c: LightShadow = a.clone();
        Assert.equals(a, c, 'Shadows are identical after clone()');

        c.mapSize.set(256, 256);
        Assert.notEquals(a, c, 'Shadows are different again after change');

        b.copy(a);
        Assert.equals(a, b, 'Shadows are identical after copy()');

        b.mapSize.set(512, 512);
        Assert.notEquals(a, b, 'Shadows are different again after change');
    }

    private function todo(name: String): Void {
        Assert.fail('everything\'s gonna be alright');
    }
}