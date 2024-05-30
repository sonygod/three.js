import js.Lib;
import js.three.AnimationClip;
import js.three.Matrix4;
import js.three.Quaternion;
import js.three.Vector3;
import js.three.VectorKeyframeTrack;
import js.three.QuaternionKeyframeTrack;
import js.three.NumberKeyframeTrack;

class AnimationParser {

	// take raw animation clips and turn them into three.js animation clips
	public function parse():Array<Dynamic> {

		var animationClips:Array<Dynamic> = [];

		var rawClips:Array<Dynamic> = this.parseClips();

		if (rawClips != null) {

			for (rawClip in rawClips) {

				var clip:AnimationClip = this.addClip(rawClip);

				animationClips.push(clip);

			}

		}

		return animationClips;

	}

	private function parseClips():Array<Dynamic> {

		// since the actual transformation data is stored in FBXTree.Objects.AnimationCurve,
		// if this is undefined we can safely assume there are no animations
		if (Lib.get(fbxTree, 'Objects.AnimationCurve') == null) return null;

		var curveNodesMap:Map<Int, Dynamic> = this.parseAnimationCurveNodes();

		this.parseAnimationCurves(curveNodesMap);

		var layersMap:Map<Int, Array<Dynamic>> = this.parseAnimationLayers(curveNodesMap);
		var rawClips:Map<Int, Dynamic> = this.parseAnimStacks(layersMap);

		return rawClips;

	}

	// parse nodes in FBXTree.Objects.AnimationCurveNode
	// each AnimationCurveNode holds data for an animation transform for a model (e.g. left arm rotation )
	// and is referenced by an AnimationLayer
	private function parseAnimationCurveNodes():Map<Int, Dynamic> {

		var rawCurveNodes:Map<Int, Dynamic> = Lib.get(fbxTree, 'Objects.AnimationCurveNode');

		var curveNodesMap:Map<Int, Dynamic> = new Map();

		for (nodeID in rawCurveNodes) {

			var rawCurveNode:Dynamic = rawCurveNodes[nodeID];

			if (rawCurveNode.attrName.match(/S|R|T|DeformPercent/) != null) {

				var curveNode:Dynamic = {

					id: rawCurveNode.id,
					attr: rawCurveNode.attrName,
					curves: {},

				};

				curveNodesMap.set(curveNode.id, curveNode);

			}

		}

		return curveNodesMap;

	}

	// parse nodes in FBXTree.Objects.AnimationCurve and connect them up to
	// previously parsed AnimationCurveNodes. Each AnimationCurve holds data for a single animated
	// axis ( e.g. times and values of x rotation)
	private function parseAnimationCurves(curveNodesMap:Map<Int, Dynamic>) {

		var rawCurves:Map<Int, Dynamic> = Lib.get(fbxTree, 'Objects.AnimationCurve');

		for (nodeID in rawCurves) {

			var animationCurve:Dynamic = {

				id: rawCurves[nodeID].id,
				times: rawCurves[nodeID].KeyTime.a.map(convertFBXTimeToSeconds),
				values: rawCurves[nodeID].KeyValueFloat.a,

			};

			var relationships:Dynamic = connections.get(animationCurve.id);

			if (relationships != null) {

				var animationCurveID:Int = relationships.parents[0].ID;
				var animationCurveRelationship:String = relationships.parents[0].relationship;

				if (animationCurveRelationship.match(/X/) != null) {

					curveNodesMap.get(animationCurveID).curves['x'] = animationCurve;

				} else if (animationCurveRelationship.match(/Y/) != null) {

					curveNodesMap.get(animationCurveID).curves['y'] = animationCurve;

				} else if (animationCurveRelationship.match(/Z/) != null) {

					curveNodesMap.get(animationCurveID).curves['z'] = animationCurve;

				} else if (animationCurveRelationship.match(/DeformPercent/) != null && curveNodesMap.has(animationCurveID)) {

					curveNodesMap.get(animationCurveID).curves['morph'] = animationCurve;

				}

			}

		}

	}

