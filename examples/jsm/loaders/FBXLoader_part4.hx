class AnimationParser {

    public function new() {}

    // take raw animation clips and turn them into three.js animation clips
    public function parse():Array<AnimationClip> {
        var animationClips:Array<AnimationClip> = [];
        var rawClips = this.parseClips();
        if (rawClips != null) {
            for (key in rawClips) {
                var rawClip = rawClips[key];
                var clip = this.addClip(rawClip);
                animationClips.push(clip);
            }
        }
        return animationClips;
    }

    // parse nodes in FBXTree.Objects.AnimationCurve
    // each AnimationCurveNode holds data for an animation transform for a model (e.g. left arm rotation )
    // and is referenced by an AnimationLayer
    private function parseAnimationCurveNodes():Map<String, CurveNode> {
        var rawCurveNodes = fbxTree.Objects.AnimationCurveNode;
        var curveNodesMap = new Map<String, CurveNode>();
        for (nodeID in rawCurveNodes) {
            var rawCurveNode = rawCurveNodes[nodeID];
            if (rawCurveNode.attrName.match(/S|R|T|DeformPercent/) != null) {
                var curveNode = {
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
    private function parseAnimationCurves(curveNodesMap:Map<String, CurveNode>) {
        var rawCurves = fbxTree.Objects.AnimationCurve;
        for (nodeID in rawCurves) {
            var animationCurve = {
                id: rawCurves[nodeID].id,
                times: rawCurves[nodeID].KeyTime.a.map(convertFBXTimeToSeconds),
                values: rawCurves[nodeID].KeyValueFloat.a,
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
                } else if (animationCurveRelationship.match(/DeformPercent/) && curveNodesMap.has(animationCurveID)) {
                    curveNodesMap.get(animationCurveID).curves['morph'] = animationCurve;
                }
            }
        }
    }

    // parse nodes in FBXTree.Objects.AnimationLayer. Each layers holds references
    // to various AnimationCurveNodes and is referenced by an AnimationStack node
    // note: theoretically a stack can have multiple layers, however in practice there always seems to be one per stack
    private function parseAnimationLayers(curveNodesMap:Map<String, CurveNode>):Map<Int, Array<CurveNode>> {
        var rawLayers = fbxTree.Objects.AnimationLayer;
        var layersMap = new Map<Int, Array<CurveNode>>();
        for (nodeID in rawLayers) {
            var layerCurveNodes = [];
            var connection = connections.get(Int(nodeID));
            if (connection != null) {
                // all the animationCurveNodes used in the layer
                var children = connection.children;
                for (i in 0...children.length) {
                    var rawCurveNode = curveNodesMap.get(children[i].ID);
                    if (rawCurveNode != null) {
                        if (rawCurveNode.curves.x != undefined ||
                            rawCurveNode.curves.y != undefined ||
                            rawCurveNode.curves.z != undefined) {
                            if (layerCurveNodes[i] == undefined) {
                                var modelID = connections.get(children[i].ID).parents.filter(
                                    function (parent) {
                                        return parent.relationship != undefined;
                                    }
                                )[0].ID;
                                if (modelID != undefined) {
                                    var rawModel = fbxTree.Objects.Model[modelID.toString()];
                                    if (rawModel == undefined) {
                                        console.warn('THREE.FBXLoader: Encountered a unused curve.', children[i]);
                                        continue;
                                    }
                                    var node = {
                                        modelName: rawModel.attrName != undefined ?
                                            PropertyBinding.sanitizeNodeName(rawModel.attrName) :
                                            '',
                                        ID: rawModel.id,
                                        initialPosition: [0, 0, 0],
                                        initialRotation: [0, 0, 0],
                                        initialScale: [1, 1, 1],
                                    };
                                    sceneGraph.traverse(function (child) {
                                        if (child.ID == rawModel.id) {
                                            node.transform = child.matrix;
                                            if (child.userData.transformData) node.eulerOrder = child.userData.transformData.eulerOrder;
                                        }
                                    });
                                    if (node.transform == null) node.transform = new Matrix4();
                                    if ('PreRotation' in rawModel) node.preRotation = rawModel.PreRotation.value;
                                    if ('PostRotation' in rawModel) node.postRotation = rawModel.PostRotation.value;
                                    layerCurveNodes[i] = node;
                                }
                            }
                            if (layerCurveNodes[i] != null) layerCurveNodes[i][rawCurveNode.attr] = rawCurveNode;
                        } else if (rawCurveNode.curves.morph != undefined) {
                            if (layerCurveNodes[i] == undefined) {
                                var deformerID = connections.get(children[i].ID).parents.filter(
                                    function (parent) {
                                        return parent.relationship != undefined;
                                    }
                                )[0].ID;
                                var morpherID = connections.get(deformerID).parents[0].ID;
                                var geoID = connections.get(morpherID).parents[0].ID;
                                // assuming geometry is not used in more than one model
                                var modelID = connections.get(geoID).parents[0].ID;
                                var rawModel = fbxTree.Objects.Model[modelID];
                                var node = {
                                    modelName: rawModel.attrName != undefined ?
                                        PropertyBinding.sanitizeNodeName(rawModel.attrName) :
                                        '',
                                    morphName: fbxTree.Objects.Deformer[deformerID].attrName,
                                };
                                layerCurveNodes[i] = node;
                            }
                            layerCurveNodes[i][rawCurveNode.attr] = rawCurveNode;
                        }
                    }
                }
                layersMap.set(Int(nodeID), layerCurveNodes);
            }
        }
        return layersMap;
    }

    // parse nodes in FBXTree.Objects.AnimationStack. These are the top level node in the animation
    // hierarchy. Each Stack node will be used to create a AnimationClip
    private function parseAnimStacks(layersMap:Map<Int, Array<CurveNode>>):Array<RawClip> {
        var rawStacks = fbxTree.Objects.AnimationStack;
        // connect the stacks (clips) up to the layers
        var rawClips = {};
        for (nodeID in rawStacks) {
            var children = connections.get(Int(nodeID)).children;
            if (children.length > 1) {
                // it seems like stacks will always be associated with a single layer. But just in case there are files
                // where there are multiple layers per stack, we'll display a warning
                console.warn('THREE.FBXLoader: Encountered an animation stack with multiple layers, this is currently not supported. Ignoring subsequent layers.');
            }
            var layer = layersMap.get(Int(children[0]));
            rawClips[nodeID] = {
                name: rawStacks[nodeID].attrName,
                layer: layer,
            };
        }
        return cast rawClips;
    }

    private function addClip(rawClip:RawClip):AnimationClip {
        var tracks:Array<Track> = [];
        var scope = this;
        rawClip.layer.forEach(function (rawTracks:Array<RawTrack>) {
            tracks = tracks.concat(scope.generateTracks(rawTracks));
        });
        return new AnimationClip(rawClip.name, -1, tracks);
    }

    // TODO: Implement generateTracks and the helper functions
    private function generateTracks(rawTracks:Array<RawTrack>):Array<Track> {
        var tracks:Array<Track> = [];
        return tracks;
    }

}

class CurveNode {
    public var id:String;
    public var attr:String;
    public var curves:Map<String, AnimationCurve>;
}

class RawClip {
    public var name:String;
    public var layer:Map<Int, Array<CurveNode>>;
}

class RawTrack {
    public var transform:Map<String, AnimationCurve>;
    public var T:Map<String, AnimationCurve>;
    public var R:Map<String, AnimationCurve>;
    public var S:Map<String, AnimationCurve>;
    public var DeformPercent:Map<String, AnimationCurve>;
    public var morphName:String;
    public var modelName:String;
}

class AnimationCurve {
    public var id:String;
    public var times:Array<Float>;
    public var values:Array<Float>;
}