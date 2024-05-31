import haxe.ds.Map;
import three.animation.AnimationClip;
import three.animation.tracks.NumberKeyframeTrack;
import three.animation.tracks.QuaternionKeyframeTrack;
import three.animation.tracks.VectorKeyframeTrack;
import three.core.PropertyBinding;
import three.math.Euler;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector3;

class AnimationParser {
	// Assuming fbxTree, connections, and sceneGraph are available in the Haxe context

	public function new() {}

	public function parse():Array<AnimationClip> {
		var animationClips:Array<AnimationClip> = [];
		var rawClips = parseClips();

		if (rawClips != null) {
			for (key in rawClips.keys()) {
				var rawClip = rawClips.get(key);
				var clip = addClip(rawClip);
				animationClips.push(clip);
			}
		}

		return animationClips;
	}

	function parseClips():Map<String, {name: String, layer: Array<Dynamic>}> {
		if (fbxTree.Objects.AnimationCurve == null) {
			return null;
		}

		var curveNodesMap = parseAnimationCurveNodes();
		parseAnimationCurves(curveNodesMap);

		var layersMap = parseAnimationLayers(curveNodesMap);
		var rawClips = parseAnimStacks(layersMap);

		return rawClips;
	}

	function parseAnimationCurveNodes():Map<Int, {id: Int, attr: String, curves: {x: Dynamic, y: Dynamic, z: Dynamic, morph: Dynamic}}> {
		var rawCurveNodes = fbxTree.Objects.AnimationCurveNode;
		var curveNodesMap = new Map<Int, {id: Int, attr: String, curves: {x: Dynamic, y: Dynamic, z: Dynamic, morph: Dynamic}}>();

		for (nodeID in rawCurveNodes.keys()) {
			var rawCurveNode = rawCurveNodes.get(nodeID);

			if (~/S|R|T|DeformPercent/.match(rawCurveNode.attrName)) {
				var curveNode = {
					id: rawCurveNode.id,
					attr: rawCurveNode.attrName,
					curves: {
						x: null,
						y: null,
						z: null,
						morph: null
					}
				};

				curveNodesMap.set(curveNode.id, curveNode);
			}
		}

		return curveNodesMap;
	}

	function parseAnimationCurves(curveNodesMap:Map<Int, {id: Int, attr: String, curves: {x: Dynamic, y: Dynamic, z: Dynamic, morph: Dynamic}}>):Void {
		var rawCurves = fbxTree.Objects.AnimationCurve;

		for (nodeID in rawCurves.keys()) {
			var animationCurve = {
				id: rawCurves.get(nodeID).id,
				times: rawCurves.get(nodeID).KeyTime.a.map(convertFBXTimeToSeconds),
				values: rawCurves.get(nodeID).KeyValueFloat.a
			};

			var relationships = connections.get(animationCurve.id);

			if (relationships != null) {
				var animationCurveID = relationships.parents[0].ID;
				var animationCurveRelationship = relationships.parents[0].relationship;

				if (~/X/.match(animationCurveRelationship)) {
					curveNodesMap.get(animationCurveID).curves.x = animationCurve;
				} else if (~/Y/.match(animationCurveRelationship)) {
					curveNodesMap.get(animationCurveID).curves.y = animationCurve;
				} else if (~/Z/.match(animationCurveRelationship)) {
					curveNodesMap.get(animationCurveID).curves.z = animationCurve;
				} else if (~/DeformPercent/.match(animationCurveRelationship) && curveNodesMap.exists(animationCurveID)) {
					curveNodesMap.get(animationCurveID).curves.morph = animationCurve;
				}
			}
		}
	}

