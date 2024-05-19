import js.three.Three;

class SharedPicking {
    public static var state = {
        width: 300, // canvas default
        height: 150, // canvas default
    };

    public static var pickPosition = { x: 0, y: 0 };

    public static function init(data:Dynamic) {
        var canvas = data.canvas;
        var renderer = new Three.WebGLRenderer({ antialias: true, canvas: canvas });
        state.width = canvas.width;
        state.height = canvas.height;

        var fov = 75;
        var aspect = 2; // the canvas default
        var near = 0.1;
        var far = 100;
        var camera = new Three.PerspectiveCamera(fov, aspect, near, far);
        camera.position.z = 4;

        var scene = new Three.Scene();

        {
            var color = 0xFFFFFF;
            var intensity = 1;
            var light = new Three.DirectionalLight(color, intensity);
            light.position.set(-1, 2, 4);
            scene.add(light);
        }

        var boxWidth = 1;
        var boxHeight = 1;
        var boxDepth = 1;
        var geometry = new Three.BoxGeometry(boxWidth, boxHeight, boxDepth);

        function makeInstance(geometry:Three.Geometry, color:Int, x:Float) {
            var material = new Three.MeshPhongMaterial({ color: color });
            var cube = new Three.Mesh(geometry, material);
            scene.add(cube);
            cube.position.x = x;
            return cube;
        }

        var cubes = [
            makeInstance(geometry, 0x44aa88, 0),
            makeInstance(geometry, 0x8844aa, -2),
            makeInstance(geometry, 0xaa8844, 2),
        ];

        class PickHelper {
            public var raycaster:Three.Raycaster;
            public var pickedObject:Three.Object3D;
            public var pickedObjectSavedColor:Int;

            public function new() {
                raycaster = new Three.Raycaster();
                pickedObject = null;
                pickedObjectSavedColor = 0;
            }

            public function pick(normalizedPosition:Three.Vector2, scene:Three.Scene, camera:Three.Camera, time:Float) {
                if (pickedObject != null) {
                    pickedObject.material.emissive.setHex(pickedObjectSavedColor);
                    pickedObject = null;
                }

                raycaster.setFromCamera(normalizedPosition, camera);
                var intersectedObjects:Array<Three.Intersection> = raycaster.intersectObjects(scene.children);
                if (intersectedObjects.length > 0) {
                    pickedObject = intersectedObjects[0].object;
                    pickedObjectSavedColor = pickedObject.material.emissive.getHex();
                    pickedObject.material.emissive.setHex((time * 8) % 2 > 1 ? 0xFFFF00 : 0xFF0000);
                }
            }
        }

        var pickHelper = new PickHelper();

        function resizeRendererToDisplaySize(renderer:Three.WebGLRenderer):Bool {
            var canvas:js.html.CanvasElement = renderer.domElement;
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

            pickHelper.pick(pickPosition, scene, camera, time);

            renderer.render(scene, camera);

            js.Browser.requestAnimationFrame(render);
        }

        js.Browser.requestAnimationFrame(render);
    }
}