import three.Three;
import three.math.Vector3;
import three.objects.Mesh;
import three.materials.MeshPhongMaterial;
import three.geometries.BoxGeometry;
import three.lights.DirectionalLight;
import three.cameras.PerspectiveCamera;
import three.scenes.Scene;
import three.renderers.WebGLRenderer;

class State {
	public var width:Int = 300;
	public var height:Int = 150;
}

var state = new State();

function main(data:Dynamic) {
	var canvas = cast(data.canvas, html.CanvasElement);
	var renderer = new WebGLRenderer({canvas:canvas});

	state.width = canvas.width;
	state.height = canvas.height;

	var fov = 75;
	var aspect = 2;
	var near = 0.1;
	var far = 100;
	var camera = new PerspectiveCamera(fov, aspect, near, far);
	camera.position.z = 4;

	var scene = new Scene();

	{
		var color = 0xFFFFFF;
		var intensity = 1;
		var light = new DirectionalLight(color, intensity);
		light.position.set(-1, 2, 4);
		scene.add(light);
	}

	var boxWidth = 1;
	var boxHeight = 1;
	var boxDepth = 1;
	var geometry = new BoxGeometry(boxWidth, boxHeight, boxDepth);

	function makeInstance(geometry:BoxGeometry, color:Int, x:Float) {
		var material = new MeshPhongMaterial({
			color:color
		});

		var cube = new Mesh(geometry, material);
		scene.add(cube);

		cube.position.x = x;

		return cube;
	}

	var cubes = [
		makeInstance(geometry, 0x44aa88, 0),
		makeInstance(geometry, 0x8844aa, -2),
		makeInstance(geometry, 0xaa8844, 2)
	];

	function resizeRendererToDisplaySize(renderer:WebGLRenderer) {
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

		cubes.forEach(function(cube, ndx) {
			var speed = 1 + ndx * 0.1;
			var rot = time * speed;
			cube.rotation.x = rot;
			cube.rotation.y = rot;
		});

		renderer.render(scene, camera);

		requestAnimationFrame(render);
	}

	requestAnimationFrame(render);
}

function size(data:Dynamic) {
	state.width = cast(data.width, Int);
	state.height = cast(data.height, Int);
}

var handlers = {
	main:main,
	size:size
};

onmessage = function(e:Dynamic) {
	var fn = handlers[cast(e.data.type, String)];
	if (typeof(fn) != "function") {
		throw new Error("no handler for type: " + e.data.type);
	}

	fn(e.data);
};