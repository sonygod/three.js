package three.js.examples.loaders;

import js.Promise;
import js.three.AnimationClip;
import js.three.Bone;
import js.three.Camera;
import js.three.Group;
import js.three.Matrix4;
import js.three.Mesh;
import js.three.Object3D;
import js.three.Quaternion;
import js.three.Scene;
import js.three.Texture;
import js.three.VectorKeyframeTrack;
import js.three.NumberKeyframeTrack;
import js.three.QuaternionKeyframeTrack;

class GLTFLoader {
  var json:Dynamic;
  var parser:GLTFLoader;
  var nodeCache:Map<Int, Promise<Object3D>>;
  var associations:Map<Object3D, Dynamic>;
  var meshCache:Map<String, Mesh>;
  var cameraCache:Map<String, Camera>;
  var extensions:Array<Dynamic>;

  public function loadAnimation(animationIndex:Int):Promise<AnimationClip> {
    var animationDef = json.animations[animationIndex];
    var animationName = animationDef.name != null ? animationDef.name : 'animation_' + animationIndex;

    var pendingNodes:Array<Promise<Object3D>> = [];
    var pendingInputAccessors:Array<Promise<Accessor>> = [];
    var pendingOutputAccessors:Array<Promise<Accessor>> = [];
    var pendingSamplers:Array<Promise<Sampler>> = [];
    var pendingTargets:Array<Promise<Target>> = [];

    for (i in 0...animationDef.channels.length) {
      var channel = animationDef.channels[i];
      var sampler = animationDef.samplers[channel.sampler];
      var target = channel.target;
      var nodeName = target.node;
      var input = animationDef.parameters != null ? animationDef.parameters[sampler.input] : sampler.input;
      var output = animationDef.parameters != null ? animationDef.parameters[sampler.output] : sampler.output;

      if (target.node == null) continue;

      pendingNodes.push(getDependency('node', nodeName));
      pendingInputAccessors.push(getDependency('accessor', input));
      pendingOutputAccessors.push(getDependency('accessor', output));
      pendingSamplers.push(Promise.resolve(sampler));
      pendingTargets.push(Promise.resolve(target));
    }

    return Promise.all([
      Promise.all(pendingNodes),
      Promise.all(pendingInputAccessors),
      Promise.all(pendingOutputAccessors),
      Promise.all(pendingSamplers),
      Promise.all(pendingTargets)
    ]).then(function(dependencies:Array<Array<Dynamic>>) {
      var nodes:Array<Object3D> = dependencies[0];
      var inputAccessors:Array<Accessor> = dependencies[1];
      var outputAccessors:Array<Accessor> = dependencies[2];
      var samplers:Array<Sampler> = dependencies[3];
      var targets:Array<Target> = dependencies[4];

      var tracks:Array<KeyframeTrack> = [];

      for (i in 0...nodes.length) {
        var node:Object3D = nodes[i];
        var inputAccessor:Accessor = inputAccessors[i];
        var outputAccessor:Accessor = outputAccessors[i];
        var sampler:Sampler = samplers[i];
        var target:Target = targets[i];

        if (node == null) continue;

        if (node.updateMatrix != null) {
          node.updateMatrix();
        }

        var createdTracks:Array<KeyframeTrack> = _createAnimationTracks(node, inputAccessor, outputAccessor, sampler, target);

        if (createdTracks != null) {
          for (k in 0...createdTracks.length) {
            tracks.push(createdTracks[k]);
          }
        }
      }

      return new AnimationClip(animationName, null, tracks);
    });
  }

  public function createNodeMesh(nodeIndex:Int):Promise<Mesh> {
    var nodeDef = json.nodes[nodeIndex];

    if (nodeDef.mesh == null) return Promise.resolve(null);

    return getDependency('mesh', nodeDef.mesh).then(function(mesh:Mesh) {
      var node:Object3D = _getNodeRef(meshCache, nodeDef.mesh, mesh);

      if (nodeDef.weights != null) {
        node.traverse(function(o:Object3D) {
          if (!o.isMesh) return;

          for (i in 0...nodeDef.weights.length) {
            o.morphTargetInfluences[i] = nodeDef.weights[i];
          }
        });
      }

      return node;
    });
  }

