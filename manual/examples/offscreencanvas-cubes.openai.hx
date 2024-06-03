package three.js.manual.examples;

import three.js.*;

class OffscreenCanvasCubes {
    static var state = {
        width: 300, // canvas default
        height: 150, // canvas default
    };

    static function main(data:Dynamic) {
        var canvas:HTMLCanvasElement = data.canvas;
        var renderer:WebGLRenderer = new WebGLRenderer({ canvas: canvas });
        state.width = canvas.width;
        state.height = canvas.height;

        var fov:Float = 75;
        var aspect:Float = 2; // the canvas default
        var near:Float = 0.1;
        var far:Float = 100;
        var camera:PerspectiveCamera = new PerspectiveCamera(fov, aspect, near, far);
        camera.position.z = 4;

        var scene:Scene = new Scene();

        {
            var color:Int = 0xFFFFFF;
            var intensity:Float = 1;
            var light:DirectionalLight = new DirectionalLight(color, intensity);
            light.position.set(-1, 2, 4);
            scene.add(light);
        }

        var boxWidth:Float = 1;
        var boxHeight:Float = 1;
        var boxDepth:Float = 1;
        var geometry:BoxGeometry = new BoxGeometry(boxWidth, boxHeight, boxDepth);

        function makeInstance(geometry:Geometry, color:Int, x:Float) {
            var material:MeshPhongMaterial = new MeshPhongMaterial({ color: color });
            var cube:Mesh = new Mesh(geometry, material);
            scene.add(cube);
            cube.position.x = x;
            return cube;
        }

        var cubes:Array<Mesh> = [
            makeInstance(geometry, 0x44aa88, 0),
            makeInstance(geometry, 0x8844aa, -2),
            makeInstance(geometry, 0xaa8844, 2),
        ];

        function resizeRendererToDisplaySize(renderer:WebGLRenderer):Bool {
            var canvas:HTMLCanvasElement = renderer.domElement;
            var width:Int = state.width;
            var height:Int = state.height;
            var needResize:Bool = canvas.width != width || canvas.height != height;
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
                var speed:Float = 1 + cubes.indexOf(cube) * 0.1;
                var rot:Float = time * speed;
                cube.rotation.x = rot;
                cube.rotation.y = rot;
            }

            renderer.render(scene, camera);

            js.Browser.requestAnimationFrame(render);
        }

        js.Browser.requestAnimationFrame(render);
    }

    static function size(data:Dynamic) {
        state.width = data.width;
        state.height = data.height;
    }

    static var handlers:Dynamic = {
        main: main,
        size: size,
    };

    static function onMessage(event:Dynamic) {
        var fn:Dynamic = handlers[event.data.type];
        if (Reflect.isFunction(fn)) {
            fn(event.data);
        } else {
            throw new Error('no handler for type: ' + event.data.type);
        }
    }

    static function main() {
        js.Browser.window.self.onmessage = onMessage;
    }
}