import three.EventDispatcher;
import three.Matrix4;
import three.Plane;
import three.Raycaster;
import three.Vector2;
import three.Vector3;
import js.Browser;

class DragControls extends EventDispatcher {

	static var _plane = new Plane();
	static var _raycaster = new Raycaster();

	static var _pointer = new Vector2();
	static var _offset = new Vector3();
	static var _diff = new Vector2();
	static var _previousPointer = new Vector2();
	static var _intersection = new Vector3();
	static var _worldPosition = new Vector3();
	static var _inverseMatrix = new Matrix4();

	static var _up = new Vector3();
	static var _right = new Vector3();

	public var mode(default, null):String;
	public var rotateSpeed(default, null):Float;
	public var enabled(default, null):Bool;
	public var recursive(default, null):Bool;
	public var transformGroup(default, null):Bool;

	var _objects:Array<Dynamic>;
	var _camera:Dynamic;
	var _domElement:Dynamic;
	var _selected:Dynamic;
	var _hovered:Dynamic;
	var _intersections:Array<Dynamic>;

	public function new(_objects:Array<Dynamic>, _camera:Dynamic, _domElement:Dynamic) {
		super();

		this._objects = _objects;
		this._camera = _camera;
		this._domElement = _domElement;

		_domElement.style.touchAction = 'none'; // disable touch scroll

		_selected = null;
		_hovered = null;

		_intersections = [];

		this.mode = 'translate';
		this.rotateSpeed = 1;

		this.enabled = true;
		this.recursive = true;
		this.transformGroup = false;

		activate();
	}

	function activate():Void {
		_domElement.addEventListener('pointermove', onPointerMove);
		_domElement.addEventListener('pointerdown', onPointerDown);
		_domElement.addEventListener('pointerup', onPointerCancel);
		_domElement.addEventListener('pointerleave', onPointerCancel);
	}

	function deactivate():Void {
		_domElement.removeEventListener('pointermove', onPointerMove);
		_domElement.removeEventListener('pointerdown', onPointerDown);
		_domElement.removeEventListener('pointerup', onPointerCancel);
		_domElement.removeEventListener('pointerleave', onPointerCancel);

		_domElement.style.cursor = '';
	}

	public function dispose():Void {
		deactivate();
	}

	public function getObjects():Array<Dynamic> {
		return _objects;
	}

	public function setObjects(objects:Array<Dynamic>):Void {
		_objects = objects;
	}

	public function getRaycaster():Dynamic {
		return _raycaster;
	}

	function onPointerMove(event:Dynamic):Void {
		if (!enabled)
			return;

		updatePointer(event);

		_raycaster.setFromCamera(_pointer, _camera);

		if (_selected != null) {
			if (mode == 'translate') {
				if (_raycaster.ray.intersectPlane(_plane, _intersection)) {
					_selected.position.copy(_intersection.sub(_offset).applyMatrix4(_inverseMatrix));
				}
			} else if (mode == 'rotate') {
				_diff.subVectors(_pointer, _previousPointer).multiplyScalar(rotateSpeed);
				untyped _selected.rotateOnWorldAxis(_up, _diff.x);
				untyped _selected.rotateOnWorldAxis(_right.normalize(), -_diff.y);
			}

			dispatchEvent({type: 'drag', object: _selected});

			_previousPointer.copy(_pointer);
		} else {
			// hover support
			if (event.pointerType == 'mouse' || event.pointerType == 'pen') {
				_intersections = [];

				_raycaster.setFromCamera(_pointer, _camera);
				_raycaster.intersectObjects(_objects, recursive, _intersections);

				if (_intersections.length > 0) {
					var object = _intersections[0].object;

					_plane.setFromNormalAndCoplanarPoint(_camera.getWorldDirection(_plane.normal), _worldPosition.setFromMatrixPosition(object.matrixWorld));

					if (_hovered != object && _hovered != null) {
						dispatchEvent({type: 'hoveroff', object: _hovered});

						_domElement.style.cursor = 'auto';
						_hovered = null;
					}

					if (_hovered != object) {
						dispatchEvent({type: 'hoveron', object: object});

						_domElement.style.cursor = 'pointer';
						_hovered = object;
					}
				} else {
					if (_hovered != null) {
						dispatchEvent({type: 'hoveroff', object: _hovered});

						_domElement.style.cursor = 'auto';
						_hovered = null;
					}
				}
			}
		}

		_previousPointer.copy(_pointer);
	}

	function onPointerDown(event:Dynamic):Void {
		if (!enabled)
			return;

		updatePointer(event);

		_intersections = [];

		_raycaster.setFromCamera(_pointer, _camera);
		_raycaster.intersectObjects(_objects, recursive, _intersections);

		if (_intersections.length > 0) {
			if (transformGroup) {
				// look for the outermost group in the object's upper hierarchy
				_selected = findGroup(_intersections[0].object);
			} else {
				_selected = _intersections[0].object;
			}

			_plane.setFromNormalAndCoplanarPoint(_camera.getWorldDirection(_plane.normal),
				_worldPosition.setFromMatrixPosition(_selected.matrixWorld));

			if (_raycaster.ray.intersectPlane(_plane, _intersection)) {
				if (mode == 'translate') {
					_inverseMatrix.copy(_selected.parent.matrixWorld).invert();
					_offset.copy(_intersection).sub(_worldPosition.setFromMatrixPosition(_selected.matrixWorld));
				} else if (mode == 'rotate') {
					// the controls only support Y+ up
					_up.set(0, 1, 0).applyQuaternion(_camera.quaternion).normalize();
					_right.set(1, 0, 0).applyQuaternion(_camera.quaternion).normalize();
				}
			}

			_domElement.style.cursor = 'move';

			dispatchEvent({type: 'dragstart', object: _selected});
		}

		_previousPointer.copy(_pointer);
	}

	function onPointerCancel(event:Dynamic):Void {
		if (!enabled)
			return;

		if (_selected != null) {
			dispatchEvent({type: 'dragend', object: _selected});

			_selected = null;
		}

		_domElement.style.cursor = (_hovered != null) ? 'pointer' : 'auto';
	}

	function updatePointer(event:Dynamic):Void {
		var rect = _domElement.getBoundingClientRect();

		_pointer.x = (event.clientX - rect.left) / rect.width * 2 - 1;
		_pointer.y = -(event.clientY - rect.top) / rect.height * 2 + 1;
	}

	function findGroup(obj:Dynamic, group:Dynamic = null):Dynamic {
		if (untyped obj.isGroup)
			group = obj;

		if (obj.parent == null)
			return group;

		return findGroup(obj.parent, group);
	}
}