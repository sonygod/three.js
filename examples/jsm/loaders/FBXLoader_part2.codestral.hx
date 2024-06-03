import js.Array;
import js.Map;
import js.html.CanvasElement;
import js.html.ImageElement;
import js.html.WebGLRenderingContext;
import js.html.Window;
import js.html.WebGLTexture;
import three.core.Object3D;
import three.core.Group;
import three.core.Mesh;
import three.core.SkinnedMesh;
import three.core.Line;
import three.core.PerspectiveCamera;
import three.core.OrthographicCamera;
import three.core.DirectionalLight;
import three.core.PointLight;
import three.core.SpotLight;
import three.core.AmbientLight;
import three.core.Skeleton;
import three.core.Bone;
import three.core.Matrix4;
import three.core.Color;
import three.core.Vector3;
import three.math.MathUtils;
import three.textures.Texture;
import three.textures.TextureLoader;
import three.materials.MeshPhongMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.LineBasicMaterial;
import three.constants.SRGBColorSpace;
import three.constants.EquirectangularReflectionMapping;
import three.constants.RepeatWrapping;
import three.constants.ClampToEdgeWrapping;

class FBXTreeParser {

	var textureLoader: TextureLoader;
	var manager: any;
	var sceneGraph: Group;
	var connections: Map<Int, Dynamic>;
	var fbxTree: Dynamic;

	public function new(textureLoader: TextureLoader, manager: any) {
		this.textureLoader = textureLoader;
		this.manager = manager;
	}

	public function parse(): Group {
		connections = this.parseConnections();

		var images = this.parseImages();
		var textures = this.parseTextures(images);
		var materials = this.parseMaterials(textures);
		var deformers = this.parseDeformers();
		var geometryMap = new GeometryParser().parse(deformers);

		this.parseScene(deformers, geometryMap, materials);

		return sceneGraph;
	}

	// Parses FBXTree.Connections which holds parent-child connections between objects (e.g. material -> texture, model->geometry )
	// and details the connection type
	public function parseConnections(): Map<Int, Dynamic> {
		var connectionMap = new Map<Int, Dynamic>();

		if (Std.is(fbxTree, "Connections")) {
			var rawConnections = fbxTree.Connections.connections;

			rawConnections.forEach(function(rawConnection) {
				var fromID = rawConnection[0];
				var toID = rawConnection[1];
				var relationship = rawConnection[2];

				if (!connectionMap.exists(fromID)) {
					connectionMap.set(fromID, {
						parents: [],
						children: []
					});
				}

				var parentRelationship = { ID: toID, relationship: relationship };
				connectionMap.get(fromID).parents.push(parentRelationship);

				if (!connectionMap.exists(toID)) {
					connectionMap.set(toID, {
						parents: [],
						children: []
					});
				}

				var childRelationship = { ID: fromID, relationship: relationship };
				connectionMap.get(toID).children.push(childRelationship);
			});
		}

		return connectionMap;
	}

	// Parse FBXTree.Objects.Video for embedded image data
	// These images are connected to textures in FBXTree.Objects.Textures
	// via FBXTree.Connections.
	public function parseImages(): Map<Int, Dynamic> {
		var images = new Map<Int, Dynamic>();
		var blobs = new Map<String, Dynamic>();

		if (Std.is(fbxTree.Objects, "Video")) {
			var videoNodes = fbxTree.Objects.Video;

			for (var nodeID in videoNodes) {
				var videoNode = videoNodes[nodeID];

				var id = Std.parseInt(nodeID);

				images.set(id, videoNode.RelativeFilename || videoNode.Filename);

				// raw image data is in videoNode.Content
				if (Std.is(videoNode, "Content")) {
					var arrayBufferContent = (videoNode.Content is ArrayBuffer && (videoNode.Content.byteLength > 0));
					var base64Content = (typeof(videoNode.Content) == "string" && videoNode.Content != "");

					if (arrayBufferContent || base64Content) {
						var image = this.parseImage(videoNodes[nodeID]);

						blobs.set(videoNode.RelativeFilename || videoNode.Filename, image);
					}
				}
			}
		}

		for (var id in images.keys()) {
			var filename = images.get(id);

			if (blobs.exists(filename)) {
				images.set(id, blobs.get(filename));
			} else {
				images.set(id, filename.split("\\").pop());
			}
		}

		return images;
	}

