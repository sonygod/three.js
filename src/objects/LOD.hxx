import three.math.Vector3;
import three.core.Object3D;

class LOD extends Object3D {

	var _currentLevel:Int;
	var levels:Array<{distance:Float, hysteresis:Float, object:Object3D}>;
	var isLOD:Bool = true;
	var autoUpdate:Bool;

	public function new() {
		super();
		_currentLevel = 0;
		levels = [];
		autoUpdate = true;
		type = 'LOD';
	}

	public function copy(source:LOD):LOD {
		super.copy(source, false);
		var levels = source.levels;
		for (i in levels) {
			var level = levels[i];
			this.addLevel(level.object.clone(), level.distance, level.hysteresis);
		}
		autoUpdate = source.autoUpdate;
		return this;
	}

	public function addLevel(object:Object3D, distance:Float = 0, hysteresis:Float = 0):LOD {
		distance = Math.abs(distance);
		var levels = this.levels;
		var l:Int;
		for (l = 0; l < levels.length; l++) {
			if (distance < levels[l].distance) {
				break;
			}
		}
		levels.splice(l, 0, {distance: distance, hysteresis: hysteresis, object: object});
		this.add(object);
		return this;
	}

	public function getCurrentLevel():Int {
		return _currentLevel;
	}

	public function getObjectForDistance(distance:Float):Object3D {
		var levels = this.levels;
		if (levels.length > 0) {
			var i:Int;
			var l:Int = levels.length;
			for (i = 1; i < l; i++) {
				var levelDistance = levels[i].distance;
				if (levels[i].object.visible) {
					levelDistance -= levelDistance * levels[i].hysteresis;
				}
				if (distance < levelDistance) {
					break;
				}
			}
			return levels[i - 1].object;
		}
		return null;
	}

	public function raycast(raycaster:Raycaster, intersects:Array<Intersection>):Void {
		var levels = this.levels;
		if (levels.length > 0) {
			var _v1 = new Vector3();
			_v1.setFromMatrixPosition(this.matrixWorld);
			var distance = raycaster.ray.origin.distanceTo(_v1);
			this.getObjectForDistance(distance).raycast(raycaster, intersects);
		}
	}

	public function update(camera:Camera):Void {
		var levels = this.levels;
		if (levels.length > 1) {
			var _v1 = new Vector3();
			var _v2 = new Vector3();
			_v1.setFromMatrixPosition(camera.matrixWorld);
			_v2.setFromMatrixPosition(this.matrixWorld);
			var distance = _v1.distanceTo(_v2) / camera.zoom;
			levels[0].object.visible = true;
			var i:Int;
			var l:Int = levels.length;
			for (i = 1; i < l; i++) {
				var levelDistance = levels[i].distance;
				if (levels[i].object.visible) {
					levelDistance -= levelDistance * levels[i].hysteresis;
				}
				if (distance >= levelDistance) {
					levels[i - 1].object.visible = false;
					levels[i].object.visible = true;
				} else {
					break;
				}
			}
			_currentLevel = i - 1;
			for (; i < l; i++) {
				levels[i].object.visible = false;
			}
		}
	}

	public function toJSON(meta:Any):Any {
		var data = super.toJSON(meta);
		if (autoUpdate == false) data.object.autoUpdate = false;
		data.object.levels = [];
		var levels = this.levels;
		for (i in levels) {
			var level = levels[i];
			data.object.levels.push({
				object: level.object.uuid,
				distance: level.distance,
				hysteresis: level.hysteresis
			});
		}
		return data;
	}
}