package three.js.manual.examples;

import js.Browser;
import js.html.Element;
import three.js.Renderer;
import three.js.Scene;
import three.js.Camera;
import three.js.Object3D;
import three.js.Geometry;
import three.js.Material;
import three.js.Mesh;

class ThreeJSResponsive {
    static function main() {
        var canvas:Element = Browser.document.querySelector('#c');
        var renderer:Renderer = new Renderer({ antialias:true, canvas:canvas });

        var fov:Float = 75;
        var aspect:Float = 2; // the canvas default
        var near:Float = 0.1;
        var far:Float = 5;
        var camera:Camera = new PerspectiveCamera(fov, aspect, near, far);
        camera.position.z = 2;

        var scene:Scene = new Scene();

        {
            var color:Int = 0xFFFFFF;
            var intensity:Float = 3;
            var light:DirectionalLight = new DirectionalLight(color, intensity);
            light.position.set(-1, 2, 4);
            scene.add(light);
        }

        var boxWidth:Float = 1;
        var boxHeight:Float = 1;
        var boxDepth:Float = 1;
        var geometry:Geometry = new BoxGeometry(boxWidth, boxHeight, boxDepth);

        function makeInstance(geometry:Geometry, color:Int, x:Float):Mesh {
            var material:Material = new MeshPhongMaterial({ color:color });
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

        function resizeRendererToDisplaySize(renderer:Renderer):Bool {
            var canvas:Element = renderer.domElement;
            var width:Int = canvas.clientWidth;
            var height:Int = canvas.clientHeight;
            var needResize:Bool = canvas.width != width || canvas.height != height;
            if (needResize) {
                renderer.setSize(width, height, false);
            }
            return needResize;
        }

        function render(time:Float):Void {
            time *= 0.001;

            if (resizeRendererToDisplaySize(renderer)) {
                var canvas:Element = renderer.domElement;
                camera.aspect = canvas.clientWidth / canvas.clientHeight;
                camera.updateProjectionMatrix();
            }

            for (cube in cubes) {
                var speed:Float = 1 + cubes.indexOf(cube) * 0.1;
                var rot:Float = time * speed;
                cube.rotation.x = rot;
                cube.rotation.y = rot;
            }

            renderer.render(scene, camera);

            Browser.window.requestAnimationFrame(render);
        }

        Browser.window.requestAnimationFrame(render);
    }

    static function __init__() {
        main();
    }
}