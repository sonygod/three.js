import three.addons.controls.OrbitControls;
import three.addons.helpers.ViewHelper;
import three.nodes.MeshBasicNodeMaterial;
import three.nodes.vec4;
import three.PerspectiveCamera;
import three.Scene;
import three.Mesh;
import three.DoubleSide;
import three.SphereGeometry;
import three.BoxGeometry;
import three.PlaneGeometry;
import three.TorusKnotGeometry;
import three.addons.renderers.webgpu.WebGPURenderer;
import DataTypeLib.setInputAestheticsFromType;

typedef SceneDict = Map<String, Scene>;

var sceneDict:SceneDict = new Map();

function getScene(name:String):Scene {
	var scene:Scene = sceneDict.get(name);
	if (scene == null) {
		scene = new Scene();
		switch (name) {
			case 'box':
				var box:Mesh = new Mesh(new BoxGeometry(1.3, 1.3, 1.3));
				scene.add(box);
				break;
			case 'sphere':
				var sphere:Mesh = new Mesh(new SphereGeometry(1, 32, 16));
				scene.add(sphere);
				break;
			case 'plane':
			case 'sprite':
				var plane:Mesh = new Mesh(new PlaneGeometry(2, 2));
				scene.add(plane);
				break;
			case 'torus':
				var torus:Mesh = new Mesh(new TorusKnotGeometry(0.7, 0.1, 100, 16));
				scene.add(torus);
				break;
		}
		sceneDict.set(name, scene);
	}
	return scene;
}

class PreviewEditor extends BaseNodeEditor {
	private var width:Int = 300;
	private var height:Int = 300;
	private var material:MeshBasicNodeMaterial = new MeshBasicNodeMaterial();
	private var previewElement:Element;
	private var sceneInput:SelectInput;
	private var inputElement:LabelElement;
	private var canvas:Html.CanvasElement;
	private var renderer:WebGPURenderer;
	private var camera:PerspectiveCamera;
	private var controls:OrbitControls;
	private var viewHelper:ViewHelper;

	public function new() {
		super('Preview', null, width);
		material.colorNode = vec4(0, 0, 0, 1);
		material.side = DoubleSide;
		material.transparent = true;

		previewElement = new Element();
		previewElement.dom.style.paddingTop = 0;
		previewElement.dom.style.paddingBottom = 0;
		previewElement.dom.style.paddingLeft = 0;
		previewElement.dom.style.paddingRight = '14px';

		sceneInput = new SelectInput([
			{name: 'Box', value: 'box'},
			{name: 'Sphere', value: 'sphere'},
			{name: 'Plane', value: 'plane'},
			{name: 'Sprite', value: 'sprite'},
			{name: 'Torus', value: 'torus'}
		], 'box');

		inputElement = setInputAestheticsFromType(new LabelElement('Input'), 'Color').onConnect(function() {
			material.colorNode = inputElement.getLinkedObject() || vec4(0, 0, 0, 1);
			material.dispose();
		}, true);

		canvas = Html.createCanvas();
		canvas.style.position = 'absolute';
		previewElement.dom.appendChild(canvas);
		previewElement.setHeight(height);

		previewElement.dom.addEventListener('wheel', function(e) e.stopPropagation());

		renderer = new WebGPURenderer({
			canvas: canvas,
			alpha: true,
			antialias: true
		});

		renderer.autoClear = false;
		renderer.setSize(width, height, true);
		renderer.setPixelRatio(window.devicePixelRatio);

		camera = new PerspectiveCamera(45, width / height, 0.1, 100);
		camera.aspect = width / height;
		camera.updateProjectionMatrix();
		camera.position.set(-2, 2, 2);
		camera.lookAt(0, 0, 0);

		controls = new OrbitControls(camera, previewElement.dom);
		controls.enableKeys = false;
		controls.update();

		viewHelper = new ViewHelper(camera, previewElement.dom);

		this.sceneInput = sceneInput;
		this.viewHelper = viewHelper;
		this.material = material;
		this.camera = camera;
		this.renderer = renderer;

		this.add(inputElement)
			.add(new LabelElement('Object').add(sceneInput))
			.add(previewElement);
	}

	public function setEditor(editor:Editor) {
		super.setEditor(editor);
		this.updateAnimationRequest();
	}

	public function updateAnimationRequest() {
		if (this.editor != null) {
			requestAnimationFrame(function() this.update());
		}
	}

	public async function update() {
		var {viewHelper, material, renderer, camera, sceneInput} = this;
		this.updateAnimationRequest();

		var sceneName:String = sceneInput.getValue();
		var scene:Scene = getScene(sceneName);
		var mesh:Mesh = scene.children[0];

		mesh.material = material;

		if (sceneName == 'sprite') {
			mesh.lookAt(camera.position);
		}

		await renderer.clearAsync();
		await renderer.renderAsync(scene, camera);

		viewHelper.render(renderer);
	}
}