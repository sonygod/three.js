import three.animation.AnimationClip;
import three.animation.AnimationMixer;
import three.math.Matrix4;
import three.math.Quaternion;
import three.animation.tracks.QuaternionKeyframeTrack;
import three.animation.tracks.VectorKeyframeTrack;
import three.math.Vector3;
import three.objects.SkeletonHelper;

class Retarget {

	public static function retarget(target:Dynamic, source:Dynamic, options:Dynamic = {}):Void {

		var pos = new Vector3();
		var quat = new Quaternion();
		var scale = new Vector3();
		var bindBoneMatrix = new Matrix4();
		var relativeMatrix = new Matrix4();
		var globalMatrix = new Matrix4();

		options.preserveMatrix = (options.preserveMatrix != null) ? options.preserveMatrix : true;
		options.preservePosition = (options.preservePosition != null) ? options.preservePosition : true;
		options.preserveHipPosition = (options.preserveHipPosition != null) ? options.preserveHipPosition : false;
		options.useTargetMatrix = (options.useTargetMatrix != null) ? options.useTargetMatrix : false;
		options.hip = (options.hip != null) ? options.hip : "hip";
		options.names = options.names || {};

		var sourceBones = (source.isObject3D) ? source.skeleton.bones : Retarget.getBones(source);
		var bones = (target.isObject3D) ? target.skeleton.bones : Retarget.getBones(target);

		var bindBones:Array<Matrix4>;
		var bone:Dynamic;
		var name:String;
		var boneTo:Dynamic;
		var bonesPosition:Array<Vector3>;

		// reset bones
		if (target.isObject3D) {
			target.skeleton.pose();
		} else {
			options.useTargetMatrix = true;
			options.preserveMatrix = false;
		}

		if (options.preservePosition) {
			bonesPosition = [];
			for (i in 0...bones.length) {
				bonesPosition.push(bones[i].position.clone());
			}
		}

		if (options.preserveMatrix) {
			// reset matrix
			target.updateMatrixWorld();
			target.matrixWorld.identity();
			// reset children matrix
			for (i in 0...target.children.length) {
				target.children[i].updateMatrixWorld(true);
			}
		}

		if (options.offsets) {
			bindBones = [];
			for (i in 0...bones.length) {
				bone = bones[i];
				name = options.names[bone.name] || bone.name;
				if (options.offsets[name]) {
					bone.matrix.multiply(options.offsets[name]);
					bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);
					bone.updateMatrixWorld();
				}
				bindBones.push(bone.matrixWorld.clone());
			}
		}