	// parse nodes in FBXTree.Objects.AnimationLayer. Each layers holds references
	// to various AnimationCurveNodes and is referenced by an AnimationStack node
	// note: theoretically a stack can have multiple layers, however in practice there always seems to be one per stack
	private function parseAnimationLayers(curveNodesMap:Map<Int, Dynamic>):Map<Int, Array<Dynamic>> {

		var rawLayers:Map<Int, Dynamic> = Lib.get(fbxTree, 'Objects.AnimationLayer');

		var layersMap:Map<Int, Array<Dynamic>> = new Map();

		for (nodeID in rawLayers) {

			var layerCurveNodes:Array<Dynamic> = [];

			var connection:Dynamic = connections.get(Std.parseInt(nodeID));

			if (connection != null) {

				// all the animationCurveNodes used in the layer
				var children:Array<Dynamic> = connection.children;

				children.forEach(function(child, i) {

					if (curveNodesMap.has(child.ID)) {

						var curveNode:Dynamic = curveNodesMap.get(child.ID);

						// check that the curves are defined for at least one axis, otherwise ignore the curveNode
						if (curveNode.curves.x != null || curveNode.curves.y != null || curveNode.curves.z != null) {

							if (layerCurveNodes[i] == null) {

								var modelID:Int = connections.get(child.ID).parents.filter(function(parent) {

									return parent.relationship != null;

								})[0].ID;

								if (modelID != null) {

									var rawModel:Dynamic = Lib.get(fbxTree, 'Objects.Model')[modelID.toString()];

									if (rawModel == null) {

										Lib.console.warn('THREE.FBXLoader: Encountered a unused curve.', child);
										return;

									}

									var node:Dynamic = {

										modelName: rawModel.attrName ? PropertyBinding.sanitizeNodeName(rawModel.attrName) : '',
										ID: rawModel.id,
										initialPosition: [0, 0, 0],
										initialRotation: [0, 0, 0],
										initialScale: [1, 1, 1],

									};

									sceneGraph.traverse(function(child) {

										if (child.ID == rawModel.id) {

											node.transform = child.matrix;

											if (child.userData.transformData) node.eulerOrder = child.userData.transformData.eulerOrder;

										}

									});

									if (node.transform == null) node.transform = new Matrix4();

									// if the animated model is pre rotated, we'll have to apply the pre rotations to every
									// animation value as well
									if ('PreRotation' in rawModel) node.preRotation = rawModel.PreRotation.value;
									if ('PostRotation' in rawModel) node.postRotation = rawModel.PostRotation.value;

									layerCurveNodes[i] = node;

								}

							}

							if (layerCurveNodes[i]) layerCurveNodes[i][curveNode.attr] = curveNode;

						} else if (curveNode.curves.morph != null) {

							if (layerCurveNodes[i] == null) {

								var deformerID:Int = connections.get(child.ID).parents.filter(function(parent) {

									return parent.relationship != null;

								})[0].ID;

								var morpherID:Int = connections.get(deformerID).parents[0].ID;
								var geoID:Int = connections.get(morpherID).parents[0].ID;

								// assuming geometry is not used in more than one model
								var modelID:Int = connections.get(geoID).parents[0].ID;

								var rawModel:Dynamic = Lib.get(fbxTree, 'Objects.Model')[modelID];

								var node:Dynamic = {

									modelName: rawModel.attrName ? PropertyBinding.sanitizeNodeName(rawModel.attrName) : '',
									morphName: Lib.get(fbxTree, 'Objects.Deformer')[deformerID].attrName,

								};

								layerCurveNodes[i] = node;

							}

							layerCurveNodes[i][curveNode.attr] = curveNode;

						}

					}

				});

				layersMap.set(Std.parseInt(nodeID), layerCurveNodes);

			}

		}

		return layersMap;

	}

