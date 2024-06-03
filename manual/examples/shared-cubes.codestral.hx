import three.THREE;

class SharedCubes {
    public static var state:Object = {
        width: 300,
        height: 150,
    };

    public static function init(data:Object) {
        var canvas:HtmlCanvasElement = data.canvas;
        var renderer = new THREE.WebGLRenderer({antialias: true, canvas: canvas});

        state.width = canvas.offsetWidth;
        state.height = canvas.offsetHeight;

        var fov = 75;
        var aspect = 2;
        var near = 0.1;
        var far = 100;
        var camera = new THREE.PerspectiveCamera(fov, aspect, near, far);
        camera.position.z = 4;

        var scene = new THREE.Scene();

        var color = 0xFFFFFF;
        var intensity = 1;
        var light = new THREE.DirectionalLight(color, intensity);
        light.position.set(-1, 2, 4);
        scene.add(light);

        var boxWidth = 1;
        var boxHeight = 1;
        var boxDepth = 1;
        var geometry = new THREE.BoxGeometry(boxWidth, boxHeight, boxDepth);

        function makeInstance(geometry:THREE.BoxGeometry, color:Int, x:Float):THREE.Mesh {
            var material = new THREE.MeshPhongMaterial({color: color});
            var cube = new THREE.Mesh(geometry, material);
            scene.add(cube);
            cube.position.x = x;
            return cube;
        }

        var cubes = [
            makeInstance(geometry, 0x44aa88, 0),
            makeInstance(geometry, 0x8844aa, -2),
            makeInstance(geometry, 0xaa8844, 2),
        ];

        function resizeRendererToDisplaySize(renderer:THREE.WebGLRenderer):Bool {
            var canvas = renderer.domElement;
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

            for (i in 0...cubes.length) {
                var cube = cubes[i];
                var speed = 1 + i * 0.1;
                var rot = time * speed;
                cube.rotation.x = rot;
                cube.rotation.y = rot;
            }

            renderer.render(scene, camera);
            js.Browser.window.requestAnimationFrame(render);
        }

        js.Browser.window.requestAnimationFrame(render);
    }
}