		for (i in 0...bones.length) {
			bone = bones[i];
			name = options.names[bone.name] || bone.name;
			boneTo = Retarget.getBoneByName(name, sourceBones);
			globalMatrix.copy(bone.matrixWorld);
			if (boneTo) {
				boneTo.updateMatrixWorld();
				if (options.useTargetMatrix) {
					relativeMatrix.copy(boneTo.matrixWorld);
				} else {
					relativeMatrix.copy(target.matrixWorld).invert();
					relativeMatrix.multiply(boneTo.matrixWorld);
				}
				// ignore scale to extract rotation
				scale.setFromMatrixScale(relativeMatrix);
				relativeMatrix.scale(scale.set(1 / scale.x, 1 / scale.y, 1 / scale.z));
				// apply to global matrix
				globalMatrix.makeRotationFromQuaternion(quat.setFromRotationMatrix(relativeMatrix));
				if (target.isObject3D) {
					var boneIndex = bones.indexOf(bone);
					var wBindMatrix = (bindBones) ? bindBones[boneIndex] : bindBoneMatrix.copy(target.skeleton.boneInverses[boneIndex]).invert();
					globalMatrix.multiply(wBindMatrix);
				}
				globalMatrix.copyPosition(relativeMatrix);
			}
			if (bone.parent && bone.parent.isBone) {
				bone.matrix.copy(bone.parent.matrixWorld).invert();
				bone.matrix.multiply(globalMatrix);
			} else {
				bone.matrix.copy(globalMatrix);
			}
			if (options.preserveHipPosition && name == options.hip) {
				bone.matrix.setPosition(pos.set(0, bone.position.y, 0));
			}
			bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);
			bone.updateMatrixWorld();
		}

		if (options.preservePosition) {
			for (i in 0...bones.length) {
				bone = bones[i];
				name = options.names[bone.name] || bone.name;
				if (name != options.hip) {
					bone.position.copy(bonesPosition[i]);
				}
			}
		}

		if (options.preserveMatrix) {
			// restore matrix
			target.updateMatrixWorld(true);
		}

	}

	public static function retargetClip(target:Dynamic, source:Dynamic, clip:AnimationClip, options:Dynamic = {}):AnimationClip {

		options.useFirstFramePosition = (options.useFirstFramePosition != null) ? options.useFirstFramePosition : false;
		// Calculate the fps from the source clip based on the track with the most frames, unless fps is already provided.
		options.fps = (options.fps != null) ? options.fps : (Math.max(clip.tracks.map(track -> track.times.length).iterator().next()) / clip.duration);
		options.names = options.names || [];

		if (!source.isObject3D) {
			source = Retarget.getHelperFromSkeleton(source);
		}

		var numFrames = Math.round(clip.duration * (options.fps / 1000) * 1000);
		var delta = clip.duration / (numFrames - 1);
		var convertedTracks:Array<Dynamic> = [];
		var mixer = new AnimationMixer(source);
		var bones = Retarget.getBones(target.skeleton);
		var boneDatas:Array<Dynamic> = [];
		var positionOffset:Vector3;
		var bone:Dynamic;
		var boneTo:Dynamic;
		var boneData:Dynamic;
		var name:String;

		mixer.clipAction(clip).play();
		mixer.update(0);
		source.updateMatrixWorld();

		for (i in 0...numFrames) {
			var time = i * delta;
			Retarget.retarget(target, source, options);
			for (j in 0...bones.length) {
				name = options.names[bones[j].name] || bones[j].name;
				boneTo = Retarget.getBoneByName(name, source.skeleton);
				if (boneTo) {
					bone = bones[j];
					boneData = boneDatas[j] = (boneDatas[j] != null) ? boneDatas[j] : {bone: bone};
					if (options.hip == name) {
						if (!boneData.pos) {
							boneData.pos = {
								times: new Float32Array(numFrames),
								values: new Float32Array(numFrames * 3)
							};
						}
						if (options.useFirstFramePosition) {
							if (i == 0) {
								positionOffset = bone.position.clone();
							}
							bone.position.sub(positionOffset);
						}
						boneData.pos.times[i] = time;
						bone.position.toArray(boneData.pos.values, i * 3);
					}
					if (!boneData.quat) {
						boneData.quat = {
							times: new Float32Array(numFrames),
							values: new Float32Array(numFrames * 4)
						};
					}
					boneData.quat.times[i] = time;
					bone.quaternion.toArray(boneData.quat.values, i * 4);
				}
			}
			if (i == numFrames - 2) {
				// last mixer update before final loop iteration
				// make sure we do not go over or equal to clip duration
				mixer.update(delta - 0.0000001);
			} else {
				mixer.update(delta);
			}
			source.updateMatrixWorld();
		}

		for (i in 0...boneDatas.length) {
			boneData = boneDatas[i];
			if (boneData) {
				if (boneData.pos) {
					convertedTracks.push(new VectorKeyframeTrack(".bones[" + boneData.bone.name + "].position", boneData.pos.times, boneData.pos.values));
				}
				convertedTracks.push(new QuaternionKeyframeTrack(".bones[" + boneData.bone.name + "].quaternion", boneData.quat.times, boneData.quat.values));
			}
		}

		mixer.uncacheAction(clip);

		return new AnimationClip(clip.name, -1, convertedTracks);

	}

	public static function clone(source:Dynamic):Dynamic {

		var sourceLookup = new Map();
		var cloneLookup = new Map();

		var clone = source.clone();

		Retarget.parallelTraverse(source, clone, function(sourceNode:Dynamic, clonedNode:Dynamic) {
			sourceLookup.set(clonedNode, sourceNode);
			cloneLookup.set(sourceNode, clonedNode);
		});

		clone.traverse(function(node:Dynamic) {
			if (!node.isSkinnedMesh) return;
			var clonedMesh = node;
			var sourceMesh = sourceLookup.get(node);
			var sourceBones = sourceMesh.skeleton.bones;
			clonedMesh.skeleton = sourceMesh.skeleton.clone();
			clonedMesh.bindMatrix.copy(sourceMesh.bindMatrix);
			clonedMesh.skeleton.bones = sourceBones.map(function(bone:Dynamic) {
				return cloneLookup.get(bone);
			});
			clonedMesh.bind(clonedMesh.skeleton, clonedMesh.bindMatrix);
		});

		return clone;

	}

	// internal helper

	public static function getBoneByName(name:String, skeleton:Dynamic):Dynamic {

		for (i in 0...Retarget.getBones(skeleton).length) {
			if (name == Retarget.getBones(skeleton)[i].name) {
				return Retarget.getBones(skeleton)[i];
			}
		}

	}

	public static function getBones(skeleton:Dynamic):Array<Dynamic> {

		return (Std.is(skeleton, Array)) ? skeleton : skeleton.bones;

	}


	public static function getHelperFromSkeleton(skeleton:Dynamic):Dynamic {

		var source = new SkeletonHelper(skeleton.bones[0]);
		source.skeleton = skeleton;

		return source;

	}

	public static function parallelTraverse(a:Dynamic, b:Dynamic, callback:Dynamic):Void {

		callback(a, b);

		for (i in 0...a.children.length) {
			Retarget.parallelTraverse(a.children[i], b.children[i], callback);
		}

	}

}