	// Parse embedded image data in FBXTree.Video.Content
	public function parseImage(videoNode: Dynamic): String {
		var content = videoNode.Content;
		var fileName = videoNode.RelativeFilename || videoNode.Filename;
		var extension = fileName.slice(fileName.lastIndexOf(".") + 1).toLowerCase();

		var type: String;

		switch (extension) {
			case "bmp":
				type = "image/bmp";
				break;
			case "jpg":
			case "jpeg":
				type = "image/jpeg";
				break;
			case "png":
				type = "image/png";
				break;
			case "tif":
				type = "image/tiff";
				break;
			case "tga":
				if (this.manager.getHandler(".tga") == null) {
					trace("FBXLoader: TGA loader not found, skipping " + fileName);
				}
				type = "image/tga";
				break;
			default:
				trace("FBXLoader: Image type \"" + extension + "\" is not supported.");
				return null;
		}

		if (typeof(content) == "string") { // ASCII format
			return "data:" + type + ";base64," + content;
		} else { // Binary Format
			var array = new js.html.Uint8Array(content);
			return js.html.URL.createObjectURL(new js.html.Blob([array], { type: type }));
		}
	}

	// Parse nodes in FBXTree.Objects.Texture
	// These contain details such as UV scaling, cropping, rotation etc and are connected
	// to images in FBXTree.Objects.Video
	public function parseTextures(images: Map<Int, Dynamic>): Map<Int, Texture> {
		var textureMap = new Map<Int, Texture>();

		if (Std.is(fbxTree.Objects, "Texture")) {
			var textureNodes = fbxTree.Objects.Texture;
			for (var nodeID in textureNodes) {
				var texture = this.parseTexture(textureNodes[nodeID], images);
				textureMap.set(Std.parseInt(nodeID), texture);
			}
		}

		return textureMap;
	}

	// Parse individual node in FBXTree.Objects.Texture
	public function parseTexture(textureNode: Dynamic, images: Map<Int, Dynamic>): Texture {
		var texture = this.loadTexture(textureNode, images);

		texture.ID = textureNode.id;

		texture.name = textureNode.attrName;

		var wrapModeU = textureNode.WrapModeU;
		var wrapModeV = textureNode.WrapModeV;

		var valueU = wrapModeU != null ? wrapModeU.value : 0;
		var valueV = wrapModeV != null ? wrapModeV.value : 0;

		// http://download.autodesk.com/us/fbx/SDKdocs/FBX_SDK_Help/files/fbxsdkref/class_k_fbx_texture.html#889640e63e2e681259ea81061b85143a
		// 0: repeat(default), 1: clamp

		texture.wrapS = valueU === 0 ? RepeatWrapping : ClampToEdgeWrapping;
		texture.wrapT = valueV === 0 ? RepeatWrapping : ClampToEdgeWrapping;

		if (Std.is(textureNode, "Scaling")) {
			var values = textureNode.Scaling.value;

			texture.repeat.x = values[0];
			texture.repeat.y = values[1];
		}

		if (Std.is(textureNode, "Translation")) {
			var values = textureNode.Translation.value;

			texture.offset.x = values[0];
			texture.offset.y = values[1];
		}

		return texture;
	}

	// load a texture specified as a blob or data URI, or via an external URL using TextureLoader
	public function loadTexture(textureNode: Dynamic, images: Map<Int, Dynamic>): Texture {
		var fileName: String;

		var currentPath = this.textureLoader.path;

		var children = connections.get(textureNode.id).children;

		if (children != null && children.length > 0 && images.exists(children[0].ID)) {
			fileName = images.get(children[0].ID);

			if (fileName.indexOf("blob:") === 0 || fileName.indexOf("data:") === 0) {
				this.textureLoader.setPath(null);
			}
		}

		var texture: Texture;

		var extension = textureNode.FileName.slice(-3).toLowerCase();

		if (extension === "tga") {
			var loader = this.manager.getHandler(".tga");

			if (loader == null) {
				trace("FBXLoader: TGA loader not found, creating placeholder texture for " + textureNode.RelativeFilename);
				texture = new Texture();
			} else {
				loader.setPath(this.textureLoader.path);
				texture = loader.load(fileName);
			}
		} else if (extension === "dds") {
			var loader = this.manager.getHandler(".dds");

			if (loader == null) {
				trace("FBXLoader: DDS loader not found, creating placeholder texture for " + textureNode.RelativeFilename);
				texture = new Texture();
			} else {
				loader.setPath(this.textureLoader.path);
				texture = loader.load(fileName);
			}
		} else if (extension === "psd") {
			trace("FBXLoader: PSD textures are not supported, creating placeholder texture for " + textureNode.RelativeFilename);
			texture = new Texture();
		} else {
			texture = this.textureLoader.load(fileName);
		}

		this.textureLoader.setPath(currentPath);

		return texture;
	}

