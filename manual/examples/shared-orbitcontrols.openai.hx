package three;

import js.html.CanvasElement;
import js.html.InputElement;
import three.js.Lib;

class OrbitControls {
    public function new(camera:PerspectiveCamera, inputElement:InputElement) {
        // ...
    }
}

class PickHelper {
    public var raycaster:Raycaster;
    public var pickedObject:Object3D;
    public var pickedObjectSavedColor:Int;

    public function new() {
        raycaster = new Raycaster();
        pickedObject = null;
        pickedObjectSavedColor = 0;
    }

    public function pick(normalizedPosition:Vector2, scene:Scene, camera:PerspectiveCamera, time:Float) {
        // ...
    }
}

class Main {
    public static function init(data:Dynamic) {
        var canvas:CanvasElement = data.canvas;
        var inputElement:InputElement = data.inputElement;

        var renderer:WebGLRenderer = new WebGLRenderer({
            antialias: true,
            canvas: canvas
        });

        var fov:Float = 75;
        var aspect:Float = 2;
        var near:Float = 0.1;
        var far:Float = 100;
        var camera:PerspectiveCamera = new PerspectiveCamera(fov, aspect, near, far);
        camera.position.z = 4;

        var controls:OrbitControls = new OrbitControls(camera, inputElement);
        controls.target.set(0, 0, 0);
        controls.update();

        var scene:Scene = new Scene();

        var light:DirectionalLight = new DirectionalLight(0xFFFFFF, 1);
        light.position.set(-1, 2, 4);
        scene.add(light);

        var boxWidth:Float = 1;
        var boxHeight:Float = 1;
        var boxDepth:Float = 1;
        var geometry:BoxGeometry = new BoxGeometry(boxWidth, boxHeight, boxDepth);

        function makeInstance(geometry:BoxGeometry, color:Int, x:Float):Mesh {
            var material:MeshPhongMaterial = new MeshPhongMaterial({
                color: color
            });
            var cube:Mesh = new Mesh(geometry, material);
            scene.add(cube);
            cube.position.x = x;
            return cube;
        }

        var cubes:Array<Mesh> = [
            makeInstance(geometry, 0x44aa88, 0),
            makeInstance(geometry, 0x8844aa, -2),
            makeInstance(geometry, 0xaa8844, 2)
        ];

        var pickHelper:PickHelper = new PickHelper();
        var pickPosition:Vector2 = new Vector2(-2, -2);

        function resizeRendererToDisplaySize(renderer:WebGLRenderer):Bool {
            var canvas:CanvasElement = renderer.domElement;
            var width:Int = inputElement.clientWidth;
            var height:Int = inputElement.clientHeight;
            var needResize:Bool = canvas.width != width || canvas.height != height;
            if (needResize) {
                renderer.setSize(width, height, false);
            }
            return needResize;
        }

        function render(time:Float) {
            time *= 0.001;

            if (resizeRendererToDisplaySize(renderer)) {
                camera.aspect = inputElement.clientWidth / inputElement.clientHeight;
                camera.updateProjectionMatrix();
            }

            for (cube in cubes) {
                var speed:Float = 1 + cubes.indexOf(cube) * 0.1;
                var rot:Float = time * speed;
                cube.rotation.x = rot;
                cube.rotation.y = rot;
            }

            pickHelper.pick(pickPosition, scene, camera, time);

            renderer.render(scene, camera);

            js.Browser.window.requestAnimationFrame(render);
        }

        js.Browser.window.requestAnimationFrame(render);

        function getCanvasRelativePosition(event:MouseEvent):Vector2 {
            var rect:ClientRect = inputElement.getBoundingClientRect();
            return new Vector2(event.clientX - rect.left, event.clientY - rect.top);
        }

        function setPickPosition(event:MouseEvent) {
            var pos:Vector2 = getCanvasRelativePosition(event);
            pickPosition.x = (pos.x / inputElement.clientWidth) * 2 - 1;
            pickPosition.y = (pos.y / inputElement.clientHeight) * -2 + 1; // note we flip Y
        }

        function clearPickPosition() {
            pickPosition.x = -100000;
            pickPosition.y = -100000;
        }

        inputElement.addEventListener('mousemove', setPickPosition);
        inputElement.addEventListener('mouseout', clearPickPosition);
        inputElement.addEventListener('mouseleave', clearPickPosition);

        inputElement.addEventListener('touchstart', (event:Event) -> {
            event.preventDefault();
            setPickPosition(event.touches[0]);
        }, { passive: false } );

        inputElement.addEventListener('touchmove', (event:Event) -> {
            setPickPosition(event.touches[0]);
        } );

        inputElement.addEventListener('touchend', clearPickPosition);
    }
}