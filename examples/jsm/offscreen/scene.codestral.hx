import js.Browser.window;
import three.Three;

var camera:Dynamic, scene:Dynamic, renderer:Dynamic, group:Dynamic;

function init(canvas:Dynamic, width:Float, height:Float, pixelRatio:Float, path:String):Void {

    camera = new Three.PerspectiveCamera(40, width / height, 1, 1000);
    camera.position.z = 200;

    scene = new Three.Scene();
    scene.fog = new Three.Fog(0x444466, 100, 400);
    scene.background = new Three.Color(0x444466);

    group = new Three.Group();
    scene.add(group);

    var loader = new Three.ImageBitmapLoader().setPath(path);
    loader.setOptions({imageOrientation: "flipY"});
    loader.load("textures/matcaps/matcap-porcelain-white.jpg", function (imageBitmap:Dynamic) {

        var texture = new Three.CanvasTexture(imageBitmap);

        var geometry = new Three.IcosahedronGeometry(5, 8);
        var materials = [
            new Three.MeshMatcapMaterial({color: 0xaa24df, matcap: texture}),
            new Three.MeshMatcapMaterial({color: 0x605d90, matcap: texture}),
            new Three.MeshMatcapMaterial({color: 0xe04a3f, matcap: texture}),
            new Three.MeshMatcapMaterial({color: 0xe30456, matcap: texture})
        ];

        for (var i = 0; i < 100; i++) {

            var material = materials[i % materials.length];
            var mesh = new Three.Mesh(geometry, material);
            mesh.position.x = random() * 200 - 100;
            mesh.position.y = random() * 200 - 100;
            mesh.position.z = random() * 200 - 100;
            mesh.scale.setScalar(random() + 1);
            group.add(mesh);

        }

        renderer = new Three.WebGLRenderer({antialias: true, canvas: canvas});
        renderer.setPixelRatio(pixelRatio);
        renderer.setSize(width, height, false);

        animate();

    });

}

function animate():Void {

    group.rotation.y = -Date.now() / 4000;

    renderer.render(scene, camera);

    if (window.requestAnimationFrame != null) {

        window.requestAnimationFrame(animate);

    } else {

        // Firefox

    }

}

var seed = 1;

function random():Float {

    var x = Math.sin(seed++) * 10000;

    return x - Math.floor(x);

}

export function init_haxe(canvas:Dynamic, width:Float, height:Float, pixelRatio:Float, path:String):Void {
    init(canvas, width, height, pixelRatio, path);
}