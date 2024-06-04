import three.animation.AnimationMixer;
import three.Object3D;
import three.Quaternion;
import three.Vector3;
import animation.CCDIKSolver;
import animation.MMDPhysics;

/**
 * MMDAnimationHelper handles animation of MMD assets loaded by MMDLoader
 * with MMD special features as IK, Grant, and Physics.
 *
 * Dependencies
 *  - ammo.js https://github.com/kripken/ammo.js
 *  - MMDPhysics
 *  - CCDIKSolver
 *
 * TODO
 *  - more precise grant skinning support.
 */
class MMDAnimationHelper {

	/**
	 * @param {Object} params - (optional)
	 * @param {Bool} params.sync - Whether animation durations of added objects are synched. Default is true.
	 * @param {Float} params.afterglow - Default is 0.0.
	 * @param {Bool} params.resetPhysicsOnLoop - Default is true.
	 */
	public function new(params:Dynamic = {}) {

		this.meshes = new Array<three.SkinnedMesh>();

		this.camera = null;
		this.cameraTarget = new Object3D();
		this.cameraTarget.name = 'target';

		this.audio = null;
		this.audioManager = null;

		this.objects = new WeakMap<Dynamic, Dynamic>();

		this.configuration = {
			sync: params.sync != null ? params.sync : true,
			afterglow: params.afterglow != null ? params.afterglow : 0.0,
			resetPhysicsOnLoop: params.resetPhysicsOnLoop != null ? params.resetPhysicsOnLoop : true,
			pmxAnimation: params.pmxAnimation != null ? params.pmxAnimation : false
		};

		this.enabled = {
			animation: true,
			ik: true,
			grant: true,
			physics: true,
			cameraAnimation: true
		};

		this.onBeforePhysics = function(mesh:three.SkinnedMesh):Void {};

		// experimental
		this.sharedPhysics = false;
		this.masterPhysics = null;

	}

	/**
	 * Adds an Three.js Object to helper and setups animation.
	 * The anmation durations of added objects are synched
	 * if this.configuration.sync is true.
	 *
	 * @param {THREE.SkinnedMesh|THREE.Camera|THREE.Audio} object
	 * @param {Object} params - (optional)
	 * @param {THREE.AnimationClip|Array<THREE.AnimationClip>} params.animation - Only for THREE.SkinnedMesh and THREE.Camera. Default is undefined.
	 * @param {Bool} params.physics - Only for THREE.SkinnedMesh. Default is true.
	 * @param {Int} params.warmup - Only for THREE.SkinnedMesh and physics is true. Default is 60.
	 * @param {Float} params.unitStep - Only for THREE.SkinnedMesh and physics is true. Default is 1 / 65.
	 * @param {Int} params.maxStepNum - Only for THREE.SkinnedMesh and physics is true. Default is 3.
	 * @param {Vector3} params.gravity - Only for THREE.SkinnedMesh and physics is true. Default ( 0, - 9.8 * 10, 0 ).
	 * @param {Float} params.delayTime - Only for THREE.Audio. Default is 0.0.
	 * @return {MMDAnimationHelper}
	 */
	public function add(object:Dynamic, params:Dynamic = {}):MMDAnimationHelper {

		if ( Std.is(object, three.SkinnedMesh) ) {

			this._addMesh(object, params);

		} else if ( Std.is(object, three.Camera) ) {

			this._setupCamera(object, params);

		} else if ( Std.is(object, three.Audio) ) {

			this._setupAudio(object, params);

		} else {

			throw new Error('THREE.MMDAnimationHelper.add: '
				+ 'accepts only '
				+ 'THREE.SkinnedMesh or '
				+ 'THREE.Camera or '
				+ 'THREE.Audio instance.');

		}

		if (this.configuration.sync) this._syncDuration();

		return this;

	}