	// parse nodes in FBXTree.Objects.AnimationStack. These are the top level node in the animation
	// hierarchy. Each Stack node will be used to create a AnimationClip
	private function parseAnimStacks(layersMap:Map<Int, Array<Dynamic>>):Map<Int, Dynamic> {

		var rawStacks:Map<Int, Dynamic> = Lib.get(fbxTree, 'Objects.AnimationStack');

		// connect the stacks (clips) up to the layers
		var rawClips:Map<Int, Dynamic> = {};

		for (nodeID in rawStacks) {

			var children:Array<Dynamic> = connections.get(Std.parseInt(nodeID)).children;

			if (children.length > 1) {

				// it seems like stacks will always be associated with a single layer. But just in case there are files
				// where there are multiple layers per stack, we'll display a warning
				Lib.console.warn('THREE.FBXLoader: Encountered an animation stack with multiple layers, this is currently not supported. Ignoring subsequent layers.');

			}

			var layer:Array<Dynamic> = layersMap.get(children[0].ID);

			rawClips[nodeID] = {

				name: rawStacks[nodeID].attrName,
				layer: layer,

			};

		}

		return rawClips;

	}

	private function addClip(rawClip:Dynamic):AnimationClip {

		var tracks:Array<Dynamic> = [];

		var scope:AnimationParser = this;
		rawClip.layer.forEach(function(rawTracks) {

			tracks = tracks.concat(scope.generateTracks(rawTracks));

		});

		return new AnimationClip(rawClip.name, -1, tracks);

	}

	private function generateTracks(rawTracks:Dynamic):Array<Dynamic> {

		var tracks:Array<Dynamic> = [];

		var initialPosition:Vector3 = new Vector3();
		var initialScale:Vector3 = new Vector3();

		if (rawTracks.transform != null) rawTracks.transform.decompose(initialPosition, new Quaternion(), initialScale);

		initialPosition = initialPosition.toArray();
		initialScale = initialScale.toArray();

		if (rawTracks.T != null && Object.keys(rawTracks.T.curves).length > 0) {

			var positionTrack:VectorKeyframeTrack = this.generateVectorTrack(rawTracks.modelName, rawTracks.T.curves, initialPosition, 'position');
			if (positionTrack != null) tracks.push(positionTrack);

		}

		if (rawTracks.R != null && Object.keys(rawTracks.R.curves).length > 0) {

			var rotationTrack:QuaternionKeyframeTrack = this.generateRotationTrack(rawTracks.modelName, rawTracks.R.curves, rawTracks.preRotation, rawTracks.postRotation, rawTracks.eulerOrder);
			if (rotationTrack != null) tracks.push(rotationTrack);

		}

		if (rawTracks.S != null && Object.keys(rawTracks.S.curves).length > 0) {

			var scaleTrack:VectorKeyframeTrack = this.generateVectorTrack(rawTracks.modelName, rawTracks.S.curves, initialScale, 'scale');
			if (scaleTrack != null) tracks.push(scaleTrack);

		}

		if (rawTracks.DeformPercent != null) {

			var morphTrack:NumberKeyframeTrack = this.generateMorphTrack(rawTracks);
			if (morphTrack != null) tracks.push(morphTrack);

		}

		return tracks;

	}

	private function generateVectorTrack(modelName:String, curves:Dynamic, initialValue:Array<Float>, type:String):VectorKeyframeTrack {

		var times:Array<Float> = this.getTimesForAllAxes(curves);
		var values:Array<Float> = this.getKeyframeTrackValues(times, curves, initialValue);

		return new VectorKeyframeTrack(modelName + '.' + type, times, values);

	}

