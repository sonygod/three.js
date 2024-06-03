import three.js.Lib;

class SharedCubes {
    public static var state = {
        width: 300, // canvas default
        height: 150  // canvas default
    };

    public static function init(data:Any) {
        var canvas = data.canvas;
        var renderer = new three.js.Renderer.WebGLRenderer({
            antialias: true,
            canvas: canvas
        });
        state.width = canvas.width;
        state.height = canvas.height;

        var fov = 75;
        var aspect = 2; // the canvas default
        var near = 0.1;
        var far = 100;
        var camera = new three.js.Camera.PerspectiveCamera(fov, aspect, near, far);
        camera.position.z = 4;

        var scene = new three.js.Scene();

        {
            var color = 0xFFFFFF;
            var intensity = 1;
            var light = new three.js.Light.DirectionalLight(color, intensity);
            light.position.set(-1, 2, 4);
            scene.add(light);
        }

        var boxWidth = 1;
        var boxHeight = 1;
        var boxDepth = 1;
        var geometry = new three.js.Geometry.BoxGeometry(boxWidth, boxHeight, boxDepth);

        function makeInstance(geometry:Any, color:Int, x:Float) {
            var material = new three.js.Material.MeshPhongMaterial({
                color: color
            });
            var cube = new three.js.Objects.Mesh(geometry, material);
            scene.add(cube);
            cube.position.x = x;
            return cube;
        }

        var cubes = [
            makeInstance(geometry, 0x44aa88, 0),
            makeInstance(geometry, 0x8844aa, -2),
            makeInstance(geometry, 0xaa8844, 2)
        ];

        function resizeRendererToDisplaySize(renderer:Any) {
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
}