	/**
	 * Removes an Three.js Object from helper.
	 *
	 * @param {THREE.SkinnedMesh|THREE.Camera|THREE.Audio} object
	 * @return {MMDAnimationHelper}
	 */
	public function remove(object:Dynamic):MMDAnimationHelper {

		if ( Std.is(object, three.SkinnedMesh) ) {

			this._removeMesh(object);

		} else if ( Std.is(object, three.Camera) ) {

			this._clearCamera(object);

		} else if ( Std.is(object, three.Audio) ) {

			this._clearAudio(object);

		} else {

			throw new Error('THREE.MMDAnimationHelper.remove: '
				+ 'accepts only '
				+ 'THREE.SkinnedMesh or '
				+ 'THREE.Camera or '
				+ 'THREE.Audio instance.');

		}

		if (this.configuration.sync) this._syncDuration();

		return this;

	}

	/**
	 * Updates the animation.
	 *
	 * @param {Float} delta
	 * @return {MMDAnimationHelper}
	 */
	public function update(delta:Float):MMDAnimationHelper {

		if (this.audioManager != null) this.audioManager.control(delta);

		for (i in 0...this.meshes.length) {

			this._animateMesh(this.meshes[i], delta);

		}

		if (this.sharedPhysics) this._updateSharedPhysics(delta);

		if (this.camera != null) this._animateCamera(this.camera, delta);

		return this;

	}

	/**
	 * Changes the pose of SkinnedMesh as VPD specifies.
	 *
	 * @param {THREE.SkinnedMesh} mesh
	 * @param {Object} vpd - VPD content parsed MMDParser
	 * @param {Object} params - (optional)
	 * @param {Bool} params.resetPose - Default is true.
	 * @param {Bool} params.ik - Default is true.
	 * @param {Bool} params.grant - Default is true.
	 * @return {MMDAnimationHelper}
	 */
	public function pose(mesh:three.SkinnedMesh, vpd:Dynamic, params:Dynamic = {}):MMDAnimationHelper {

		if (params.resetPose != false) mesh.pose();

		var bones = mesh.skeleton.bones;
		var boneParams = vpd.bones;

		var boneNameDictionary = new Map<String, Int>();

		for (i in 0...bones.length) {

			boneNameDictionary.set(bones[i].name, i);

		}

		var vector = new Vector3();
		var quaternion = new Quaternion();

		for (i in 0...boneParams.length) {

			var boneParam = boneParams[i];
			var boneIndex = boneNameDictionary.get(boneParam.name);

			if (boneIndex == null) continue;

			var bone = bones[boneIndex];
			bone.position.add(vector.fromArray(boneParam.translation));
			bone.quaternion.multiply(quaternion.fromArray(boneParam.quaternion));

		}

		mesh.updateMatrixWorld(true);

		// PMX animation system special path
		if (this.configuration.pmxAnimation &&
			mesh.geometry.userData.MMD != null && mesh.geometry.userData.MMD.format == 'pmx') {

			var sortedBonesData = this._sortBoneDataArray(mesh.geometry.userData.MMD.bones.copy());
			var ikSolver = params.ik != false ? this._createCCDIKSolver(mesh) : null;
			var grantSolver = params.grant != false ? this.createGrantSolver(mesh) : null;
			this._animatePMXMesh(mesh, sortedBonesData, ikSolver, grantSolver);

		} else {

			if (params.ik != false) {

				this._createCCDIKSolver(mesh).update();

			}

			if (params.grant != false) {

				this.createGrantSolver(mesh).update();

			}

		}

		return this;

	}

	/**
	 * Enabes/Disables an animation feature.
	 *
	 * @param {String} key
	 * @param {Bool} enabled
	 * @return {MMDAnimationHelper}
	 */
	public function enable(key:String, enabled:Bool):MMDAnimationHelper {

		if (this.enabled.hasOwnProperty(key) == false) {

			throw new Error('THREE.MMDAnimationHelper.enable: '
				+ 'unknown key ' + key);

		}

		this.enabled[key] = enabled;

		if (key == 'physics') {

			for (i in 0...this.meshes.length) {

				this._optimizeIK(this.meshes[i], enabled);

			}

		}

		return this;

	}

	/**
	 * Creates an GrantSolver instance.
	 *
	 * @param {THREE.SkinnedMesh} mesh
	 * @return {GrantSolver}
	 */
	public function createGrantSolver(mesh:three.SkinnedMesh):GrantSolver {

		return new GrantSolver(mesh, mesh.geometry.userData.MMD.grants);

	}