	// Parse nodes in FBXTree.Objects.Material
	public function parseMaterials(textureMap: Map<Int, Texture>): Map<Int, any> {
		var materialMap = new Map<Int, any>();

		if (Std.is(fbxTree.Objects, "Material")) {
			var materialNodes = fbxTree.Objects.Material;

			for (var nodeID in materialNodes) {
				var material = this.parseMaterial(materialNodes[nodeID], textureMap);

				if (material != null) materialMap.set(Std.parseInt(nodeID), material);
			}
		}

		return materialMap;
	}

	// Parse single node in FBXTree.Objects.Material
	// Materials are connected to texture maps in FBXTree.Objects.Textures
	// FBX format currently only supports Lambert and Phong shading models
	public function parseMaterial(materialNode: Dynamic, textureMap: Map<Int, Texture>): any {
		var ID = materialNode.id;
		var name = materialNode.attrName;
		var type = materialNode.ShadingModel;

		// Case where FBX wraps shading model in property object.
		if (typeof(type) == "object") {
			type = type.value;
		}

		// Ignore unused materials which don't have any connections.
		if (!connections.exists(ID)) return null;

		var parameters = this.parseParameters(materialNode, textureMap, ID);

		var material: any;

		switch (type.toLowerCase()) {
			case "phong":
				material = new MeshPhongMaterial();
				break;
			case "lambert":
				material = new MeshLambertMaterial();
				break;
			default:
				trace("THREE.FBXLoader: unknown material type \"" + type + "\". Defaulting to MeshPhongMaterial.");
				material = new MeshPhongMaterial();
				break;
		}

		material.setValues(parameters);
		material.name = name;

		return material;
	}

