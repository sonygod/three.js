import three.animation.AnimationClip;
import three.animation.tracks.NumberKeyframeTrack;
import three.animation.tracks.QuaternionKeyframeTrack;
import three.animation.tracks.VectorKeyframeTrack;
import three.core.Euler;
import three.core.Quaternion;
import three.core.Vector3;
import three.interpolants.CubicBezierInterpolation;
import three.objects.SkinnedMesh;

class AnimationBuilder {
	public function build(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {
		var tracks:Array<any> = this.buildSkeletalAnimation(vmd, mesh).tracks;
		var tracks2:Array<any> = this.buildMorphAnimation(vmd, mesh).tracks;

		for (i in 0...tracks2.length) {
			tracks.push(tracks2[i]);
		}

		return new AnimationClip('', -1, tracks);
	}

	public function buildSkeletalAnimation(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {
		function pushInterpolation(array:Array<Float>, interpolation:Array<Float>, index:Int) {
			array.push(interpolation[index + 0] / 127);
			array.push(interpolation[index + 8] / 127);
			array.push(interpolation[index + 4] / 127);
			array.push(interpolation[index + 12] / 127);
		}

		var tracks:Array<any> = [];
		var motions:Dynamic = {};
		var bones = mesh.skeleton.bones;
		var boneNameDictionary:Dynamic = {};

		for (i in 0...bones.length) {
			boneNameDictionary[bones[i].name] = true;
		}

		for (i in 0...vmd.metadata.motionCount) {
			var motion = vmd.motions[i];
			var boneName = motion.boneName;

			if (boneNameDictionary[boneName] == null) continue;

			if (motions[boneName] == null) motions[boneName] = [];
			motions[boneName].push(motion);
		}

		for (key in Reflect.fields(motions)) {
			var array = motions[key];

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

	public function buildMorphAnimation(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {
		var tracks:Array<NumberKeyframeTrack> = [];
		var morphs:Dynamic = {};
		var morphTargetDictionary = mesh.morphTargetDictionary;

		for (i in 0...vmd.metadata.morphCount) {
			var morph = vmd.morphs[i];
			var morphName = morph.morphName;

			if (morphTargetDictionary[morphName] == null) continue;

			if (morphs[morphName] == null) morphs[morphName] = [];
			morphs[morphName].push(morph);
		}

		for (key in Reflect.fields(morphs)) {
			var array = morphs[key];

			array.sort(function(a:Dynamic, b:Dynamic) {
				return a.frameNum - b.frameNum;
			});

			var times:Array<Float> = [];
			var values:Array<Float> = [];

			for (i in 0...array.length) {
				times.push(array[i].frameNum / 30);
				values.push(array[i].weight);
			}

			tracks.push(new NumberKeyframeTrack('.morphTargetInfluences[' + morphTargetDictionary[key] + ']', times, values));
		}

		return new AnimationClip('', -1, tracks);
	}

	public function buildCameraAnimation(vmd:Dynamic):AnimationClip {
		function pushVector3(array:Array<Float>, vec:Vector3) {
			array.push(vec.x);
			array.push(vec.y);
			array.push(vec.z);
		}

		function pushQuaternion(array:Array<Float>, q:Quaternion) {
			array.push(q.x);
			array.push(q.y);
			array.push(q.z);
			array.push(q.w);
		}

		function pushInterpolation(array:Array<Float>, interpolation:Array<Float>, index:Int) {
			array.push(interpolation[index * 4 + 0] / 127);
			array.push(interpolation[index * 4 + 1] / 127);
			array.push(interpolation[index * 4 + 2] / 127);
			array.push(interpolation[index * 4 + 3] / 127);
		}

		var cameras:Array<Dynamic> = vmd.cameras == null ? [] : vmd.cameras.slice();

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

		var quaternion:Quaternion = new Quaternion();
		var euler:Euler = new Euler();
		var position:Vector3 = new Vector3();
		var center:Vector3 = new Vector3();

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

			for (j in 0...3) {
				pushInterpolation(pInterpolations, interpolation, 4);
			}

			pushInterpolation(fInterpolations, interpolation, 5);
		}

		var tracks:Array<any> = [];

		tracks.push(this._createTrack('target.position', VectorKeyframeTrack, times, centers, cInterpolations));
		tracks.push(this._createTrack('.quaternion', QuaternionKeyframeTrack, times, quaternions, qInterpolations));
		tracks.push(this._createTrack('.position', VectorKeyframeTrack, times, positions, pInterpolations));
		tracks.push(this._createTrack('.fov', NumberKeyframeTrack, times, fovs, fInterpolations));

		return new AnimationClip('', -1, tracks);
	}

	private function _createTrack(node:String, typedKeyframeTrack:Class<any>, times:Array<Float>, values:Array<Float>, interpolations:Array<Float>):any {
		if (times.length > 2) {
			times = times.slice();
			values = values.slice();
			interpolations = interpolations.slice();

			var stride = values.length / times.length;
			var interpolateStride = interpolations.length / times.length;

			var index = 1;

			for (var aheadIndex = 2, endIndex = times.length; aheadIndex < endIndex; aheadIndex++) {
				for (var i = 0; i < stride; i++) {
					if (values[index * stride + i] != values[(index - 1) * stride + i] ||
							values[index * stride + i] != values[aheadIndex * stride + i]) {
						index++;
						break;
					}
				}

				if (aheadIndex > index) {
					times[index] = times[aheadIndex];

					for (var i = 0; i < stride; i++) {
						values[index * stride + i] = values[aheadIndex * stride + i];
					}

					for (var i = 0; i < interpolateStride; i++) {
						interpolations[index * interpolateStride + i] = interpolations[aheadIndex * interpolateStride + i];
					}
				}
			}

			times.length = index + 1;
			values.length = (index + 1) * stride;
			interpolations.length = (index + 1) * interpolateStride;
		}

		var track:any = Reflect.makeInstance(typedKeyframeTrack, [node, times, values]);

		track.createInterpolant = function(result) {
			return new CubicBezierInterpolation(this.times, this.values, this.getValueSize(), result, new Float32Array(interpolations));
		};

		return track;
	}
}