	// private methods

	private function _addMesh(mesh:three.SkinnedMesh, params:Dynamic) {

		if (this.meshes.indexOf(mesh) >= 0) {

			throw new Error('THREE.MMDAnimationHelper._addMesh: '
				+ 'SkinnedMesh \'' + mesh.name + '\' has already been added.');

		}

		this.meshes.push(mesh);
		this.objects.set(mesh, {looped: false});

		this._setupMeshAnimation(mesh, params.animation);

		if (params.physics != false) {

			this._setupMeshPhysics(mesh, params);

		}

		return this;

	}

	private function _setupCamera(camera:three.Camera, params:Dynamic) {

		if (this.camera == camera) {

			throw new Error('THREE.MMDAnimationHelper._setupCamera: '
				+ 'Camera \'' + camera.name + '\' has already been set.');

		}

		if (this.camera) this.clearCamera(this.camera);

		this.camera = camera;

		camera.add(this.cameraTarget);

		this.objects.set(camera, {});

		if (params.animation != null) {

			this._setupCameraAnimation(camera, params.animation);

		}

		return this;

	}

	private function _setupAudio(audio:three.Audio, params:Dynamic) {

		if (this.audio == audio) {

			throw new Error('THREE.MMDAnimationHelper._setupAudio: '
				+ 'Audio \'' + audio.name + '\' has already been set.');

		}

		if (this.audio) this.clearAudio(this.audio);

		this.audio = audio;
		this.audioManager = new AudioManager(audio, params);

		this.objects.set(this.audioManager, {
			duration: this.audioManager.duration
		});

		return this;

	}

	private function _removeMesh(mesh:three.SkinnedMesh) {

		var found = false;
		var writeIndex = 0;

		for (i in 0...this.meshes.length) {

			if (this.meshes[i] == mesh) {

				this.objects.delete(mesh);
				found = true;

				continue;

			}

			this.meshes[writeIndex++] = this.meshes[i];

		}

		if (found == false) {

			throw new Error('THREE.MMDAnimationHelper._removeMesh: '
				+ 'SkinnedMesh \'' + mesh.name + '\' has not been added yet.');

		}

		this.meshes.length = writeIndex;

		return this;

	}

	private function _clearCamera(camera:three.Camera) {

		if (camera != this.camera) {

			throw new Error('THREE.MMDAnimationHelper._clearCamera: '
				+ 'Camera \'' + camera.name + '\' has not been set yet.');

		}

		this.camera.remove(this.cameraTarget);

		this.objects.delete(this.camera);
		this.camera = null;

		return this;

	}

	private function _clearAudio(audio:three.Audio) {

		if (audio != this.audio) {

			throw new Error('THREE.MMDAnimationHelper._clearAudio: '
				+ 'Audio \'' + audio.name + '\' has not been set yet.');

		}

		this.objects.delete(this.audioManager);

		this.audio = null;
		this.audioManager = null;

		return this;

	}

	private function _setupMeshAnimation(mesh:three.SkinnedMesh, animation:Dynamic) {

		var objects = this.objects.get(mesh);

		if (animation != null) {

			var animations:Array<three.AnimationClip> = Std.is(animation, Array)
				? animation : [animation];

			objects.mixer = new AnimationMixer(mesh);

			for (i in 0...animations.length) {

				objects.mixer.clipAction(animations[i]).play();

			}

			// TODO: find a workaround not to access ._clip looking like a private property
			objects.mixer.addEventListener('loop', function(event:Dynamic):Void {

				var tracks = event.action._clip.tracks;

				if (tracks.length > 0 && tracks[0].name.substring(0, 6) != '.bones') return;

				objects.looped = true;

			});

		}

		objects.ikSolver = this._createCCDIKSolver(mesh);
		objects.grantSolver = this.createGrantSolver(mesh);

		return this;

	}

