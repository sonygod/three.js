Here is the converted Haxe code:
```
package three.examples.jsm.effects;

import three.StereoCamera;
import three.Vector2;

class StereoEffect {
    private var _stereo:StereoCamera;
    private var size:Vector2;

    public function new(renderer:Renderer) {
        _stereo = new StereoCamera();
        _stereo.aspect = 0.5;
        size = new Vector2();

        setEyeSeparation = function(eyeSep:Float) {
            _stereo.eyeSep = eyeSep;
        };

        setSize = function(width:Int, height:Int) {
            renderer.setSize(width, height);
        };

        render = function(scene:Scene, camera:Camera) {
            if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();

            if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

            _stereo.update(camera);

            renderer.getSize(size);

            if (renderer.autoClear) renderer.clear();
            renderer.setScissorTest(true);

            renderer.setScissor(0, 0, Std.int(size.width / 2), Std.int(size.height));
            renderer.setViewport(0, 0, Std.int(size.width / 2), Std.int(size.height));
            renderer.render(scene, _stereo.cameraL);

            renderer.setScissor(Std.int(size.width / 2), 0, Std.int(size.width / 2), Std.int(size.height));
            renderer.setViewport(Std.int(size.width / 2), 0, Std.int(size.width / 2), Std.int(size.height));
            renderer.render(scene, _stereo.cameraR);

            renderer.setScissorTest(false);
        };
    }
}
```
Note:

* I assumed that the `Renderer` class is already imported and available in the Haxe code.
* I used `Std.int` to convert Float values to Int, as Haxe is a statically-typed language and requires explicit type conversions.
* I kept the original JavaScript code's logic and structure, and only translated it to Haxe syntax.

Please test the converted code and let me know if you have any issues or questions!