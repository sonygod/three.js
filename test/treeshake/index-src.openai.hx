import js.three.*;

class Main {
	static function main() {
		init();
	}

	static function init() {
		camera = new PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.01, 10);
		scene = new Scene();
		renderer = new WebGLRenderer({antialias:true});
		renderer.setSize(window.innerWidth, window.innerHeight);
		renderer.animationLoop = animation;
		document.body.appendChild(renderer.domElement);
	}

	static function animation() {
		renderer.render(scene, camera);
	}

	static var camera:Camera;
	static var scene:Scene;
	static var renderer:WebGLRenderer;
}