	private function _setupCameraAnimation(camera:three.Camera, animation:Dynamic) {

		var animations:Array<three.AnimationClip> = Std.is(animation, Array)
			? animation : [animation];

		var objects = this.objects.get(camera);

		objects.mixer = new AnimationMixer(camera);

		for (i in 0...animations.length) {

			objects.mixer.clipAction(animations[i]).play();

		}

	}

	private function _setupMeshPhysics(mesh:three.SkinnedMesh, params:Dynamic) {

		var objects = this.objects.get(mesh);

		// shared physics is experimental

		var world:Dynamic = null;
		if (params.world == null && this.sharedPhysics) {

			var masterPhysics = this._getMasterPhysics();

			if (masterPhysics != null) world = masterPhysics.world; // eslint-disable-line no-undef

		}

		objects.physics = this._createMMDPhysics(mesh, params);

		if (objects.mixer && params.animationWarmup != false) {

			this._animateMesh(mesh, 0);
			objects.physics.reset();

		}

		objects.physics.warmup(params.warmup != null ? params.warmup : 60);

		this._optimizeIK(mesh, true);

	}

	private function _animateMesh(mesh:three.SkinnedMesh, delta:Float) {

		var objects = this.objects.get(mesh);

		var mixer = objects.mixer;
		var ikSolver = objects.ikSolver;
		var grantSolver = objects.grantSolver;
		var physics = objects.physics;
		var looped = objects.looped;

		if (mixer && this.enabled.animation) {

			// alternate solution to save/restore bones but less performant?
			//mesh.pose();
			//this._updatePropertyMixersBuffer(mesh);

			this._restoreBones(mesh);

			mixer.update(delta);

			this._saveBones(mesh);

			// PMX animation system special path
			if (this.configuration.pmxAnimation &&
				mesh.geometry.userData.MMD != null && mesh.geometry.userData.MMD.format == 'pmx') {

				if (objects.sortedBonesData == null) objects.sortedBonesData = this._sortBoneDataArray(mesh.geometry.userData.MMD.bones.copy());

				this._animatePMXMesh(
					mesh,
					objects.sortedBonesData,
					ikSolver && this.enabled.ik ? ikSolver : null,
					grantSolver && this.enabled.grant ? grantSolver : null
				);

			} else {

				if (ikSolver && this.enabled.ik) {

					mesh.updateMatrixWorld(true);
					ikSolver.update();

				}

				if (grantSolver && this.enabled.grant) {

					grantSolver.update();

				}

			}

		}

		if (looped == true && this.enabled.physics) {

			if (physics && this.configuration.resetPhysicsOnLoop) physics.reset();

			objects.looped = false;

		}

		if (physics && this.enabled.physics && this.sharedPhysics == false) {

			this.onBeforePhysics(mesh);
			physics.update(delta);

		}

	}

	// Sort bones in order by 1. transformationClass and 2. bone index.
	// In PMX animation system, bone transformations should be processed
	// in this order.
	private function _sortBoneDataArray(boneDataArray:Array<Dynamic>):Array<Dynamic> {

		return boneDataArray.sort(function(a:Dynamic, b:Dynamic):Int {

			if (a.transformationClass != b.transformationClass) {

				return a.transformationClass - b.transformationClass;

			} else {

				return a.index - b.index;

			}

		});

	}

	// PMX Animation system is a bit too complex and doesn't great match to
	// Three.js Animation system. This method attempts to simulate it as much as
	// possible but doesn't perfectly simulate.
	// This method is more costly than the regular one so
	// you are recommended to set constructor parameter "pmxAnimation: true"
	// only if your PMX model animation doesn't work well.
	// If you need better method you would be required to write your own.
	private function _animatePMXMesh(mesh:three.SkinnedMesh, sortedBonesData:Array<Dynamic>, ikSolver:CCDIKSolver, grantSolver:GrantSolver) {

		_quaternionIndex = 0;
		_grantResultMap.clear();

		for (i in 0...sortedBonesData.length) {

			updateOne(mesh, sortedBonesData[i].index, ikSolver, grantSolver);

		}

		mesh.updateMatrixWorld(true);
		return this;

	}

