import js.html.ArrayBufferView;
import js.html.Float32Array;
import js.html.HTMLCanvasElement;
import js.html.WebGLRenderingContext;
import js.html.WebGLUniformLocation;
import js.html.WebGLVertexArrayObject;
import js.html.WebGLBuffer;
import js.html.WebGLProgram;
import js.html.WebGLShader;

class AnimationParser {

    public function parse():Array<AnimationClip> {
        var animationClips:Array<AnimationClip> = [];
        var rawClips = this.parseClips();

        if (rawClips != null) {
            for (key in rawClips.keys()) {
                var rawClip = rawClips.get(key);
                var clip = this.addClip(rawClip);
                animationClips.push(clip);
            }
        }

        return animationClips;
    }

    public function parseClips():haxe.ds.StringMap<Dynamic> {
        if (fbxTree.Objects.AnimationCurve == null) return null;

        var curveNodesMap = this.parseAnimationCurveNodes();
        this.parseAnimationCurves(curveNodesMap);
        var layersMap = this.parseAnimationLayers(curveNodesMap);
        var rawClips = this.parseAnimStacks(layersMap);

        return rawClips;
    }

    public function parseAnimationCurveNodes():haxe.ds.IntMap<Dynamic> {
        var rawCurveNodes = fbxTree.Objects.AnimationCurveNode;
        var curveNodesMap = new haxe.ds.IntMap<Dynamic>();

        for (nodeID in rawCurveNodes.keys()) {
            var rawCurveNode = rawCurveNodes.get(nodeID);

            if (rawCurveNode.attrName.match(/S|R|T|DeformPercent/) != null) {
                var curveNode = {
                    id: rawCurveNode.id,
                    attr: rawCurveNode.attrName,
                    curves: new haxe.ds.StringMap<Dynamic>()
                };

                curveNodesMap.set(Std.parseInt(nodeID), curveNode);
            }
        }

        return curveNodesMap;
    }

