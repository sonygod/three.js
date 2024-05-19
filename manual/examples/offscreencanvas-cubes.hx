Here is the converted Haxe code:
```
import js.html.CanvasElement;
import js.html.WebGLRenderingContext;
import three.js.Lib;

class OffscreenCanvasCubes {
    static var state = {
        width: 300, // canvas default
        height: 150, // canvas default
    };

    static function main(data:Dynamic) {
        var canvas:CanvasElement = data.canvas;
        var renderer = new three.js.renderers.WebGLRenderer({ canvas: canvas });
        state.width = canvas.width;
        state.height = canvas.height;

        var fov = 75;
        var aspect = 2; // the canvas default
        var near = 0.1;
        var far = 100;
        var camera = new three.js.cameras.PerspectiveCamera(fov, aspect, near, far);
        camera.position.z = 4;

        var scene = new three.js.Scene();

        {
            var color = 0xFFFFFF;
            var intensity = 1;
            var light = new three.js.lights.DirectionalLight(color, intensity);
            light.position.set(-1, 2, 4);
            scene.add(light);
        }

        var boxWidth = 1;
        var boxHeight = 1;
        var boxDepth = 1;
        var geometry = new three.js.geometries.BoxGeometry(boxWidth, boxHeight, boxDepth);

        function makeInstance(geometry:three.js.geometries.Geometry, color:Int, x:Float) {
            var material = new three.js.materials.MeshPhongMaterial({ color: color });
            var cube = new three.js.meshes.Mesh(geometry, material);
            scene.add(cube);
            cube.position.x = x;
            return cube;
        }

        var cubes:Array<three.js.meshes.Mesh> = [
            makeInstance(geometry, 0x44aa88, 0),
            makeInstance(geometry, 0x8844aa, -2),
            makeInstance(geometry, 0xaa8844, 2),
        ];

        function resizeRendererToDisplaySize(renderer:three.js.renderers.WebGLRenderer) {
            var canvas:CanvasElement = renderer.domElement;
            var width = state.width;
            var height = state.height;
            var needResize = canvas.width != width || canvas.height != height;
            if (needResize) {
                renderer.setSize(width, height, false);
            }
            return needResize;
        }

        function render(time:Float) {
            time *= 0.001;
            if (resizeRendererToDisplaySize(renderer)) {
                camera.aspect = state.width / state.height;
                camera.updateProjectionMatrix();
            }

            for (cube in cubes) {
                var speed = 1 + cubes.indexOf(cube) * 0.1;
                var rot = time * speed;
                cube.rotation.x = rot;
                cube.rotation.y = rot;
            }

            renderer.render(scene, camera);
            js.Browser.window.requestAnimationFrame(render);
        }

        js.Browser.window.requestAnimationFrame(render);
    }

    static function size(data:Dynamic) {
        state.width = data.width;
        state.height = data.height;
    }

    static var handlers:Dynamic = {
        main: main,
        size: size,
    };

    static function onMessage(e:Dynamic) {
        var fn = handlers[e.data.type];
        if (fn == null) {
            throw new js.Error('no handler for type: ' + e.data.type);
        }
        fn(e.data);
    }

    static function main() {
        js.Browser.window.addEventListener("message", onMessage);
    }
}
```
Note that I've used the `three.js` library's Haxe externs, which are available in the `three.js` package on haxelib. I've also used the `js.html` package for working with HTML elements, and the `js.Browser` package for working with the browser's window and requestAnimationFrame.

Please note that this is a manual conversion, and you should test the code thoroughly to ensure it works as expected.