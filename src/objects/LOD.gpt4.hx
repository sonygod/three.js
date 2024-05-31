import three.math.Vector3;
import three.core.Object3D;

class LOD extends Object3D {

	private var _currentLevel:Int = 0;
	public var levels:Array<{ distance:Float, hysteresis:Float, object:Object3D }>;
	public var isLOD:Bool = true;
	public var autoUpdate:Bool = true;

	public function new() {
		super();
		this.levels = [];
		this.type = 'LOD';
	}

	public function copy(source:LOD):LOD {
		super.copy(source, false);
		for (level in source.levels) {
			this.addLevel(level.object.clone(), level.distance, level.hysteresis);
		}
		this.autoUpdate = source.autoUpdate;
		return this;
	}

	public function addLevel(object:Object3D, distance:Float = 0, hysteresis:Float = 0):LOD {
		distance = Math.abs(distance);
		var l:Int;
		for (l in 0...levels.length) {
			if (distance < levels[l].distance) break;
		}
		levels.splice(l, 0, { distance: distance, hysteresis: hysteresis, object: object });
		this.add(object);
		return this;
	}

	public function getCurrentLevel():Int {
		return this._currentLevel;
	}

	public function getObjectForDistance(distance:Float):Object3D {
		if (levels.length > 0) {
			for (i in 1...levels.length) {
				var levelDistance = levels[i].distance;
				if (levels[i].object.visible) {
					levelDistance -= levelDistance * levels[i].hysteresis;
				}
				if (distance < levelDistance) {
					return levels[i - 1].object;
				}
			}
			return levels[levels.length - 1].object;
		}
		return null;
	}

	public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>):Void {
		if (levels.length > 0) {
			var _v1 = new Vector3();
			_v1.setFromMatrixPosition(this.matrixWorld);
			var distance = raycaster.ray.origin.distanceTo(_v1);
			this.getObjectForDistance(distance).raycast(raycaster, intersects);
		}
	}

	public function update(camera:Dynamic):Void {
		if (levels.length > 1) {
			var _v1 = new Vector3();
			var _v2 = new Vector3();
			_v1.setFromMatrixPosition(camera.matrixWorld);
			_v2.setFromMatrixPosition(this.matrixWorld);
			var distance = _v1.distanceTo(_v2) / camera.zoom;
			levels[0].object.visible = true;
			for (i in 1...levels.length) {
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
			this._currentLevel = i - 1;
			for (i in this._currentLevel + 1...levels.length) {
				levels[i].object.visible = false;
			}
		}
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var data = super.toJSON(meta);
		if (!this.autoUpdate) data.object.autoUpdate = false;
		data.object.levels = [];
		for (level in levels) {
			data.object.levels.push({
				object: level.object.uuid,
				distance: level.distance,
				hysteresis: level.hysteresis
			});
		}
		return data;
	}

}