	// Parse FBX material and return parameters suitable for a three.js material
	// Also parse the texture map and return any textures associated with the material
	public function parseParameters(materialNode: Dynamic, textureMap: Map<Int, Texture>, ID: Int): Map<String, Dynamic> {
		var parameters = new Map<String, Dynamic>();

		if (Std.is(materialNode, "BumpFactor")) {
			parameters.set("bumpScale", materialNode.BumpFactor.value);
		}

		if (Std.is(materialNode, "Diffuse")) {
			parameters.set("color", new Color().fromArray(materialNode.Diffuse.value).convertSRGBToLinear());
		} else if (Std.is(materialNode, "DiffuseColor") && (materialNode.DiffuseColor.type === "Color" || materialNode.DiffuseColor.type === "ColorRGB")) {
			// The blender exporter exports diffuse here instead of in materialNode.Diffuse
			parameters.set("color", new Color().fromArray(materialNode.DiffuseColor.value).convertSRGBToLinear());
		}

		if (Std.is(materialNode, "DisplacementFactor")) {
			parameters.set("displacementScale", materialNode.DisplacementFactor.value);
		}

		if (Std.is(materialNode, "Emissive")) {
			parameters.set("emissive", new Color().fromArray(materialNode.Emissive.value).convertSRGBToLinear());
		} else if (Std.is(materialNode, "EmissiveColor") && (materialNode.EmissiveColor.type === "Color" || materialNode.EmissiveColor.type === "ColorRGB")) {
			// The blender exporter exports emissive color here instead of in materialNode.Emissive
			parameters.set("emissive", new Color().fromArray(materialNode.EmissiveColor.value).convertSRGBToLinear());
		}

		if (Std.is(materialNode, "EmissiveFactor")) {
			parameters.set("emissiveIntensity", Std.parseFloat(materialNode.EmissiveFactor.value));
		}

		if (Std.is(materialNode, "Opacity")) {
			parameters.set("opacity", Std.parseFloat(materialNode.Opacity.value));
		}

		if (parameters.get("opacity") < 1.0) {
			parameters.set("transparent", true);
		}

		if (Std.is(materialNode, "ReflectionFactor")) {
			parameters.set("reflectivity", materialNode.ReflectionFactor.value);
		}

		if (Std.is(materialNode, "Shininess")) {
			parameters.set("shininess", materialNode.Shininess.value);
		}

		if (Std.is(materialNode, "Specular")) {
			parameters.set("specular", new Color().fromArray(materialNode.Specular.value).convertSRGBToLinear());
		} else if (Std.is(materialNode, "SpecularColor") && materialNode.SpecularColor.type == "Color") {
			// The blender exporter exports specular color here instead of in materialNode.Specular
			parameters.set("specular", new Color().fromArray(materialNode.SpecularColor.value).convertSRGBToLinear());
		}

		var scope = this;
		connections.get(ID).children.forEach(function(child) {
			var type = child.relationship;

			switch (type) {
				case "Bump":
					parameters.set("bumpMap", scope.getTexture(textureMap, child.ID));
					break;
				case "Maya|TEX_ao_map":
					parameters.set("aoMap", scope.getTexture(textureMap, child.ID));
					break;
				case "DiffuseColor":
				case "Maya|TEX_color_map":
					parameters.set("map", scope.getTexture(textureMap, child.ID));
					if (parameters.get("map") != null) {
						parameters.get("map").colorSpace = SRGBColorSpace;
					}
					break;
				case "DisplacementColor":
					parameters.set("displacementMap", scope.getTexture(textureMap, child.ID));
					break;
				case "EmissiveColor":
					parameters.set("emissiveMap", scope.getTexture(textureMap, child.ID));
					if (parameters.get("emissiveMap") != null) {
						parameters.get("emissiveMap").colorSpace = SRGBColorSpace;
					}
					break;
				case "NormalMap":
				case "Maya|TEX_normal_map":
					parameters.set("normalMap", scope.getTexture(textureMap, child.ID));
					break;
				case "ReflectionColor":
					parameters.set("envMap", scope.getTexture(textureMap, child.ID));
					if (parameters.get("envMap") != null) {
						parameters.get("envMap").mapping = EquirectangularReflectionMapping;
						parameters.get("envMap").colorSpace = SRGBColorSpace;
					}
					break;
				case "SpecularColor":
					parameters.set("specularMap", scope.getTexture(textureMap, child.ID));
					if (parameters.get("specularMap") != null) {
						parameters.get("specularMap").colorSpace = SRGBColorSpace;
					}
					break;
				case "TransparentColor":
				case "TransparencyFactor":
					parameters.set("alphaMap", scope.getTexture(textureMap, child.ID));
					parameters.set("transparent", true);
					break;
				case "AmbientColor":
				case "ShininessExponent": // AKA glossiness map
				case "SpecularFactor": // AKA specularLevel
				case "VectorDisplacementColor": // NOTE: Seems to be a copy of DisplacementColor
				default:
					trace("THREE.FBXLoader: " + type + " map is not supported in three.js, skipping texture.");
					break;
			}
		});

		return parameters;
	}

	// get a texture from the textureMap for use by a material.
	public function getTexture(textureMap: Map<Int, Texture>, id: Int): Texture {
		// if the texture is a layered texture, just use the first layer and issue a warning
		if (Std.is(fbxTree.Objects, "LayeredTexture") && textureMap.exists(id)) {
			trace("THREE.FBXLoader: layered textures are not supported in three.js. Discarding all but first layer.");
			id = connections.get(id).children[0].ID;
		}

		return textureMap.get(id);
	}

