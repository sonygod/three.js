import three.THREE;

var camera:THREE.PerspectiveCamera;
var scene:THREE.Scene;
var renderer:THREE.WebGLRenderer;
var group:THREE.Group;

function init(canvas:js.html.CanvasElement, width:Float, height:Float, pixelRatio:Float, path:String) {

	camera = new THREE.PerspectiveCamera(40, width / height, 1, 1000);
	camera.position.z = 200;

	scene = new THREE.Scene();
	scene.fog = new THREE.Fog(0x444466, 100, 400);
	scene.background = new THREE.Color(0x444466);

	group = new THREE.Group();
	scene.add(group);

	var loader = new THREE.ImageBitmapLoader().setPath(path);
	loader.setOptions({imageOrientation: 'flipY'});
	loader.load('textures/matcaps/matcap-porcelain-white.jpg', function(imageBitmap) {

		var texture = new THREE.CanvasTexture(imageBitmap);

		var geometry = new THREE.IcosahedronGeometry(5, 8);
		var materials = [
			new THREE.MeshMatcapMaterial({color: 0xaa24df, matcap: texture}),
			new THREE.MeshMatcapMaterial({color: 0x605d90, matcap: texture}),
			new THREE.MeshMatcapMaterial({color: 0xe04a3f, matcap: texture}),
			new THREE.MeshMatcapMaterial({color: 0xe30456, matcap: texture})
		];

		for (i in 0...100) {

			var material = materials[Std.int(i % materials.length)];
			var mesh = new THREE.Mesh(geometry, material);
			mesh.position.x = random() * 200 - 100;
			mesh.position.y = random() * 200 - 100;
			mesh.position.z = random() * 200 - 100;
			mesh.scale.setScalar(random() + 1);
			group.add(mesh);

		}

		renderer = new THREE.WebGLRenderer({antialias: true, canvas: canvas});
		renderer.setPixelRatio(pixelRatio);
		renderer.setSize(width, height, false);

		animate();

	});

}

function animate() {

	group.rotation.y = - Date.now() / 4000;

	renderer.render(scene, camera);

	if (js.Browser.requestAnimationFrame) {

		js.Browser.requestAnimationFrame(animate);

	} else {

		// Firefox

	}

}

// PRNG

var seed = 1;

function random() {

	var x = Math.sin(seed ++) * 10000;

	return x - Math.floor(x);

}

@:keep
@:noCompletion
@:extern
class js {
    public static var Browser:Browser;
    public static var html:Html;
}

@:keep
@:noCompletion
@:extern
class js.html {
    public extern class CanvasElement extends js.html.Element {
    }
}

@:keep
@:noCompletion
@:extern
class js.Browser {
    public static extern function requestAnimationFrame(callback:Dynamic->Void):Int;
}

@:keep
@:noCompletion
@:extern
class js.html.Element {
}