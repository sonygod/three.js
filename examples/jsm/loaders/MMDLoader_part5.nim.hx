class AnimationBuilder {

	/**
	 * @param vmd:Object - parsed VMD data
	 * @param mesh:SkinnedMesh - tracks will be fitting to mesh
	 * @return AnimationClip
	 */
	public function build(vmd:Object, mesh:SkinnedMesh):AnimationClip {

		// combine skeletal and morph animations

		var tracks = this.buildSkeletalAnimation(vmd, mesh).tracks;
		var tracks2 = this.buildMorphAnimation(vmd, mesh).tracks;

		for (i in 0...tracks2.length) {

			tracks.push(tracks2[i]);

		}

		return new AnimationClip("", -1, tracks);

	}

	/**
	 * @param vmd:Object - parsed VMD data
	 * @param mesh:SkinnedMesh - tracks will be fitting to mesh
	 * @return AnimationClip
	 */
	public function buildSkeletalAnimation(vmd:Object, mesh:SkinnedMesh):AnimationClip {

		function pushInterpolation(array:Array<Float>, interpolation:Array<Float>, index:Int) {

			array.push(interpolation[index + 0] / 127); // x1
			array.push(interpolation[index + 8] / 127); // x2
			array.push(interpolation[index + 4] / 127); // y1
			array.push(interpolation[index + 12] / 127); // y2

		}

		var tracks:Array<Track> = [];

		var motions:Object = {};
		var bones:Array<Bone> = mesh.skeleton.bones;
		var boneNameDictionary:Object = {};

		for (i in 0...bones.length) {

			boneNameDictionary[bones[i].name] = true;

		}

		for (i in 0...vmd.metadata.motionCount) {

			var motion:Motion = vmd.motions[i];
			var boneName:String = motion.boneName;

			if (boneNameDictionary[boneName] === undefined) continue;

			motions[boneName] = motions[boneName] || [];
			motions[boneName].push(motion);

		}

		for (key in motions) {

			var array:Array<Motion> = motions[key];

			array.sort(function(a:Motion, b:Motion) {

				return a.frameNum - b.frameNum;

			});

			var times:Array<Float> = [];
			var positions:Array<Float> = [];
			var rotations:Array<Float> = [];
			var pInterpolations:Array<Float> = [];
			var rInterpolations:Array<Float> = [];

			var basePosition:Array<Float> = mesh.skeleton.getBoneByName(key).position.toArray();

			for (i in 0...array.length) {

				var time:Float = array[i].frameNum / 30;
				var position:Array<Float> = array[i].position;
				var rotation:Array<Float> = array[i].rotation;
				var interpolation:Array<Float> = array[i].interpolation;

				times.push(time);

				for (j in 0...3) positions.push(basePosition[j] + position[j]);
				for (j in 0...4) rotations.push(rotation[j]);
				for (j in 0...3) pushInterpolation(pInterpolations, interpolation, j);

				pushInterpolation(rInterpolations, interpolation, 3);

			}

			var targetName:String = '.bones[' + key + ']';

			tracks.push(this._createTrack(targetName + '.position', VectorKeyframeTrack, times, positions, pInterpolations));
			tracks.push(this._createTrack(targetName + '.quaternion', QuaternionKeyframeTrack, times, rotations, rInterpolations));

		}

		return new AnimationClip("", -1, tracks);

	}

	/**
	 * @param vmd:Object - parsed VMD data
	 * @param mesh:SkinnedMesh - tracks will be fitting to mesh
	 * @return AnimationClip
	 */
	public function buildMorphAnimation(vmd:Object, mesh:SkinnedMesh):AnimationClip {

		var tracks:Array<Track> = [];

		var morphs:Object = {};
		var morphTargetDictionary:Object = mesh.morphTargetDictionary;

		for (i in 0...vmd.metadata.morphCount) {

			var morph:Morph = vmd.morphs[i];
			var morphName:String = morph.morphName;

			if (morphTargetDictionary[morphName] === undefined) continue;

			morphs[morphName] = morphs[morphName] || [];
			morphs[morphName].push(morph);

		}

		for (key in morphs) {

			var array:Array<Morph> = morphs[key];

			array.sort(function(a:Morph, b:Morph) {

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

		return new AnimationClip("", -1, tracks);

	}

	/**
	 * @param vmd:Object - parsed VMD data
	 * @return AnimationClip
	 */
	public function buildCameraAnimation(vmd:Object):AnimationClip {

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

			array.push(interpolation[index * 4 + 0] / 127); // x1
			array.push(interpolation[index * 4 + 1] / 127); // x2
			array.push(interpolation[index * 4 + 2] / 127); // y1
			array.push(interpolation[index * 4 + 3] / 127); // y2

		}

		var cameras:Array<Camera> = vmd.cameras === undefined ? [] : vmd.cameras.slice();

		cameras.sort(function(a:Camera, b:Camera) {

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

			var motion:Camera = cameras[i];

			var time:Float = motion.frameNum / 30;
			var pos:Array<Float> = motion.position;
			var rot:Array<Float> = motion.rotation;
			var distance:Float = motion.distance;
			var fov:Float = motion.fov;
			var interpolation:Array<Float> = motion.interpolation;

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

		var tracks:Array<Track> = [];

		// I expect an object whose name 'target' exists under THREE.Camera
		tracks.push(this._createTrack('target.position', VectorKeyframeTrack, times, centers, cInterpolations));

		tracks.push(this._createTrack('.quaternion', QuaternionKeyframeTrack, times, quaternions, qInterpolations));
		tracks.push(this._createTrack('.position', VectorKeyframeTrack, times, positions, pInterpolations));
		tracks.push(this._createTrack('.fov', NumberKeyframeTrack, times, fovs, fInterpolations));

		return new AnimationClip("", -1, tracks);

	}

	// private method

	private function _createTrack(node:String, typedKeyframeTrack:Class<Track>, times:Array<Float>, values:Array<Float>, interpolations:Array<Float>):Track {

		/*
			 * optimizes here not to let KeyframeTrackPrototype optimize
			 * because KeyframeTrackPrototype optimizes times and values but
			 * doesn't optimize interpolations.
			 */
		if (times.length > 2) {

			times = times.slice();
			values = values.slice();
			interpolations = interpolations.slice();

			var stride:Int = values.length / times.length;
			var interpolateStride:Int = interpolations.length / times.length;

			var index:Int = 1;

			for (aheadIndex in 2...times.length) {

				for (i in 0...stride) {

					if (values[index * stride + i] !== values[(index - 1) * stride + i] ||
							values[index * stride + i] !== values[aheadIndex * stride + i]) {

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

		var track:Track = Type.createInstance(typedKeyframeTrack, [node, times, values]);

		track.createInterpolant = function(result:Float) {

			return new CubicBezierInterpolation(this.times, this.values, this.getValueSize(), result, new Float32Array(interpolations));

		};

		return track;

	}

}