package three.js.examples.jm.offscreen;

import three.js.*;

class Scene {
    private var camera:PerspectiveCamera;
    private var scene:Scene;
    private var renderer:WebGLRenderer;
    private var group:Group;

    public function new() {}

    public function init(canvas:js.html.CanvasElement, width:Int, height:Int, pixelRatio:Float, path:String) {
        camera = new PerspectiveCamera(40, width / height, 1, 1000);
        camera.position.z = 200;

        scene = new Scene();
        scene.fog = new Fog(0x444466, 100, 400);
        scene.background = new Color(0x444466);

        group = new Group();
        scene.add(group);

        var loader = new ImageBitmapLoader().setPath(path);
        loader.setOptions({ imageOrientation: 'flipY' });
        loader.load('textures/matcaps/matcap-porcelain-white.jpg', function(imageBitmap) {
            var texture = new CanvasTexture(imageBitmap);

            var geometry = new IcosahedronGeometry(5, 8);
            var materials:Array<MeshMatcapMaterial> = [
                new MeshMatcapMaterial({ color: 0xaa24df, matcap: texture }),
                new MeshMatcapMaterial({ color: 0x605d90, matcap: texture }),
                new MeshMatcapMaterial({ color: 0xe04a3f, matcap: texture }),
                new MeshMatcapMaterial({ color: 0xe30456, matcap: texture })
            ];

            for (i in 0...100) {
                var material = materials[i % materials.length];
                var mesh = new Mesh(geometry, material);
                mesh.position.x = random() * 200 - 100;
                mesh.position.y = random() * 200 - 100;
                mesh.position.z = random() * 200 - 100;
                mesh.scale.setScalar(random() + 1);
                group.add(mesh);
            }

            renderer = new WebGLRenderer({ antialias: true, canvas: canvas });
            renderer.setPixelRatio(pixelRatio);
            renderer.setSize(width, height, false);

            animate();
        });
    }

    private function animate() {
        // group.rotation.x = Date.now() / 4000;
        group.rotation.y = -Date.now() / 4000;

        renderer.render(scene, camera);

        if (js.Browser.supported) {
            js.Browser.window.requestAnimationFrame(animate);
        } else {
            // Firefox
        }
    }

    private function random():Float {
        var x = Math.sin(seed++) * 10000;
        return x - Math.floor(x);
    }

    private var seed:Int = 1;
}