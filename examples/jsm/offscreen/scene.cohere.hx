import js.three.*;

class Main {
    static function main() {
        var canvas = cast CanvasElement(window.document.getElementById("canvas"));
        var width = Std.int(window.innerWidth);
        var height = Std.int(window.innerHeight);
        var pixelRatio = Std.int(window.devicePixelRatio);
        var path = "models/";

        var camera:PerspectiveCamera;
        var scene:Scene;
        var renderer:WebGLRenderer;
        var group:Group;

        function init() {
            camera = new PerspectiveCamera(40, width / height, 1, 1000);
            camera.position.z = 200;

            scene = new Scene();
            scene.fog = new Fog(0x444466, 100, 400);
            scene.background = new Color(0x444466);

            group = new Group();
            scene.add(group);

            var loader = new ImageBitmapLoader();
            loader.setPath(path);
            loader.setOptions({ imageOrientation: "flipY" });
            loader.load("textures/matcaps/matcap-porcelain-white.jpg", function(imageBitmap) {
                var texture = new CanvasTexture(imageBitmap);

                var geometry = new IcosahedronGeometry(5, 8);
                var materials = [
                    new MeshMatcapMaterial({ color: 0xaa24df, matcap: texture }),
                    new MeshMatcapMaterial({ color: 0x605d90, matcap: texture }),
                    new MeshMatcapMaterial({ color: 0xe04a3f, matcap: texture }),
                    new MeshMatcapMaterial({ color: 0xe30456, matcap: texture })
                ];

                for (i in 0...100) {
                    var material = materials[i % materials.length];
                    var mesh = new Mesh(geometry, material);
                    mesh.position.x = Math.random() * 200 - 100;
                    mesh.position.y = Math.random() * 200 - 100;
                    mesh.position.z = Math.random() * 200 - 100;
                    mesh.scale.setScalar(Math.random() + 1);
                    group.add(mesh);
                }

                renderer = new WebGLRenderer({ antialias: true, canvas: canvas });
                renderer.setPixelRatio(pixelRatio);
                renderer.setSize(width, height, false);

                animate();
            });
        }

        function animate() {
            group.rotation.y = -Date.now() / 4000;

            renderer.render(scene, camera);

            window.requestAnimationFrame(animate);
        }

        function random() {
            var x = Math.sin(seed++) * 10000;
            return x - Std.int(x);
        }

        init();
    }
}

Main.main();