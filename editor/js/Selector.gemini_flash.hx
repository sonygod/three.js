import three.core.Object3D;
import three.math.Raycaster;
import three.math.Vector2;

class Selector {

	public var editor(get, never):Editor;
	public var signals(get, never):Signals;

	static var mouse = new Vector2();
	static var raycaster = new Raycaster();

	public function new(editor:Editor) {
		this.editor = editor;
		this.signals = editor.signals;

		signals.intersectionsDetected.add((intersects) -> {
			if (intersects.length > 0) {
				var object:Dynamic = intersects[0].object;
				if (object.userData.object != null) {
					this.select(object.userData.object);
				} else {
					this.select(object);
				}
			} else {
				this.select(null);
			}
		});
	}

	function getIntersects(raycaster:Raycaster):Array<Dynamic> {
		var objects:Array<Dynamic> = [];
		editor.scene.traverseVisible(function(child) {
			objects.push(child);
		});
		editor.sceneHelpers.traverseVisible(function(child) {
			if (child.name == "picker")
				objects.push(child);
		});
		return raycaster.intersectObjects(objects, false);
	}

	public function getPointerIntersects(point:{x:Float, y:Float}, camera:Dynamic):Array<Dynamic> {
		mouse.set((point.x * 2) - 1, -(point.y * 2) + 1);
		raycaster.setFromCamera(mouse, camera);
		return getIntersects(raycaster);
	}

	public function select(object:Object3D):Void {
		if (editor.selected == object)
			return;

		var uuid:String = null;
		if (object != null) {
			uuid = object.uuid;
		}

		editor.selected = object;
		editor.config.setKey("selected", uuid);
		signals.objectSelected.dispatch(object);
	}

	public function deselect():Void {
		select(null);
	}

	inline function get_editor():Editor {
		return this.editor;
	}

	inline function get_signals():Signals {
		return this.signals;
	}
}

#if !display
// Placeholder types
typedef Editor = {
	scene:Dynamic,
	sceneHelpers:Dynamic,
	selected:Dynamic,
	config:Dynamic,
	signals:Signals
}
typedef Signals = {
	intersectionsDetected:Dynamic,
	objectSelected:Dynamic,
	add:(Dynamic) -> Void,
	dispatch:(Dynamic) -> Void
}
#end