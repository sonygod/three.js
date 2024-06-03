import js.Browser;
import three.THREE;
import three.controls.OrbitControls;

class Main {
    public static function init(data:Dynamic):Void {
        var canvas:THREE.Canvas = data.canvas;
        var inputElement:Browser.Element = data.inputElement;
        var renderer:THREE.WebGLRenderer = new THREE.WebGLRenderer({antialias: true, canvas: canvas});

        var fov:Float = 75;
        var aspect:Float = 2;
        var near:Float = 0.1;
        var far:Float = 100;
        var camera:THREE.PerspectiveCamera = new THREE.PerspectiveCamera(fov, aspect, near, far);
        camera.position.z = 4;

        var controls:OrbitControls = new OrbitControls(camera, inputElement);
        controls.target.set(0, 0, 0);
        controls.update();

        var scene:THREE.Scene = new THREE.Scene();

        var color:Int = 0xFFFFFF;
        var intensity:Float = 1;
        var light:THREE.DirectionalLight = new THREE.DirectionalLight(color, intensity);
        light.position.set(-1, 2, 4);
        scene.add(light);

        var boxWidth:Float = 1;
        var boxHeight:Float = 1;
        var boxDepth:Float = 1;
        var geometry:THREE.BoxGeometry = new THREE.BoxGeometry(boxWidth, boxHeight, boxDepth);

        function makeInstance(geometry:THREE.BoxGeometry, color:Int, x:Float):THREE.Mesh {
            var material:THREE.MeshPhongMaterial = new THREE.MeshPhongMaterial({color: color});
            var cube:THREE.Mesh = new THREE.Mesh(geometry, material);
            scene.add(cube);
            cube.position.x = x;
            return cube;
        }

        var cubes:Array<THREE.Mesh> = [
            makeInstance(geometry, 0x44aa88, 0),
            makeInstance(geometry, 0x8844aa, -2),
            makeInstance(geometry, 0xaa8844, 2)
        ];

        class PickHelper {
            public var raycaster:THREE.Raycaster;
            public var pickedObject:THREE.Object3D;
            public var pickedObjectSavedColor:Int;

            public function new() {
                this.raycaster = new THREE.Raycaster();
                this.pickedObject = null;
                this.pickedObjectSavedColor = 0;
            }

            public function pick(normalizedPosition:Dynamic, scene:THREE.Scene, camera:THREE.PerspectiveCamera, time:Float):Void {
                if (this.pickedObject != null) {
                    this.pickedObject.material.emissive.setHex(this.pickedObjectSavedColor);
                    this.pickedObject = null;
                }

                this.raycaster.setFromCamera(normalizedPosition, camera);
                var intersectedObjects = this.raycaster.intersectObjects(scene.children);
                if (intersectedObjects.length > 0) {
                    this.pickedObject = intersectedObjects[0].object;
                    this.pickedObjectSavedColor = this.pickedObject.material.emissive.getHex();
                    this.pickedObject.material.emissive.setHex((time * 8) % 2 > 1 ? 0xFFFF00 : 0xFF0000);
                }
            }
        }

        var pickPosition:Dynamic = {x: -2, y: -2};
        var pickHelper:PickHelper = new PickHelper();
        clearPickPosition();

        function resizeRendererToDisplaySize(renderer:THREE.WebGLRenderer):Bool {
            var canvas:THREE.Canvas = renderer.domElement;
            var width:Int = inputElement.clientWidth;
            var height:Int = inputElement.clientHeight;
            var needResize:Bool = canvas.width != width || canvas.height != height;
            if (needResize) {
                renderer.setSize(width, height, false);
            }
            return needResize;
        }

        function render(time:Float):Void {
            time *= 0.001;

            if (resizeRendererToDisplaySize(renderer)) {
                camera.aspect = inputElement.clientWidth / inputElement.clientHeight;
                camera.updateProjectionMatrix();
            }

            for (cube in cubes) {
                var speed:Float = 1 + cubes.indexOf(cube) * .1;
                var rot:Float = time * speed;
                cube.rotation.x = rot;
                cube.rotation.y = rot;
            }

            pickHelper.pick(pickPosition, scene, camera, time);

            renderer.render(scene, camera);

            Browser.window.requestAnimationFrame(render);
        }

        Browser.window.requestAnimationFrame(render);

        function getCanvasRelativePosition(event:Browser.Event):Dynamic {
            var rect:Browser.ClientRect = inputElement.getBoundingClientRect();
            return {
                x: event.clientX - rect.left,
                y: event.clientY - rect.top
            };
        }

        function setPickPosition(event:Browser.Event):Void {
            var pos:Dynamic = getCanvasRelativePosition(event);
            pickPosition.x = (pos.x / inputElement.clientWidth) * 2 - 1;
            pickPosition.y = (pos.y / inputElement.clientHeight) * -2 + 1;
        }

        function clearPickPosition():Void {
            pickPosition.x = -100000;
            pickPosition.y = -100000;
        }

        inputElement.addEventListener("mousemove", setPickPosition);
        inputElement.addEventListener("mouseout", clearPickPosition);
        inputElement.addEventListener("mouseleave", clearPickPosition);

        inputElement.addEventListener("touchstart", (event:Browser.Event) => {
            event.preventDefault();
            setPickPosition(event.touches[0]);
        }, {passive: false});

        inputElement.addEventListener("touchmove", (event:Browser.Event) => {
            setPickPosition(event.touches[0]);
        });

        inputElement.addEventListener("touchend", clearPickPosition);
    }
}