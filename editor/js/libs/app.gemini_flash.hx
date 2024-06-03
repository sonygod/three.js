import three.Object3D;
import three.Scene;
import three.Camera;
import three.WebGLRenderer;
import three.ObjectLoader;
import three.Vector2;
import three.Event;

class Player {

	public var renderer:WebGLRenderer;
	public var dom:HtmlElement;
	public var canvas:HtmlElement;
	public var width:Int = 500;
	public var height:Int = 500;

	private var loader:ObjectLoader;
	private var camera:Camera;
	private var scene:Scene;
	private var events:Map<String, Array<Dynamic>>;

	public function new() {
		renderer = new WebGLRenderer(antialias:true);
		renderer.setPixelRatio(window.devicePixelRatio);
		loader = new ObjectLoader();
		dom = HtmlElement.createElement('div');
		dom.appendChild(renderer.domElement);
		canvas = renderer.domElement;
		events = new Map<String, Array<Dynamic>>();
	}

	public function load(json:Dynamic) {

		var project = json.project;

		if (project.shadows != null) renderer.shadowMap.enabled = project.shadows;
		if (project.shadowType != null) renderer.shadowMap.type = project.shadowType;
		if (project.toneMapping != null) renderer.toneMapping = project.toneMapping;
		if (project.toneMappingExposure != null) renderer.toneMappingExposure = project.toneMappingExposure;

		setScene(loader.parse(json.scene));
		setCamera(loader.parse(json.camera));

		events = new Map<String, Array<Dynamic>>();
		events.set('init', []);
		events.set('start', []);
		events.set('stop', []);
		events.set('keydown', []);
		events.set('keyup', []);
		events.set('pointerdown', []);
		events.set('pointerup', []);
		events.set('pointermove', []);
		events.set('update', []);

		var scriptWrapParams = 'player,renderer,scene,camera,init,start,stop,keydown,keyup,pointerdown,pointerup,pointermove,update';

		for (uuid in json.scripts) {

			var object = scene.getObjectByProperty('uuid', uuid, true);

			if (object == null) {

				Sys.println('APP.Player: Script without object.', uuid);
				continue;

			}

			var scripts = json.scripts[uuid];

			for (i in 0...scripts.length) {

				var script = scripts[i];

				var functions:Dynamic = Reflect.callMethod(object, script.source, [this, renderer, scene, camera, events.get('init'), events.get('start'), events.get('stop'), events.get('keydown'), events.get('keyup'), events.get('pointerdown'), events.get('pointerup'), events.get('pointermove'), events.get('update')]);

				for (name in functions) {

					if (functions[name] == null) continue;

					if (events.exists(name)) {

						events.get(name).push(Reflect.makeFunction(functions[name], object));

					} else {

						Sys.println('APP.Player: Event type not supported (', name, ')');

					}

				}

			}

		}

		dispatch(events.get('init'), []);

	}

	public function setCamera(value:Camera) {
		camera = value;
		camera.aspect = width / height;
		camera.updateProjectionMatrix();
	}

	public function setScene(value:Scene) {
		scene = value;
	}

	public function setPixelRatio(pixelRatio:Float) {
		renderer.setPixelRatio(pixelRatio);
	}

	public function setSize(width:Int, height:Int) {
		this.width = width;
		this.height = height;

		if (camera != null) {

			camera.aspect = this.width / this.height;
			camera.updateProjectionMatrix();

		}

		renderer.setSize(width, height);
	}

	private function dispatch(array:Array<Dynamic>, event:Array<Dynamic>) {
		for (i in 0...array.length) {
			array[i](event);
		}
	}

	private var time:Float;
	private var startTime:Float;
	private var prevTime:Float;

	public function play() {
		startTime = prevTime = Date.now();

		window.addEventListener('keydown', onKeyDown);
		window.addEventListener('keyup', onKeyUp);
		window.addEventListener('pointerdown', onPointerDown);
		window.addEventListener('pointerup', onPointerUp);
		window.addEventListener('pointermove', onPointerMove);

		dispatch(events.get('start'), []);

		// TODO: Implement animation loop
	}

	public function stop() {

		window.removeEventListener('keydown', onKeyDown);
		window.removeEventListener('keyup', onKeyUp);
		window.removeEventListener('pointerdown', onPointerDown);
		window.removeEventListener('pointerup', onPointerUp);
		window.removeEventListener('pointermove', onPointerMove);

		dispatch(events.get('stop'), []);

		// TODO: Stop animation loop
	}

	public function render(time:Float) {
		dispatch(events.get('update'), [{time: time * 1000, delta: 0}]);
		renderer.render(scene, camera);
	}

	public function dispose() {
		renderer.dispose();
		camera = null;
		scene = null;
	}

	private function onKeyDown(event:Event) {
		dispatch(events.get('keydown'), [event]);
	}

	private function onKeyUp(event:Event) {
		dispatch(events.get('keyup'), [event]);
	}

	private function onPointerDown(event:Event) {
		dispatch(events.get('pointerdown'), [event]);
	}

	private function onPointerUp(event:Event) {
		dispatch(events.get('pointerup'), [event]);
	}

	private function onPointerMove(event:Event) {
		dispatch(events.get('pointermove'), [event]);
	}

}