package three.js.examples.jsm.exporters;

import haxe.Json;
import three.js.exporters.GLTFExporter;

class GLTFExporterPart2FuncPart4 {
    public function new() {}

    public function detectMeshQuantization(attributeName:String, attribute:Dynamic) {
        if (this.extensionsUsed.get(KHR_MESH_QUANTIZATION)) return;

        var attrType:String = null;

        switch (attribute.array.constructor) {
            case Int8Array:
                attrType = 'byte';
                break;
            case Uint8Array:
                attrType = 'unsigned byte';
                break;
            case Int16Array:
                attrType = 'short';
                break;
            case Uint16Array:
                attrType = 'unsigned short';
                break;
            default:
                return;
        }

        if (attribute.normalized) attrType += ' normalized';

        var attrNamePrefix:String = attributeName.split('_', 1)[0];

        if (KHR_mesh_quantization_ExtraAttrTypes.get(attrNamePrefix) && KHR_mesh_quantization_ExtraAttrTypes.get(attrNamePrefix).indexOf(attrType) != -1) {
            this.extensionsUsed.set(KHR_MESH_QUANTIZATION, true);
            this.extensionsRequired.set(KHR_MESH_QUANTIZATION, true);
        }
    }

    public function processCamera(camera:Dynamic) {
        var json:Json = this.json;

        if (json.cameras == null) json.cameras = [];

        var isOrtho:Bool = camera.isOrthographicCamera;
        var cameraDef:Dynamic = {
            type: isOrtho ? 'orthographic' : 'perspective'
        };

        if (isOrtho) {
            cameraDef.orthographic = {
                xmag: camera.right * 2,
                ymag: camera.top * 2,
                zfar: camera.far <= 0 ? 0.001 : camera.far,
                znear: camera.near < 0 ? 0 : camera.near
            };
        } else {
            cameraDef.perspective = {
                aspectRatio: camera.aspect,
                yfov: MathUtils.degToRad(camera.fov),
                zfar: camera.far <= 0 ? 0.001 : camera.far,
                znear: camera.near < 0 ? 0 : camera.near
            };
        }

        if (camera.name != '') cameraDef.name = camera.type;

        return json.cameras.push(cameraDef) - 1;
    }

    public function processAnimation(clip:Dynamic, root:Dynamic) {
        var json:Json = this.json;
        var nodeMap:Map<Dynamic, Int> = this.nodeMap;

        if (json.animations == null) json.animations = [];

        clip = GLTFExporter.Utils.mergeMorphTargetTracks(clip.clone(), root);

        var tracks:Array<Dynamic> = clip.tracks;
        var channels:Array<Dynamic> = [];
        var samplers:Array<Dynamic> = [];

        for (i in 0...tracks.length) {
            var track:Dynamic = tracks[i];
            var trackBinding:Dynamic = PropertyBinding.parseTrackName(track.name);
            var trackNode:Dynamic = PropertyBinding.findNode(root, trackBinding.nodeName);
            var trackProperty:Dynamic = PATH_PROPERTIES.get(trackBinding.propertyName);

            if (trackBinding.objectName == 'bones') {
                if (trackNode.isSkinnedMesh == true) {
                    trackNode = trackNode.skeleton.getBoneByName(trackBinding.objectIndex);
                } else {
                    trackNode = null;
                }
            }

            if (trackNode == null || trackProperty == null) {
                console.warn('THREE.GLTFExporter: Could not export animation track "${track.name}".');
                return null;
            }

            var inputItemSize:Int = 1;
            var outputItemSize:Int = track.values.length / track.times.length;

            if (trackProperty == PATH_PROPERTIES.morphTargetInfluences) {
                outputItemSize /= trackNode.morphTargetInfluences.length;
            }

            var interpolation:String;

            if (track.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline) {
                interpolation = 'CUBICSPLINE';
                outputItemSize /= 3;
            } else if (track.getInterpolation() == InterpolateDiscrete) {
                interpolation = 'STEP';
            } else {
                interpolation = 'LINEAR';
            }

            samplers.push({
                input: this.processAccessor(new BufferAttribute(track.times, inputItemSize)),
                output: this.processAccessor(new BufferAttribute(track.values, outputItemSize)),
                interpolation: interpolation
            });

            channels.push({
                sampler: samplers.length - 1,
                target: {
                    node: nodeMap.get(trackNode),
                    path: trackProperty
                }
            });
        }

        json.animations.push({
            name: clip.name != '' ? clip.name : 'clip_' + json.animations.length,
            samplers: samplers,
            channels: channels
        });

        return json.animations.length - 1;
    }