  public function loadNode(nodeIndex:Int):Promise<Object3D> {
    var nodeDef = json.nodes[nodeIndex];

    var nodePending:Promise<Object3D> = _loadNodeShallow(nodeIndex);

    var childPending:Array<Promise<Object3D>> = [];
    var childrenDef:Array<Int> = nodeDef.children;

    for (i in 0...childrenDef.length) {
      childPending.push(getDependency('node', childrenDef[i]));
    }

    var skeletonPending:Promise<Skin> = nodeDef.skin == null ? Promise.resolve(null) : getDependency('skin', nodeDef.skin);

    return Promise.all([nodePending, Promise.all(childPending), skeletonPending]).then(function(results:Array<Dynamic>) {
      var node:Object3D = results[0];
      var children:Array<Object3D> = results[1];
      var skeleton:Skin = results[2];

      if (skeleton != null) {
        node.traverse(function(mesh:Object3D) {
          if (!mesh.isSkinnedMesh) return;

          mesh.bind(skeleton, _identityMatrix);
        });
      }

      for (i in 0...children.length) {
        node.add(children[i]);
      }

      return node;
    });
  }

  function _loadNodeShallow(nodeIndex:Int):Promise<Object3D> {
    if (nodeCache[nodeIndex] != null) {
      return nodeCache[nodeIndex];
    }

    var nodeDef = json.nodes[nodeIndex];

    var nodeName:String = nodeDef.name != null ? createUniqueName(nodeDef.name) : '';

    var pending:Array<Promise<Dynamic>> = [];

    var meshPromise:Promise<Mesh> = _invokeOne(function(ext:Dynamic) {
      return ext.createNodeMesh && ext.createNodeMesh(nodeIndex);
    });

    if (meshPromise != null) {
      pending.push(meshPromise);
    }

    if (nodeDef.camera != null) {
      pending.push(getDependency('camera', nodeDef.camera).then(function(camera:Camera) {
        return _getNodeRef(cameraCache, nodeDef.camera, camera);
      }));
    }

    _invokeAll(function(ext:Dynamic) {
      return ext.createNodeAttachment && ext.createNodeAttachment(nodeIndex);
    }).forEach(function(promise:Promise<Dynamic>) {
      pending.push(promise);
    });

    nodeCache[nodeIndex] = Promise.all(pending).then(function(objects:Array<Dynamic>) {
      var node:Object3D;

      if (nodeDef.isBone) {
        node = new Bone();
      } else if (objects.length > 1) {
        node = new Group();
      } else if (objects.length == 1) {
        node = objects[0];
      } else {
        node = new Object3D();
      }

      if (node != objects[0]) {
        for (i in 0...objects.length) {
          node.add(objects[i]);
        }
      }

      if (nodeDef.name != null) {
        node.userData.name = nodeDef.name;
        node.name = nodeName;
      }

      assignExtrasToUserData(node, nodeDef);

      if (nodeDef.extensions != null) addUnknownExtensionsToUserData(extensions, node, nodeDef);

      if (nodeDef.matrix != null) {
        var matrix:Matrix4 = new Matrix4();
        matrix.fromArray(nodeDef.matrix);
        node.applyMatrix4(matrix);
      } else {
        if (nodeDef.translation != null) {
          node.position.fromArray(nodeDef.translation);
        }

        if (nodeDef.rotation != null) {
          node.quaternion.fromArray(nodeDef.rotation);
        }

        if (nodeDef.scale != null) {
          node.scale.fromArray(nodeDef.scale);
        }
      }

      if (!associations.has(node)) {
        associations.set(node, {});
      }

      associations.get(node).nodes = nodeIndex;

      return node;
    });

    return nodeCache[nodeIndex];
  }

