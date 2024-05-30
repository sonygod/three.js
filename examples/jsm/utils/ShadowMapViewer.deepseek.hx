import three.DoubleSide;
import three.LinearFilter;
import three.Mesh;
import three.MeshBasicMaterial;
import three.OrthographicCamera;
import three.PlaneGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.Texture;
import three.UniformsUtils;
import three.examples.jsm.shaders.UnpackDepthRGBAShader;

class ShadowMapViewer {

	var enabled:Bool = true;
	var size:Size = new Size();
	var position:Position = new Position();

	public function new(light:Dynamic) {

		var scope = this;
		var doRenderLabel = (light.name != null && light.name != "");
		var userAutoClearSetting:Dynamic;

		var frame = {
			x: 10,
			y: 10,
			width: 256,
			height: 256
		};

		var camera = new OrthographicCamera(window.innerWidth / -2, window.innerWidth / 2, window.innerHeight / 2, window.innerHeight / -2, 1, 10);
		camera.position.set(0, 0, 2);
		var scene = new Scene();

		var shader = UnpackDepthRGBAShader;

		var uniforms = UniformsUtils.clone(shader.uniforms);
		var material = new ShaderMaterial({
			uniforms: uniforms,
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader
		});
		var plane = new PlaneGeometry(frame.width, frame.height);
		var mesh = new Mesh(plane, material);

		scene.add(mesh);

		var labelCanvas:Dynamic;
		var labelMesh:Dynamic;

		if (doRenderLabel) {

			labelCanvas = document.createElement('canvas');

			var context = labelCanvas.getContext('2d');
			context.font = 'Bold 20px Arial';

			var labelWidth = context.measureText(light.name).width;
			labelCanvas.width = labelWidth;
			labelCanvas.height = 25;

			context.font = 'Bold 20px Arial';
			context.fillStyle = 'rgba(255, 0, 0, 1)';
			context.fillText(light.name, 0, 20);

			var labelTexture = new Texture(labelCanvas);
			labelTexture.magFilter = LinearFilter;
			labelTexture.minFilter = LinearFilter;
			labelTexture.needsUpdate = true;

			var labelMaterial = new MeshBasicMaterial({map: labelTexture, side: DoubleSide});
			labelMaterial.transparent = true;

			var labelPlane = new PlaneGeometry(labelCanvas.width, labelCanvas.height);
			labelMesh = new Mesh(labelPlane, labelMaterial);

			scene.add(labelMesh);

		}

		function resetPosition() {

			scope.position.set(scope.position.x, scope.position.y);

		}

		this.size.set = function(width:Float, height:Float) {

			this.width = width;
			this.height = height;

			mesh.scale.set(this.width / frame.width, this.height / frame.height, 1);

			resetPosition();

		};

		this.position.set = function(x:Float, y:Float) {

			this.x = x;
			this.y = y;

			var width = scope.size.width;
			var height = scope.size.height;

			mesh.position.set(-window.innerWidth / 2 + width / 2 + this.x, window.innerHeight / 2 - height / 2 - this.y, 0);

			if (doRenderLabel) labelMesh.position.set(mesh.position.x, mesh.position.y - scope.size.height / 2 + labelCanvas.height / 2, 0);

		};

		this.render = function(renderer:Dynamic) {

			if (this.enabled) {

				uniforms.tDiffuse.value = light.shadow.map.texture;

				userAutoClearSetting = renderer.autoClear;
				renderer.autoClear = false;
				renderer.clearDepth();
				renderer.render(scene, camera);
				renderer.autoClear = userAutoClearSetting;

			}

		};

		this.updateForWindowResize = function() {

			if (this.enabled) {

				camera.left = window.innerWidth / -2;
				camera.right = window.innerWidth / 2;
				camera.top = window.innerHeight / 2;
				camera.bottom = window.innerHeight / -2;
				camera.updateProjectionMatrix();

				this.update();

			}

		};

		this.update = function() {

			this.position.set(this.position.x, this.position.y);
			this.size.set(this.size.width, this.size.height);

		};

		this.update();

	}

}

class Size {
	public var width(default, null):Float;
	public var height(default, null):Float;
	public function set(width:Float, height:Float):Void {}
}

class Position {
	public var x(default, null):Float;
	public var y(default, null):Float;
	public function set(x:Float, y:Float):Void {}
}