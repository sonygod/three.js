class AnimationParser {
	public function parse():Array<AnimationClip> {
		var animationClips:Array<AnimationClip> = [];
		var rawClips = parseClips();
		if (rawClips != null) {
			var key:String;
			for (key in rawClips) {
				var rawClip = rawClips[key];
				var clip = addClip(rawClip);
				animationClips.push(clip);
			}
		}
		return animationClips;
	}

	private function parseClips():Dynamic {
		if (fbxTree.Objects.AnimationCurve == null) return null;
		var curveNodesMap = parseAnimationCurveNodes();
		parseAnimationCurves(curveNodesMap);
		var layersMap = parseAnimationLayers(curveNodesMap);
		var rawClips = parseAnimStacks(layersMap);
		return rawClips;
	}

	private function parseAnimationCurveNodes():Map<Int,Dynamic> {
		var rawCurveNodes = fbxTree.Objects.AnimationCurveNode;
		var curveNodesMap = new Map<Int,Dynamic>();
		var nodeID:String;
		for (nodeID in rawCurveNodes) {
			var rawCurveNode = rawCurveNodes[Std.parseInt(nodeID)];
			if (rawCurveNode.attrName.match(/S|R|T|DeformPercent/)) {
				var curveNode = { id: rawCurveNode.id, attr: rawCurveNode.attrName, curves: {} };
				curveNodesMap.set(curveNode.id, curveNode);
			}
		}
		return curveNodesMap;
	}

	private function parseAnimationCurves(curveNodesMap:Map<Int,Dynamic>) {
		var rawCurves = fbxTree.Objects.AnimationCurve;
		var nodeID:String;
		for (nodeID in rawCurves) {
			var rawCurve = rawCurves[Std.parseInt(nodeID)];
			var animationCurve = {
				id: rawCurve.id,
				times: rawCurve.KeyTime.a.map(convertFBXTimeToSeconds),
				values: rawCurve.KeyValueFloat.a,
			};
			var relationships = connections.get(animationCurve.id);
			if (relationships != null) {
				var animationCurveID = relationships.parents[0].ID;
				var animationCurveRelationship = relationships.parents[0].relationship;
				if (animationCurveRelationship.match(/X/)) {
					curveNodesMap.get(animationCurveID).curves['x'] = animationCurve;
				} else if (animationCurveRelationship.match(/Y/)) {
					curveNodesMap.get(animationCurveID).curves['y'] = animationCurve;
				} else if (animationCurveRelationship.match(/Z/)) {
					curveNodesMap.get(animationCurveID).curves['z'] = animationCurve;
				} else if (animationCurveRelationship.match(/DeformPercent/) && curveNodesMap.exists(animationCurveID)) {
					curveNodesMap.get(animationCurveID).curves['morph'] = animationCurve;
				}
			}
		}
	}

	private function parseAnimationLayers(curveNodesMap:Map<Int,Dynamic>):Map<Int,Dynamic> {
		var rawLayers = fbxTree.Objects.AnimationLayer;
		var layersMap = new Map<Int,Dynamic>();
		var nodeID:String;
		for (nodeID in rawLayers) {
			var layerCurveNodes:Array<Dynamic> = [];
			var connection = connections.get(Std.parseInt(nodeID));
			if (connection != null) {
				var children = connection.children;
				var child:Dynamic;
				for (child in children) {
					if (curveNodesMap.exists(child.ID)) {
						var curveNode = curveNodesMap.get(child.ID);
						if (curveNode.curves.x != null || curveNode.curves.y != null || curveNode.curves.z != null) {
							if (layerCurveNodes.length == 0) {
								var modelID = connections.get(child.ID).parents.filter(function (parent) {
									return parent.relationship != null;
								})[0].ID;
								var rawModel = fbxTree.Objects.Model[modelID.toString()];
								if (rawModel == null) {
									trace('THREE.FBXLoader: Encountered a unused curve.');
									continue;
								}
								var node = {
									modelName: rawModel.attrName != null ? PropertyBinding.sanitizeNodeName(rawModel.attrName) : '',
									ID: rawModel.id,
									initialPosition: [0, 0, 0],
									initialRotation: [0, 0, 0],
									initialScale: [1, 1, 1],
								};
								sceneGraph.traverse(function (child) {
									if (child.ID == rawModel.id) {
										node.transform = child.matrix;
										if (child.userData.transformData != null) node.eulerOrder = child.userData.transformData.eulerOrder;
									}
								});
								if (node.transform == null) node.transform = new Matrix4();
								if ('PreRotation' in rawModel) node.preRotation = rawModel.PreRotation.value;
								if ('PostRotation' in rawModel) node.postRotation = rawModel.PostRotation.value;
								layerCurveNodes.push(node);
							}
							layerCurveNodes[layerCurveNodes.length - 1][curveNode.attr] = curveNode;
						} else if (curveNode.curves.morph != null) {
							if (layerCurveNodes.length == 0) {
								var deformerID = connections.get(child.ID).parents.filter(function (parent) {
									return parent.relationship != null;
								})[0].ID;
								var morpherID = connections.get(deformerID).parents[0].ID;
								var geoID = connections.get(morpherID).parents[0].ID;
								var modelID = connections.get(geoID).parents[0].ID;
								var rawModel = fbxTree.Objects.Model[modelID];
								var node = {
									modelName: rawModel.attrName != null ? PropertyBinding.sanitizeNodeName(rawModel.attrName) : '',
									morphName: fbxTree.Objects.Deformer[deformerID].attrName,
								};
								layerCurveNodes.push(node);
							}
							layerCurveNodes[layerCurveNodes.length - 1][curveNode.attr] = curveNode;
						}
					}
				}
				layersMap.set(Std.parseInt(nodeID), layerCurveNodes);
			}
		}
		return layersMap;
	}

	private function parseAnimStacks(layersMap:Map<Int,Dynamic>):Dynamic {
		var rawStacks = fbxTree.Objects.AnimationStack;
		var rawClips:Dynamic = {};
		var nodeID:String;
		for (nodeID in rawStacks) {
			var children = connections.get(Std.parseInt(nodeID)).children;
			if (children.length > 1) {
				trace('THREE.FBXLoader: Encountered an animation stack with multiple layers, this is currently not supported. Ignoring subsequent layers.');
			}
			var layer = layersMap.get(children[0].ID);
			rawClips[nodeID] = { name: rawStacks[nodeID].attrName, layer: layer };
		}
		return rawClips;
	}

	private function addClip(rawClip:Dynamic):AnimationClip {
		var tracks:Array<KeyframeTrack> = [];
		var rawTracks = rawClip.layer;
		var rawTrack:Dynamic;
		for (rawTrack in rawTracks) {
			tracks = tracks.concat(generateTracks(rawTrack));
		}
		return new AnimationClip(rawClip.name, -1, tracks);
	}

	private function generateTracks(rawTracks:Dynamic):Array<KeyframeTrack> {
		var tracks:Array<KeyframeTrack> = [];
		var initialPosition = new Vector3();
		var initialScale = new Vector3();
		if (rawTracks.transform != null) rawTracks.transform.decompose(initialPosition, new Quaternion(), initialScale);
		initialPosition = initialPosition.toArray();
		initialScale = initialScale.toArray();
		if (rawTracks.T != null && Reflect.field(rawTracks.T.curves) != null) {
			var positionTrack = generateVectorTrack(rawTracks.modelName, rawTracks.T.curves, initialPosition, 'position');
			if (positionTrack != null) tracks.push(positionTrack);
		}
		if (rawTracks.R != null && Reflect.field(rawTracks.R.curves) != null) {
			var rotationTrack = generateRotationTrack(rawTracks.modelName, rawTracks.R.curves, rawTracks.preRotation, rawTracks.postRotation, rawTracks.eulerOrder);
			if (rotationTrack != null) tracks.push(rotationTrack);
		}
		if (rawTracks.S != null && Reflect.field(rawTracks.S.curves) != null) {
			var scaleTrack = generateVectorTrack(rawTracks.modelName, rawTracks.S.curves, initialScale, 'scale');
			if (scaleTrack != null) tracks.push(scaleTrack);
		}
		if (rawTracks.DeformPercent != null) {
			var morphTrack = generateMorphTrack(rawTracks);
			if (morphTrack != null) tracks.push(morphTrack);
		}
		return tracks;
	}

	private function generateVectorTrack(modelName:String, curves:Dynamic, initialValue:Array<Float>, type:String):VectorKeyframeTrack {
		var times = getTimesForAllAxes(curves);
		var values = getKeyframeTrackValues(times, curves, initialValue);
		return new VectorKeyframeTrack(modelName + '.' + type, times, values);
	}

	private function generateRotationTrack(modelName:String, curves:Dynamic, preRotation:Dynamic, postRotation:Dynamic, eulerOrder:Dynamic):QuaternionKeyframeTrack {
		var times:Array<Float>;
		var values:Array<Float>;
		if (curves.x != null && curves.y != null && curves.z != null) {
			var result = interpolateRotations(curves.x, curves.y, curves.z, eulerOrder);
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
		var quaternion = new Quaternion();
		var euler = new Euler();
		var quaternionValues:Array<Float> = [];
		if (values == null || times == null) return new QuaternionKeyframeTrack(modelName + '.quaternion', [0], [0]);
		var i:Int;
		for (i = 0; i < values.length; i += 3) {
			euler.set(values[i], values[i + 1], values[i + 2], eulerOrder);
			quaternion.setFromEuler(euler);
			if (preRotation != null) quaternion.premultiply(preRotation);
			if (postRotation != null) quaternion.multiply(postRotation);
			if (i > 2) {
				var prevQuat = new Quaternion().fromArray(quaternionValues, ((i - 3) / 3) * 4);
				if (prevQuat.dot(quaternion) < 0) {
					quaternion.set(-quaternion.x, -quaternion.y, -quaternion.z, -quaternion.w);
				}
			}
			quaternion.toArray(quaternionValues, (i / 3) * 4);
		}
		return new QuaternionKeyframeTrack(modelName + '.quaternion', times, quaternionValues);
	}

	private function generateMorphTrack(rawTracks:Dynamic):NumberKeyframeTrack {
		var curves = rawTracks.DeformPercent.curves.morph;
		var values = curves.values.map(function (val) {
			return val / 100;
		});
		var morphNum = sceneGraph.getObjectByName(rawTracks.modelName).morphTargetDictionary[rawTracks.morphName];
		return new NumberKeyframeTrack(rawTracks.modelName + '.morphTargetInfluences[' + morphNum + ']', curves.times, values);
	}

	private function getTimesForAllAxes(curves:Dynamic):Array<Float> {
		var times:Array<Float> = [];
		if (curves.x != null) times = times.concat(curves.x.times);
		if (curves.y != null) times = times.concat(curves.y.times);
		if (curves.z != null) times = times.concat(curves.z.times);
		times = times.sort(function (a, b) {
			return a - b;
		});
		if (times.length > 1) {
			var targetIndex = 1;
			var lastValue = times[0];
			var i:Int;
			for (i = 1; i < times.length; i++) {
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

	private function getKeyframeTrackValues(times:Array<Float>, curves:Dynamic, initialValue:Array<Float>):Array<Float> {
		var prevValue = initialValue;
		var values:Array<Float> = [];
		var xIndex = -1;
		var yIndex = -1;
		var zIndex = -1;
		var time:Float;
		for (time in times) {
			if (curves.x != null) xIndex = curves.x.times.indexOf(time);
			if (curves.y != null) yIndex = curves.y.times.indexOf(time);
			if (curves.z != null) zIndex = curves.z.times.indexOf(time);
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

	private function interpolateRotations(curvex:Dynamic, curvey:Dynamic, curvez:Dynamic, eulerOrder:Dynamic):Array<Dynamic> {
		var times:Array<Float> = [];
		var values:Array<Float> = [];
		times.push(curvex.times[0]);
		values.push(MathUtils.degToRad(curvex.values[0]));
		values.push(MathUtils.degToRad(curvey.values[0]));
		values.push(MathUtils.degToRad(curvez.values[0]));
		var i:Int;
		for (i = 1; i < curvex.values.length; i++) {
			var initialValue = [curvex.values[i - 1], curvey.values[i - 1], curvez.values[i - 1]];
			var currentValue = [curvex.values[i], curvey.values[i], curvez.values[i]];
			var valuesSpan = [currentValue[0] - initialValue[0], currentValue[1] - initialValue[1], currentValue[2] - initialValue[2]];
			var absoluteSpan = [Math.abs(valuesSpan[0]), Math.abs(valuesSpan[1]), Math.abs(valuesSpan[2])];
			if (absoluteSpan[0] >= 180 || absoluteSpan[1] >= 180 || absoluteSpan[2] >= 180) {
				var maxAbsSpan = Math.max(absoluteSpan[0], absoluteSpan[1], absolute
span[2]);
				var numSubIntervals = maxAbsSpan / 180;
				var E1 = new Euler(initialValue[0], initialValue[1], initialValue[2], eulerOrder);
				var E2 = new Euler(currentValue[0], currentValue[1], currentValue[2], eulerOrder);
				var Q1 = new Quaternion().setFromEuler(E1);
				var Q2 = new Quaternion().setFromEuler(E2);
				if (Q1.dot(Q2) == 0) {
					Q2.set(-Q2.x, -Q2.y, -Q2.z, -Q2.w);
				}
				var initialTime = curvex.times[i - 1];
				var timeSpan = curvex.times[i] - initialTime;
				var Q = new Quaternion();
				var E = new Euler();
				var t:Float;
				for (t = 0; t < 1; t += 1 / numSubIntervals) {
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