import haxe.extern.Either;
import three.core.Object3D;
import three.math.Vector3;

class LOD extends Object3D {
	public var levels:Array<{ distance:Float, hysteresis:Float, object:Object3D }> = [];
	public var _currentLevel:Int = 0;
	public var autoUpdate:Bool = true;

	public function new() {
		super();
		this.type = "LOD";
		this.isLOD = true;
	}

	public function copy(source:LOD):LOD {
		super.copy(source, false);
		for (i in 0...source.levels.length) {
			this.addLevel(source.levels[i].object.clone(), source.levels[i].distance, source.levels[i].hysteresis);
		}
		this.autoUpdate = source.autoUpdate;
		return this;
	}

	public function addLevel(object:Object3D, distance:Float = 0, hysteresis:Float = 0):LOD {
		distance = Math.abs(distance);
		var levels = this.levels;
		var l:Int = 0;
		for (l in 0...levels.length) {
			if (distance < levels[l].distance) {
				break;
			}
		}
		levels.splice(l, 0, {distance:distance, hysteresis:hysteresis, object:object});
		this.add(object);
		return this;
	}

	public function getCurrentLevel():Int {
		return this._currentLevel;
	}

	public function getObjectForDistance(distance:Float):Either<Object3D,Null<Object3D>> {
		var levels = this.levels;
		if (levels.length > 0) {
			var i:Int = 1;
			var l:Int = levels.length;
			for (i in 1...l) {
				var levelDistance:Float = levels[i].distance;
				if (levels[i].object.visible) {
					levelDistance -= levelDistance * levels[i].hysteresis;
				}
				if (distance < levelDistance) {
					break;
				}
			}
			return Either.Left(levels[i - 1].object);
		}
		return Either.Right(null);
	}

	public function raycast(raycaster:Dynamic, intersects:Dynamic) {
		var levels = this.levels;
		if (levels.length > 0) {
			var _v1:Vector3 = new Vector3();
			_v1.setFromMatrixPosition(this.matrixWorld);
			var distance:Float = raycaster.ray.origin.distanceTo(_v1);
			this.getObjectForDistance(distance).handle(
				(object:Object3D) => object.raycast(raycaster, intersects),
				() => {}
			);
		}
	}

	public function update(camera:Dynamic) {
		var levels = this.levels;
		if (levels.length > 1) {
			var _v1:Vector3 = new Vector3();
			var _v2:Vector3 = new Vector3();
			_v1.setFromMatrixPosition(camera.matrixWorld);
			_v2.setFromMatrixPosition(this.matrixWorld);
			var distance:Float = _v1.distanceTo(_v2) / camera.zoom;
			levels[0].object.visible = true;
			var i:Int = 1;
			var l:Int = levels.length;
			for (i in 1...l) {
				var levelDistance:Float = levels[i].distance;
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
			for (i in i...l) {
				levels[i].object.visible = false;
			}
		}
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var data:Dynamic = super.toJSON(meta);
		if (!this.autoUpdate) {
			data.object.autoUpdate = false;
		}
		data.object.levels = [];
		var levels = this.levels;
		for (i in 0...levels.length) {
			var level = levels[i];
			data.object.levels.push({
				object:level.object.uuid,
				distance:level.distance,
				hysteresis:level.hysteresis
			});
		}
		return data;
	}

	public var isLOD:Bool;
}