	// Parse nodes in FBXTree.Objects.Deformer
	// Deformer node can contain skinning or Vertex Cache animation data, however only skinning is supported here
	// Generates map of Skeleton-like objects for use later when generating and binding skeletons.
	public function parseDeformers(): Dynamic {
		var skeletons = new Map<Int, Dynamic>();
		var morphTargets = new Map<Int, Dynamic>();

		if (Std.is(fbxTree.Objects, "Deformer")) {
			var DeformerNodes = fbxTree.Objects.Deformer;

			for (var nodeID in DeformerNodes) {
				var deformerNode = DeformerNodes[nodeID];

				var relationships = connections.get(Std.parseInt(nodeID));

				if (deformerNode.attrType == "Skin") {
					var skeleton = this.parseSkeleton(relationships, DeformerNodes);
					skeleton.ID = nodeID;

					if (relationships.parents.length > 1) trace("THREE.FBXLoader: skeleton attached to more than one geometry is not supported.");
					skeleton.geometryID = relationships.parents[0].ID;

					skeletons.set(Std.parseInt(nodeID), skeleton);
				} else if (deformerNode.attrType == "BlendShape") {
					var morphTarget = {
						id: nodeID,
					};

					morphTarget.rawTargets = this.parseMorphTargets(relationships, DeformerNodes);
					morphTarget.id = nodeID;

					if (relationships.parents.length > 1) trace("THREE.FBXLoader: morph target attached to more than one geometry is not supported.");

					morphTargets.set(Std.parseInt(nodeID), morphTarget);
				}
			}
		}

		return {
			skeletons: skeletons,
			morphTargets: morphTargets,
		};
	}

