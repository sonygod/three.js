import three.THREE;
import js.html.Window;
import js.html.Element;

class Main {

    public function new() {
        var canvas:Element = Window.document.querySelector("#c");
        var renderer:THREE.WebGLRenderer = new THREE.WebGLRenderer({antialias: true, canvas: canvas});

        var fov:Float = 75;
        var aspect:Float = 2; // the canvas default
        var near:Float = 0.1;
        var far:Float = 5;
        var camera:THREE.PerspectiveCamera = new THREE.PerspectiveCamera(fov, aspect, near, far);
        camera.position.z = 2;

        var scene:THREE.Scene = new THREE.Scene();

        var color:Int = 0xFFFFFF;
        var intensity:Float = 3;
        var light:THREE.DirectionalLight = new THREE.DirectionalLight(color, intensity);
        light.position.set(-1, 2, 4);
        scene.add(light);

        var boxWidth:Float = 1;
        var boxHeight:Float = 1;
        var boxDepth:Float = 1;
        var geometry:THREE.BoxGeometry = new THREE.BoxGeometry(boxWidth, boxHeight, boxDepth);

        var cubes:Array<THREE.Mesh> = [
            makeInstance(geometry, 0x44aa88, 0),
            makeInstance(geometry, 0x8844aa, -2),
            makeInstance(geometry, 0xaa8844, 2)
        ];

        requestAnimationFrame(render);
    }

    private function makeInstance(geometry:THREE.BoxGeometry, color:Int, x:Float):THREE.Mesh {
        var material:THREE.MeshPhongMaterial = new THREE.MeshPhongMaterial({color: color});

        var cube:THREE.Mesh = new THREE.Mesh(geometry, material);
        scene.add(cube);

        cube.position.x = x;

        return cube;
    }

    private function resizeRendererToDisplaySize(renderer:THREE.WebGLRenderer):Bool {
        var canvas:Element = renderer.domElement;
        var width:Float = canvas.clientWidth;
        var height:Float = canvas.clientHeight;
        var needResize:Bool = canvas.width !== width || canvas.height !== height;
        if (needResize) {
            renderer.setSize(width, height, false);
        }

        return needResize;
    }

    private function render(time:Float):Void {
        time *= 0.001;

        if (resizeRendererToDisplaySize(renderer)) {
            var canvas:Element = renderer.domElement;
            camera.aspect = canvas.clientWidth / canvas.clientHeight;
            camera.updateProjectionMatrix();
        }

        for (ndx in 0...cubes.length) {
            var cube:THREE.Mesh = cubes[ndx];
            var speed:Float = 1 + ndx * 0.1;
            var rot:Float = time * speed;
            cube.rotation.x = rot;
            cube.rotation.y = rot;
        }

        renderer.render(scene, camera);

        requestAnimationFrame(render);
    }
}

var main:Main = new Main();