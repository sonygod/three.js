import js.Browser;
import js.html.CanvasElement;
import three.Three;

class SharedPicking {

    static var state: {width: Int, height: Int} = {width: 300, height: 150};
    static var pickPosition: {x: Float, y: Float} = {x: 0.0, y: 0.0};

    static function init(data: Dynamic) {
        var canvas: CanvasElement = data.canvas;
        var renderer = new Three.WebGLRenderer({antialias: true, canvas: canvas});

        state.width = canvas.width;
        state.height = canvas.height;

        var fov = 75;
        var aspect = 2;
        var near = 0.1;
        var far = 100;
        var camera = new Three.PerspectiveCamera(fov, aspect, near, far);
        camera.position.z = 4;

        var scene = new Three.Scene();

        var color = 0xFFFFFF;
        var intensity = 1;
        var light = new Three.DirectionalLight(color, intensity);
        light.position.set(- 1, 2, 4);
        scene.add(light);

        var boxWidth = 1;
        var boxHeight = 1;
        var boxDepth = 1;
        var geometry = new Three.BoxGeometry(boxWidth, boxHeight, boxDepth);

        function makeInstance(geometry: Three.BoxGeometry, color: Int, x: Float): Three.Mesh {
            var material = new Three.MeshPhongMaterial({color: color});

            var cube = new Three.Mesh(geometry, material);
            scene.add(cube);

            cube.position.x = x;

            return cube;
        }

        var cubes = [
            makeInstance(geometry, 0x44aa88, 0.0),
            makeInstance(geometry, 0x8844aa, - 2.0),
            makeInstance(geometry, 0xaa8844, 2.0)
        ];

        class PickHelper {
            var raycaster: Three.Raycaster;
            var pickedObject: Three.Mesh;
            var pickedObjectSavedColor: Int;

            new() {
                this.raycaster = new Three.Raycaster();
                this.pickedObject = null;
                this.pickedObjectSavedColor = 0;
            }

            function pick(normalizedPosition: {x: Float, y: Float}, scene: Three.Scene, camera: Three.PerspectiveCamera, time: Float) {
                if (this.pickedObject != null) {
                    this.pickedObject.material.emissive.setHex(this.pickedObjectSavedColor);
                    this.pickedObject = null;
                }

                this.raycaster.setFromCamera(normalizedPosition, camera);
                var intersectedObjects = this.raycaster.intersectObjects(scene.children);
                if (intersectedObjects.length > 0) {
                    this.pickedObject = intersectedObjects[0].object;
                    this.pickedObjectSavedColor = this.pickedObject.material.emissive.getHex();
                    this.pickedObject.material.emissive.setHex((Std.int(time * 8) % 2 > 1) ? 0xFFFF00 : 0xFF0000);
                }
            }
        }

        var pickHelper = new PickHelper();

        function resizeRendererToDisplaySize(renderer: Three.WebGLRenderer): Bool {
            var canvas = renderer.domElement;
            var width = state.width;
            var height = state.height;
            var needResize = canvas.width != width || canvas.height != height;
            if (needResize) {
                renderer.setSize(width, height, false);
            }

            return needResize;
        }

        function render(time: Float) {
            time *= 0.001;

            if (resizeRendererToDisplaySize(renderer)) {
                camera.aspect = state.width / state.height;
                camera.updateProjectionMatrix();
            }

            for (cube in cubes) {
                var ndx = cubes.indexOf(cube);
                var speed = 1 + ndx * .1;
                var rot = time * speed;
                cube.rotation.x = rot;
                cube.rotation.y = rot;
            }

            pickHelper.pick(pickPosition, scene, camera, time);

            renderer.render(scene, camera);

            Browser.requestAnimationFrame(render);
        }

        Browser.requestAnimationFrame(render);
    }
}