	private function _animateCamera(camera:three.Camera, delta:Float) {

		var mixer = this.objects.get(camera).mixer;

		if (mixer && this.enabled.cameraAnimation) {

			mixer.update(delta);

			camera.updateProjectionMatrix();

			camera.up.set(0, 1, 0);
			camera.up.applyQuaternion(camera.quaternion);
			camera.lookAt(this.cameraTarget.position);

		}

	}

	private function _optimizeIK(mesh:three.SkinnedMesh, physicsEnabled:Bool) {

		var iks = mesh.geometry.userData.MMD.iks;
		var bones = mesh.geometry.userData.MMD.bones;

		for (i in 0...iks.length) {

			var ik = iks[i];
			var links = ik.links;

			for (j in 0...links.length) {

				var link = links[j];

				if (physicsEnabled == true) {

					// disable IK of the bone the corresponding rigidBody type of which is 1 or 2
					// because its rotation will be overriden by physics
					link.enabled = bones[link.index].rigidBodyType > 0 ? false : true;

				} else {

					link.enabled = true;

				}

			}

		}

	}

	private function _createCCDIKSolver(mesh:three.SkinnedMesh):CCDIKSolver {

		if (CCDIKSolver == null) {

			throw new Error('THREE.MMDAnimationHelper: Import CCDIKSolver.');

		}

		return new CCDIKSolver(mesh, mesh.geometry.userData.MMD.iks);

	}

	private function _createMMDPhysics(mesh:three.SkinnedMesh, params:Dynamic):MMDPhysics {

		if (MMDPhysics == null) {

			throw new Error('THREE.MMDPhysics: Import MMDPhysics.');

		}

		return new MMDPhysics(
			mesh,
			mesh.geometry.userData.MMD.rigidBodies,
			mesh.geometry.userData.MMD.constraints,
			params);

	}

	/*
	 * Detects the longest duration and then sets it to them to sync.
	 * TODO: Not to access private properties ( ._actions and ._clip )
	 */
	private function _syncDuration() {

		var max = 0.0;

		var objects = this.objects;
		var meshes = this.meshes;
		var camera = this.camera;
		var audioManager = this.audioManager;

		// get the longest duration

		for (i in 0...meshes.length) {

			var mixer = this.objects.get(meshes[i]).mixer;

			if (mixer == null) continue;

			for (j in 0...mixer._actions.length) {

				var clip = mixer._actions[j]._clip;

				if (objects.has(clip) == false) {

					objects.set(clip, {
						duration: clip.duration
					});

				}

				max = Math.max(max, objects.get(clip).duration);

			}

		}

		if (camera != null) {

			var mixer = this.objects.get(camera).mixer;

			if (mixer != null) {

				for (i in 0...mixer._actions.length) {

					var clip = mixer._actions[i]._clip;

					if (objects.has(clip) == false) {

						objects.set(clip, {
							duration: clip.duration
						});

					}

					max = Math.max(max, objects.get(clip).duration);

				}

			}

		}

		if (audioManager != null) {

			max = Math.max(max, objects.get(audioManager).duration);

		}

		max += this.configuration.afterglow;

		// update the duration

		for (i in 0...this.meshes.length) {

			var mixer = this.objects.get(this.meshes[i]).mixer;

			if (mixer == null) continue;

			for (j in 0...mixer._actions.length) {

				mixer._actions[j]._clip.duration = max;

			}

		}

		if (camera != null) {

			var mixer = this.objects.get(camera).mixer;

			if (mixer != null) {

				for (i in 0...mixer._actions.length) {

					mixer._actions[i]._clip.duration = max;

				}

			}

		}

		if (audioManager != null) {

			audioManager.duration = max;

		}

	}

	// workaround

	private function _updatePropertyMixersBuffer(mesh:three.SkinnedMesh) {

		var mixer = this.objects.get(mesh).mixer;

		var propertyMixers = mixer._bindings;
		var accuIndex = mixer._accuIndex;

		for (i in 0...propertyMixers.length) {

			var propertyMixer = propertyMixers[i];
			var buffer = propertyMixer.buffer;
			var stride = propertyMixer.valueSize;
			var offset = (accuIndex + 1) * stride;

			propertyMixer.binding.getValue(buffer, offset);

		}

	}