	private function generateRotationTrack(modelName:String, curves:Dynamic, preRotation:Array<Float>, postRotation:Array<Float>, eulerOrder:String):QuaternionKeyframeTrack {

		var times:Array<Float>;
		var values:Array<Float>;

		if (curves.x != null && curves.y != null && curves.z != null) {

			var result:Array<Array<Float>> = this.interpolateRotations(curves.x, curves.y, curves.z, eulerOrder);

			times = result[0];
			values = result[1];

		}

		if (preRotation != null) {

			preRotation = preRotation.map(MathUtils.degToRad);
			preRotation.push(eulerOrder);

			preRotation = new Euler().fromArray(preRotation);
			preRotation = new Quaternion().setFromEuler(preRotation);

		}

		if (postRotation != null) {

			postRotation = postRotation.map(MathUtils.degToRad);
			postRotation.push(eulerOrder);

			postRotation = new Euler().fromArray(postRotation);
			postRotation = new Quaternion().setFromEuler(postRotation).invert();

		}

		var quaternion:Quaternion = new Quaternion();
		var euler:Euler = new Euler();

		var quaternionValues:Array<Float> = [];

		if (!values || !times) return new QuaternionKeyframeTrack(modelName + '.quaternion', [0], [0]);

		for (i in 0...values.length) {

			euler.set(values[i], values[i + 1], values[i + 2], eulerOrder);
			quaternion.setFromEuler(euler);

			if (preRotation != null) quaternion.premultiply(preRotation);
			if (postRotation != null) quaternion.multiply(postRotation);

			// Check unroll
			if (i > 2) {

				var prevQuat:Quaternion = new Quaternion().fromArray(
					quaternionValues,
					((i - 3) / 3) * 4
				);

				if (prevQuat.dot(quaternion) < 0) {

					quaternion.set(-quaternion.x, -quaternion.y, -quaternion.z, -quaternion.w);

				}

			}

			quaternion.toArray(quaternionValues, (i / 3) * 4);

		}

		return new QuaternionKeyframeTrack(modelName + '.quaternion', times, quaternionValues);

	}

	private function generateMorphTrack(rawTracks:Dynamic):NumberKeyframeTrack {

		var curves:Dynamic = rawTracks.DeformPercent.curves.morph;
		var values:Array<Float> = curves.values.map(function(val) {

			return val / 100;

		});

		var morphNum:Int = sceneGraph.getObjectByName(rawTracks.modelName).morphTargetDictionary[rawTracks.morphName];

		return new NumberKeyframeTrack(rawTracks.modelName + '.morphTargetInfluences[' + morphNum + ']', curves.times, values);

	}

	// For all animated objects, times are defined separately for each axis
	// Here we'll combine the times into one sorted array without duplicates
	private function getTimesForAllAxes(curves:Dynamic):Array<Float> {

		var times:Array<Float> = [];

		// first join together the times for each axis, if defined
		if (curves.x != null) times = times.concat(curves.x.times);
		if (curves.y != null) times = times.concat(curves.y.times);
		if (curves.z != null) times = times.concat(curves.z.times);

		// then sort them
		times.sort(function(a, b) {

			return a - b;

		});

		// and remove duplicates
		if (times.length > 1) {

			var targetIndex:Int = 1;
			var lastValue:Float = times[0];
			for (i in 1...times.length) {

				var currentValue:Float = times[i];
				if (currentValue != lastValue) {

					times[targetIndex] = currentValue;
					lastValue = currentValue;
					targetIndex++;

				}

			}

			times = times.slice(0, targetIndex);

		}

		return times;

	}

	private function getKeyframeTrackValues(times:Array<Float>, curves:Dynamic, initialValue:Array<Float>):Array<Float> {

		var prevValue:Array<Float> = initialValue;

		var values:Array<Float> = [];

		var xIndex:Int = -1;
		var yIndex:Int = -1;
		var zIndex:Int = -1;

		times.forEach(function(time) {

			if (curves.x != null) xIndex = curves.x.times.indexOf(time);
			if (curves.y != null) yIndex = curves.y.times.indexOf(time);
			if (curves.z != null) zIndex = curves.z.times.indexOf(time);

			// if there is an x value defined for this frame, use that
			if (xIndex != -1) {

				var xValue:Float = curves.x.values[xIndex];
				values.push(xValue);
				prevValue[0] = xValue;

			} else {

				// otherwise use the x value from the previous frame
				values.push(prevValue[0]);

			}

			if (yIndex != -1) {

				var yValue:Float = curves.y.values[yIndex];
				values.push(yValue);
				prevValue[1] = yValue;

			} else {

				values.push(prevValue[1]);

			}

			if (zIndex != -1) {

				var zValue:Float = curves.z.values[zIndex];
				values.push(zValue);
				prevValue[2] = zValue;

			} else {

				values.push(prevValue[2]);

			}

		});

		return values;

	}

