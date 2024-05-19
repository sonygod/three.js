package three;

import js.html.Element;
import js.html.Event;
import js.html.Touch;
import js.html.TouchEvent;
import three.Lib;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Color;
import three.objects.Mesh;
import three.objects.Scene;
import three.cameras.PerspectiveCamera;
import three.renderers.WebGLRenderer;
import three.controls.OrbitControls;

class SharedOrbitControls {
    // ...

    public function init(data:Dynamic) {
        var canvas:Element = data.canvas;
        var inputElement:Element = data.inputElement;

        var renderer = new WebGLRenderer({ antialias: true, canvas: canvas });

        var fov = 75;
        var aspect = 2; // the canvas default
        var near = 0.1;
        var far = 100;
        var camera = new PerspectiveCamera(fov, aspect, near, far);
        camera.position.z = 4;

        var controls = new OrbitControls(camera, inputElement);
        controls.target.set(0, 0, 0);
        controls.update();

        var scene = new Scene();

        var light = new DirectionalLight(0xFFFFFF, 1);
        light.position.set(-1, 2, 4);
        scene.add(light);

        var boxWidth = 1;
        var boxHeight = 1;
        var boxDepth = 1;
        var geometry = new BoxGeometry(boxWidth, boxHeight, boxDepth);

        function makeInstance(geometry:Geometry, color:Int, x:Float) {
            var material = new MeshPhongMaterial({ color: color });
            var cube = new Mesh(geometry, material);
            scene.add(cube);
            cube.position.x = x;
            return cube;
        }

        var cubes = [makeInstance(geometry, 0x44aa88, 0), makeInstance(geometry, 0x8844aa, -2), makeInstance(geometry, 0xaa8844, 2)];

        class PickHelper {
            public var raycaster:Raycaster;
            public var pickedObject:Object3D;
            public var pickedObjectSavedColor:Int;

            public function new() {
                raycaster = new Raycaster();
                pickedObject = null;
                pickedObjectSavedColor = 0;
            }

            public function pick(normalizedPosition:Vector2, scene:Scene, camera:Camera, time:Float) {
                if (pickedObject != null) {
                    pickedObject.material.emissive.setHex(pickedObjectSavedColor);
                    pickedObject = null;
                }

                raycaster.setFromCamera(normalizedPosition, camera);
                var intersectedObjects:Array<RaycastHit> = raycaster.intersectObjects(scene.children);
                if (intersectedObjects.length > 0) {
                    pickedObject = intersectedObjects[0].object;
                    pickedObjectSavedColor = pickedObject.material.emissive.getHex();
                    pickedObject.material.emissive.setHex((time * 8) % 2 > 1 ? 0xFFFF00 : 0xFF0000);
                }
            }
        }

        var pickPosition:Vector2 = new Vector2(-2, -2);
        var pickHelper:PickHelper = new PickHelper();

        function clearPickPosition() {
            pickPosition.x = -100000;
            pickPosition.y = -100000;
        }

        function resizeRendererToDisplaySize(renderer:WebGLRenderer):Bool {
            var canvas:Element = renderer.domElement;
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

        function getCanvasRelativePosition(event:Event):Vector2 {
            var rect:ClientRect = inputElement.getBoundingClientRect();
            return new Vector2(event.clientX - rect.left, event.clientY - rect.top);
        }

        function setPickPosition(event:Event) {
            var pos:Vector2 = getCanvasRelativePosition(event);
            pickPosition.x = (pos.x / inputElement.clientWidth) * 2 - 1;
            pickPosition.y = (pos.y / inputElement.clientHeight) * -2 + 1;
        }

        inputElement.addEventListener('mousemove', setPickPosition);
        inputElement.addEventListener('mouseout', clearPickPosition);
        inputElement.addEventListener('mouseleave', clearPickPosition);

        inputElement.addEventListener('touchstart', (event:TouchEvent) -> {
            event.preventDefault();
            setPickPosition(event.touches[0]);
        }, false);

        inputElement.addEventListener('touchmove', (event:TouchEvent) -> {
            setPickPosition(event.touches[0]);
        });

        inputElement.addEventListener('touchend', clearPickPosition);
    }
}