	/*
	 * Avoiding these two issues by restore/save bones before/after mixer animation.
	 *
	 * 1. PropertyMixer used by AnimationMixer holds cache value in .buffer.
	 *    Calculating IK, Grant, and Physics after mixer animation can break
	 *    the cache coherency.
	 *
	 * 2. Applying Grant two or more times without reset the posing breaks model.
	 */
	private function _saveBones(mesh:three.SkinnedMesh) {

		var objects = this.objects.get(mesh);

		var bones = mesh.skeleton.bones;

		var backupBones = objects.backupBones;

		if (backupBones == null) {

			backupBones = new Float32Array(bones.length * 7);
			objects.backupBones = backupBones;

		}

		for (i in 0...bones.length) {

			var bone = bones[i];
			bone.position.toArray(backupBones, i * 7);
			bone.quaternion.toArray(backupBones, i * 7 + 3);

		}

	}

	private function _restoreBones(mesh:three.SkinnedMesh) {

		var objects = this.objects.get(mesh);

		var backupBones = objects.backupBones;

		if (backupBones == null) return;

		var bones = mesh.skeleton.bones;

		for (i in 0...bones.length) {

			var bone = bones[i];
			bone.position.fromArray(backupBones, i * 7);
			bone.quaternion.fromArray(backupBones, i * 7 + 3);

		}

	}

	// experimental

	private function _getMasterPhysics():MMDPhysics {

		if (this.masterPhysics != null) return this.masterPhysics;

		for (i in 0...this.meshes.length) {

			var physics = this.meshes[i].physics;

			if (physics != null) {

				this.masterPhysics = physics;
				return this.masterPhysics;

			}

		}

		return null;

	}

	private function _updateSharedPhysics(delta:Float) {

		if (this.meshes.length == 0 || this.enabled.physics == false || this.sharedPhysics == false) return;

		var physics = this._getMasterPhysics();

		if (physics == null) return;

		for (i in 0...this.meshes.length) {

			var p = this.meshes[i].physics;

			if (p != null) {

				p.updateRigidBodies();

			}

		}

		physics.stepSimulation(delta);

		for (i in 0...this.meshes.length) {

			var p = this.meshes[i].physics;

			if (p != null) {

				p.updateBones();

			}

		}

	}

}

// Keep working quaternions for less GC
var _quaternions:Array<Quaternion> = new Array<Quaternion>();
var _quaternionIndex:Int = 0;

function getQuaternion():Quaternion {

	if (_quaternionIndex >= _quaternions.length) {

		_quaternions.push(new Quaternion());

	}

	return _quaternions[_quaternionIndex++];

}

// Save rotation whose grant and IK are already applied
// used by grant children
var _grantResultMap:Map<Int, Quaternion> = new Map<Int, Quaternion>();

function updateOne(mesh:three.SkinnedMesh, boneIndex:Int, ikSolver:CCDIKSolver, grantSolver:GrantSolver) {

	var bones = mesh.skeleton.bones;
	var bonesData = mesh.geometry.userData.MMD.bones;
	var boneData = bonesData[boneIndex];
	var bone = bones[boneIndex];

	// Return if already updated by being referred as a grant parent.
	if (_grantResultMap.has(boneIndex)) return;

	var quaternion = getQuaternion();

	// Initialize grant result here to prevent infinite loop.
	// If it's referred before updating with actual result later
	// result without applyting IK or grant is gotten
	// but better than composing of infinite loop.
	_grantResultMap.set(boneIndex, quaternion.copy(bone.quaternion));

	// @TODO: Support global grant and grant position
	if (grantSolver != null && boneData.grant != null &&
		boneData.grant.isLocal == false && boneData.grant.affectRotation) {

		var parentIndex = boneData.grant.parentIndex;
		var ratio = boneData.grant.ratio;

		if (_grantResultMap.has(parentIndex) == false) {

			updateOne(mesh, parentIndex, ikSolver, grantSolver);

		}

		grantSolver.addGrantRotation(bone, _grantResultMap.get(parentIndex), ratio);

	}

	if (ikSolver != null && boneData.ik != null) {

		// @TODO: Updating world matrices every time solving an IK bone is
		// costly. Optimize if possible.
		mesh.updateMatrixWorld(true);
		ikSolver.updateOne(boneData.ik);

		// No confident, but it seems the grant results with ik links should be updated?
		var links = boneData.ik.links;

		for (i in 0...links.length) {

			var link = links[i];

			if (link.enabled == false) continue;

			var linkIndex = link.index;

			if (_grantResultMap.has(linkIndex)) {

				_grantResultMap.set(linkIndex, _grantResultMap.get(linkIndex).copy(bones[linkIndex].quaternion));

			}

		}

	}

	// Update with the actual result here
	quaternion.copy(bone.quaternion);

}

