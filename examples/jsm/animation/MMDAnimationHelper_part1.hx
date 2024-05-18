class MMDAnimationHelper {

	private var _meshes:Array<Dynamic>;
	private var _camera:Dynamic;
	private var _cameraTarget:Dynamic;
	private var _audio:Dynamic;
	private var _audioManager:Dynamic;
	private var _objects:Map<Dynamic, Dynamic>;
	private var _configuration:Dynamic;
	private var _enabled:Dynamic;
	private var _onBeforePhysics:Dynamic;
	private var _sharedPhysics:Bool;
	private var _masterPhysics:Dynamic;

	public function new(params:Dynamic = null) {
		_meshes = [];
		_camera = null;
		_cameraTarget = {name:"target"};
		_audio = null;
		_audioManager = null;
		_objects = new Map<Dynamic, Dynamic>();
		_configuration = {
			sync: Std.is(params, Dynamic) && Std.has(params, "sync") ? params.sync : true,
			afterglow: Std.is(params, Dynamic) && Std.has(params, "afterglow") ? params.afterglow : 0.0,
			resetPhysicsOnLoop: Std.is(params, Dynamic) && Std.has(params, "resetPhysicsOnLoop") ? params.resetPhysicsOnLoop : true,
			pmxAnimation: Std.is(params, Dynamic) && Std.has(params, "pmxAnimation") ? params.pmxAnimation : false
		};
		_enabled = {
			animation: true,
			ik: true,
			grant: true,
			physics: true,
			cameraAnimation: true
		};
		_onBeforePhysics = function ( /* mesh */ ) {};
		_sharedPhysics = false;
		_masterPhysics = null;
	}

	public function add(object:Dynamic, params:Dynamic = null):MMDAnimationHelper {
		if (Std.is(object, Dynamic) && (Std.has(object, "isSkinnedMesh") && object.isSkinnedMesh || Std.has(object, "isCamera") && object.isCamera || object.type == "Audio")) {
			if (Std.has(object, "isSkinnedMesh") && object.isSkinnedMesh) {
				_addMesh(object, params);
			} else if (Std.has(object, "isCamera") && object.isCamera) {
				_setupCamera(object, params);
			} else if (object.type == "Audio") {
				_setupAudio(object, params);
			}
			if (_configuration.sync) _syncDuration();
		} else {
			throw new Error("THREE.MMDAnimationHelper.add: accepts only THREE.SkinnedMesh or THREE.Camera or THREE.Audio instance.");
		}
		return this;
	}

	public function remove(object:Dynamic):MMDAnimationHelper {
		if (Std.is(object, Dynamic) && (Std.has(object, "isSkinnedMesh") && object.isSkinnedMesh || Std.has(object, "isCamera") && object.isCamera || object.type == "Audio")) {
			if (Std.has(object, "isSkinnedMesh") && object.isSkinnedMesh) {
				_removeMesh(object);
			} else if (Std.has(object, "isCamera") && object.isCamera) {
				_clearCamera(object);
			} else if (object.type == "Audio") {
				_clearAudio(object);
			}
			if (_configuration.sync) _syncDuration();
		} else {
			throw new Error("THREE.MMDAnimationHelper.remove: accepts only THREE.SkinnedMesh or THREE.Camera or THREE.Audio instance.");
		}
		return this;
	}

	public function update(delta:Float):MMDAnimationHelper {
		if (_audioManager != null) _audioManager.control(delta);
		for (mesh in _meshes) {
			_animateMesh(mesh, delta);
		}
		if (_sharedPhysics) _updateSharedPhysics(delta);
		if (_camera != null) _animateCamera(_camera, delta);
		return this;
	}

	public function pose(mesh:Dynamic, vpd:Dynamic, params:Dynamic = null):MMDAnimationHelper {
		if (Std.is(mesh, Dynamic) && Std.is(vpd, Dynamic)) {
			if (params != null && Std.has(params, "resetPose") && !params.resetPose) {
				// do something if resetPose is false
			} else {
				// do something if resetPose is true or not provided
			}
			// do something with bones
		} else {
			throw new Error("THREE.MMDAnimationHelper.pose: accepts only THREE.SkinnedMesh and VPD content parsed MMDParser.");
		}
		return this;
	}

	public function enable(key:String, enabled:Bool):MMDAnimationHelper {
		if (Std.is(key, String) && Std.is(enabled, Bool) && _enabled[key] != undefined) {
			_enabled[key] = enabled;
			if (key == "physics") {
				for (mesh in _meshes) {
					_optimizeIK(mesh, enabled);
				}
			}
		} else {
			throw new Error("THREE.MMDAnimationHelper.enable: unknown key " + key);
		}
		return this;
	}

	private function _addMesh(mesh:Dynamic, params:Dynamic):Void {
		// do something
	}

	private function _setupCamera(camera:Dynamic, params:Dynamic):Void {
		// do something
	}

	private function _setupAudio(audio:Dynamic, params:Dynamic):Void {
		// do something
	}

	private function _removeMesh(mesh:Dynamic):Void {
		// do something
	}

	private function _clearCamera(camera:Dynamic):Void {
		// do something
	}

	private function _clearAudio(audio:Dynamic):Void {
		// do something
	}

	private function _setupMeshAnimation(mesh:Dynamic, animation:Dynamic):Void {
		// do something
	}

	private function _setupCameraAnimation(camera:Dynamic, animation:Dynamic):Void {
		// do something
	}

	private function _setupMeshPhysics(mesh:Dynamic, params:Dynamic):Void {
		// do something
	}

	private function _optimizeIK(mesh:Dynamic, physicsEnabled:Bool):Void {
		// do something
	}

	private function _animateMesh(mesh:Dynamic, delta:Float):Void {
		// do something
	}

	private function _sortBoneDataArray(boneDataArray:Array<Dynamic>):Array<Dynamic> {
		// do something
	}

	private function _animatePMXMesh(mesh:Dynamic, sortedBonesData:Array<Dynamic>, ikSolver:Dynamic, grantSolver:Dynamic):Void {
		// do something
	}

	private function _animateCamera(camera:Dynamic, delta:Float):Void {
		// do something
	}

	private function _createCCDIKSolver(mesh:Dynamic):Dynamic {
		// do something
	}

	private function _createMMDPhysics(mesh:Dynamic, params:Dynamic):Dynamic {
		// do something
	}

	private function _syncDuration():Void {
		// do something
	}

	private function _updatePropertyMixersBuffer(mesh:Dynamic):Void {
		// do something
	}

	private function _saveBones(mesh:Dynamic):Void {
		// do something
	}

	private function _restoreBones(mesh:Dynamic):Void {
		// do something
	}

	private function _getMasterPhysics():Dynamic {
		// do something
	}

	private function _updateSharedPhysics(delta:Float):Void {
		// do something
	}

}