	// Rotations are defined as Euler angles which can have values  of any size
	// These will be converted to quaternions which don't support values greater than
	// PI, so we'll interpolate large rotations
	private function interpolateRotations(curvex:Dynamic, curvey:Dynamic, curvez:Dynamic, eulerOrder:String):Array<Array<Float>> {

		var times:Array<Float> = [];
		var values:Array<Float> = [];

		// Add first frame
		times.push(curvex.times[0]);
		values.push(MathUtils.degToRad(curvex.values[0]));
		values.push(MathUtils.degToRad(curvey.values[0]));
		values.push(MathUtils.degToRad(curvez.values[0]));

		for (i in 1...curvex.values.length) {

			var initialValue:Array<Float> = [
				curvex.values[i - 1],
				curvey.values[i - 1],
				curvez.values[i - 1],
			];

			if (isNaN(initialValue[0]) || isNaN(initialValue[1]) || isNaN(initialValue[2])) {

				continue;

			}

			var initialValueRad:Array<Float> = initialValue.map(MathUtils.degToRad);

			var currentValue:Array<Float> = [
				curvex.values[i],
				curvey.values[i],
				curvez.values[i],
			];

			if (isNaN(currentValue[0]) || isNaN(currentValue[1]) || isNaN(currentValue[2])) {

				continue;

			}

			var currentValueRad:Array<Float> = currentValue.map(MathUtils.degToRad);

			var valuesSpan:Array<Float> = [
				currentValue[0] - initialValue[0],
				currentValue[1] - initialValue[1],
				currentValue[2] - initialValue[2],
			];

			var absoluteSpan:Array<Float> = [
				Math.abs(valuesSpan[0]),
				Math.abs(valuesSpan[1]),
				Math.abs(valuesSpan[2]),
			];

			if (absoluteSpan[0] >= 180 || absoluteSpan[1] >= 180 || absoluteSpan[2] >= 180) {

				var maxAbsSpan:Float = Math.max(...absoluteSpan);

				var numSubIntervals:Float = maxAbsSpan / 180;

				var E1:Euler = new Euler(...initialValueRad, eulerOrder);
				var E2:Euler = new Euler(...currentValueRad, eulerOrder);

				var Q1:Quaternion = new Quaternion().setFromEuler(E1);
				var Q2:Quaternion = new Quaternion().setFromEuler(E2);

				// Check unroll
				if (Q1.dot(Q2) > 0) {

					Q2.set(-Q2.x, -Q2.y, -Q2.z, -Q2.w);

				}

				// Interpolate
				var initialTime:Float = curvex.times[i - 1];
				var timeSpan:Float = curvex.times[i] - initialTime;

				var Q:Quaternion = new Quaternion();
				var E:Euler = new Euler();
				for (t in 0...1) {

					Q.copy(Q1.clone().slerp(Q2.clone(), t));

					times.push(initialTime + t * timeSpan);
					E.setFromQuaternion(Q, eulerOrder);

					values.push(E.x);
					values.push(E.y);
					values.push(E.z);

				}

			} else {

				times.push(curvex.times[i]);
				values.push(MathUtils.degToRad(curvex.values[i]));
				values.push(MathUtils.degToRad(curvey.values[i]));
				values.push(MathUtils.degToRad(curvez.values[i]));

			}

		}

		return [times, values];

	}

}