    public function parseAnimationCurves(curveNodesMap:haxe.ds.IntMap<Dynamic>):Void {
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

                if (animationCurveRelationship.match(/X/) != null) {
                    curveNodesMap.get(animationCurveID).curves.set("x", animationCurve);
                } else if (animationCurveRelationship.match(/Y/) != null) {
                    curveNodesMap.get(animationCurveID).curves.set("y", animationCurve);
                } else if (animationCurveRelationship.match(/Z/) != null) {
                    curveNodesMap.get(animationCurveID).curves.set("z", animationCurve);
                } else if (animationCurveRelationship.match(/DeformPercent/) != null && curveNodesMap.exists(animationCurveID)) {
                    curveNodesMap.get(animationCurveID).curves.set("morph", animationCurve);
                }
            }
        }
    }

    public function parseAnimationLayers(curveNodesMap:haxe.ds.IntMap<Dynamic>):haxe.ds.IntMap<Array<Dynamic>> {
        var rawLayers = fbxTree.Objects.AnimationLayer;
        var layersMap = new haxe.ds.IntMap<Array<Dynamic>>();

        for (nodeID in rawLayers.keys()) {
            var layerCurveNodes:Array<Dynamic> = [];
            var connection = connections.get(Std.parseInt(nodeID));

            if (connection != null) {
                var children = connection.children;

                for (i in 0...children.length) {
                    var child = children[i];

                    if (curveNodesMap.exists(child.ID)) {
                        var curveNode = curveNodesMap.get(child.ID);

                        if (curveNode.curves.get("x") != null || curveNode.curves.get("y") != null || curveNode.curves.get("z") != null) {
                            if (layerCurveNodes[i] == null) {
                                var modelID = connection.parents.filter(function(parent) {
                                    return parent.relationship != null;
                                })[0].ID;

                                if (modelID != null) {
                                    var rawModel = fbxTree.Objects.Model[modelID.toString()];

                                    if (rawModel == null) {
                                        trace("THREE.FBXLoader: Encountered a unused curve.");
                                        trace(child);
                                        continue;
                                    }

                                    var node = {
                                        modelName: rawModel.attrName != null ? PropertyBinding.sanitizeNodeName(rawModel.attrName) : "",
                                        ID: rawModel.id,
                                        initialPosition: [0, 0, 0],
                                        initialRotation: [0, 0, 0],
                                        initialScale: [1, 1, 1]
                                    };

                                    sceneGraph.traverse(function(child) {
                                        if (child.ID == rawModel.id) {
                                            node.transform = child.matrix;

                                            if (child.userData.transformData) node.eulerOrder = child.userData.transformData.eulerOrder;
                                        }
                                    });

                                    if (node.transform == null) node.transform = new Matrix4();

                                    if ("PreRotation" in rawModel) node.preRotation = rawModel.PreRotation.value;
                                    if ("PostRotation" in rawModel) node.postRotation = rawModel.PostRotation.value;

                                    layerCurveNodes[i] = node;
                                }
                            }

                            if (layerCurveNodes[i] != null) layerCurveNodes[i][curveNode.attr] = curveNode;
                        } else if (curveNode.curves.get("morph") != null) {
                            if (layerCurveNodes[i] == null) {
                                var deformerID = connection.parents.filter(function(parent) {
                                    return parent.relationship != null;
                                })[0].ID;

                                var morpherID = connections.get(deformerID).parents[0].ID;
                                var geoID = connections.get(morpherID).parents[0].ID;
                                var modelID = connections.get(geoID).parents[0].ID;

                                var rawModel = fbxTree.Objects.Model[modelID];

                                var node = {
                                    modelName: rawModel.attrName != null ? PropertyBinding.sanitizeNodeName(rawModel.attrName) : "",
                                    morphName: fbxTree.Objects.Deformer[deformerID].attrName
                                };

                                layerCurveNodes[i] = node;
                            }

                            layerCurveNodes[i][curveNode.attr] = curveNode;
                        }
                    }
                }

                layersMap.set(Std.parseInt(nodeID), layerCurveNodes);
            }
        }

        return layersMap;
    }

    public function parseAnimStacks(layersMap:haxe.ds.IntMap<Array<Dynamic>>):haxe.ds.StringMap<Dynamic> {
        var rawStacks = fbxTree.Objects.AnimationStack;
        var rawClips = new haxe.ds.StringMap<Dynamic>();

        for (nodeID in rawStacks.keys()) {
            var children = connections.get(Std.parseInt(nodeID)).children;

            if (children.length > 1) {
                trace("THREE.FBXLoader: Encountered an animation stack with multiple layers, this is currently not supported. Ignoring subsequent layers.");
            }

            var layer = layersMap.get(children[0].ID);

            rawClips.set(nodeID, {
                name: rawStacks.get(nodeID).attrName,
                layer: layer
            });
        }

        return rawClips;
    }

    public function addClip(rawClip:Dynamic):AnimationClip {
        var tracks:Array<KeyframeTrack> = [];
        var scope = this;

        rawClip.layer.forEach(function(rawTracks) {
            tracks = tracks.concat(scope.generateTracks(rawTracks));
        });

        return new AnimationClip(rawClip.name, -1, tracks);
    }

    public function generateTracks(rawTracks:Dynamic):Array<KeyframeTrack> {
        var tracks:Array<KeyframeTrack> = [];

        var initialPosition = new Vector3();
        var initialScale = new Vector3();

        if (rawTracks.transform != null) rawTracks.transform.decompose(initialPosition, new Quaternion(), initialScale);

        initialPosition = initialPosition.toArray();
        initialScale = initialScale.toArray();

        if (rawTracks.T != null && rawTracks.T.curves.keys().length > 0) {
            var positionTrack = this.generateVectorTrack(rawTracks.modelName, rawTracks.T.curves, initialPosition, "position");
            if (positionTrack != null) tracks.push(positionTrack);
        }

        if (rawTracks.R != null && rawTracks.R.curves.keys().length > 0) {
            var rotationTrack = this.generateRotationTrack(rawTracks.modelName, rawTracks.R.curves, rawTracks.preRotation, rawTracks.postRotation, rawTracks.eulerOrder);
            if (rotationTrack != null) tracks.push(rotationTrack);
        }

        if (rawTracks.S != null && rawTracks.S.curves.keys().length > 0) {
            var scaleTrack = this.generateVectorTrack(rawTracks.modelName, rawTracks.S.curves, initialScale, "scale");
            if (scaleTrack != null) tracks.push(scaleTrack);
        }

        if (rawTracks.DeformPercent != null) {
            var morphTrack = this.generateMorphTrack(rawTracks);
            if (morphTrack != null) tracks.push(morphTrack);
        }

        return tracks;
    }

    public function generateVectorTrack(modelName:String, curves:haxe.ds.StringMap<Dynamic>, initialValue:Array<Float>, type:String):KeyframeTrack {
        var times = this.getTimesForAllAxes(curves);
        var values = this.getKeyframeTrackValues(times, curves, initialValue);

        return new VectorKeyframeTrack(modelName + "." + type, times, values);
    }

    public function generateRotationTrack(modelName:String, curves:haxe.ds.StringMap<Dynamic>, preRotation:Array<Float>, postRotation:Array<Float>, eulerOrder:String):KeyframeTrack {
        var times:Array<Float> = null;
        var values:Array<Float> = null;

        if (curves.get("x") != null && curves.get("y") != null && curves.get("z") != null) {
            var result = this.interpolateRotations(curves.get("x"), curves.get("y"), curves.get("z"), eulerOrder);

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

        if (values == null || times == null) return new QuaternionKeyframeTrack(modelName + ".quaternion", [0], [0]);

        for (var i = 0; i < values.length; i += 3) {
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

        return new QuaternionKeyframeTrack(modelName + ".quaternion", times, quaternionValues);
    }

    public function generateMorphTrack(rawTracks:Dynamic):KeyframeTrack {
        var curves = rawTracks.DeformPercent.curves.morph;
        var values = curves.values.map(function(val) {
            return val / 100;
        });

        var morphNum = sceneGraph.getObjectByName(rawTracks.modelName).morphTargetDictionary[rawTracks.morphName];

        return new NumberKeyframeTrack(rawTracks.modelName + ".morphTargetInfluences[" + morphNum + "]", curves.times, values);
    }

    public function getTimesForAllAxes(curves:haxe.ds.StringMap<Dynamic>):Array<Float> {
        var times:Array<Float> = [];

        if (curves.get("x") != null) times = times.concat(curves.get("x").times);
        if (curves.get("y") != null) times = times.concat(curves.get("y").times);
        if (curves.get("z") != null) times = times.concat(curves.get("z").times);

        times = times.sort(function(a, b) {
            return a - b;
        });

        if (times.length > 1) {
            var targetIndex = 1;
            var lastValue = times[0];
            for (var i = 1; i < times.length; i++) {
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

    public function getKeyframeTrackValues(times:Array<Float>, curves:haxe.ds.StringMap<Dynamic>, initialValue:Array<Float>):Array<Float> {
        var prevValue = initialValue;
        var values:Array<Float> = [];

        var xIndex = -1;
        var yIndex = -1;
        var zIndex = -1;

        for (time in times) {
            if (curves.get("x") != null) xIndex = curves.get("x").times.indexOf(time);
            if (curves.get("y") != null) yIndex = curves.get("y").times.indexOf(time);
            if (curves.get("z") != null) zIndex = curves.get("z").times.indexOf(time);

            if (xIndex != -1) {
                var xValue = curves.get("x").values[xIndex];
                values.push(xValue);
                prevValue[0] = xValue;
            } else {
                values.push(prevValue[0]);
            }

            if (yIndex != -1) {
                var yValue = curves.get("y").values[yIndex];
                values.push(yValue);
                prevValue[1] = yValue;
            } else {
                values.push(prevValue[1]);
            }

            if (zIndex != -1) {
                var zValue = curves.get("z").values[zIndex];
                values.push(zValue);
                prevValue[2] = zValue;
            } else {
                values.push(prevValue[2]);
            }
        }

        return values;
    }

    public function interpolateRotations(curvex:Dynamic, curvey:Dynamic, curvez:Dynamic, eulerOrder:String):Array<Array<Float>> {
        var times:Array<Float> = [];
        var values:Array<Float> = [];

        times.push(curvex.times[0]);
        values.push(MathUtils.degToRad(curvex.values[0]));
        values.push(MathUtils.degToRad(curvey.values[0]));
        values.push(MathUtils.degToRad(curvez.values[0]));

        for (var i = 1; i < curvex.values.length; i++) {
            var initialValue = [
                curvex.values[i - 1],
                curvey.values[i - 1],
                curvez.values[i - 1]
            ];

            if (isNaN(initialValue[0]) || isNaN(initialValue[1]) || isNaN(initialValue[2])) {
                continue;
            }

            var initialValueRad = initialValue.map(MathUtils.degToRad);

            var currentValue = [
                curvex.values[i],
                curvey.values[i],
                curvez.values[i]
            ];

            if (isNaN(currentValue[0]) || isNaN(currentValue[1]) || isNaN(currentValue[2])) {
                continue;
            }

            var currentValueRad = currentValue.map(MathUtils.degToRad);

            var valuesSpan = [
                currentValue[0] - initialValue[0],
                currentValue[1] - initialValue[1],
                currentValue[2] - initialValue[2]
            ];

            var absoluteSpan = [
                Math.abs(valuesSpan[0]),
                Math.abs(valuesSpan[1]),
                Math.abs(valuesSpan[2])
            ];

            if (absoluteSpan[0] >= 180 || absoluteSpan[1] >= 180 || absoluteSpan[2] >= 180) {
                var maxAbsSpan = Math.max(absoluteSpan[0], absoluteSpan[1], absoluteSpan[2]);

                var numSubIntervals = maxAbsSpan / 180;

                var E1 = new Euler(initialValueRad[0], initialValueRad[1], initialValueRad[2], eulerOrder);
                var E2 = new Euler(currentValueRad[0], currentValueRad[1], currentValueRad[2], eulerOrder);

                var Q1 = new Quaternion().setFromEuler(E1);
                var Q2 = new Quaternion().setFromEuler(E2);

                if (Q1.dot(Q2)) {
                    Q2.set(-Q2.x, -Q2.y, -Q2.z, -Q2.w);
                }

                var initialTime = curvex.times[i - 1];
                var timeSpan = curvex.times[i] - initialTime;

                var Q = new Quaternion();
                var E = new Euler();
                for (var t = 0; t < 1; t += 1 / numSubIntervals) {
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