	// Parse single nodes in FBXTree.Objects.Deformer
	// The top level skeleton node has type 'Skin' and sub nodes have type 'Cluster'
	// Each skin node represents a skeleton and each cluster node represents a bone
	public function parseSkeleton(relationships: Dynamic, deformerNodes: Map<String, Dynamic>): Dynamic {
		var rawBones = [];

		relationships.children.forEach(function(child) {
			var boneNode = deformerNodes.get(child.ID);

			if (boneNode.attrType !== "Cluster") return;

			var rawBone = {
				ID: child.ID,
				indices: [],
				weights: [],
				transformLink: new Matrix4().fromArray(boneNode.TransformLink.a),
				// transform: new Matrix4().fromArray(boneNode.Transform.a),
				// linkMode: boneNode.Mode,
			};

			if (Std.is(boneNode, "Indexes")) {
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

	// The top level morph deformer node has type "BlendShape" and sub nodes have type "BlendShapeChannel"
	public function parseMorphTargets(relationships: Dynamic, deformerNodes: Map<String, Dynamic>): Array<Dynamic> {
		var rawMorphTargets = [];

		for (var i = 0; i < relationships.children.length; i++) {
			var child = relationships.children[i];

			var morphTargetNode = deformerNodes.get(child.ID);

			var rawMorphTarget = {
				name: morphTargetNode.attrName,
				initialWeight: morphTargetNode.DeformPercent,
				id: morphTargetNode.id,
				fullWeights: morphTargetNode.FullWeights.a
			};

			if (morphTargetNode.attrType !== "BlendShapeChannel") return null;

			rawMorphTarget.geoID = connections.get(Std.parseInt(child.ID)).children.filter(function(child) {
				return child.relationship == null;
			})[0].ID;

			rawMorphTargets.push(rawMorphTarget);
		}

		return rawMorphTargets;
	}

	// create the main Group() to be returned by the loader
	public function parseScene(deformers: Dynamic, geometryMap: Map<String, Dynamic>, materialMap: Map<String, Dynamic>): Void {
		sceneGraph = new Group();

		var modelMap = this.parseModels(deformers.skeletons, geometryMap, materialMap);

		var modelNodes = fbxTree.Objects.Model;

		var scope = this;
		modelMap.forEach(function(model) {
			var modelNode = modelNodes[model.ID];
			scope.setLookAtProperties(model, modelNode);

			var parentConnections = connections.get(model.ID).parents;

			parentConnections.forEach(function(connection) {
				var parent = modelMap.get(connection.ID);
				if (parent != null) parent.add(model);
			});

			if (model.parent == null) {
				sceneGraph.add(model);
			}
		});

		this.bindSkeleton(deformers.skeletons, geometryMap, modelMap);

		this.addGlobalSceneSettings();

		sceneGraph.traverse(function(node) {
			if (node.userData.transformData != null) {
				if (node.parent != null) {
					node.userData.transformData.parentMatrix = node.parent.matrix;
					node.userData.transformData.parentMatrixWorld = node.parent.matrixWorld;
				}

				var transform = generateTransform(node.userData.transformData);

				node.applyMatrix4(transform);
				node.updateWorldMatrix();
			}
		});

		var animations = new AnimationParser().parse();

		// if all the models where already combined in a single group, just return that
		if (sceneGraph.children.length == 1 && sceneGraph.children[0] is Group) {
			sceneGraph.children[0].animations = animations;
			sceneGraph = sceneGraph.children[0];
		}

		sceneGraph.animations = animations;
	}

	// parse nodes in FBXTree.Objects.Model
	public function parseModels(skeletons: Map<Int, Dynamic>, geometryMap: Map<String, Dynamic>, materialMap: Map<String, Dynamic>): Map<Int, Object3D> {
		var modelMap = new Map<Int, Object3D>();
		var modelNodes = fbxTree.Objects.Model;

		for (var nodeID in modelNodes) {
			var id = Std.parseInt(nodeID);
			var node = modelNodes[nodeID];
			var relationships = connections.get(id);

			var model = this.buildSkeleton(relationships, skeletons, id, node.attrName);

			if (model == null) {
				switch (node.attrType) {
					case "Camera":
						model = this.createCamera(relationships);
						break;
					case "Light":
						model = this.createLight(relationships);
						break;
					case "Mesh":
						model = this.createMesh(relationships, geometryMap, materialMap);
						break;
					case "NurbsCurve":
						model = this.createCurve(relationships, geometryMap);
						break;
					case "LimbNode":
					case "Root":
						model = new Bone();
						break;
					case "Null":
					default:
						model = new Group();
						break;
				}

				model.name = node.attrName ? PropertyBinding.sanitizeNodeName(node.attrName) : "";
				model.userData.originalName = node.attrName;

				model.ID = id;
			}

			this.getTransformData(model, node);
			modelMap.set(id, model);
		}

		return modelMap;
	}

	public function buildSkeleton(relationships: Dynamic, skeletons: Map<Int, Dynamic>, id: Int, name: String): Bone {
		var bone: Bone = null;

		relationships.parents.forEach(function(parent) {
			for (var ID in skeletons.keys()) {
				var skeleton = skeletons.get(Std.parseInt(ID));

				skeleton.rawBones.forEach(function(rawBone, i) {
					if (rawBone.ID == parent.ID) {
						var subBone = bone;
						bone = new Bone();

						bone.matrixWorld.copy(rawBone.transformLink);

						// set name and id here - otherwise in cases where "subBone" is created it will not have a name / id

						bone.name = name ? PropertyBinding.sanitizeNodeName(name) : "";
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

	// create a PerspectiveCamera or OrthographicCamera
	public function createCamera(relationships: Dynamic): Object3D {
		var model: Object3D;
		var cameraAttribute: Dynamic;

		relationships.children.forEach(function(child) {
			var attr = fbxTree.Objects.NodeAttribute[child.ID];

			if (attr != null) {
				cameraAttribute = attr;
			}
		});

		if (cameraAttribute == null) {
			model = new Object3D();
		} else {
			var type = 0;
			if (cameraAttribute.CameraProjectionType != null && cameraAttribute.CameraProjectionType.value == 1) {
				type = 1;
			}

			var nearClippingPlane = 1;
			if (cameraAttribute.NearPlane != null) {
				nearClippingPlane = cameraAttribute.NearPlane.value / 1000;
			}

			var farClippingPlane = 1000;
			if (cameraAttribute.FarPlane != null) {
				farClippingPlane = cameraAttribute.FarPlane.value / 1000;
			}

			var width = js.html.window.innerWidth;
			var height = js.html.window.innerHeight;

			if (cameraAttribute.AspectWidth != null && cameraAttribute.AspectHeight != null) {
				width = cameraAttribute.AspectWidth.value;
				height = cameraAttribute.AspectHeight.value;
			}

			var aspect = width / height;

			var fov = 45;
			if (cameraAttribute.FieldOfView != null) {
				fov = cameraAttribute.FieldOfView.value;
			}

			var focalLength = cameraAttribute.FocalLength != null ? cameraAttribute.FocalLength.value : null;

			switch (type) {
				case 0: // Perspective
					model = new PerspectiveCamera(fov, aspect, nearClippingPlane, farClippingPlane);
					if (focalLength != null) model.setFocalLength(focalLength);
					break;
				case 1: // Orthographic
					model = new OrthographicCamera(-width / 2, width / 2, height / 2, -height / 2, nearClippingPlane, farClippingPlane);
					break;
				default:
					trace("THREE.FBXLoader: Unknown camera type " + type + ".");
					model = new Object3D();
					break;
			}
		}

		return model;
	}

	// Create a DirectionalLight, PointLight or SpotLight
	public function createLight(relationships: Dynamic): Object3D {
		var model: Object3D;
		var lightAttribute: Dynamic;

		relationships.children.forEach(function(child) {
			var attr = fbxTree.Objects.NodeAttribute[child.ID];

			if (attr != null) {
				lightAttribute = attr;
			}
		});

		if (lightAttribute == null) {
			model = new Object3D();
		} else {
			var type: Int;

			// LightType can be undefined for Point lights
			if (lightAttribute.LightType == null) {
				type = 0;
			} else {
				type = lightAttribute.LightType.value;
			}

			var color = 0xffffff;

			if (lightAttribute.Color != null) {
				color = new Color().fromArray(lightAttribute.Color.value).convertSRGBToLinear();
			}

			var intensity = (lightAttribute.Intensity == null) ? 1 : lightAttribute.Intensity.value / 100;

			// light disabled
			if (lightAttribute.CastLightOnObject != null && lightAttribute.CastLightOnObject.value == 0) {
				intensity = 0;
			}

			var distance = 0;
			if (lightAttribute.FarAttenuationEnd != null) {
				if (lightAttribute.EnableFarAttenuation != null && lightAttribute.EnableFarAttenuation.value == 0) {
					distance = 0;
				} else {
					distance = lightAttribute.FarAttenuationEnd.value;
				}
			}

			// TODO: could this be calculated linearly from FarAttenuationStart to FarAttenuationEnd?
			var decay = 1;

			switch (type) {
				case 0: // Point
					model = new PointLight(color, intensity, distance, decay);
					break;
				case 1: // Directional
					model = new DirectionalLight(color, intensity);
					break;
				case 2: // Spot
					var angle = Math.PI / 3;

					if (lightAttribute.InnerAngle != null) {
						angle = MathUtils.degToRad(lightAttribute.InnerAngle.value);
					}

					var penumbra = 0;
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
					trace("THREE.FBXLoader: Unknown light type " + lightAttribute.LightType.value + ", defaulting to a PointLight.");
					model = new PointLight(color, intensity);
					break;
			}

			if (lightAttribute.CastShadows != null && lightAttribute.CastShadows.value == 1) {
				model.castShadow = true;
			}
		}

		return model;
	}

	public function createMesh(relationships: Dynamic, geometryMap: Map<String, Dynamic>, materialMap: Map<String, Dynamic>): Mesh {
		var model: Mesh;
		var geometry: Dynamic = null;
		var material: any = null;
		var materials = [];

		// get geometry and materials(s) from connections
		relationships.children.forEach(function(child) {
			if (geometryMap.exists(child.ID)) {
				geometry = geometryMap.get(child.ID);
			}

			if (materialMap.exists(child.ID)) {
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

		if (Std.is(geometry.attributes, "color")) {
			materials.forEach(function(material) {
				material.vertexColors = true;
			});
		}

		if (geometry.FBX_Deformer != null) {
			model = new SkinnedMesh(geometry, material);
			model.normalizeSkinWeights();
		} else {
			model = new Mesh(geometry, material);
		}

		return model;
	}

	public function createCurve(relationships: Dynamic, geometryMap: Map<String, Dynamic>): Line {
		var geometry = relationships.children.reduce(function(geo, child) {
			if (geometryMap.exists(child.ID)) geo = geometryMap.get(child.ID);

			return geo;
		}, null);

		// FBX does not list materials for Nurbs lines, so we'll just put our own in here.
		var material = new LineBasicMaterial({
			name: Loader.DEFAULT_MATERIAL_NAME,
			color: 0x3300ff,
			linewidth: 1
		});
		return new Line(geometry, material);
	}

	// parse the model node for transform data
	public function getTransformData(model: Object3D, modelNode: Dynamic): Void {
		var transformData = {};

		if (Std.is(modelNode, "InheritType")) transformData.inheritType = Std.parseInt(modelNode.InheritType.value);

		if (Std.is(modelNode, "RotationOrder")) transformData.eulerOrder = getEulerOrder(modelNode.RotationOrder.value);
		else transformData.eulerOrder = "ZYX";

		if (Std.is(modelNode, "Lcl_Translation")) transformData.translation = modelNode.Lcl_Translation.value;

		if (Std.is(modelNode, "PreRotation")) transformData.preRotation = modelNode.PreRotation.value;
		if (Std.is(modelNode, "Lcl_Rotation")) transformData.rotation = modelNode.Lcl_Rotation.value;
		if (Std.is(modelNode, "PostRotation")) transformData.postRotation = modelNode.PostRotation.value;

		if (Std.is(modelNode, "Lcl_Scaling")) transformData.scale = modelNode.Lcl_Scaling.value;

		if (Std.is(modelNode, "ScalingOffset")) transformData.scalingOffset = modelNode.ScalingOffset.value;
		if (Std.is(modelNode, "ScalingPivot")) transformData.scalingPivot = modelNode.ScalingPivot.value;

		if (Std.is(modelNode, "RotationOffset")) transformData.rotationOffset = modelNode.RotationOffset.value;
		if (Std.is(modelNode, "RotationPivot")) transformData.rotationPivot = modelNode.RotationPivot.value;

		model.userData.transformData = transformData;
	}

	public function setLookAtProperties(model: Object3D, modelNode: Dynamic): Void {
		if (Std.is(modelNode, "LookAtProperty")) {
			var children = connections.get(model.ID).children;

			children.forEach(function(child) {
				if (child.relationship == "LookAtProperty") {
					var lookAtTarget = fbxTree.Objects.Model[child.ID];

					if (Std.is(lookAtTarget, "Lcl_Translation")) {
						var pos = lookAtTarget.Lcl_Translation.value;

						// DirectionalLight, SpotLight
						if (model.target != null) {
							model.target.position.fromArray(pos);
							sceneGraph.add(model.target);
						} else { // Cameras and other Object3Ds
							model.lookAt(new Vector3().fromArray(pos));
						}
					}
				}
			});
		}
	}

	public function bindSkeleton(skeletons: Map<Int, Dynamic>, geometryMap: Map<String, Dynamic>, modelMap: Map<Int, Object3D>): Void {
		var bindMatrices = this.parsePoseNodes();

		for (var ID in skeletons.keys()) {
			var skeleton = skeletons.get(Std.parseInt(ID));

			var parents = connections.get(Std.parseInt(skeleton.ID)).parents;

			parents.forEach(function(parent) {
				if (geometryMap.exists(parent.ID)) {
					var geoID = parent.ID;
					var geoRelationships = connections.get(geoID);

					geoRelationships.parents.forEach(function(geoConnParent) {
						if (modelMap.exists(geoConnParent.ID)) {
							var model = modelMap.get(geoConnParent.ID);

							model.bind(new Skeleton(skeleton.bones), bindMatrices[geoConnParent.ID]);
						}
					});
				}
			});
		}
	}

	public function parsePoseNodes(): Map<String, Matrix4> {
		var bindMatrices = new Map<String, Matrix4>();

		if (Std.is(fbxTree, "Pose")) {
			var BindPoseNode = fbxTree.Objects.Pose;

			for (var nodeID in BindPoseNode) {
				if (BindPoseNode[nodeID].attrType == "BindPose" && BindPoseNode[nodeID].NbPoseNodes > 0) {
					var poseNodes = BindPoseNode[nodeID].PoseNode;

					if (poseNodes is Array) {
						poseNodes.forEach(function(poseNode) {
							bindMatrices.set(poseNode.Node, new Matrix4().fromArray(poseNode.Matrix.a));
						});
					} else {
						bindMatrices.set(poseNodes.Node, new Matrix4().fromArray(poseNodes.Matrix.a));
					}
				}
			}
		}

		return bindMatrices;
	}

	public function addGlobalSceneSettings(): Void {
		if (Std.is(fbxTree, "GlobalSettings")) {
			if (Std.is(fbxTree.GlobalSettings, "AmbientColor")) {
				// Parse ambient color - if it's not set to black (default), create an ambient light

				var ambientColor = fbxTree.GlobalSettings.AmbientColor.value;
				var r = ambientColor[0];
				var g = ambientColor[1];
				var b = ambientColor[2];

				if (r != 0 || g != 0 || b != 0) {
					var color = new Color(r, g, b).convertSRGBToLinear();
					sceneGraph.add(new AmbientLight(color, 1));
				}
			}

			if (Std.is(fbxTree.GlobalSettings, "UnitScaleFactor")) {
				sceneGraph.userData.unitScaleFactor = fbxTree.GlobalSettings.UnitScaleFactor.value;
			}
		}
	}
}