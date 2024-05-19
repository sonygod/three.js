Here is the converted Haxe code:
```
package three.js.examples.jsm.loaders;

import haxe.ds.Map;
import haxe.Json;
import three.core.Group;
import three.core.Object3D;
import three.loaders.AnimationParser;
import three.math.Matrix4;
import three.math.Vector3;
import three.mesh.Bone;
import three.mesh.Mesh;
import three.mesh.SkinnedMesh;
import three.mesh.VertexColors;
import three.materials.Material;
import three.materials.MeshPhongMaterial;
import three.materials.LineBasicMaterial;
import three.lights.AmbientLight;
import three.lights.DirectionalLight;
import three.lights.PointLight;
import three.lights.SpotLight;
import three.cameras.Camera;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.loaders.FBXLoader;

class FBXLoader_part2_func_part2 {
    public function getTexture(textureMap:Map<Int, Dynamic>, id:Int) {
        if (fbxTree.Objects.LayeredTexture != null && fbxTree.Objects.LayeredTexture[id] != null) {
            Console.warn('THREE.FBXLoader: layered textures are not supported in three.js. Discarding all but first layer.');
            id = connections.get(id).children[0].ID;
        }
        return textureMap.get(id);
    }

    public function parseDeformers():{skeletons:Map<Int, Dynamic>, morphTargets:Map<Int, Dynamic>} {
        var skeletons:Map<Int, Dynamic> = new Map<Int, Dynamic>();
        var morphTargets:Map<Int, Dynamic> = new Map<Int, Dynamic>();

        if (fbxTree.Objects.Deformer != null) {
            var DeformerNodes = fbxTree.Objects.Deformer;
            for (nodeID in DeformerNodes.keys()) {
                var deformerNode = DeformerNodes[nodeID];
                var relationships = connections.get(Std.parseInt(nodeID));

                if (deformerNode.attrType == 'Skin') {
                    var skeleton:Skeleton = parseSkeleton(relationships, DeformerNodes);
                    skeleton.ID = nodeID;

                    if (relationships.parents.length > 1) Console.warn('THREE.FBXLoader: skeleton attached to more than one geometry is not supported.');
                    skeleton.geometryID = relationships.parents[0].ID;

                    skeletons[nodeID] = skeleton;

                } else if (deformerNode.attrType == 'BlendShape') {
                    var morphTarget = {
                        id: nodeID
                    };

                    morphTarget.rawTargets = parseMorphTargets(relationships, DeformerNodes);
                    morphTarget.id = nodeID;

                    if (relationships.parents.length > 1) Console.warn('THREE.FBXLoader: morph target attached to more than one geometry is not supported.');

                    morphTargets[nodeID] = morphTarget;
                }
            }
        }

        return {
            skeletons: skeletons,
            morphTargets: morphTargets
        };
    }

    public function parseSkeleton(relationships:Map<Int, Dynamic>, deformerNodes:Map<Int, Dynamic>):Skeleton {
        var rawBones:Array<Bone> = [];

        relationships.children.forEach(function(child) {
            var boneNode = deformerNodes[child.ID];
            if (boneNode.attrType != 'Cluster') return;

            var rawBone:Bone = {
                ID: child.ID,
                indices: [],
                weights: [],
                transformLink: new Matrix4().fromArray(boneNode.TransformLink.a),
                // transform: new Matrix4().fromArray(boneNode.Transform.a),
                // linkMode: boneNode.Mode
            };

            if (boneNode.Indexes != null) {
                rawBone.indices = boneNode.Indexes.a;
                rawBone.weights = boneNode.Weights.a;
            }

            rawBones.push(rawBone);
        });

        return {
            rawBones: rawBones,
            bones: []
        };
    }

    public function parseMorphTargets(relationships:Map<Int, Dynamic>, deformerNodes:Map<Int, Dynamic>):Array<MorphTarget> {
        var rawMorphTargets:Array<MorphTarget> = [];

        for (i in 0...relationships.children.length) {
            var child = relationships.children[i];
            var morphTargetNode = deformerNodes[child.ID];

            var rawMorphTarget:MorphTarget = {
                name: morphTargetNode.attrName,
                initialWeight: morphTargetNode.DeformPercent,
                id: morphTargetNode.id,
                fullWeights: morphTargetNode.FullWeights.a
            };

            if (morphTargetNode.attrType != 'BlendShapeChannel') return;

            rawMorphTarget.geoID = connections.get(Std.parseInt(child.ID)).children.filter(function(child) {
                return child.relationship == undefined;
            })[0].ID;

            rawMorphTargets.push(rawMorphTarget);
        }

        return rawMorphTargets;
    }

    public function parseScene(deformers:{skeletons:Map<Int, Dynamic>, morphTargets:Map<Int, Dynamic>}, geometryMap:Map<Int, Geometry>, materialMap:Map<Int, Material>) {
        var sceneGraph:Group = new Group();

        var modelMap:Map<Int, Object3D> = parseModels(deformers.skeletons, geometryMap, materialMap);

        var modelNodes:Map<Int, Dynamic> = fbxTree.Objects.Model;

        for (id in modelMap.keys()) {
            var model:Object3D = modelMap.get(id);
            var modelNode:Dynamic = modelNodes[id];
            setLookAtProperties(model, modelNode);

            var parentConnections:Array<Dynamic> = connections.get(id).parents;
            parentConnections.forEach(function(parent) {
                var parentModel:Object3D = modelMap.get(parent.ID);
                if (parentModel != null) parentModel.add(model);
            });

            if (model.parent == null) {
                sceneGraph.add(model);
            }
        }

        bindSkeleton(deformers.skeletons, geometryMap, modelMap);

        addGlobalSceneSettings();

        sceneGraph.traverse(function(node:Object3D) {
            if (node.userData.transformData != null) {
                if (node.parent != null) {
                    node.userData.transformData.parentMatrix = node.parent.matrix;
                    node.userData.transformData.parentMatrixWorld = node.parent.matrixWorld;
                }

                var transform:Matrix4 = generateTransform(node.userData.transformData);
                node.applyMatrix4(transform);
                node.updateWorldMatrix();
            }
        });

        var animations:Array<Animation> = new AnimationParser().parse();

        if (sceneGraph.children.length == 1 && sceneGraph.children[0] is Group) {
            sceneGraph.children[0].animations = animations;
            sceneGraph = sceneGraph.children[0];
        }

        sceneGraph.animations = animations;
    }

    public function parseModels(skeletons:Map<Int, Dynamic>, geometryMap:Map<Int, Geometry>, materialMap:Map<Int, Material>):Map<Int, Object3D> {
        var modelMap:Map<Int, Object3D> = new Map<Int, Object3D>();
        var modelNodes:Map<Int, Dynamic> = fbxTree.Objects.Model;

        for (nodeID in modelNodes.keys()) {
            var id:Int = Std.parseInt(nodeID);
            var node:Dynamic = modelNodes[nodeID];
            var relationships:Map<Int, Dynamic> = connections.get(id);

            var model:Object3D;

            switch (node.attrType) {
                case 'Camera':
                    model = createCamera(relationships);
                    break;
                case 'Light':
                    model = createLight(relationships);
                    break;
                case 'Mesh':
                    model = createMesh(relationships, geometryMap, materialMap);
                    break;
                case 'NurbsCurve':
                    model = createCurve(relationships, geometryMap);
                    break;
                case 'LimbNode':
                case 'Root':
                    model = new Bone();
                    break;
                case 'Null':
                default:
                    model = new Group();
                    break;
            }

            model.name = node.attrName != null ? PropertyBinding.sanitizeNodeName(node.attrName) : '';
            model.userData.originalName = node.attrName;

            model.ID = id;

            getTransformData(model, node);

            modelMap.set(id, model);
        }

        return modelMap;
    }

    public function buildSkeleton(relationships:Map<Int, Dynamic>, skeletons:Map<Int, Dynamic>, id:Int, name:String):Bone {
        var bone:Bone = null;

        relationships.parents.forEach(function(parent) {
            for (skeletonID in skeletons.keys()) {
                var skeleton:Skeleton = skeletons[skeletonID];
                skeleton.rawBones.forEach(function(rawBone:Bone, i:Int) {
                    if (rawBone.ID == parent.ID) {
                        var subBone:Bone = bone;
                        bone = new Bone();

                        bone.matrixWorld.copy(rawBone.transformLink);

                        // set name and id here - otherwise in cases where "subBone" is created it will not have a name / id

                        bone.name = name != null ? PropertyBinding.sanitizeNodeName(name) : '';
                        bone.userData.originalName = name;
                        bone.ID = id;

                        skeleton.bones[i] = bone;

                        // In cases where a bone is shared between multiple meshes
                        // duplicate the bone here and and it as a child of the first bone
                        if (subBone != null) {
                            bone.add(subBone);
                        }
                    }
                });
            }
        });

        return bone;
    }

    public function createCamera(relationships:Map<Int, Dynamic>):Camera {
        var model:Camera;
        var cameraAttribute:Dynamic;

        relationships.children.forEach(function(child) {
            var attr:Dynamic = fbxTree.Objects.NodeAttribute[child.ID];
            if (attr != null) {
                cameraAttribute = attr;
            }
        });

        if (cameraAttribute == null) {
            model = new Object3D();
        } else {
            var type:Int = 0;
            if (cameraAttribute.CameraProjectionType != null && cameraAttribute.CameraProjectionType.value == 1) {
                type = 1;
            }

            var nearClippingPlane:Float = 1;
            if (cameraAttribute.NearPlane != null) {
                nearClippingPlane = cameraAttribute.NearPlane.value / 1000;
            }

            var farClippingPlane:Float = 1000;
            if (cameraAttribute.FarPlane != null) {
                farClippingPlane = cameraAttribute.FarPlane.value / 1000;
            }

            var width:Float = window.innerWidth;
            var height:Float = window.innerHeight;

            if (cameraAttribute.AspectWidth != null && cameraAttribute.AspectHeight != null) {
                width = cameraAttribute.AspectWidth.value;
                height = cameraAttribute.AspectHeight.value;
            }

            var aspect:Float = width / height;

            var fov:Float = 45;
            if (cameraAttribute.FieldOfView != null) {
                fov = cameraAttribute.FieldOfView.value;
            }

            var focalLength:Float = cameraAttribute.FocalLength != null ? cameraAttribute.FocalLength.value : null;

            switch (type) {
                case 0: // Perspective
                    model = new PerspectiveCamera(fov, aspect, nearClippingPlane, farClippingPlane);
                    if (focalLength != null) model.setFocalLength(focalLength);
                    break;
                case 1: // Orthographic
                    model = new OrthographicCamera(-width / 2, width / 2, height / 2, -height / 2, nearClippingPlane, farClippingPlane);
                    break;
                default:
                    Console.warn('THREE.FBXLoader: Unknown camera type ' + type + '.');
                    model = new Object3D();
                    break;
            }
        }

        return model;
    }

    public function createLight(relationships:Map<Int, Dynamic>):Light {
        var model:Light;
        var lightAttribute:Dynamic;

        relationships.children.forEach(function(child) {
            var attr:Dynamic = fbxTree.Objects.NodeAttribute[child.ID];
            if (attr != null) {
                lightAttribute = attr;
            }
        });

        if (lightAttribute == null) {
            model = new Object3D();
        } else {
            var type:Int;

            // LightType can be undefined for Point lights
            if (lightAttribute.LightType == null) {
                type = 0;
            } else {
                type = lightAttribute.LightType.value;
            }

            var color:Int = 0xffffff;

            if (lightAttribute.Color != null) {
                color = new Color().fromArray(lightAttribute.Color.value).convertSRGBToLinear();
            }

            var intensity:Float = (lightAttribute.Intensity == null) ? 1 : lightAttribute.Intensity.value / 100;

            // light disabled
            if (lightAttribute.CastLightOnObject != null && lightAttribute.CastLightOnObject.value == 0) {
                intensity = 0;
            }

            var distance:Float = 0;
            if (lightAttribute.FarAttenuationEnd != null) {
                if (lightAttribute.EnableFarAttenuation != null && lightAttribute.EnableFarAttenuation.value == 0) {
                    distance = 0;
                } else {
                    distance = lightAttribute.FarAttenuationEnd.value;
                }
            }

            // TODO: could this be calculated linearly from FarAttenuationStart to FarAttenuationEnd?
            var decay:Float = 1;

            switch (type) {
                case 0: // Point
                    model = new PointLight(color, intensity, distance, decay);
                    break;
                case 1: // Directional
                    model = new DirectionalLight(color, intensity);
                    break;
                case 2: // Spot
                    var angle:Float = Math.PI / 3;

                    if (lightAttribute.InnerAngle != null) {
                        angle = MathUtils.degToRad(lightAttribute.InnerAngle.value);
                    }

                    var penumbra:Float = 0;
                    if (lightAttribute.OuterAngle != null) {
                        // TODO: this is not correct - FBX calculates outer and inner angle in degrees
                        // with OuterAngle > InnerAngle && OuterAngle <= Math.PI
                        // while three.js uses a penumbra between (0, 1) to attenuate the inner angle
                        penumbra = MathUtils.degToRad(lightAttribute.OuterAngle.value);
                        penumbra = Math.max(penumbra, 1);
                    }

                    model = new SpotLight(color, intensity, distance, angle, penumbra, decay);
                    break;
                default:
                    Console.warn('THREE.FBXLoader: Unknown light type ' + lightAttribute.LightType.value + ', defaulting to a PointLight.');
                    model = new PointLight(color, intensity);
                    break;
            }

            if (lightAttribute.CastShadows != null && lightAttribute.CastShadows.value == 1) {
                model.castShadow = true;
            }
        }

        return model;
    }

    public function createMesh(relationships:Map<Int, Dynamic>, geometryMap:Map<Int, Geometry>, materialMap:Map<Int, Material>):Mesh {
        var geometry:Geometry = null;
        var material:Material = null;
        var materials:Array<Material> = [];

        relationships.children.forEach(function(child) {
            if (geometryMap.has(child.ID)) {
                geometry = geometryMap.get(child.ID);
            }

            if (materialMap.has(child.ID)) {
                materials.push(materialMap.get(child.ID));
            }
        });

        if (materials.length > 1) {
            material = materials;
        } else if (materials.length > 0) {
            material = materials[0];
        } else {
            material = new MeshPhongMaterial({
                name: Loader.DEFAULT_MATERIAL_NAME,
                color: 0xcccccc
            });
            materials.push(material);
        }

        if ('color' in geometry.attributes) {
            materials.forEach(function(material) {
                material.vertexColors = true;
            });
        }

        if (geometry.FBX_Deformer) {
            return new SkinnedMesh(geometry, material);
        } else {
            return new Mesh(geometry, material);
        }
    }

    public function createCurve(relationships:Map<Int, Dynamic>, geometryMap:Map<Int, Geometry>):Line {
        var geometry:Geometry = relationships.children.reduce(function(geo:Geometry, child) {
            if (geometryMap.has(child.ID)) geo = geometryMap.get(child.ID);
            return geo;
        }, null);

        // FBX does not list materials for Nurbs lines, so we'll just put our own in here.
        var material:Material = new LineBasicMaterial({
            name: Loader.DEFAULT_MATERIAL_NAME,
            color: 0x3300ff,
            linewidth: 1
        });
        return new Line(geometry, material);
    }

    public function getTransformData(model:Object3D, modelNode:Dynamic) {
        var transformData:Dynamic = {};

        if ('InheritType' in modelNode) transformData.inheritType = Std.parseInt(modelNode.InheritType.value);

        if ('RotationOrder' in modelNode) transformData.eulerOrder = getEulerOrder(modelNode.RotationOrder.value);
        else transformData.eulerOrder = 'ZYX';

        if ('Lcl_Translation' in modelNode) transformData.translation = modelNode.Lcl_Translation.value;

        if ('PreRotation' in modelNode) transformData.preRotation = modelNode.PreRotation.value;
        if ('Lcl_Rotation' in modelNode) transformData.rotation = modelNode.Lcl_Rotation.value;
        if ('PostRotation' in modelNode) transformData.postRotation = modelNode.PostRotation.value;

        if ('Lcl_Scaling' in modelNode) transformData.scale = modelNode.Lcl_Scaling.value;

        if ('ScalingOffset' in modelNode) transformData.scalingOffset = modelNode.ScalingOffset.value;
        if ('ScalingPivot' in modelNode