//

class AudioManager {

	/**
	 * @param {THREE.Audio} audio
	 * @param {Object} params - (optional)
	 * @param {Float} params.delayTime
	 */
	public function new(audio:three.Audio, params:Dynamic = {}) {

		this.audio = audio;

		this.elapsedTime = 0.0;
		this.currentTime = 0.0;
		this.delayTime = params.delayTime != null
			? params.delayTime : 0.0;

		this.audioDuration = this.audio.buffer.duration;
		this.duration = this.audioDuration + this.delayTime;

	}

	/**
	 * @param {Float} delta
	 * @return {AudioManager}
	 */
	public function control(delta:Float):AudioManager {

		this.elapsed += delta;
		this.currentTime += delta;

		if (this._shouldStopAudio()) this.audio.stop();
		if (this._shouldStartAudio()) this.audio.play();

		return this;

	}

	// private methods

	private function _shouldStartAudio():Bool {

		if (this.audio.isPlaying) return false;

		while (this.currentTime >= this.duration) {

			this.currentTime -= this.duration;

		}

		if (this.currentTime < this.delayTime) return false;

		// 'duration' can be bigger than 'audioDuration + delayTime' because of sync configuration
		if ((this.currentTime - this.delayTime) > this.audioDuration) return false;

		return true;

	}

	private function _shouldStopAudio():Bool {

		return this.audio.isPlaying &&
			this.currentTime >= this.duration;

	}

}

var _q:Quaternion = new Quaternion();

/**
 * Solver for Grant (Fuyo in Japanese. I just google translated because
 * Fuyo may be MMD specific term and may not be common word in 3D CG terms.)
 * Grant propagates a bone's transform to other bones transforms even if
 * they are not children.
 * @param {THREE.SkinnedMesh} mesh
 * @param {Array<Object>} grants
 */
class GrantSolver {

	public function new(mesh:three.SkinnedMesh, grants:Array<Dynamic> = []) {

		this.mesh = mesh;
		this.grants = grants;

	}

	/**
	 * Solve all the grant bones
	 * @return {GrantSolver}
	 */
	public function update():GrantSolver {

		var grants = this.grants;

		for (i in 0...grants.length) {

			this.updateOne(grants[i]);

		}

		return this;

	}

	/**
	 * Solve a grant bone
	 * @param {Object} grant - grant parameter
	 * @return {GrantSolver}
	 */
	public function updateOne(grant:Dynamic):GrantSolver {

		var bones = this.mesh.skeleton.bones;
		var bone = bones[grant.index];
		var parentBone = bones[grant.parentIndex];

		if (grant.isLocal) {

			// TODO: implement
			if (grant.affectPosition) {

			}

			// TODO: implement
			if (grant.affectRotation) {

			}

		} else {

			// TODO: implement
			if (grant.affectPosition) {

			}

			if (grant.affectRotation) {

				this.addGrantRotation(bone, parentBone.quaternion, grant.ratio);

			}

		}

		return this;

	}

	public function addGrantRotation(bone:three.Bone, q:Quaternion, ratio:Float):GrantSolver {

		_q.set(0, 0, 0, 1);
		_q.slerp(q, ratio);
		bone.quaternion.multiply(_q);

		return this;

	}

}