	function parseAnimationLayers(curveNodesMap:Map<Int, {id: Int, attr: String, curves: {x: Dynamic, y: Dynamic, z: Dynamic, morph: Dynamic}}>):Map<Int, Array<Dynamic>> {
		var rawLayers = fbxTree.Objects.AnimationLayer;
		var layersMap = new Map<Int, Array<Dynamic>>();

		for (nodeID in rawLayers.keys()) {
			var layerCurveNodes:Array<Dynamic> = [];
			var connection = connections.get(Std.parseInt(nodeID));

			if (connection != null) {
				var children = connection.children;

				for (i in 0...children.length) {
					var child = children[i];
					if (curveNodesMap.exists(child.ID)) {
						var curveNode = curveNodesMap.get(child.ID);

						if (curveNode.curves.x != null || curveNode.curves.y != null || curveNode.curves.z != null) {
							if (layerCurveNodes[i] == null) {
								var modelID:Int = null;

								for (parent in connections.get(child.ID).parents) {
									if (parent.relationship != null) {
										modelID = parent.ID;
										break;
									}
								}

								if (modelID != null) {
									var rawModel = fbxTree.Objects.Model.get(modelID.toString());

									if (rawModel == null) {
										trace('THREE.FBXLoader: Encountered a unused curve.', child);
										continue;
									}

									var node = {
										modelName: (rawModel.attrName != null) ? PropertyBinding.sanitizeNodeName(rawModel.attrName) : '',
										ID: rawModel.id,
										initialPosition: [0, 0, 0],
										initialRotation: [0, 0, 0],
										initialScale: [1, 1, 1],
										transform: null,
										eulerOrder: null,
										preRotation: null,
										postRotation: null
									};

									sceneGraph.traverse(function(child) {
										if (child.ID == rawModel.id) {
											node.transform = child.matrix.clone();
											if (Reflect.hasField(child.userData, 'transformData'))
												node.eulerOrder = Reflect.field(child.userData, 'transformData').eulerOrder;
										}
									});

									if (node.transform == null) {
										node.transform = new Matrix4();
									}

									if (Reflect.hasField(rawModel, 'PreRotation'))
										node.preRotation = rawModel.PreRotation.value;
									if (Reflect.hasField(rawModel, 'PostRotation'))
										node.postRotation = rawModel.PostRotation.value;

									layerCurveNodes[i] = node;
								}
							}

							if (layerCurveNodes[i] != null) {
								Reflect.setField(layerCurveNodes[i], curveNode.attr, curveNode);
							}
						} else if (curveNode.curves.morph != null) {
							if (layerCurveNodes[i] == null) {
								var deformerID = connections.get(child.ID).parents[0].ID;
								var morpherID = connections.get(deformerID).parents[0].ID;
								var geoID = connections.get(morpherID).parents[0].ID;
								var modelID = connections.get(geoID).parents[0].ID;

								var rawModel = fbxTree.Objects.Model.get(modelID);

								var node = {
									modelName: (rawModel.attrName != null) ? PropertyBinding.sanitizeNodeName(rawModel.attrName) : '',
									morphName: fbxTree.Objects.Deformer.get(deformerID).attrName
								};

								layerCurveNodes[i] = node;
							}

							Reflect.setField(layerCurveNodes[i], curveNode.attr, curveNode);
						}
					}
				}

				layersMap.set(Std.parseInt(nodeID), layerCurveNodes);
			}
		}

		return layersMap;
	}