    public function processSkin(object:Dynamic) {
        var json:Json = this.json;
        var nodeMap:Map<Dynamic, Int> = this.nodeMap;

        var node:Dynamic = json.nodes.get(nodeMap.get(object));

        var skeleton:Dynamic = object.skeleton;

        if (skeleton == null) return null;

        var rootJoint:Dynamic = object.skeleton.bones[0];

        if (rootJoint == null) return null;

        var joints:Array<Dynamic> = [];
        var inverseBindMatrices:Array<Float> = new Array<Float>(skeleton.bones.length * 16);
        var temporaryBoneInverse:Matrix4 = new Matrix4();

        for (i in 0...skeleton.bones.length) {
            joints.push(nodeMap.get(skeleton.bones[i]));
            temporaryBoneInverse.copy(skeleton.boneInverses[i]);
            temporaryBoneInverse.multiply(object.bindMatrix).toArray(inverseBindMatrices, i * 16);
        }

        if (json.skins == null) json.skins = [];

        json.skins.push({
            inverseBindMatrices: this.processAccessor(new BufferAttribute(inverseBindMatrices, 16)),
            joints: joints,
            skeleton: nodeMap.get(rootJoint)
        });

        var skinIndex:Int = node.skin = json.skins.length - 1;

        return skinIndex;
    }

    public function processNode(object:Dynamic) {
        var json:Json = this.json;
        var options:Dynamic = this.options;
        var nodeMap:Map<Dynamic, Int> = this.nodeMap;

        if (json.nodes == null) json.nodes = [];

        var nodeDef:Dynamic = {};

        if (options.trs) {
            var rotation:Array<Float> = object.quaternion.toArray();
            var position:Array<Float> = object.position.toArray();
            var scale:Array<Float> = object.scale.toArray();

            if (!equalArray(rotation, [0, 0, 0, 1])) {
                nodeDef.rotation = rotation;
            }

            if (!equalArray(position, [0, 0, 0])) {
                nodeDef.translation = position;
            }

            if (!equalArray(scale, [1, 1, 1])) {
                nodeDef.scale = scale;
            }
        } else {
            if (object.matrixAutoUpdate) {
                object.updateMatrix();
            }

            if (!isIdentityMatrix(object.matrix)) {
                nodeDef.matrix = object.matrix.elements;
            }
        }

        if (object.name != '') nodeDef.name = String(object.name);

        this.serializeUserData(object, nodeDef);

        if (object.isMesh || object.isLine || object.isPoints) {
            var meshIndex:Int = this.processMesh(object);

            if (meshIndex != null) nodeDef.mesh = meshIndex;
        } else if (object.isCamera) {
            nodeDef.camera = this.processCamera(object);
        }

        if (object.isSkinnedMesh) this.skins.push(object);

        if (object.children.length > 0) {
            var children:Array<Int> = [];

            for (i in 0...object.children.length) {
                var child:Dynamic = object.children[i];

                if (child.visible || options.onlyVisible == false) {
                    var nodeIndex:Int = this.processNode(child);

                    if (nodeIndex != null) children.push(nodeIndex);
                }
            }

            if (children.length > 0) nodeDef.children = children;
        }

        this._invokeAll(function(ext) {
            ext.writeNode && ext.writeNode(object, nodeDef);
        });

        var nodeIndex:Int = json.nodes.push(nodeDef) - 1;
        nodeMap.set(object, nodeIndex);
        return nodeIndex;
    }

    public function processScene(scene:Dynamic) {
        var json:Json = this.json;
        var options:Dynamic = this.options;

        if (json.scenes == null) {
            json.scenes = [];
            json.scene = 0;
        }

        var sceneDef:Dynamic = {};

        if (scene.name != '') sceneDef.name = scene.name;

        json.scenes.push(sceneDef);

        var nodes:Array<Int> = [];

        for (i in 0...scene.children.length) {
            var child:Dynamic = scene.children[i];

            if (child.visible || options.onlyVisible == false) {
                var nodeIndex:Int = this.processNode(child);

                if (nodeIndex != null) nodes.push(nodeIndex);
            }
        }

        if (nodes.length > 0) sceneDef.nodes = nodes;

        this.serializeUserData(scene, sceneDef);
    }

    public function processObjects(objects:Array<Dynamic>) {
        var scene:Scene = new Scene();
        scene.name = 'AuxScene';

        for (i in 0...objects.length) {
            scene.children.push(objects[i]);
        }

        this.processScene(scene);
    }

    public function processInput(input:Array<Dynamic>) {
        var options:Dynamic = this.options;

        this._invokeAll(function(ext) {
            ext.beforeParse && ext.beforeParse(input);
        });

        var objectsWithoutScene:Array<Dynamic> = [];

        for (i in 0...input.length) {
            if (input[i] instanceof Scene) {
                this.processScene(input[i]);
            } else {
                objectsWithoutScene.push(input[i]);
            }
        }

        if (objectsWithoutScene.length > 0) this.processObjects(objectsWithoutScene);

        for (i in 0...this.skins.length) {
            this.processSkin(this.skins[i]);
        }

        for (i in 0...options.animations.length) {
            this.processAnimation(options.animations[i], input[0]);
        }

        this._invokeAll(function(ext) {
            ext.afterParse && ext.afterParse(input);
        });
    }

    public function _invokeAll(func:Dynamic) {
        for (i in 0...this.plugins.length) {
            func(this.plugins[i]);
        }
    }
}