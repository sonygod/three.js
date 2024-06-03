import haxe.ds.StringMap;
import three.animation.AnimationClip;
import three.animation.KeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.animation.QuaternionKeyframeTrack;
import three.animation.NumberKeyframeTrack;
import three.core.Object3D;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Euler;
import three.objects.SkinnedMesh;

class AnimationBuilder {

	/**
	 * @param {Object} vmd - parsed VMD data
	 * @param {SkinnedMesh} mesh - tracks will be fitting to mesh
	 * @return {AnimationClip}
	 */
	public function build(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {

		// combine skeletal and morph animations

		var tracks = this.buildSkeletalAnimation(vmd, mesh).tracks;
		var tracks2 = this.buildMorphAnimation(vmd, mesh).tracks;

		for (i in 0...tracks2.length) {

			tracks.push(tracks2[i]);

		}

		return new AnimationClip('', -1, tracks);

	}

	/**
	 * @param {Object} vmd - parsed VMD data
	 * @param {SkinnedMesh} mesh - tracks will be fitting to mesh
	 * @return {AnimationClip}
	 */
	public function buildSkeletalAnimation(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {

		function pushInterpolation(array:Array<Float>, interpolation:Array<Int>, index:Int):Void {

			array.push(interpolation[index + 0] / 127); // x1
			array.push(interpolation[index + 8] / 127); // x2
			array.push(interpolation[index + 4] / 127); // y1
			array.push(interpolation[index + 12] / 127); // y2

		}

		var tracks:Array<KeyframeTrack> = [];

		var motions:StringMap<Array<Dynamic>> = new StringMap();
		var bones:Array<Object3D> = mesh.skeleton.bones;
		var boneNameDictionary:StringMap<Bool> = new StringMap();

		for (i in 0...bones.length) {

			boneNameDictionary.set(bones[i].name, true);

		}

		for (i in 0...vmd.metadata.motionCount) {

			var motion = vmd.motions[i];
			var boneName = motion.boneName;

			if (boneNameDictionary.exists(boneName) == false) continue;

			motions.set(boneName, motions.get(boneName) == null ? [] : motions.get(boneName));
			motions.get(boneName).push(motion);

		}

		for (key in motions.keys()) {

			var array = motions.get(key);

			array.sort(function(a:Dynamic, b:Dynamic) {

				return a.frameNum - b.frameNum;

			});

			var times:Array<Float> = [];
			var positions:Array<Float> = [];
			var rotations:Array<Float> = [];
			var pInterpolations:Array<Float> = [];
			var rInterpolations:Array<Float> = [];

			var basePosition = mesh.skeleton.getBoneByName(key).position.toArray();

			for (i in 0...array.length) {

				var time = array[i].frameNum / 30;
				var position = array[i].position;
				var rotation = array[i].rotation;
				var interpolation = array[i].interpolation;

				times.push(time);

				for (j in 0...3) positions.push(basePosition[j] + position[j]);
				for (j in 0...4) rotations.push(rotation[j]);
				for (j in 0...3) pushInterpolation(pInterpolations, interpolation, j);

				pushInterpolation(rInterpolations, interpolation, 3);

			}

			var targetName = '.bones[' + key + ']';

			tracks.push(this._createTrack(targetName + '.position', VectorKeyframeTrack, times, positions, pInterpolations));
			tracks.push(this._createTrack(targetName + '.quaternion', QuaternionKeyframeTrack, times, rotations, rInterpolations));

		}

		return new AnimationClip('', -1, tracks);

	}

	/**
	 * @param {Object} vmd - parsed VMD data
	 * @param {SkinnedMesh} mesh - tracks will be fitting to mesh
	 * @return {AnimationClip}
	 */
	public function buildMorphAnimation(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {

		var tracks:Array<KeyframeTrack> = [];

		var morphs:StringMap<Array<Dynamic>> = new StringMap();
		var morphTargetDictionary = mesh.morphTargetDictionary;

		for (i in 0...vmd.metadata.morphCount) {

			var morph = vmd.morphs[i];
			var morphName = morph.morphName;

			if (morphTargetDictionary.exists(morphName) == false) continue;

			morphs.set(morphName, morphs.get(morphName) == null ? [] : morphs.get(morphName));
			morphs.get(morphName).push(morph);

		}

		for (key in morphs.keys()) {

			var array = morphs.get(key);

			array.sort(function(a:Dynamic, b:Dynamic) {

				return a.frameNum - b.frameNum;

			});

			var times:Array<Float> = [];
			var values:Array<Float> = [];

			for (i in 0...array.length) {

				times.push(array[i].frameNum / 30);
				values.push(array[i].weight);

			}

			tracks.push(new NumberKeyframeTrack('.morphTargetInfluences[' + morphTargetDictionary.get(key) + ']', times, values));

		}

		return new AnimationClip('', -1, tracks);

	}

	/**
	 * @param {Object} vmd - parsed VMD data
	 * @return {AnimationClip}
	 */
	public function buildCameraAnimation(vmd:Dynamic):AnimationClip {

		function pushVector3(array:Array<Float>, vec:Vector3):Void {

			array.push(vec.x);
			array.push(vec.y);
			array.push(vec.z);

		}

		function pushQuaternion(array:Array<Float>, q:Quaternion):Void {

			array.push(q.x);
			array.push(q.y);
			array.push(q.z);
			array.push(q.w);

		}

		function pushInterpolation(array:Array<Float>, interpolation:Array<Int>, index:Int):Void {

			array.push(interpolation[index * 4 + 0] / 127); // x1
			array.push(interpolation[index * 4 + 1] / 127); // x2
			array.push(interpolation[index * 4 + 2] / 127); // y1
			array.push(interpolation[index * 4 + 3] / 127); // y2

		}

		var cameras = vmd.cameras == null ? [] : vmd.cameras.copy();

		cameras.sort(function(a:Dynamic, b:Dynamic) {

			return a.frameNum - b.frameNum;

		});

		var times:Array<Float> = [];
		var centers:Array<Float> = [];
		var quaternions:Array<Float> = [];
		var positions:Array<Float> = [];
		var fovs:Array<Float> = [];

		var cInterpolations:Array<Float> = [];
		var qInterpolations:Array<Float> = [];
		var pInterpolations:Array<Float> = [];
		var fInterpolations:Array<Float> = [];

		var quaternion = new Quaternion();
		var euler = new Euler();
		var position = new Vector3();
		var center = new Vector3();

		for (i in 0...cameras.length) {

			var motion = cameras[i];

			var time = motion.frameNum / 30;
			var pos = motion.position;
			var rot = motion.rotation;
			var distance = motion.distance;
			var fov = motion.fov;
			var interpolation = motion.interpolation;

			times.push(time);

			position.set(0, 0, -distance);
			center.set(pos[0], pos[1], pos[2]);

			euler.set(-rot[0], -rot[1], -rot[2]);
			quaternion.setFromEuler(euler);

			position.add(center);
			position.applyQuaternion(quaternion);

			pushVector3(centers, center);
			pushQuaternion(quaternions, quaternion);
			pushVector3(positions, position);

			fovs.push(fov);

			for (j in 0...3) {

				pushInterpolation(cInterpolations, interpolation, j);

			}

			pushInterpolation(qInterpolations, interpolation, 3);

			// use the same parameter for x, y, z axis.
			for (j in 0...3) {

				pushInterpolation(pInterpolations, interpolation, 4);

			}

			pushInterpolation(fInterpolations, interpolation, 5);

		}

		var tracks:Array<KeyframeTrack> = [];

		// I expect an object whose name 'target' exists under THREE.Camera
		tracks.push(this._createTrack('target.position', VectorKeyframeTrack, times, centers, cInterpolations));

		tracks.push(this._createTrack('.quaternion', QuaternionKeyframeTrack, times, quaternions, qInterpolations));
		tracks.push(this._createTrack('.position', VectorKeyframeTrack, times, positions, pInterpolations));
		tracks.push(this._createTrack('.fov', NumberKeyframeTrack, times, fovs, fInterpolations));

		return new AnimationClip('', -1, tracks);

	}

	// private method

	private function _createTrack(node:String, typedKeyframeTrack:Class<KeyframeTrack>, times:Array<Float>, values:Array<Float>, interpolations:Array<Float>):KeyframeTrack {

		/*
			 * optimizes here not to let KeyframeTrackPrototype optimize
			 * because KeyframeTrackPrototype optimizes times and values but
			 * doesn't optimize interpolations.
			 */
		if (times.length > 2) {

			times = times.copy();
			values = values.copy();
			interpolations = interpolations.copy();

			var stride = values.length / times.length;
			var interpolateStride = interpolations.length / times.length;

			var index = 1;

			for (aheadIndex in 2...times.length) {

				for (i in 0...stride) {

					if (values[index * stride + i] != values[(index - 1) * stride + i] ||
							values[index * stride + i] != values[aheadIndex * stride + i]) {

						index++;
						break;

					}

				}

				if (aheadIndex > index) {

					times[index] = times[aheadIndex];

					for (i in 0...stride) {

						values[index * stride + i] = values[aheadIndex * stride + i];

					}

					for (i in 0...interpolateStride) {

						interpolations[index * interpolateStride + i] = interpolations[aheadIndex * interpolateStride + i];

					}

				}

			}

			times.length = index + 1;
			values.length = (index + 1) * stride;
			interpolations.length = (index + 1) * interpolateStride;

		}

		var track = new typedKeyframeTrack(node, times, values);

		track.createInterpolant = function(result:Dynamic):Dynamic {

			// this.times, this.values, this.getValueSize(), result, new Float32Array(interpolations)
			//  - Create a Float32Array from the interpolations array.
			//  - Pass these parameters to the CubicBezierInterpolation constructor.
			return new CubicBezierInterpolation(this.times, this.values, this.getValueSize(), result, new Float32Array(interpolations));

		};

		return track;

	}

}