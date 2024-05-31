import three.animation.AnimationMixer;
import three.core.Object3D;
import three.math.Quaternion;
import three.math.Vector3;
import three.animation.CCDIKSolver;
import three.animation.MMDPhysics;
//import js.lib.Float32Array; // Use haxe.ds.Vector instead
import haxe.ds.Vector;
import three.core.BufferGeometry;
import three.objects.SkinnedMesh;
import three.animation.AnimationClip;
import three.audio.Audio;

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
	 * @param {boolean} params.sync - Whether animation durations of added objects are synched. Default is true.
	 * @param {Number} params.afterglow - Default is 0.0.
	 * @param {boolean} params.resetPhysicsOnLoop - Default is true.
	 */
	public function new(params:Dynamic = null) {

		if (params == null) params = {};

		meshes = [];

		camera = null;
		cameraTarget = new Object3D();
		cameraTarget.name = 'target';

		audio = null;
		audioManager = null;

		objects = new Map<Dynamic, Dynamic>();

		configuration = {
			sync: (params.sync != null) ? params.sync : true,
			afterglow: (params.afterglow != null) ? params.afterglow : 0.0,
			resetPhysicsOnLoop: (params.resetPhysicsOnLoop != null) ? params.resetPhysicsOnLoop : true,
			pmxAnimation: (params.pmxAnimation != null) ? params.pmxAnimation : false
		};

		enabled = {
			animation: true,
			ik: true,
			grant: true,
			physics: true,
			cameraAnimation: true
		};

		// experimental
		sharedPhysics = false;
		masterPhysics = null;

	}

	/**
	 * Adds an Three.js Object to helper and setups animation.
	 * The anmation durations of added objects are synched
	 * if this.configuration.sync is true.
	 *
	 * @param {THREE.SkinnedMesh|THREE.Camera|THREE.Audio} object
	 * @param {Object} params - (optional)
	 * @param {THREE.AnimationClip|Array<THREE.AnimationClip>} params.animation - Only for THREE.SkinnedMesh and THREE.Camera. Default is undefined.
	 * @param {boolean} params.physics - Only for THREE.SkinnedMesh. Default is true.
	 * @param {Integer} params.warmup - Only for THREE.SkinnedMesh and physics is true. Default is 60.
	 * @param {Number} params.unitStep - Only for THREE.SkinnedMesh and physics is true. Default is 1 / 65.
	 * @param {Integer} params.maxStepNum - Only for THREE.SkinnedMesh and physics is true. Default is 3.
	 * @param {Vector3} params.gravity - Only for THREE.SkinnedMesh and physics is true. Default ( 0, - 9.8 * 10, 0 ).
	 * @param {Number} params.delayTime - Only for THREE.Audio. Default is 0.0.
	 * @return {MMDAnimationHelper}
	 */
	public function add(object:Dynamic, params:Dynamic = null):MMDAnimationHelper {

		if (params == null) params = {};

		if (Std.is(object, SkinnedMesh)) {

			_addMesh(cast object, params);

		} else if (Std.is(object, three.cameras.Camera)) {

			_setupCamera(cast object, params);

		} else if (Std.is(object, Audio)) {

			_setupAudio(cast object, params);

		} else {

			throw new String("THREE.MMDAnimationHelper.add: accepts only THREE.SkinnedMesh, THREE.Camera, or THREE.Audio instances.");

		}

		if (configuration.sync) _syncDuration();

		return this;

	}

	/**
	 * Removes an Three.js Object from helper.
	 *
	 * @param {THREE.SkinnedMesh|THREE.Camera|THREE.Audio} object
	 * @return {MMDAnimationHelper}
	 */
	public function remove(object:Dynamic):MMDAnimationHelper {

		if (Std.is(object, SkinnedMesh)) {

			_removeMesh(cast object);

		} else if (Std.is(object, three.cameras.Camera)) {

			_clearCamera(cast object);

		} else if (Std.is(object, Audio)) {

			_clearAudio(cast object);

		} else {

			throw new String("THREE.MMDAnimationHelper.remove: accepts only THREE.SkinnedMesh, THREE.Camera, or THREE.Audio instances.");

		}

		if (configuration.sync) _syncDuration();

		return this;

	}

	/**
	 * Updates the animation.
	 *
	 * @param {Number} delta
	 * @return {MMDAnimationHelper}
	 */
	public function update(delta:Float):MMDAnimationHelper {

		if (audioManager != null) audioManager.control(delta);

		for (i in 0...meshes.length) {

			_animateMesh(meshes[i], delta);

		}

		if (sharedPhysics) _updateSharedPhysics(delta);

		if (camera != null) _animateCamera(camera, delta);

		return this;

	}

	/**
	 * Changes the pose of SkinnedMesh as VPD specifies.
	 *
	 * @param {THREE.SkinnedMesh} mesh
	 * @param {Object} vpd - VPD content parsed MMDParser
	 * @param {Object} params - (optional)
	 * @param {boolean} params.resetPose - Default is true.
	 * @param {boolean} params.ik - Default is true.
	 * @param {boolean} params.grant - Default is true.
	 * @return {MMDAnimationHelper}
	 */
	public function pose(mesh:SkinnedMesh, vpd:Dynamic, params:Dynamic = null):MMDAnimationHelper {

		if (params == null) params = {};

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
			if (!boneNameDictionary.exists(boneParam.name)) continue;
			var boneIndex = boneNameDictionary.get(boneParam.name);

			var bone = bones[boneIndex];
			bone.position.add(vector.fromArray(boneParam.translation));
			bone.quaternion.multiply(quaternion.fromArray(boneParam.quaternion));

		}

		mesh.updateMatrixWorld(true);

		// PMX animation system special path
		if (configuration.pmxAnimation &&
			mesh.geometry.userData.exists("MMD") && mesh.geometry.userData.MMD.format == "pmx") {

			var sortedBonesData = _sortBoneDataArray(mesh.geometry.userData.MMD.bones.copy());
			var ikSolver = params.ik != false ? _createCCDIKSolver(mesh) : null;
			var grantSolver = params.grant != false ? createGrantSolver(mesh) : null;
			_animatePMXMesh(mesh, sortedBonesData, ikSolver, grantSolver);

		} else {

			if (params.ik != false) {

				_createCCDIKSolver(mesh).update();

			}

			if (params.grant != false) {

				createGrantSolver(mesh).update();

			}

		}

		return this;

	}

	/**
	 * Enabes/Disables an animation feature.
	 *
	 * @param {string} key
	 * @param {boolean} enabled
	 * @return {MMDAnimationHelper}
	 */
	public function enable(key:String, enabled:Bool):MMDAnimationHelper {

		if (!Reflect.hasField(this.enabled, key)) {

			throw new String('THREE.MMDAnimationHelper.enable: unknown key ' + key);

		}

		Reflect.setField(this.enabled, key, enabled);

		if (key == "physics") {

			for (i in 0...meshes.length) {

				_optimizeIK(meshes[i], enabled);

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
	public function createGrantSolver(mesh:SkinnedMesh):GrantSolver {

		return new GrantSolver(mesh, mesh.geometry.userData.MMD.grants);

	}

	// private methods

	private function _addMesh(mesh:SkinnedMesh, params:Dynamic) {

		if (meshes.indexOf(mesh) >= 0) {

			throw new String('THREE.MMDAnimationHelper._addMesh: SkinnedMesh ${mesh.name} has already been added.');

		}

		meshes.push(mesh);
		objects.set(mesh, { looped: false });

		_setupMeshAnimation(mesh, params.animation);

		if (params.physics != false) {

			_setupMeshPhysics(mesh, params);

		}

	}

	private function _setupCamera(camera:three.cameras.Camera, params:Dynamic) {

		if (this.camera == camera) {

			throw new String('THREE.MMDAnimationHelper._setupCamera: Camera ${camera.name} has already been set.');

		}

		if (this.camera != null) _clearCamera(this.camera);

		this.camera = camera;

		camera.add(this.cameraTarget);

		objects.set(camera, {});

		if (params.animation != null) {

			_setupCameraAnimation(camera, params.animation);

		}

	}

	private function _setupAudio(audio:Audio, params:Dynamic) {

		if (this.audio == audio) {

			throw new String('THREE.MMDAnimationHelper._setupAudio: Audio ${audio.name} has already been set.');

		}

		if (this.audio != null) _clearAudio(this.audio);

		this.audio = audio;
		this.audioManager = new AudioManager(audio, params);

		objects.set(this.audioManager, {
			duration: this.audioManager.duration
		});

	}

	private function _removeMesh(mesh:SkinnedMesh) {

		var found = false;
		var writeIndex = 0;

		for (i in 0...meshes.length) {

			if (meshes[i] == mesh) {

				objects.remove(mesh);
				found = true;

				continue;

			}

			meshes[writeIndex++] = meshes[i];

		}

		if (!found) {

			throw new String('THREE.MMDAnimationHelper._removeMesh: SkinnedMesh ${mesh.name} has not been added yet.');

		}

		meshes.resize(writeIndex);

	}

	private function _clearCamera(camera:three.cameras.Camera) {

		if (camera != this.camera) {

			throw new String('THREE.MMDAnimationHelper._clearCamera: Camera \ '${camera.name}\' has not been set yet.');

		}

		this.camera.remove(this.cameraTarget);

		this.objects.remove(this.camera);
		this.camera = null;

	}

	private function _clearAudio(audio:Audio) {

		if (audio != this.audio) {

			throw new String('THREE.MMDAnimationHelper._clearAudio: Audio ${audio.name} has not been set yet.');

		}

		objects.remove(this.audioManager);

		this.audio = null;
		this.audioManager = null;

	}

	private function _setupMeshAnimation(mesh:SkinnedMesh, animation:Dynamic) {

		var objects:Dynamic = objects.get(mesh);

		if (animation != null) {
			var animations:Array<AnimationClip>;
			if (Std.is(animation, Array)) {
				animations = cast animation;
			} else {
				animations = [animation];
			}

			objects.mixer = new AnimationMixer(mesh);

			for (i in 0...animations.length) {

				objects.mixer.clipAction(animations[i]).play();

			}

			// TODO: find a workaround not to access ._clip looking like a private property
			objects.mixer.addEventListener("loop", function(event) {

				var tracks = event.action._clip.tracks;

				if (tracks.length > 0 && tracks[0].name.substr(0, 6) != ".bones") return;

				objects.looped = true;

			});

		}

		objects.ikSolver = _createCCDIKSolver(mesh);
		objects.grantSolver = createGrantSolver(mesh);

	}

	private function _setupCameraAnimation(camera:three.cameras.Camera, animation:Dynamic) {
		var animations:Array<AnimationClip>;
		if (Std.is(animation, Array)) {
			animations = cast animation;
		} else {
			animations = [animation];
		}

		var objects = this.objects.get(camera);

		objects.mixer = new AnimationMixer(camera);

		for (i in 0...animations.length) {

			objects.mixer.clipAction(animations[i]).play();

		}

	}

	private function _setupMeshPhysics(mesh:SkinnedMesh, params:Dynamic) {

		var objects:Dynamic = objects.get(mesh);

		// shared physics is experimental

		if (params.world == null && sharedPhysics) {

			var masterPhysics = _getMasterPhysics();

			if (masterPhysics != null) {

				var world = masterPhysics.world; // eslint-disable-line no-undef

			}

		}

		objects.physics = _createMMDPhysics(mesh, params);

		if (objects.mixer != null && params.animationWarmup != false) {

			_animateMesh(mesh, 0);
			objects.physics.reset();

		}

		objects.physics.warmup((params.warmup != null) ? params.warmup : 60);

		_optimizeIK(mesh, true);

	}

	private function _animateMesh(mesh:SkinnedMesh, delta:Float) {

		var objects:Dynamic = objects.get(mesh);

		var mixer = objects.mixer;
		var ikSolver = objects.ikSolver;
		var grantSolver = objects.grantSolver;
		var physics = objects.physics;
		var looped = objects.looped;

		if (mixer != null && enabled.animation) {

			// alternate solution to save/restore bones but less performant?
			//mesh.pose();
			//this._updatePropertyMixersBuffer( mesh );

			_restoreBones(mesh);

			mixer.update(delta);

			_saveBones(mesh);

			// PMX animation system special path
			if (configuration.pmxAnimation &&
				mesh.geometry.userData.exists("MMD") && mesh.geometry.userData.MMD.format == "pmx") {

				if (objects.sortedBonesData == null) objects.sortedBonesData = _sortBoneDataArray(mesh.geometry.userData.MMD.bones.copy());

				_animatePMXMesh(
					mesh,
					objects.sortedBonesData,
					ikSolver != null && enabled.ik ? ikSolver : null,
					grantSolver != null && enabled.grant ? grantSolver : null
				);

			} else {

				if (ikSolver != null && enabled.ik) {

					mesh.updateMatrixWorld(true);
					ikSolver.update();

				}

				if (grantSolver != null && enabled.grant) {

					grantSolver.update();

				}

			}

		}

		if (looped == true && enabled.physics) {

			if (physics != null && configuration.resetPhysicsOnLoop) physics.reset();

			objects.looped = false;

		}

		if (physics != null && enabled.physics && !sharedPhysics) {

			//this.onBeforePhysics( mesh ); // Not supported
			physics.update(delta);

		}

	}

	// Sort bones in order by 1. transformationClass and 2. bone index.
	// In PMX animation system, bone transformations should be processed
	// in this order.
	private function _sortBoneDataArray(boneDataArray:Array<Dynamic>):Array<Dynamic> {

		//return boneDataArray.sort( function ( a, b ) {
		boneDataArray.sort(function(a, b) {

			if (a.transformationClass != b.transformationClass) {

				return a.transformationClass - b.transformationClass;

			} else {

				return a.index - b.index;

			}

		});

		return boneDataArray;

	}

	// PMX Animation system is a bit too complex and doesn't great match to
	// Three.js Animation system. This method attempts to simulate it as much as
	// possible but doesn't perfectly simulate.
	// This method is more costly than the regular one so
	// you are recommended to set constructor parameter "pmxAnimation: true"
	// only if your PMX model animation doesn't work well.
	// If you need better method you would be required to write your own.
	private function _animatePMXMesh(mesh:SkinnedMesh, sortedBonesData:Array<Dynamic>, ikSolver:CCDIKSolver, grantSolver:GrantSolver):MMDAnimationHelper {

		_quaternionIndex = 0;
		_grantResultMap = new Map<Int, Quaternion>();

		for (i in 0...sortedBonesData.length) {

			updateOne(mesh, sortedBonesData[i].index, ikSolver, grantSolver);

		}

		mesh.updateMatrixWorld(true);
		return this;

	}

	private function _animateCamera(camera:three.cameras.Camera, delta:Float) {

		var mixer = objects.get(camera).mixer;

		if (mixer != null && enabled.cameraAnimation) {

			mixer.update(delta);

			camera.updateProjectionMatrix();

			camera.up.set(0, 1, 0);
			camera.up.applyQuaternion(camera.quaternion);
			camera.lookAt(cameraTarget.position);

		}

	}

	private function _optimizeIK(mesh:SkinnedMesh, physicsEnabled:Bool) {

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

	private function _createCCDIKSolver(mesh:SkinnedMesh):CCDIKSolver {

		if (CCDIKSolver == null) {

			throw new String("THREE.MMDAnimationHelper: Import CCDIKSolver.");

		}

		return new CCDIKSolver(mesh, mesh.geometry.userData.MMD.iks);

	}

	private function _createMMDPhysics(mesh:SkinnedMesh, params:Dynamic):MMDPhysics {

		if (MMDPhysics == null) {

			throw new String("THREE.MMDPhysics: Import MMDPhysics.");

		}

		return new MMDPhysics(
			mesh,
			mesh.geometry.userData.MMD.rigidBodies,
			mesh.geometry.userData.MMD.constraints,
			params
		);

	}

	/*
	 * Detects the longest duration and then sets it to them to sync.
	 * TODO: Not to access private properties ( ._actions and ._clip )
	 */
	private function _syncDuration() {

		var max = 0.0;

		// get the longest duration

		for (i in 0...meshes.length) {

			var mixer = objects.get(meshes[i]).mixer;

			if (mixer == null) continue;

			for (j in 0...mixer._actions.length) {

				var clip = mixer._actions[j]._clip;

				if (!objects.exists(clip)) {

					objects.set(clip, {
						duration: clip.duration
					});

				}

				max = Math.max(max, objects.get(clip).duration);

			}

		}

		if (camera != null) {

			var mixer = objects.get(camera).mixer;

			if (mixer != null) {

				for (i in 0...mixer._actions.length) {

					var clip = mixer._actions[i]._clip;

					if (!objects.exists(clip)) {

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

		max += configuration.afterglow;

		// update the duration

		for (i in 0...meshes.length) {

			var mixer = objects.get(meshes[i]).mixer;

			if (mixer == null) continue;

			for (j in 0...mixer._actions.length) {

				mixer._actions[j]._clip.duration = max;

			}

		}

		if (camera != null) {

			var mixer = objects.get(camera).mixer;

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

	// private function _updatePropertyMixersBuffer( mesh:SkinnedMesh ) {
	//
	// 	var mixer = objects.get( mesh ).mixer;
	//
	// 	var propertyMixers = mixer._bindings;
	// 	var accuIndex = mixer._accuIndex;
	//
	// 	for ( i = 0, il = propertyMixers.length; i < il; i ++ ) {
	//
	// 		var propertyMixer = propertyMixers[ i ];
	// 		var buffer = propertyMixer.buffer;
	// 		var stride = propertyMixer.valueSize;
	// 		var offset = ( accuIndex + 1 ) * stride;
	//
	// 		propertyMixer.binding.getValue( buffer, offset );
	//
	// 	}
	//
	// }

	/*
	 * Avoiding these two issues by restore/save bones before/after mixer animation.
	 *
	 * 1. PropertyMixer used by AnimationMixer holds cache value in .buffer.
	 *    Calculating IK, Grant, and Physics after mixer animation can break
	 *    the cache coherency.
	 *
	 * 2. Applying Grant two or more times without reset the posing breaks model.
	 */
	private function _saveBones(mesh:SkinnedMesh) {

		var objects:Dynamic = objects.get(mesh);

		var bones = mesh.skeleton.bones;

		var backupBones:Vector<Float> = objects.backupBones; //new Float32Array( bones.length * 7 );

		if (backupBones == null) {

			backupBones = new Vector<Float>(bones.length * 7);
			objects.backupBones = backupBones;

		}

		for (i in 0...bones.length) {

			var bone = bones[i];
			bone.position.toArray(backupBones, i * 7);
			bone.quaternion.toArray(backupBones, i * 7 + 3);

		}

	}

	private function _restoreBones(mesh:SkinnedMesh) {

		var objects:Dynamic = objects.get(mesh);

		var backupBones:Vector<Float> = objects.backupBones;

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

		if (masterPhysics != null) return masterPhysics;

		for (i in 0...meshes.length) {

			var physics = meshes[i].physics;

			if (physics != null) {

				masterPhysics = physics;
				return masterPhysics;

			}

		}

		return null;

	}

	private function _updateSharedPhysics(delta:Float) {

		if (meshes.length == 0 || !enabled.physics || !sharedPhysics) return;

		var physics = _getMasterPhysics();

		if (physics == null) return;

		for (i in 0...meshes.length) {

			var p = meshes[i].physics;

			if (p != null) {

				p.updateRigidBodies();

			}

		}

		physics.stepSimulation(delta);

		for (i in 0...meshes.length) {

			var p = meshes[i].physics;

			if (p != null) {

				p.updateBones();

			}

		}

	}

	public var meshes:Array<SkinnedMesh>;
	public var camera:three.cameras.Camera;
	public var cameraTarget:Object3D;
	public var audio:Audio;
	public var audioManager:AudioManager;
	public var objects:Map<Dynamic, Dynamic>;
	public var configuration:Dynamic;
	public var enabled:Dynamic;
	public var sharedPhysics:Bool;
	public var masterPhysics:MMDPhysics;

}

// Keep working quaternions for less GC
var _quaternions = new Array<Quaternion>();
var _quaternionIndex = 0;

function getQuaternion():Quaternion {

	if (_quaternionIndex >= _quaternions.length) {

		_quaternions.push(new Quaternion());

	}

	return _quaternions[_quaternionIndex++];

}

// Save rotation whose grant and IK are already applied
// used by grant children
var _grantResultMap = new Map<Int, Quaternion>();

function updateOne(mesh:SkinnedMesh, boneIndex:Int, ikSolver:CCDIKSolver, grantSolver:GrantSolver) {

	var bones = mesh.skeleton.bones;
	var bonesData = mesh.geometry.userData.MMD.bones;
	var boneData = bonesData[boneIndex];
	var bone = bones[boneIndex];

	// Return if already updated by being referred as a grant parent.
	if (_grantResultMap.exists(boneIndex)) return;

	var quaternion = getQuaternion();

	// Initialize grant result here to prevent infinite loop.
	// If it's referred before updating with actual result later
	// result without applyting IK or grant is gotten
	// but better than composing of infinite loop.
	_grantResultMap.set(boneIndex, quaternion.copy(bone.quaternion));

	// @TODO: Support global grant and grant position
	if (grantSolver != null && boneData.grant != null &&
		!boneData.grant.isLocal && boneData.grant.affectRotation) {

		var parentIndex = boneData.grant.parentIndex;
		var ratio = boneData.grant.ratio;

		if (!_grantResultMap.exists(parentIndex)) {

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

			if (_grantResultMap.exists(linkIndex)) {

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
	 * @param {Nuumber} params.delayTime
	 */
	public function new(audio:Audio, params:Dynamic = null) {

		if (params == null) params = {};

		this.audio = audio;

		elapsedTime = 0.0;
		currentTime = 0.0;
		delayTime = (params.delayTime != null) ? params.delayTime : 0.0;

		audioDuration = audio.buffer.duration;
		duration = audioDuration + delayTime;

	}

	/**
	 * @param {Number} delta
	 * @return {AudioManager}
	 */
	public function control(delta:Float):AudioManager {

		elapsed += delta;
		currentTime += delta;

		if (_shouldStopAudio()) audio.stop();
		if (_shouldStartAudio()) audio.play();

		return this;

	}

	// private methods

	private function _shouldStartAudio():Bool {

		if (audio.isPlaying) return false;

		while (currentTime >= duration) {

			currentTime -= duration;

		}

		if (currentTime < delayTime) return false;

		// 'duration' can be bigger than 'audioDuration + delayTime' because of sync configuration
		if ((currentTime - delayTime) > audioDuration) return false;

		return true;

	}

	private function _shouldStopAudio():Bool {

		return audio.isPlaying && currentTime >= duration;

	}

	public var audio:Audio;
	public var elapsedTime:Float;
	public var currentTime:Float;
	public var delayTime:Float;
	public var audioDuration:Float;
	public var duration:Float;
	public var elapsed(get, set):Float;

	private function get_elapsed():Float {
		return elapsedTime;
	}

	private function set_elapsed(value:Float):Float {
		return elapsedTime = value;
	}

}

var _q = new Quaternion();

/**
 * Solver for Grant (Fuyo in Japanese. I just google translated because
 * Fuyo may be MMD specific term and may not be common word in 3D CG terms.)
 * Grant propagates a bone's transform to other bones transforms even if
 * they are not children.
 * @param {THREE.SkinnedMesh} mesh
 * @param {Array<Object>} grants
 */
class GrantSolver {

	public function new(mesh:SkinnedMesh, grants:Array<Dynamic> = null) {

		if (grants == null) grants = [];

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

			updateOne(grants[i]);

		}

		return this;

	}

	/**
	 * Solve a grant bone
	 * @param {Object} grant - grant parameter
	 * @return {GrantSolver}
	 */
	public function updateOne(grant:Dynamic):GrantSolver {

		var bones = mesh.skeleton.bones;
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

				addGrantRotation(bone, parentBone.quaternion, grant.ratio);

			}

		}

		return this;

	}

	public function addGrantRotation(bone:Dynamic, q:Quaternion, ratio:Float):GrantSolver {

		_q.set(0, 0, 0, 1);
		_q.slerp(q, ratio);
		bone.quaternion.multiply(_q);

		return this;

	}

	public var mesh:SkinnedMesh;
	public var grants:Array<Dynamic>;

}