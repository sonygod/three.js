package three.js.examples.jsm.loaders;

import js.html.Promise;
import three.MathUtils;
import three.BufferGeometry;
import three.Color;
import three.DrawMode;
import three.Group;
import three.Line;
import three.LineLoop;
import three.LineSegments;
import three.Material;
import three.Mesh;
import three.MeshBasicMaterial;
import three.MeshPhongMaterial;
import three.Object3D;
import three.PerspectiveCamera;
import three.Points;
import three.SkinnedMesh;
import three.Texture;
import three.Vector2;
import three.Vector4;

class GLTFLoader {
    public function loadMaterial(materialIndex:Int):Promise<Material> {
        var parser:GLTFLoader = this;
        var json:Dynamic = parser.json;
        var extensions:Dynamic = parser.extensions;
        var materialDef:Dynamic = json.materials[materialIndex];
        
        var materialType:Null<Material>;
        var materialParams:Dynamic = {};
        var materialExtensions:Dynamic = materialDef.extensions || {};

        var pending:Array<Promise<Dynamic>> = [];

        if (materialExtensions[EXTENSIONS.KHR_MATERIALS_UNLIT]) {
            var kmuExtension:Dynamic = extensions[EXTENSIONS.KHR_MATERIALS_UNLIT];
            materialType = kmuExtension.getMaterialType();
            pending.push(kmuExtension.extendParams(materialParams, materialDef, parser));
        } else {
            var metallicRoughness:Dynamic = materialDef.pbrMetallicRoughness || {};
            
            materialParams.color = new Color(1.0, 1.0, 1.0);
            materialParams.opacity = 1.0;

            if (Std.isArray(metallicRoughness.baseColorFactor)) {
                var array:Array<Float> = cast metallicRoughness.baseColorFactor;
                materialParams.color.setRGB(array[0], array[1], array[2], LinearSRGBColorSpace);
                materialParams.opacity = array[3];
            }

            if (metallicRoughness.baseColorTexture != null) {
                pending.push(parser.assignTexture(materialParams, 'map', metallicRoughness.baseColorTexture, SRGBColorSpace));
            }

            materialParams.metalness = metallicRoughness.metallicFactor != null ? metallicRoughness.metallicFactor : 1.0;
            materialParams.roughness = metallicRoughness.roughnessFactor != null ? metallicRoughness.roughnessFactor : 1.0;

            if (metallicRoughness.metallicRoughnessTexture != null) {
                pending.push(parser.assignTexture(materialParams, 'metalnessMap', metallicRoughness.metallicRoughnessTexture));
                pending.push(parser.assignTexture(materialParams, 'roughnessMap', metallicRoughness.metallicRoughnessTexture));
            }

            materialType = _invokeOne(function(ext:Dynamic) {
                return ext.getMaterialType && ext.getMaterialType(materialIndex);
            });

            pending.push(Promise.all(_invokeAll(function(ext:Dynamic) {
                return ext.extendMaterialParams && ext.extendMaterialParams(materialIndex, materialParams);
            }));
        }

        if (materialDef.doubleSided) {
            materialParams.side = DoubleSide;
        }

        var alphaMode:String = materialDef.alphaMode || ALPHA_MODES.OPAQUE;

        if (alphaMode == ALPHA_MODES.BLEND) {
            materialParams.transparent = true;
            materialParams.depthWrite = false;
        } else {
            materialParams.transparent = false;

            if (alphaMode == ALPHA_MODES.MASK) {
                materialParams.alphaTest = materialDef.alphaCutoff != null ? materialDef.alphaCutoff : 0.5;
            }
        }

        if (materialDef.normalTexture != null && materialType != MeshBasicMaterial) {
            pending.push(parser.assignTexture(materialParams, 'normalMap', materialDef.normalTexture));
            materialParams.normalScale = new Vector2(1, 1);

            if (materialDef.normalTexture.scale != null) {
                var scale:Dynamic = materialDef.normalTexture.scale;
                materialParams.normalScale.set(scale, scale);
            }
        }

        if (materialDef.occlusionTexture != null && materialType != MeshBasicMaterial) {
            pending.push(parser.assignTexture(materialParams, 'aoMap', materialDef.occlusionTexture));
            if (materialDef.occlusionTexture.strength != null) {
                materialParams.aoMapIntensity = materialDef.occlusionTexture.strength;
            }
        }

        if (materialDef.emissiveFactor != null && materialType != MeshBasicMaterial) {
            var emissiveFactor:Array<Float> = cast materialDef.emissiveFactor;
            materialParams.emissive = new Color().setRGB(emissiveFactor[0], emissiveFactor[1], emissiveFactor[2], LinearSRGBColorSpace);
        }

        if (materialDef.emissiveTexture != null && materialType != MeshBasicMaterial) {
            pending.push(parser.assignTexture(materialParams, 'emissiveMap', materialDef.emissiveTexture, SRGBColorSpace));
        }

        return Promise.all(pending).then(function() {
            var material:Material = new materialType(materialParams);

            if (materialDef.name) material.name = materialDef.name;

            assignExtrasToUserData(material, materialDef);

            parser.associations.set(material, {materials: materialIndex});

            if (materialDef.extensions) addUnknownExtensionsToUserData(extensions, material, materialDef);

            return material;
        });
    }

    public function createUniqueName(originalName:String):String {
        var sanitizedName:String = PropertyBinding.sanitizeNodeName(originalName || '');
        if (sanitizedName in this.nodeNamesUsed) {
            return sanitizedName + '_' + (this.nodeNamesUsed[sanitizedName]++);
        } else {
            this.nodeNamesUsed[sanitizedName] = 0;
            return sanitizedName;
        }
    }

    public function loadGeometries(primitives:Array<Dynamic>):Promise<Array<BufferGeometry>> {
        var parser:GLTFLoader = this;
        var extensions:Dynamic = parser.extensions;
        var cache:Dynamic = parser.primitiveCache;

        function createDracoPrimitive(primitive:Dynamic):Promise<BufferGeometry> {
            return extensions[EXTENSIONS.KHR_DRACO_MESH_COMPRESSION].decodePrimitive(primitive, parser).then(function(geometry:BufferGeometry) {
                return addPrimitiveAttributes(geometry, primitive, parser);
            });
        }

        var pending:Array<Promise<BufferGeometry>> = [];

        for (i in 0...primitives.length) {
            var primitive:Dynamic = primitives[i];
            var cacheKey:String = createPrimitiveKey(primitive);

            if (cache[cacheKey] != null) {
                pending.push(cache[cacheKey].promise);
            } else {
                var geometryPromise:Promise<BufferGeometry>;

                if (primitive.extensions != null && primitive.extensions[EXTENSIONS.KHR_DRACO_MESH_COMPRESSION] != null) {
                    geometryPromise = createDracoPrimitive(primitive);
                } else {
                    geometryPromise = addPrimitiveAttributes(new BufferGeometry(), primitive, parser);
                }

                cache[cacheKey] = {primitive: primitive, promise: geometryPromise};

                pending.push(geometryPromise);
            }
        }

        return Promise.all(pending);
    }

    public function loadMesh(meshIndex:Int):Promise<Object3D> {
        var parser:GLTFLoader = this;
        var json:Dynamic = parser.json;
        var extensions:Dynamic = parser.extensions;

        var meshDef:Dynamic = json.meshes[meshIndex];
        var primitives:Array<Dynamic> = meshDef.primitives;

        var pending:Array<Promise<Dynamic>> = [];

        for (i in 0...primitives.length) {
            var material:Material = primitives[i].material == null ? createDefaultMaterial(parser.cache) : parser.getDependency('material', primitives[i].material);

            pending.push(material);

        }

        pending.push(parser.loadGeometries(primitives));

        return Promise.all(pending).then(function(results:Array<Dynamic>) {
            var materials:Array<Material> = results.slice(0, results.length - 1);
            var geometries:Array<BufferGeometry> = cast results[results.length - 1];

            var meshes:Array<Object3D> = [];

            for (i in 0...geometries.length) {
                var geometry:BufferGeometry = geometries[i];
                var primitive:Dynamic = primitives[i];

                var mesh:Object3D;

                var material:Material = materials[i];

                if (primitive.mode == WEBGL_CONSTANTS.TRIANGLES || primitive.mode == WEBGL_CONSTANTS.TRIANGLE_STRIP || primitive.mode == WEBGL_CONSTANTS.TRIANGLE_FAN || primitive.mode == null) {
                    mesh = meshDef.isSkinnedMesh ? new SkinnedMesh(geometry, material) : new Mesh(geometry, material);

                    if (mesh.isSkinnedMesh) {
                        mesh.normalizeSkinWeights();
                    }

                    if (primitive.mode == WEBGL_CONSTANTS.TRIANGLE_STRIP) {
                        mesh.geometry = toTrianglesDrawMode(mesh.geometry, TriangleStripDrawMode);
                    } else if (primitive.mode == WEBGL_CONSTANTS.TRIANGLE_FAN) {
                        mesh.geometry = toTrianglesDrawMode(mesh.geometry, TriangleFanDrawMode);
                    }
                } else if (primitive.mode == WEBGL_CONSTANTS.LINES) {
                    mesh = new LineSegments(geometry, material);
                } else if (primitive.mode == WEBGL_CONSTANTS.LINE_STRIP) {
                    mesh = new Line(geometry, material);
                } else if (primitive.mode == WEBGL_CONSTANTS.LINE_LOOP) {
                    mesh = new LineLoop(geometry, material);
                } else if (primitive.mode == WEBGL_CONSTANTS.POINTS) {
                    mesh = new Points(geometry, material);
                } else {
                    throw new Error('THREE.GLTFLoader: Primitive mode unsupported: ' + primitive.mode);
                }

                if (Object.keys(mesh.geometry.morphAttributes).length > 0) {
                    updateMorphTargets(mesh, meshDef);
                }

                mesh.name = parser.createUniqueName(meshDef.name || ('mesh_' + meshIndex));

                assignExtrasToUserData(mesh, meshDef);

                if (primitive.extensions) addUnknownExtensionsToUserData(extensions, mesh, primitive);

                parser.assignFinalMaterial(mesh);

                meshes.push(mesh);
            }

            for (i in 0...meshes.length) {
                parser.associations.set(meshes[i], {meshes: meshIndex, primitives: i});
            }

            if (meshes.length == 1) {
                if (meshDef.extensions) addUnknownExtensionsToUserData(extensions, meshes[0], meshDef);

                return meshes[0];
            }

            var group:Group = new Group();

            if (meshDef.extensions) addUnknownExtensionsToUserData(extensions, group, meshDef);

            parser.associations.set(group, {meshes: meshIndex});

            for (i in 0...meshes.length) {
                group.add(meshes[i]);
            }

            return group;
        });
    }

    public function loadCamera(cameraIndex:Int):Promise<Camera> {
        var camera:Camera;
        var cameraDef:Dynamic = json.cameras[cameraIndex];
        var params:Dynamic = cameraDef[cameraDef.type];

        if (params == null) {
            Console.warn('THREE.GLTFLoader: Missing camera parameters.');
            return;
        }

        if (cameraDef.type == 'perspective') {
            camera = new PerspectiveCamera(MathUtils.radToDeg(params.yfov), params.aspectRatio || 1, params.znear || 1, params.zfar || 2e6);
        } else if (cameraDef.type == 'orthographic') {
            camera = new OrthographicCamera(-params.xmag, params.xmag, params.ymag, -params.ymag, params.znear, params.zfar);
        }

        if (cameraDef.name) camera.name = parser.createUniqueName(cameraDef.name);

        assignExtrasToUserData(camera, cameraDef);

        return Promise.resolve(camera);
    }

    public function loadSkin(skinIndex:Int):Promise<Skeleton> {
        var skinDef:Dynamic = json.skins[skinIndex];

        var pending:Array<Promise<Dynamic>> = [];

        for (i in 0...skinDef.joints.length) {
            pending.push(parser._loadNodeShallow(skinDef.joints[i]));
        }

        if (skinDef.inverseBindMatrices != null) {
            pending.push(parser.getDependency('accessor', skinDef.inverseBindMatrices));
        } else {
            pending.push(null);
        }

        return Promise.all(pending).then(function(results:Array<Dynamic>) {
            var inverseBindMatrices:Array<Float> = results.pop();
            var jointNodes:Array<Object3D> = results;

            var bones:Array<Object3D> = [];
            var boneInverses:Array<Matrix4> = [];

            for (i in 0...jointNodes.length) {
                var jointNode:Object3D = jointNodes[i];

                if (jointNode != null) {
                    bones.push(jointNode);

                    var mat:Matrix4 = new Matrix4();

                    if (inverseBindMatrices != null) {
                        mat.fromArray(inverseBindMatrices, i * 16);
                    }

                    boneInverses.push(mat);
                } else {
                    Console.warn('THREE.GLTFLoader: Joint "%s" could not be found.', skinDef.joints[i]);
                }
            }

            return new Skeleton(bones, boneInverses);
        });
    }
}