  public function loadScene(sceneIndex:Int):Promise<Scene> {
    var sceneDef = json.scenes[sceneIndex];
    var parser:GLTFLoader = this;

    var scene:Scene = new Group();
    if (sceneDef.name != null) scene.name = createUniqueName(sceneDef.name);

    assignExtrasToUserData(scene, sceneDef);

    if (sceneDef.extensions != null) addUnknownExtensionsToUserData(extensions, scene, sceneDef);

    var nodeIds:Array<Int> = sceneDef.nodes;

    var pending:Array<Promise<Object3D>> = [];

    for (i in 0...nodeIds.length) {
      pending.push(getDependency('node', nodeIds[i]));
    }

    return Promise.all(pending).then(function(nodes:Array<Object3D>) {
      for (i in 0...nodes.length) {
        scene.add(nodes[i]);
      }

      var reducedAssociations:Map<Object3D, Dynamic> = new Map();

      for (key => value in associations) {
        if (Std.isOfType(key, Material) || Std.isOfType(key, Texture)) {
          reducedAssociations.set(key, value);
        }
      }

      scene.traverse(function(node:Object3D) {
        var mappings:Dynamic = associations.get(node);

        if (mappings != null) {
          reducedAssociations.set(node, mappings);
        }
      });

      associations = reducedAssociations;

      return scene;
    });
  }

  function _createAnimationTracks(node:Object3D, inputAccessor:Accessor, outputAccessor:Accessor, sampler:Sampler, target:Target):Array<KeyframeTrack> {
    var tracks:Array<KeyframeTrack> = [];

    var targetName:String = node.name != null ? node.name : node.uuid;
    var targetNames:Array<String> = [];

    if (PATH_PROPERTIES[target.path] == PATH_PROPERTIES.weights) {
      node.traverse(function(object:Object3D) {
        if (object.morphTargetInfluences != null) {
          targetNames.push(object.name != null ? object.name : object.uuid);
        }
      });
    } else {
      targetNames.push(targetName);
    }

    var TypedKeyframeTrack:Class<KeyframeTrack>;

    switch (PATH_PROPERTIES[target.path]) {
      case PATH_PROPERTIES.weights:
        TypedKeyframeTrack = NumberKeyframeTrack;
        break;
      case PATH_PROPERTIES.rotation:
        TypedKeyframeTrack = QuaternionKeyframeTrack;
        break;
      case PATH_PROPERTIES.position:
      case PATH_PROPERTIES.scale:
        TypedKeyframeTrack = VectorKeyframeTrack;
        break;
      default:
        switch (outputAccessor.itemSize) {
          case 1:
            TypedKeyframeTrack = NumberKeyframeTrack;
            break;
          case 2:
          case 3:
          default:
            TypedKeyframeTrack = VectorKeyframeTrack;
            break;
        }
        break;
    }

    var interpolation:Interpolation = sampler.interpolation != null ? INTERPOLATION[sampler.interpolation] : InterpolateLinear;

    var outputArray:Array<Float> = _getArrayFromAccessor(outputAccessor);

    for (j in 0...targetNames.length) {
      var track:KeyframeTrack = new TypedKeyframeTrack(
        targetNames[j] + '.' + PATH_PROPERTIES[target.path],
        inputAccessor.array,
        outputArray,
        interpolation
      );

      if (sampler.interpolation == 'CUBICSPLINE') {
        _createCubicSplineTrackInterpolant(track);
      }

      tracks.push(track);
    }

    return tracks;
  }

  function _getArrayFromAccessor(accessor:Accessor):Array<Float> {
    var outputArray:Array<Float> = accessor.array;

    if (accessor.normalized) {
      var scale:Float = getNormalizedComponentScale(outputArray.constructor);
      var scaled:Array<Float> = new Float32Array(outputArray.length);

      for (j in 0...outputArray.length) {
        scaled[j] = outputArray[j] * scale;
      }

      outputArray = scaled;
    }

    return outputArray;
  }

  function _createCubicSplineTrackInterpolant(track:KeyframeTrack) {
    track.createInterpolant = function(result:Dynamic) {
      var interpolantType:Class<Interpolant> = Std.isOfType(track, QuaternionKeyframeTrack) ? GLTFCubicSplineQuaternionInterpolant : GLTFCubicSplineInterpolant;

      return new interpolantType(track.times, track.values, track.getValueSize() / 3, result);
    };

    track.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline = true;
  }
}