	function parseAnimStacks(layersMap:Map<Int, Array<Dynamic>>):Map<String, {name: String, layer: Array<Dynamic>}> {
		var rawStacks = fbxTree.Objects.AnimationStack;
		var rawClips = new Map<String, {name: String, layer: Array<Dynamic>>>();

		for (nodeID in rawStacks.keys()) {
			var children = connections.get(Std.parseInt(nodeID)).children;

			if (children.length > 1) {
				trace('THREE.FBXLoader: Encountered an animation stack with multiple layers, this is currently not supported. Ignoring subsequent layers.');
			}

			var layer = layersMap.get(children[0].ID);

			rawClips.set(nodeID, {
				name: rawStacks.get(nodeID).attrName,
				layer: layer
			});
		}

		return rawClips;
	}

	function addClip(rawClip:{name: String, layer: Array<Dynamic>}):AnimationClip {
		var tracks:Array<Dynamic> = [];
		var scope = this;

		for (rawTracks in rawClip.layer) {
			tracks = tracks.concat(scope.generateTracks(rawTracks));
		}

		return new AnimationClip(rawClip.name, -1, tracks);
	}

	function generateTracks(rawTracks:Dynamic):Array<Dynamic> {
		var tracks:Array<Dynamic> = [];
		var initialPosition = new Vector3();
		var initialScale = new Vector3();

		if (Reflect.hasField(rawTracks, 'transform')) {
			var quaternion = new Quaternion();
			rawTracks.transform.decompose(initialPosition, quaternion, initialScale);
		}

		var initPosArr = initialPosition.toArray();
		var initScaleArr = initialScale.toArray();

		if (Reflect.hasField(rawTracks, 'T') && Reflect.fields(rawTracks.T.curves).length > 0) {
			var positionTrack = generateVectorTrack(rawTracks.modelName, rawTracks.T.curves, initPosArr, 'position');
			if (positionTrack != null)
				tracks.push(positionTrack);
		}

		if (Reflect.hasField(rawTracks, 'R') && Reflect.fields(rawTracks.R.curves).length > 0) {
			var rotationTrack = generateRotationTrack(rawTracks.modelName, rawTracks.R.curves, rawTracks.preRotation, rawTracks.postRotation, rawTracks.eulerOrder);
			if (rotationTrack != null)
				tracks.push(rotationTrack);
		}

		if (Reflect.hasField(rawTracks, 'S') && Reflect.fields(rawTracks.S.curves).length > 0) {
			var scaleTrack = generateVectorTrack(rawTracks.modelName, rawTracks.S.curves, initScaleArr, 'scale');
			if (scaleTrack != null)
				tracks.push(scaleTrack);
		}

		if (Reflect.hasField(rawTracks, 'DeformPercent')) {
			var morphTrack = generateMorphTrack(rawTracks);
			if (morphTrack != null)
				tracks.push(morphTrack);
		}

		return tracks;
	}

	function generateVectorTrack(modelName:String, curves:{x: Dynamic, y: Dynamic, z: Dynamic}, initialValue:Array<Float>, type:String):VectorKeyframeTrack {
		var times = getTimesForAllAxes(curves);
		var values = getKeyframeTrackValues(times, curves, initialValue);

		return new VectorKeyframeTrack(modelName + '.' + type, times, values);
	}

	function generateRotationTrack(modelName:String, curves:{x: Dynamic, y: Dynamic, z: Dynamic}, preRotation:Array<Float>, postRotation:Array<Float>, eulerOrder:String):QuaternionKeyframeTrack {
		var times:Array<Float> = null;
		var values:Array<Float> = null;

		if (curves.x != null && curves.y != null && curves.z != null) {
			var result = interpolateRotations(curves.x, curves.y, curves.z, eulerOrder);
			times = result[0];
			values = result[1];
		}

		var preRotQ:Quaternion = null;
		if (preRotation != null) {
			var preRotationRad = preRotation.map(MathUtils.degToRad);
			preRotationRad.push(eulerOrder); // Assuming eulerOrder is a string

			preRotQ = new Quaternion();
			preRotQ.setFromEuler(new Euler(preRotationRad[0], preRotationRad[1], preRotationRad[2], eulerOrder));
		}

		var postRotQ:Quaternion = null;
		if (postRotation != null) {
			var postRotationRad = postRotation.map(MathUtils.degToRad);
			postRotationRad.push(eulerOrder); // Assuming eulerOrder is a string

			postRotQ = new Quaternion();
			postRotQ.setFromEuler(new Euler(postRotationRad[0], postRotationRad[1], postRotationRad[2], eulerOrder));
			postRotQ.invert();
		}

		var quaternion = new Quaternion();
		var euler = new Euler();
		var quaternionValues:Array<Float> = [];

		if (values == null || times == null) {
			return new QuaternionKeyframeTrack(modelName + '.quaternion', [0], [0, 0, 0, 1]);
		}

		for (i in 0...Std.int(values.length / 3)) {
			euler.set(values[i * 3], values[i * 3 + 1], values[i * 3 + 2], eulerOrder);
			quaternion.setFromEuler(euler);

			if (preRotQ != null)
				quaternion.premultiply(preRotQ);
			if (postRotQ != null)
				quaternion.multiply(postRotQ);

			if (i > 0) {
				var prevQuat = new Quaternion().fromArray(quaternionValues, (i - 1) * 4);
				if (prevQuat.dot(quaternion) < 0) {
					quaternion.set(-quaternion.x, -quaternion.y, -quaternion.z, -quaternion.w);
				}
			}

			quaternion.toArray(quaternionValues, i * 4);
		}

		return new QuaternionKeyframeTrack(modelName + '.quaternion', times, quaternionValues);
	}

	function generateMorphTrack(rawTracks:Dynamic):NumberKeyframeTrack {
		var curves = Reflect.field(rawTracks, 'DeformPercent').curves.morph;
		var values = curves.values.map(function(val) {
			return val / 100;
		});

		var morphNum = Reflect.field(sceneGraph.getObjectByName(rawTracks.modelName), 'morphTargetDictionary')[rawTracks.morphName];
		return new NumberKeyframeTrack(rawTracks.modelName + '.morphTargetInfluences[' + morphNum + ']', curves.times, values);
	}

	function getTimesForAllAxes(curves:{x: Dynamic, y: Dynamic, z: Dynamic}):Array<Float> {
		var times:Array<Float> = [];

		if (curves.x != null)
			times = times.concat(curves.x.times);
		if (curves.y != null)
			times = times.concat(curves.y.times);
		if (curves.z != null)
			times = times.concat(curves.z.times);

		times.sort(function(a, b) {
			return a - b;
		});

		if (times.length > 1) {
			var targetIndex = 1;
			var lastValue = times[0];

			for (i in 1...times.length) {
				var currentValue = times[i];
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

	function getKeyframeTrackValues(times:Array<Float>, curves:{x: Dynamic, y: Dynamic, z: Dynamic}, initialValue:Array<Float>):Array<Float> {
		var prevValue = initialValue.copy();
		var values:Array<Float> = [];
		var xIndex = -1;
		var yIndex = -1;
		var zIndex = -1;

		for (time in times) {
			if (curves.x != null)
				xIndex = curves.x.times.indexOf(time);
			if (curves.y != null)
				yIndex = curves.y.times.indexOf(time);
			if (curves.z != null)
				zIndex = curves.z.times.indexOf(time);

			if (xIndex != -1) {
				var xValue = curves.x.values[xIndex];
				values.push(xValue);
				prevValue[0] = xValue;
			} else {
				values.push(prevValue[0]);
			}

			if (yIndex != -1) {
				var yValue = curves.y.values[yIndex];
				values.push(yValue);
				prevValue[1] = yValue;
			} else {
				values.push(prevValue[1]);
			}

			if (zIndex != -1) {
				var zValue = curves.z.values[zIndex];
				values.push(zValue);
				prevValue[2] = zValue;
			} else {
				values.push(prevValue[2]);
			}
		}

		return values;
	}

	function interpolateRotations(curvex:{times: Array<Float>, values: Array<Float>}, curvey:{times: Array<Float>, values: Array<Float>}, curvez:{times: Array<Float>, values: Array<Float>}, eulerOrder:String):Array<Dynamic> {
		var times:Array<Float> = [];
		var values:Array<Float> = [];

		times.push(curvex.times[0]);
		values.push(MathUtils.degToRad(curvex.values[0]));
		values.push(MathUtils.degToRad(curvey.values[0]));
		values.push(MathUtils.degToRad(curvez.values[0]));

		for (i in 1...curvex.values.length) {
			var initialValue = [curvex.values[i - 1], curvey.values[i - 1], curvez.values[i - 1]];

			if (!isNaN(initialValue[0]) && !isNaN(initialValue[1]) && !isNaN(initialValue[2])) {
				var initialValueRad = initialValue.map(MathUtils.degToRad);
				var currentValue = [curvex.values[i], curvey.values[i], curvez.values[i]];

				if (!isNaN(currentValue[0]) && !isNaN(currentValue[1]) && !isNaN(currentValue[2])) {
					var currentValueRad = currentValue.map(MathUtils.degToRad);

					var valuesSpan = [
						currentValue[0] - initialValue[0],
						currentValue[1] - initialValue[1],
						currentValue[2] - initialValue[2]
					];

					var absoluteSpan = [Math.abs(valuesSpan[0]), Math.abs(valuesSpan[1]), Math.abs(valuesSpan[2])];

					if (absoluteSpan[0] >= 180 || absoluteSpan[1] >= 180 || absoluteSpan[2] >= 180) {
						var maxAbsSpan = Math.max(absoluteSpan[0], Math.max(absoluteSpan[1], absoluteSpan[2]));
						var numSubIntervals = Math.floor(maxAbsSpan / 180);

						var E1 = new Euler(initialValueRad[0], initialValueRad[1], initialValueRad[2], eulerOrder);
						var E2 = new Euler(currentValueRad[0], currentValueRad[1], currentValueRad[2], eulerOrder);

						var Q1 = new Quaternion().setFromEuler(E1);
						var Q2 = new Quaternion().setFromEuler(E2);

						if (Q1.dot(Q2) < 0) {
							Q2.set(-Q2.x, -Q2.y, -Q2.z, -Q2.w);
						}

						var initialTime = curvex.times[i - 1];
						var timeSpan = curvex.times[i] - initialTime;
						var Q = new Quaternion();
						var E = new Euler();

						for (t in 0...numSubIntervals + 1) {
							var tVal = t / numSubIntervals;
							Q.copy(Q1).slerp(Q2, tVal);

							times.push(initialTime + tVal * timeSpan);
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
			}
		}

		return [times, values];
	}

	static function convertFBXTimeToSeconds(time:Float):Float {
		return time / 46186155000;
	}
}