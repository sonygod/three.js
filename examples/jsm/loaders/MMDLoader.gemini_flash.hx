import three.core.LoadingManager;
import three.loaders.FileLoader;
import three.loaders.LoaderUtils;
import three.materials.ShaderMaterial;
import three.math.Color;
import three.math.Euler;
import three.math.Quaternion;
import three.math.Vector3;
import three.objects.Bone;
import three.objects.Skeleton;
import three.objects.SkinnedMesh;
import three.textures.TextureLoader;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Uint16BufferAttribute;
import three.animation.AnimationClip;
import three.animation.NumberKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.animation.QuaternionKeyframeTrack;
import three.animation.Interpolant;
import three.extras.objects.SkinnedMesh;
import three.renderers.shaders.ShaderLib;
import three.renderers.shaders.UniformsUtils;
import three.constants.BlendingEquation;
import three.constants.BlendingFactorDest;
import three.constants.BlendingFactorSrc;
import three.constants.Side;
import three.constants.Wrapping;
import three.constants.TextureFilter;
import three.constants.TextureEncoding;
import three.constants.TextureFormat;
import three.constants.Mapping;
import three.constants.Combine;
import three.constants.NormalMapTypes;
import three.materials.Material;
import three.materials.MeshBasicMaterial;

import mmd.MMDParser;
import mmd.shaders.MMDToonShader;

class MMDLoader extends three.loaders.Loader {

	public var animationPath:String;
	public var parser:MMDParser.Parser;
	public var meshBuilder:MeshBuilder;
	public var animationBuilder:AnimationBuilder;

	public function new(manager:LoadingManager = null) {
		super(manager);
		this.loader = new FileLoader(this.manager);
		this.parser = null;
		this.meshBuilder = new MeshBuilder(this.manager);
		this.animationBuilder = new AnimationBuilder();
	}

	public function setAnimationPath(animationPath:String):MMDLoader {
		this.animationPath = animationPath;
		return this;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var builder = this.meshBuilder.setCrossOrigin(this.crossOrigin);
		var resourcePath:String;
		if (this.resourcePath != "") {
			resourcePath = this.resourcePath;
		} else if (this.path != "") {
			resourcePath = this.path;
		} else {
			resourcePath = LoaderUtils.extractUrlBase(url);
		}
		var parser = this._getParser();
		var extractModelExtension = this._extractModelExtension;

		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					var modelExtension = extractModelExtension(buffer);
					if (modelExtension != "pmd" && modelExtension != "pmx") {
						if (onError != null) onError(new Error("THREE.MMDLoader: Unknown model file extension ." + modelExtension + "."));
						return;
					}
					var data = modelExtension == "pmd" ? parser.parsePmd(buffer, true) : parser.parsePmx(buffer, true);
					onLoad(builder.build(data, resourcePath, onProgress, onError));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadAnimation(url:Dynamic, object:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var builder = this.animationBuilder;
		this.loadVMD(url, function(vmd:MMDParser.VMD) {
			onLoad(object.isCamera ? builder.buildCameraAnimation(vmd) : builder.build(vmd, object));
		}, onProgress, onError);
	}

	public function loadWithAnimation(modelUrl:String, vmdUrl:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var scope = this;
		this.load(modelUrl, function(mesh:SkinnedMesh) {
			scope.loadAnimation(vmdUrl, mesh, function(animation:AnimationClip) {
				onLoad({
					mesh: mesh,
					animation: animation
				});
			}, onProgress, onError);
		}, onProgress, onError);
	}

	public function loadPMD(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmd(buffer, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadPMX(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmx(buffer, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadVMD(url:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var urls:Array<String> = Std.isOfType(url, Array) ? url : [url];
		var vmds:Array<MMDParser.VMD> = [];
		var vmdNum = urls.length;
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.animationPath)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials);
		for (i in 0...urls.length) {
			this.loader.load(urls[i], function(buffer:haxe.io.Bytes) {
				try {
					vmds.push(parser.parseVmd(buffer, true));
					if (vmds.length == vmdNum) onLoad(parser.mergeVmds(vmds));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
		}
	}

	public function loadVPD(url:String, isUnicode:Bool, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(isUnicode ? null : "text/plain; charset=shift_jis")
			.setPath(this.animationPath)
			.setResponseType("text")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(text:String) {
				try {
					onLoad(parser.parseVpd(text, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	private function _extractModelExtension(buffer:haxe.io.Bytes):String {
		var decoder = new haxe.io.BytesInput(buffer).readString(3);
		return decoder.toLowerCase();
	}

	private function _getParser():MMDParser.Parser {
		if (this.parser == null) {
			this.parser = new MMDParser.Parser();
		}
		return this.parser;
	}

}

class MeshBuilder {

	private var crossOrigin:String;
	private var geometryBuilder:GeometryBuilder;
	private var materialBuilder:MaterialBuilder;

	public function new(manager:LoadingManager) {
		this.crossOrigin = "anonymous";
		this.geometryBuilder = new GeometryBuilder();
		this.materialBuilder = new MaterialBuilder(manager);
	}

	public function setCrossOrigin(crossOrigin:String):MeshBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function build(data:Dynamic, resourcePath:String, onProgress:Dynamic = null, onError:Dynamic = null):SkinnedMesh {
		var geometry = this.geometryBuilder.build(data);
		var material = this.materialBuilder
			.setCrossOrigin(this.crossOrigin)
			.setResourcePath(resourcePath)
			.build(data, geometry, onProgress, onError);
		var mesh = new SkinnedMesh(geometry, material);
		var skeleton = new Skeleton(initBones(mesh));
		mesh.bind(skeleton);
		return mesh;
	}

}

function initBones(mesh:SkinnedMesh):Array<Bone> {
	var geometry = mesh.geometry;
	var bones:Array<Bone> = [];
	if (geometry != null && geometry.bones != null) {
		for (i in 0...geometry.bones.length) {
			var gbone = geometry.bones[i];
			var bone = new Bone();
			bones.push(bone);
			bone.name = gbone.name;
			bone.position.fromArray(gbone.pos);
			bone.quaternion.fromArray(gbone.rotq);
			if (gbone.scl != null) bone.scale.fromArray(gbone.scl);
		}
		for (i in 0...geometry.bones.length) {
			var gbone = geometry.bones[i];
			if (gbone.parent != -1 && gbone.parent != null && bones[gbone.parent] != null) {
				bones[gbone.parent].add(bones[i]);
			} else {
				mesh.add(bones[i]);
			}
		}
	}
	mesh.updateMatrixWorld(true);
	return bones;
}

class GeometryBuilder {

	public function build(data:Dynamic):BufferGeometry {
		var positions:Array<Float> = [];
		var uvs:Array<Float> = [];
		var normals:Array<Float> = [];
		var indices:Array<Int> = [];
		var groups:Array<{offset:Int, count:Int}> = [];
		var bones:Array<{index:Int, transformationClass:Int, parent:Int, name:String, pos:Array<Float>, rotq:Array<Float>, scl:Array<Float>, rigidBodyType:Int}> = [];
		var skinIndices:Array<Float> = [];
		var skinWeights:Array<Float> = [];
		var morphTargets:Array<{name:String}> = [];
		var morphPositions:Array<Float32BufferAttribute> = [];
		var iks:Array<{target:Int, effector:Int, iteration:Int, maxAngle:Float, links:Array<{index:Int, enabled:Bool, limitation:Vector3, rotationMin:Vector3, rotationMax:Vector3}>>} = [];
		var grants:Array<{index:Int, parentIndex:Int, ratio:Float, isLocal:Bool, affectRotation:Bool, affectPosition:Bool, transformationClass:Int}> = [];
		var rigidBodies:Array<Dynamic> = [];
		var constraints:Array<Dynamic> = [];
		var offset:Int = 0;
		var boneTypeTable:Map<Int, Int> = new Map();
		for (i in 0...data.metadata.vertexCount) {
			var v = data.vertices[i];
			for (j in 0...v.position.length) {
				positions.push(v.position[j]);
			}
			for (j in 0...v.normal.length) {
				normals.push(v.normal[j]);
			}
			for (j in 0...v.uv.length) {
				uvs.push(v.uv[j]);
			}
			for (j in 0...4) {
				skinIndices.push(v.skinIndices.length - 1 >= j ? v.skinIndices[j] : 0.0);
			}
			for (j in 0...4) {
				skinWeights.push(v.skinWeights.length - 1 >= j ? v.skinWeights[j] : 0.0);
			}
		}
		for (i in 0...data.metadata.faceCount) {
			var face = data.faces[i];
			for (j in 0...face.indices.length) {
				indices.push(face.indices[j]);
			}
		}
		for (i in 0...data.metadata.materialCount) {
			var material = data.materials[i];
			groups.push({
				offset: offset * 3,
				count: material.faceCount * 3
			});
			offset += material.faceCount;
		}
		for (i in 0...data.metadata.rigidBodyCount) {
			var body = data.rigidBodies[i];
			var value = boneTypeTable.get(body.boneIndex);
			value = value == null ? body.type : Math.max(body.type, value);
			boneTypeTable.set(body.boneIndex, value);
		}
		for (i in 0...data.metadata.boneCount) {
			var boneData = data.bones[i];
			var bone = {
				index: i,
				transformationClass: boneData.transformationClass,
				parent: boneData.parentIndex,
				name: boneData.name,
				pos: boneData.position.slice(0, 3),
				rotq: [0, 0, 0, 1],
				scl: [1, 1, 1],
				rigidBodyType: boneTypeTable.get(i) != null ? boneTypeTable.get(i) : -1
			};
			if (bone.parent != -1) {
				bone.pos[0] -= data.bones[bone.parent].position[0];
				bone.pos[1] -= data.bones[bone.parent].position[1];
				bone.pos[2] -= data.bones[bone.parent].position[2];
			}
			bones.push(bone);
		}
		if (data.metadata.format == "pmd") {
			for (i in 0...data.metadata.ikCount) {
				var ik = data.iks[i];
				var param = {
					target: ik.target,
					effector: ik.effector,
					iteration: ik.iteration,
					maxAngle: ik.maxAngle * 4,
					links: []
				};
				for (j in 0...ik.links.length) {
					var link = {
						index: ik.links[j].index,
						enabled: true,
						limitation: null,
						rotationMin: null,
						rotationMax: null
					};
					if (data.bones[link.index].name.indexOf("ひざ") >= 0) {
						link.limitation = new Vector3(1.0, 0.0, 0.0);
					}
					param.links.push(link);
				}
				iks.push(param);
			}
		} else {
			for (i in 0...data.metadata.boneCount) {
				var ik = data.bones[i].ik;
				if (ik == null) continue;
				var param = {
					target: i,
					effector: ik.effector,
					iteration: ik.iteration,
					maxAngle: ik.maxAngle,
					links: []
				};
				for (j in 0...ik.links.length) {
					var link = {
						index: ik.links[j].index,
						enabled: true,
						limitation: null,
						rotationMin: null,
						rotationMax: null
					};
					if (ik.links[j].angleLimitation == 1) {
						var rotationMin = ik.links[j].lowerLimitationAngle;
						var rotationMax = ik.links[j].upperLimitationAngle;
						var tmp1 = -rotationMax[0];
						var tmp2 = -rotationMax[1];
						rotationMax[0] = -rotationMin[0];
						rotationMax[1] = -rotationMin[1];
						rotationMin[0] = tmp1;
						rotationMin[1] = tmp2;
						link.rotationMin = new Vector3().fromArray(rotationMin);
						link.rotationMax = new Vector3().fromArray(rotationMax);
					}
					param.links.push(link);
				}
				iks.push(param);
				bones[i].ik = param;
			}
		}
		if (data.metadata.format == "pmx") {
			var grantEntryMap:Map<Int, {parent:Dynamic, children:Array<Dynamic>, param:Dynamic, visited:Bool}> = new Map();
			for (i in 0...data.metadata.boneCount) {
				var boneData = data.bones[i];
				var grant = boneData.grant;
				if (grant == null) continue;
				var param = {
					index: i,
					parentIndex: grant.parentIndex,
					ratio: grant.ratio,
					isLocal: grant.isLocal,
					affectRotation: grant.affectRotation,
					affectPosition: grant.affectPosition,
					transformationClass: boneData.transformationClass
				};
				grantEntryMap.set(i, {parent: null, children: [], param: param, visited: false});
			}
			var rootEntry = {parent: null, children: [], param: null, visited: false};
			for (boneIndex in grantEntryMap.keys()) {
				var grantEntry = grantEntryMap.get(boneIndex);
				var parentGrantEntry = grantEntryMap.get(grantEntry.parentIndex) != null ? grantEntryMap.get(grantEntry.parentIndex) : rootEntry;
				grantEntry.parent = parentGrantEntry;
				parentGrantEntry.children.push(grantEntry);
			}
			function traverse(entry) {
				if (entry.param != null) {
					grants.push(entry.param);
					bones[entry.param.index].grant = entry.param;
				}
				entry.visited = true;
				for (i in 0...entry.children.length) {
					var child = entry.children[i];
					if (!child.visited) traverse(child);
				}
			}
			traverse(rootEntry);
		}
		function updateAttributes(attribute:Float32BufferAttribute, morph:Dynamic, ratio:Float) {
			for (i in 0...morph.elementCount) {
				var element = morph.elements[i];
				var index:Int;
				if (data.metadata.format == "pmd") {
					index = data.morphs[0].elements[element.index].index;
				} else {
					index = element.index;
				}
				attribute.array[index * 3 + 0] += element.position[0] * ratio;
				attribute.array[index * 3 + 1] += element.position[1] * ratio;
				attribute.array[index * 3 + 2] += element.position[2] * ratio;
			}
		}
		for (i in 0...data.metadata.morphCount) {
			var morph = data.morphs[i];
			var params = {name: morph.name};
			var attribute = new Float32BufferAttribute(data.metadata.vertexCount * 3, 3);
			attribute.name = morph.name;
			for (j in 0...data.metadata.vertexCount * 3) {
				attribute.array[j] = positions[j];
			}
			if (data.metadata.format == "pmd") {
				if (i != 0) {
					updateAttributes(attribute, morph, 1.0);
				}
			} else {
				if (morph.type == 0) {
					for (j in 0...morph.elementCount) {
						var morph2 = data.morphs[morph.elements[j].index];
						var ratio = morph.elements[j].ratio;
						if (morph2.type == 1) {
							updateAttributes(attribute, morph2, ratio);
						} else {
							// TODO: implement
						}
					}
				} else if (morph.type == 1) {
					updateAttributes(attribute, morph, 1.0);
				} else if (morph.type == 2) {
					// TODO: implement
				} else if (morph.type == 3) {
					// TODO: implement
				} else if (morph.type == 4) {
					// TODO: implement
				} else if (morph.type == 5) {
					// TODO: implement
				} else if (morph.type == 6) {
					// TODO: implement
				} else if (morph.type == 7) {
					// TODO: implement
				} else if (morph.type == 8) {
					// TODO: implement
				}
			}
			morphTargets.push(params);
			morphPositions.push(attribute);
		}
		for (i in 0...data.metadata.rigidBodyCount) {
			var rigidBody = data.rigidBodies[i];
			var params:Dynamic = {};
			for (key in Reflect.fields(rigidBody)) {
				params[key] = rigidBody[key];
			}
			if (data.metadata.format == "pmx") {
				if (params.boneIndex != -1) {
					var bone = data.bones[params.boneIndex];
					params.position[0] -= bone.position[0];
					params.position[1] -= bone.position[1];
					params.position[2] -= bone.position[2];
				}
			}
			rigidBodies.push(params);
		}
		for (i in 0...data.metadata.constraintCount) {
			var constraint = data.constraints[i];
			var params:Dynamic = {};
			for (key in Reflect.fields(constraint)) {
				params[key] = constraint[key];
			}
			var bodyA = rigidBodies[params.rigidBodyIndex1];
			var bodyB = rigidBodies[params.rigidBodyIndex2];
			if (bodyA.type != 0 && bodyB.type == 2) {
				if (bodyA.boneIndex != -1 && bodyB.boneIndex != -1 && data.bones[bodyB.boneIndex].parentIndex == bodyA.boneIndex) {
					bodyB.type = 1;
				}
			}
			constraints.push(params);
		}
		var geometry = new BufferGeometry();
		geometry.setAttribute("position", new Float32BufferAttribute(positions, 3));
		geometry.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		geometry.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
		geometry.setAttribute("skinIndex", new Uint16BufferAttribute(skinIndices, 4));
		geometry.setAttribute("skinWeight", new Float32BufferAttribute(skinWeights, 4));
		geometry.setIndex(indices);
		for (i in 0...groups.length) {
			geometry.addGroup(groups[i].offset, groups[i].count, i);
		}
		geometry.bones = bones;
		geometry.morphTargets = morphTargets;
		geometry.morphAttributes.position = morphPositions;
		geometry.morphTargetsRelative = false;
		geometry.userData.MMD = {
			bones: bones,
			iks: iks,
			grants: grants,
			rigidBodies: rigidBodies,
			constraints: constraints,
			format: data.metadata.format
		};
		geometry.computeBoundingSphere();
		return geometry;
	}

}

class MaterialBuilder {

	private var manager:LoadingManager;
	private var textureLoader:TextureLoader;
	private var tgaLoader:Dynamic;
	private var crossOrigin:String;
	private var resourcePath:String;

	public function new(manager:LoadingManager) {
		this.manager = manager;
		this.textureLoader = new TextureLoader(this.manager);
		this.tgaLoader = null;
		this.crossOrigin = "anonymous";
		this.resourcePath = null;
	}

	public function setCrossOrigin(crossOrigin:String):MaterialBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function setResourcePath(resourcePath:String):MaterialBuilder {
		this.resourcePath = resourcePath;
		return this;
	}

	public function build(data:Dynamic, geometry:BufferGeometry, onProgress:Dynamic = null, onError:Dynamic = null):Array<MMDToonMaterial> {
		var materials:Array<MMDToonMaterial> = [];
		var textures:Map<String, three.textures.Texture> = new Map();
		this.textureLoader.setCrossOrigin(this.crossOrigin);
		for (i in 0...data.metadata.materialCount) {
			var material = data.materials[i];
			var params:Dynamic = {userData: {MMD: {}}};
			if (material.name != null) params.name = material.name;
			params.diffuse = new Color().setRGB(material.diffuse[0], material.diffuse[1], material.diffuse[2], TextureEncoding.SRGB);
			params.opacity = material.diffuse[3];
			params.specular = new Color().setRGB(material.specular[0], material.specular[1], material.specular[2], TextureEncoding.SRGB);
			params.shininess = material.shininess;
			params.emissive = new Color().setRGB(material.ambient[0], material.ambient[1], material.ambient[2], TextureEncoding.SRGB);
			params.transparent = params.opacity != 1.0;
			params.fog = true;
			params.blending = BlendingEquation.CustomBlending;
			params.blendSrc = BlendingFactorSrc.SrcAlphaFactor;
			params.blendDst = BlendingFactorDest.OneMinusSrcAlphaFactor;
			params.blendSrcAlpha = BlendingFactorSrc.SrcAlphaFactor;
			params.blendDstAlpha = BlendingFactorDest.DstAlphaFactor;
			if (data.metadata.format == "pmx" && (material.flag & 0x1) == 1) {
				params.side = Side.DoubleSide;
			} else {
				params.side = params.opacity == 1.0 ? Side.FrontSide : Side.DoubleSide;
			}
			if (data.metadata.format == "pmd") {
				if (material.fileName != null) {
					var fileName = material.fileName;
					var fileNames = fileName.split("*");
					params.map = this._loadTexture(fileNames[0], textures);
					if (fileNames.length > 1) {
						var extension = fileNames[1].slice(-4).toLowerCase();
						params.matcap = this._loadTexture(fileNames[1], textures);
						params.matcapCombine = extension == ".sph" ? Combine.MultiplyOperation : Combine.AddOperation;
					}
				}
				var toonFileName = material.toonIndex == -1 ? "toon00.bmp" : data.toonTextures[material.toonIndex].fileName;
				params.gradientMap = this._loadTexture(toonFileName, textures, {
					isToonTexture: true,
					isDefaultToonTexture: this._isDefaultToonTexture(toonFileName)
				});
				params.userData.outlineParameters = {
					thickness: material.edgeFlag == 1 ? 0.003 : 0.0,
					color: [0, 0, 0],
					alpha: 1.0,
					visible: material.edgeFlag == 1
				};
			} else {
				if (material.textureIndex != -1) {
					params.map = this._loadTexture(data.textures[material.textureIndex], textures);
					params.userData.MMD.mapFileName = data.textures[material.textureIndex];
				}
				if (material.envTextureIndex != -1 && (material.envFlag == 1 || material.envFlag == 2)) {
					params.matcap = this._loadTexture(data.textures[material.envTextureIndex], textures);
					params.userData.MMD.matcapFileName = data.textures[material.envTextureIndex];
					params.matcapCombine = material.envFlag == 1 ? Combine.MultiplyOperation : Combine.AddOperation;
				}
				var toonFileName:String;
				var isDefaultToon:Bool;
				if (material.toonIndex == -1 || material.toonFlag != 0) {
					toonFileName = "toon" + ("0" + (material.toonIndex + 1)).slice(-2) + ".bmp";
					isDefaultToon = true;
				} else {
					toonFileName = data.textures[material.toonIndex];
					isDefaultToon = false;
				}
				params.gradientMap = this._loadTexture(toonFileName, textures, {
					isToonTexture: true,
					isDefaultToonTexture: isDefaultToon
				});
				params.userData.outlineParameters = {
					thickness: material.edgeSize / 300,
					color: material.edgeColor.slice(0, 3),
					alpha: material.edgeColor[3],
					visible: (material.flag & 0x10) != 0 && material.edgeSize > 0.0
				};
			}
			if (params.map != null) {
				if (!params.transparent) {
					this._checkImageTransparency(params.map, geometry, i);
				}
				params.emissive.multiplyScalar(0.2);
			}
			materials.push(new MMDToonMaterial(params));
		}
		if (data.metadata.format == "pmx") {
			function checkAlphaMorph(elements:Array<Dynamic>, materials:Array<MMDToonMaterial>) {
				for (i in 0...elements.length) {
					var element = elements[i];
					if (element.index == -1) continue;
					var material = materials[element.index];
					if (material.opacity != element.diffuse[3]) {
						material.transparent = true;
					}
				}
			}
			for (i in 0...data.morphs.length) {
				var morph = data.morphs[i];
				var elements = morph.elements;
				if (morph.type == 0) {
					for (j in 0...elements.length) {
						var morph2 = data.morphs[elements[j].index];
						if (morph2.type != 8) continue;
						checkAlphaMorph(morph2.elements, materials);
					}
				} else if (morph.type == 8) {
					checkAlphaMorph(elements, materials);
				}
			}
		}
		return materials;
	}

	private function _getTGALoader():Dynamic {
		if (this.tgaLoader == null) {
			throw new Error("THREE.MMDLoader: Import TGALoader");
		}
		return this.tgaLoader;
	}

	private function _isDefaultToonTexture(name:String):Bool {
		if (name.length != 10) return false;
		return /toon(10|0[0-9])\.bmp/.test(name);
	}

	private function _loadTexture(filePath:String, textures:Map<String, three.textures.Texture>, params:Dynamic = null, onProgress:Dynamic = null, onError:Dynamic = null):three.textures.Texture {
		params = params != null ? params : {};
		var scope = this;
		var fullPath:String;
		if (params.isDefaultToonTexture == true) {
			var index:Int;
			try {
				index = Std.parseInt(filePath.match(/toon([0-9]{2})\.bmp$/)[1]);
			} catch (e:Dynamic) {
				js.Lib.warn("THREE.MMDLoader: " + filePath + " seems like a " + "not right default texture path. Using toon00.bmp instead.");
				index = 0;
			}
			fullPath = DEFAULT_TOON_TEXTURES[index];
		} else {
			fullPath = this.resourcePath + filePath;
		}
		if (textures.exists(fullPath)) return textures.get(fullPath);
		var loader = this.manager.getHandler(fullPath);
		if (loader == null) {
			loader = filePath.slice(-4).toLowerCase() == ".tga" ? this._getTGALoader() : this.textureLoader;
		}
		var texture = loader.load(fullPath, function(t:three.textures.Texture) {
			if (params.isToonTexture == true) {
				t.image = scope._getRotatedImage(t.image);
				t.magFilter = TextureFilter.NearestFilter;
				t.minFilter = TextureFilter.NearestFilter;
			}
			t.flipY = false;
			t.wrapS = Wrapping.RepeatWrapping;
			t.wrapT = Wrapping.RepeatWrapping;
			t.colorSpace = TextureEncoding.SRGB;
			for (i in 0...t.readyCallbacks.length) {
				t.readyCallbacks[i](t);
			}
			t.readyCallbacks = [];
		}, onProgress, onError);
		texture.readyCallbacks = [];
		textures.set(fullPath, texture);
		return texture;
	}

	private function _getRotatedImage(image:html.Image):html.ImageData {
		var canvas = document.createElement("canvas");
		var context = canvas.getContext("2d");
		var width = image.width;
		var height = image.height;
		canvas.width = width;
		canvas.height = height;
		context.clearRect(0,
import three.core.LoadingManager;
import three.loaders.FileLoader;
import three.loaders.LoaderUtils;
import three.materials.ShaderMaterial;
import three.math.Color;
import three.math.Euler;
import three.math.Quaternion;
import three.math.Vector3;
import three.objects.Bone;
import three.objects.Skeleton;
import three.objects.SkinnedMesh;
import three.textures.TextureLoader;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Uint16BufferAttribute;
import three.animation.AnimationClip;
import three.animation.NumberKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.animation.QuaternionKeyframeTrack;
import three.animation.Interpolant;
import three.extras.objects.SkinnedMesh;
import three.renderers.shaders.ShaderLib;
import three.renderers.shaders.UniformsUtils;
import three.constants.BlendingEquation;
import three.constants.BlendingFactorDest;
import three.constants.BlendingFactorSrc;
import three.constants.Side;
import three.constants.Wrapping;
import three.constants.TextureFilter;
import three.constants.TextureEncoding;
import three.constants.TextureFormat;
import three.constants.Mapping;
import three.constants.Combine;
import three.constants.NormalMapTypes;
import three.materials.Material;
import three.materials.MeshBasicMaterial;

import mmd.MMDParser;
import mmd.shaders.MMDToonShader;

class MMDLoader extends three.loaders.Loader {

	public var animationPath:String;
	public var parser:MMDParser.Parser;
	public var meshBuilder:MeshBuilder;
	public var animationBuilder:AnimationBuilder;

	public function new(manager:LoadingManager = null) {
		super(manager);
		this.loader = new FileLoader(this.manager);
		this.parser = null;
		this.meshBuilder = new MeshBuilder(this.manager);
		this.animationBuilder = new AnimationBuilder();
	}

	public function setAnimationPath(animationPath:String):MMDLoader {
		this.animationPath = animationPath;
		return this;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var builder = this.meshBuilder.setCrossOrigin(this.crossOrigin);
		var resourcePath:String;
		if (this.resourcePath != "") {
			resourcePath = this.resourcePath;
		} else if (this.path != "") {
			resourcePath = this.path;
		} else {
			resourcePath = LoaderUtils.extractUrlBase(url);
		}
		var parser = this._getParser();
		var extractModelExtension = this._extractModelExtension;

		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					var modelExtension = extractModelExtension(buffer);
					if (modelExtension != "pmd" && modelExtension != "pmx") {
						if (onError != null) onError(new Error("THREE.MMDLoader: Unknown model file extension ." + modelExtension + "."));
						return;
					}
					var data = modelExtension == "pmd" ? parser.parsePmd(buffer, true) : parser.parsePmx(buffer, true);
					onLoad(builder.build(data, resourcePath, onProgress, onError));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadAnimation(url:Dynamic, object:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var builder = this.animationBuilder;
		this.loadVMD(url, function(vmd:MMDParser.VMD) {
			onLoad(object.isCamera ? builder.buildCameraAnimation(vmd) : builder.build(vmd, object));
		}, onProgress, onError);
	}

	public function loadWithAnimation(modelUrl:String, vmdUrl:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var scope = this;
		this.load(modelUrl, function(mesh:SkinnedMesh) {
			scope.loadAnimation(vmdUrl, mesh, function(animation:AnimationClip) {
				onLoad({
					mesh: mesh,
					animation: animation
				});
			}, onProgress, onError);
		}, onProgress, onError);
	}

	public function loadPMD(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmd(buffer, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadPMX(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmx(buffer, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadVMD(url:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var urls:Array<String> = Std.isOfType(url, Array) ? url : [url];
		var vmds:Array<MMDParser.VMD> = [];
		var vmdNum = urls.length;
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.animationPath)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials);
		for (i in 0...urls.length) {
			this.loader.load(urls[i], function(buffer:haxe.io.Bytes) {
				try {
					vmds.push(parser.parseVmd(buffer, true));
					if (vmds.length == vmdNum) onLoad(parser.mergeVmds(vmds));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
		}
	}

	public function loadVPD(url:String, isUnicode:Bool, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(isUnicode ? null : "text/plain; charset=shift_jis")
			.setPath(this.animationPath)
			.setResponseType("text")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(text:String) {
				try {
					onLoad(parser.parseVpd(text, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	private function _extractModelExtension(buffer:haxe.io.Bytes):String {
		var decoder = new haxe.io.BytesInput(buffer).readString(3);
		return decoder.toLowerCase();
	}

	private function _getParser():MMDParser.Parser {
		if (this.parser == null) {
			this.parser = new MMDParser.Parser();
		}
		return this.parser;
	}

}

class MeshBuilder {

	private var crossOrigin:String;
	private var geometryBuilder:GeometryBuilder;
	private var materialBuilder:MaterialBuilder;

	public function new(manager:LoadingManager) {
		this.crossOrigin = "anonymous";
		this.geometryBuilder = new GeometryBuilder();
		this.materialBuilder = new MaterialBuilder(manager);
	}

	public function setCrossOrigin(crossOrigin:String):MeshBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function build(data:Dynamic, resourcePath:String, onProgress:Dynamic = null, onError:Dynamic = null):SkinnedMesh {
		var geometry = this.geometryBuilder.build(data);
		var material = this.materialBuilder
			.setCrossOrigin(this.crossOrigin)
			.setResourcePath(resourcePath)
			.build(data, geometry, onProgress, onError);
		var mesh = new SkinnedMesh(geometry, material);
		var skeleton = new Skeleton(initBones(mesh));
		mesh.bind(skeleton);
		return mesh;
	}

}

function initBones(mesh:SkinnedMesh):Array<Bone> {
	var geometry = mesh.geometry;
	var bones:Array<Bone> = [];
	if (geometry != null && geometry.bones != null) {
		for (i in 0...geometry.bones.length) {
			var gbone = geometry.bones[i];
			var bone = new Bone();
			bones.push(bone);
			bone.name = gbone.name;
			bone.position.fromArray(gbone.pos);
			bone.quaternion.fromArray(gbone.rotq);
			if (gbone.scl != null) bone.scale.fromArray(gbone.scl);
		}
		for (i in 0...geometry.bones.length) {
			var gbone = geometry.bones[i];
			if (gbone.parent != -1 && gbone.parent != null && bones[gbone.parent] != null) {
				bones[gbone.parent].add(bones[i]);
			} else {
				mesh.add(bones[i]);
			}
		}
	}
	mesh.updateMatrixWorld(true);
	return bones;
}

class GeometryBuilder {

	public function build(data:Dynamic):BufferGeometry {
		var positions:Array<Float> = [];
		var uvs:Array<Float> = [];
		var normals:Array<Float> = [];
		var indices:Array<Int> = [];
		var groups:Array<{offset:Int, count:Int}> = [];
		var bones:Array<{index:Int, transformationClass:Int, parent:Int, name:String, pos:Array<Float>, rotq:Array<Float>, scl:Array<Float>, rigidBodyType:Int}> = [];
		var skinIndices:Array<Float> = [];
		var skinWeights:Array<Float> = [];
		var morphTargets:Array<{name:String}> = [];
		var morphPositions:Array<Float32BufferAttribute> = [];
		var iks:Array<{target:Int, effector:Int, iteration:Int, maxAngle:Float, links:Array<{index:Int, enabled:Bool, limitation:Vector3, rotationMin:Vector3, rotationMax:Vector3}>>} = [];
		var grants:Array<{index:Int, parentIndex:Int, ratio:Float, isLocal:Bool, affectRotation:Bool, affectPosition:Bool, transformationClass:Int}> = [];
		var rigidBodies:Array<Dynamic> = [];
		var constraints:Array<Dynamic> = [];
		var offset:Int = 0;
		var boneTypeTable:Map<Int, Int> = new Map();
		for (i in 0...data.metadata.vertexCount) {
			var v = data.vertices[i];
			for (j in 0...v.position.length) {
				positions.push(v.position[j]);
			}
			for (j in 0...v.normal.length) {
				normals.push(v.normal[j]);
			}
			for (j in 0...v.uv.length) {
				uvs.push(v.uv[j]);
			}
			for (j in 0...4) {
				skinIndices.push(v.skinIndices.length - 1 >= j ? v.skinIndices[j] : 0.0);
			}
			for (j in 0...4) {
				skinWeights.push(v.skinWeights.length - 1 >= j ? v.skinWeights[j] : 0.0);
			}
		}
		for (i in 0...data.metadata.faceCount) {
			var face = data.faces[i];
			for (j in 0...face.indices.length) {
				indices.push(face.indices[j]);
			}
		}
		for (i in 0...data.metadata.materialCount) {
			var material = data.materials[i];
			groups.push({
				offset: offset * 3,
				count: material.faceCount * 3
			});
			offset += material.faceCount;
		}
		for (i in 0...data.metadata.rigidBodyCount) {
			var body = data.rigidBodies[i];
			var value = boneTypeTable.get(body.boneIndex);
			value = value == null ? body.type : Math.max(body.type, value);
			boneTypeTable.set(body.boneIndex, value);
		}
		for (i in 0...data.metadata.boneCount) {
			var boneData = data.bones[i];
			var bone = {
				index: i,
				transformationClass: boneData.transformationClass,
				parent: boneData.parentIndex,
				name: boneData.name,
				pos: boneData.position.slice(0, 3),
				rotq: [0, 0, 0, 1],
				scl: [1, 1, 1],
				rigidBodyType: boneTypeTable.get(i) != null ? boneTypeTable.get(i) : -1
			};
			if (bone.parent != -1) {
				bone.pos[0] -= data.bones[bone.parent].position[0];
				bone.pos[1] -= data.bones[bone.parent].position[1];
				bone.pos[2] -= data.bones[bone.parent].position[2];
			}
			bones.push(bone);
		}
		if (data.metadata.format == "pmd") {
			for (i in 0...data.metadata.ikCount) {
				var ik = data.iks[i];
				var param = {
					target: ik.target,
					effector: ik.effector,
					iteration: ik.iteration,
					maxAngle: ik.maxAngle * 4,
					links: []
				};
				for (j in 0...ik.links.length) {
					var link = {
						index: ik.links[j].index,
						enabled: true,
						limitation: null,
						rotationMin: null,
						rotationMax: null
					};
					if (data.bones[link.index].name.indexOf("ひざ") >= 0) {
						link.limitation = new Vector3(1.0, 0.0, 0.0);
					}
					param.links.push(link);
				}
				iks.push(param);
			}
		} else {
			for (i in 0...data.metadata.boneCount) {
				var ik = data.bones[i].ik;
				if (ik == null) continue;
				var param = {
					target: i,
					effector: ik.effector,
					iteration: ik.iteration,
					maxAngle: ik.maxAngle,
					links: []
				};
				for (j in 0...ik.links.length) {
					var link = {
						index: ik.links[j].index,
						enabled: true,
						limitation: null,
						rotationMin: null,
						rotationMax: null
					};
					if (ik.links[j].angleLimitation == 1) {
						var rotationMin = ik.links[j].lowerLimitationAngle;
						var rotationMax = ik.links[j].upperLimitationAngle;
						var tmp1 = -rotationMax[0];
						var tmp2 = -rotationMax[1];
						rotationMax[0] = -rotationMin[0];
						rotationMax[1] = -rotationMin[1];
						rotationMin[0] = tmp1;
						rotationMin[1] = tmp2;
						link.rotationMin = new Vector3().fromArray(rotationMin);
						link.rotationMax = new Vector3().fromArray(rotationMax);
					}
					param.links.push(link);
				}
				iks.push(param);
				bones[i].ik = param;
			}
		}
		if (data.metadata.format == "pmx") {
			var grantEntryMap:Map<Int, {parent:Dynamic, children:Array<Dynamic>, param:Dynamic, visited:Bool}> = new Map();
			for (i in 0...data.metadata.boneCount) {
				var boneData = data.bones[i];
				var grant = boneData.grant;
				if (grant == null) continue;
				var param = {
					index: i,
					parentIndex: grant.parentIndex,
					ratio: grant.ratio,
					isLocal: grant.isLocal,
					affectRotation: grant.affectRotation,
					affectPosition: grant.affectPosition,
					transformationClass: boneData.transformationClass
				};
				grantEntryMap.set(i, {parent: null, children: [], param: param, visited: false});
			}
			var rootEntry = {parent: null, children: [], param: null, visited: false};
			for (boneIndex in grantEntryMap.keys()) {
				var grantEntry = grantEntryMap.get(boneIndex);
				var parentGrantEntry = grantEntryMap.get(grantEntry.parentIndex) != null ? grantEntryMap.get(grantEntry.parentIndex) : rootEntry;
				grantEntry.parent = parentGrantEntry;
				parentGrantEntry.children.push(grantEntry);
			}
			function traverse(entry) {
				if (entry.param != null) {
					grants.push(entry.param);
					bones[entry.param.index].grant = entry.param;
				}
				entry.visited = true;
				for (i in 0...entry.children.length) {
					var child = entry.children[i];
					if (!child.visited) traverse(child);
				}
			}
			traverse(rootEntry);
		}
		function updateAttributes(attribute:Float32BufferAttribute, morph:Dynamic, ratio:Float) {
			for (i in 0...morph.elementCount) {
				var element = morph.elements[i];
				var index:Int;
				if (data.metadata.format == "pmd") {
					index = data.morphs[0].elements[element.index].index;
				} else {
					index = element.index;
				}
				attribute.array[index * 3 + 0] += element.position[0] * ratio;
				attribute.array[index * 3 + 1] += element.position[1] * ratio;
				attribute.array[index * 3 + 2] += element.position[2] * ratio;
			}
		}
		for (i in 0...data.metadata.morphCount) {
			var morph = data.morphs[i];
			var params = {name: morph.name};
			var attribute = new Float32BufferAttribute(data.metadata.vertexCount * 3, 3);
			attribute.name = morph.name;
			for (j in 0...data.metadata.vertexCount * 3) {
				attribute.array[j] = positions[j];
			}
			if (data.metadata.format == "pmd") {
				if (i != 0) {
					updateAttributes(attribute, morph, 1.0);
				}
			} else {
				if (morph.type == 0) {
					for (j in 0...morph.elementCount) {
						var morph2 = data.morphs[morph.elements[j].index];
						var ratio = morph.elements[j].ratio;
						if (morph2.type == 1) {
							updateAttributes(attribute, morph2, ratio);
						} else {
							// TODO: implement
						}
					}
				} else if (morph.type == 1) {
					updateAttributes(attribute, morph, 1.0);
				} else if (morph.type == 2) {
					// TODO: implement
				} else if (morph.type == 3) {
					// TODO: implement
				} else if (morph.type == 4) {
					// TODO: implement
				} else if (morph.type == 5) {
					// TODO: implement
				} else if (morph.type == 6) {
					// TODO: implement
				} else if (morph.type == 7) {
					// TODO: implement
				} else if (morph.type == 8) {
					// TODO: implement
				}
			}
			morphTargets.push(params);
			morphPositions.push(attribute);
		}
		for (i in 0...data.metadata.rigidBodyCount) {
			var rigidBody = data.rigidBodies[i];
			var params:Dynamic = {};
			for (key in Reflect.fields(rigidBody)) {
				params[key] = rigidBody[key];
			}
			if (data.metadata.format == "pmx") {
				if (params.boneIndex != -1) {
					var bone = data.bones[params.boneIndex];
					params.position[0] -= bone.position[0];
					params.position[1] -= bone.position[1];
					params.position[2] -= bone.position[2];
				}
			}
			rigidBodies.push(params);
		}
		for (i in 0...data.metadata.constraintCount) {
			var constraint = data.constraints[i];
			var params:Dynamic = {};
			for (key in Reflect.fields(constraint)) {
				params[key] = constraint[key];
			}
			var bodyA = rigidBodies[params.rigidBodyIndex1];
			var bodyB = rigidBodies[params.rigidBodyIndex2];
			if (bodyA.type != 0 && bodyB.type == 2) {
				if (bodyA.boneIndex != -1 && bodyB.boneIndex != -1 && data.bones[bodyB.boneIndex].parentIndex == bodyA.boneIndex) {
					bodyB.type = 1;
				}
			}
			constraints.push(params);
		}
		var geometry = new BufferGeometry();
		geometry.setAttribute("position", new Float32BufferAttribute(positions, 3));
		geometry.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		geometry.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
		geometry.setAttribute("skinIndex", new Uint16BufferAttribute(skinIndices, 4));
		geometry.setAttribute("skinWeight", new Float32BufferAttribute(skinWeights, 4));
		geometry.setIndex(indices);
		for (i in 0...groups.length) {
			geometry.addGroup(groups[i].offset, groups[i].count, i);
		}
		geometry.bones = bones;
		geometry.morphTargets = morphTargets;
		geometry.morphAttributes.position = morphPositions;
		geometry.morphTargetsRelative = false;
		geometry.userData.MMD = {
			bones: bones,
			iks: iks,
			grants: grants,
			rigidBodies: rigidBodies,
			constraints: constraints,
			format: data.metadata.format
		};
		geometry.computeBoundingSphere();
		return geometry;
	}

}

class MaterialBuilder {

	private var manager:LoadingManager;
	private var textureLoader:TextureLoader;
	private var tgaLoader:Dynamic;
	private var crossOrigin:String;
	private var resourcePath:String;

	public function new(manager:LoadingManager) {
		this.manager = manager;
		this.textureLoader = new TextureLoader(this.manager);
		this.tgaLoader = null;
		this.crossOrigin = "anonymous";
		this.resourcePath = null;
	}

	public function setCrossOrigin(crossOrigin:String):MaterialBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function setResourcePath(resourcePath:String):MaterialBuilder {
		this.resourcePath = resourcePath;
		return this;
	}

	public function build(data:Dynamic, geometry:BufferGeometry, onProgress:Dynamic = null, onError:Dynamic = null):Array<MMDToonMaterial> {
		var materials:Array<MMDToonMaterial> = [];
		var textures:Map<String, three.textures.Texture> = new Map();
		this.textureLoader.setCrossOrigin(this.crossOrigin);
		for (i in 0...data.metadata.materialCount) {
			var material = data.materials[i];
			var params:Dynamic = {userData: {MMD: {}}};
			if (material.name != null) params.name = material.name;
			params.diffuse = new Color().setRGB(material.diffuse[0], material.diffuse[1], material.diffuse[2], TextureEncoding.SRGB);
			params.opacity = material.diffuse[3];
			params.specular = new Color().setRGB(material.specular[0], material.specular[1], material.specular[2], TextureEncoding.SRGB);
			params.shininess = material.shininess;
			params.emissive = new Color().setRGB(material.ambient[0], material.ambient[1], material.ambient[2], TextureEncoding.SRGB);
			params.transparent = params.opacity != 1.0;
			params.fog = true;
			params.blending = BlendingEquation.CustomBlending;
			params.blendSrc = BlendingFactorSrc.SrcAlphaFactor;
			params.blendDst = BlendingFactorDest.OneMinusSrcAlphaFactor;
			params.blendSrcAlpha = BlendingFactorSrc.SrcAlphaFactor;
			params.blendDstAlpha = BlendingFactorDest.DstAlphaFactor;
			if (data.metadata.format == "pmx" && (material.flag & 0x1) == 1) {
				params.side = Side.DoubleSide;
			} else {
				params.side = params.opacity == 1.0 ? Side.FrontSide : Side.DoubleSide;
			}
			if (data.metadata.format == "pmd") {
				if (material.fileName != null) {
					var fileName = material.fileName;
					var fileNames = fileName.split("*");
					params.map = this._loadTexture(fileNames[0], textures);
					if (fileNames.length > 1) {
						var extension = fileNames[1].slice(-4).toLowerCase();
						params.matcap = this._loadTexture(fileNames[1], textures);
						params.matcapCombine = extension == ".sph" ? Combine.MultiplyOperation : Combine.AddOperation;
					}
				}
				var toonFileName = material.toonIndex == -1 ? "toon00.bmp" : data.toonTextures[material.toonIndex].fileName;
				params.gradientMap = this._loadTexture(toonFileName, textures, {
					isToonTexture: true,
					isDefaultToonTexture: this._isDefaultToonTexture(toonFileName)
				});
				params.userData.outlineParameters = {
					thickness: material.edgeFlag == 1 ? 0.003 : 0.0,
					color: [0, 0, 0],
					alpha: 1.0,
					visible: material.edgeFlag == 1
				};
			} else {
				if (material.textureIndex != -1) {
					params.map = this._loadTexture(data.textures[material.textureIndex], textures);
					params.userData.MMD.mapFileName = data.textures[material.textureIndex];
				}
				if (material.envTextureIndex != -1 && (material.envFlag == 1 || material.envFlag == 2)) {
					params.matcap = this._loadTexture(data.textures[material.envTextureIndex], textures);
					params.userData.MMD.matcapFileName = data.textures[material.envTextureIndex];
					params.matcapCombine = material.envFlag == 1 ? Combine.MultiplyOperation : Combine.AddOperation;
				}
				var toonFileName:String;
				var isDefaultToon:Bool;
				if (material.toonIndex == -1 || material.toonFlag != 0) {
					toonFileName = "toon" + ("0" + (material.toonIndex + 1)).slice(-2) + ".bmp";
					isDefaultToon = true;
				} else {
					toonFileName = data.textures[material.toonIndex];
					isDefaultToon = false;
				}
				params.gradientMap = this._loadTexture(toonFileName, textures, {
					isToonTexture: true,
					isDefaultToonTexture: isDefaultToon
				});
				params.userData.outlineParameters = {
					thickness: material.edgeSize / 300,
					color: material.edgeColor.slice(0, 3),
					alpha: material.edgeColor[3],
					visible: (material.flag & 0x10) != 0 && material.edgeSize > 0.0
				};
			}
			if (params.map != null) {
				if (!params.transparent) {
					this._checkImageTransparency(params.map, geometry, i);
				}
				params.emissive.multiplyScalar(0.2);
			}
			materials.push(new MMDToonMaterial(params));
		}
		if (data.metadata.format == "pmx") {
			function checkAlphaMorph(elements:Array<Dynamic>, materials:Array<MMDToonMaterial>) {
				for (i in 0...elements.length) {
					var element = elements[i];
					if (element.index == -1) continue;
					var material = materials[element.index];
					if (material.opacity != element.diffuse[3]) {
						material.transparent = true;
					}
				}
			}
			for (i in 0...data.morphs.length) {
				var morph = data.morphs[i];
				var elements = morph.elements;
				if (morph.type == 0) {
					for (j in 0...elements.length) {
						var morph2 = data.morphs[elements[j].index];
						if (morph2.type != 8) continue;
						checkAlphaMorph(morph2.elements, materials);
					}
				} else if (morph.type == 8) {
					checkAlphaMorph(elements, materials);
				}
			}
		}
		return materials;
	}

	private function _getTGALoader():Dynamic {
		if (this.tgaLoader == null) {
			throw new Error("THREE.MMDLoader: Import TGALoader");
		}
		return this.tgaLoader;
	}

	private function _isDefaultToonTexture(name:String):Bool {
		if (name.length != 10) return false;
		return /toon(10|0[0-9])\.bmp/.test(name);
	}

	private function _loadTexture(filePath:String, textures:Map<String, three.textures.Texture>, params:Dynamic = null, onProgress:Dynamic = null, onError:Dynamic = null):three.textures.Texture {
		params = params != null ? params : {};
		var scope = this;
		var fullPath:String;
		if (params.isDefaultToonTexture == true) {
			var index:Int;
			try {
				index = Std.parseInt(filePath.match(/toon([0-9]{2})\.bmp$/)[1]);
			} catch (e:Dynamic) {
				js.Lib.warn("THREE.MMDLoader: " + filePath + " seems like a " + "not right default texture path. Using toon00.bmp instead.");
				index = 0;
			}
			fullPath = DEFAULT_TOON_TEXTURES[index];
		} else {
			fullPath = this.resourcePath + filePath;
		}
		if (textures.exists(fullPath)) return textures.get(fullPath);
		var loader = this.manager.getHandler(fullPath);
		if (loader == null) {
			loader = filePath.slice(-4).toLowerCase() == ".tga" ? this._getTGALoader() : this.textureLoader;
		}
		var texture = loader.load(fullPath, function(t:three.textures.Texture) {
			if (params.isToonTexture == true) {
				t.image = scope._getRotatedImage(t.image);
				t.magFilter = TextureFilter.NearestFilter;
				t.minFilter = TextureFilter.NearestFilter;
			}
			t.flipY = false;
			t.wrapS = Wrapping.RepeatWrapping;
			t.wrapT = Wrapping.RepeatWrapping;
			t.colorSpace = TextureEncoding.SRGB;
			for (i in 0...t.readyCallbacks.length) {
				t.readyCallbacks[i](t);
			}
			t.readyCallbacks = [];
		}, onProgress, onError);
		texture.readyCallbacks = [];
		textures.set(fullPath, texture);
		return texture;
	}

	private function _getRotatedImage(image:html.Image):html.ImageData {
		var canvas = document.createElement("canvas");
		var context = canvas.getContext("2d");
		var width = image.width;
		var height = image.height;
		canvas.width = width;
		canvas.height = height;
		context.clearRect(0,
import three.core.LoadingManager;
import three.loaders.FileLoader;
import three.loaders.LoaderUtils;
import three.materials.ShaderMaterial;
import three.math.Color;
import three.math.Euler;
import three.math.Quaternion;
import three.math.Vector3;
import three.objects.Bone;
import three.objects.Skeleton;
import three.objects.SkinnedMesh;
import three.textures.TextureLoader;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Uint16BufferAttribute;
import three.animation.AnimationClip;
import three.animation.NumberKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.animation.QuaternionKeyframeTrack;
import three.animation.Interpolant;
import three.extras.objects.SkinnedMesh;
import three.renderers.shaders.ShaderLib;
import three.renderers.shaders.UniformsUtils;
import three.constants.BlendingEquation;
import three.constants.BlendingFactorDest;
import three.constants.BlendingFactorSrc;
import three.constants.Side;
import three.constants.Wrapping;
import three.constants.TextureFilter;
import three.constants.TextureEncoding;
import three.constants.TextureFormat;
import three.constants.Mapping;
import three.constants.Combine;
import three.constants.NormalMapTypes;
import three.materials.Material;
import three.materials.MeshBasicMaterial;

import mmd.MMDParser;
import mmd.shaders.MMDToonShader;

class MMDLoader extends three.loaders.Loader {

	public var animationPath:String;
	public var parser:MMDParser.Parser;
	public var meshBuilder:MeshBuilder;
	public var animationBuilder:AnimationBuilder;

	public function new(manager:LoadingManager = null) {
		super(manager);
		this.loader = new FileLoader(this.manager);
		this.parser = null;
		this.meshBuilder = new MeshBuilder(this.manager);
		this.animationBuilder = new AnimationBuilder();
	}

	public function setAnimationPath(animationPath:String):MMDLoader {
		this.animationPath = animationPath;
		return this;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var builder = this.meshBuilder.setCrossOrigin(this.crossOrigin);
		var resourcePath:String;
		if (this.resourcePath != "") {
			resourcePath = this.resourcePath;
		} else if (this.path != "") {
			resourcePath = this.path;
		} else {
			resourcePath = LoaderUtils.extractUrlBase(url);
		}
		var parser = this._getParser();
		var extractModelExtension = this._extractModelExtension;

		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					var modelExtension = extractModelExtension(buffer);
					if (modelExtension != "pmd" && modelExtension != "pmx") {
						if (onError != null) onError(new Error("THREE.MMDLoader: Unknown model file extension ." + modelExtension + "."));
						return;
					}
					var data = modelExtension == "pmd" ? parser.parsePmd(buffer, true) : parser.parsePmx(buffer, true);
					onLoad(builder.build(data, resourcePath, onProgress, onError));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadAnimation(url:Dynamic, object:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var builder = this.animationBuilder;
		this.loadVMD(url, function(vmd:MMDParser.VMD) {
			onLoad(object.isCamera ? builder.buildCameraAnimation(vmd) : builder.build(vmd, object));
		}, onProgress, onError);
	}

	public function loadWithAnimation(modelUrl:String, vmdUrl:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var scope = this;
		this.load(modelUrl, function(mesh:SkinnedMesh) {
			scope.loadAnimation(vmdUrl, mesh, function(animation:AnimationClip) {
				onLoad({
					mesh: mesh,
					animation: animation
				});
			}, onProgress, onError);
		}, onProgress, onError);
	}

	public function loadPMD(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmd(buffer, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadPMX(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmx(buffer, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadVMD(url:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var urls:Array<String> = Std.isOfType(url, Array) ? url : [url];
		var vmds:Array<MMDParser.VMD> = [];
		var vmdNum = urls.length;
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.animationPath)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials);
		for (i in 0...urls.length) {
			this.loader.load(urls[i], function(buffer:haxe.io.Bytes) {
				try {
					vmds.push(parser.parseVmd(buffer, true));
					if (vmds.length == vmdNum) onLoad(parser.mergeVmds(vmds));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
		}
	}

	public function loadVPD(url:String, isUnicode:Bool, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(isUnicode ? null : "text/plain; charset=shift_jis")
			.setPath(this.animationPath)
			.setResponseType("text")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(text:String) {
				try {
					onLoad(parser.parseVpd(text, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	private function _extractModelExtension(buffer:haxe.io.Bytes):String {
		var decoder = new haxe.io.BytesInput(buffer).readString(3);
		return decoder.toLowerCase();
	}

	private function _getParser():MMDParser.Parser {
		if (this.parser == null) {
			this.parser = new MMDParser.Parser();
		}
		return this.parser;
	}

}

class MeshBuilder {

	private var crossOrigin:String;
	private var geometryBuilder:GeometryBuilder;
	private var materialBuilder:MaterialBuilder;

	public function new(manager:LoadingManager) {
		this.crossOrigin = "anonymous";
		this.geometryBuilder = new GeometryBuilder();
		this.materialBuilder = new MaterialBuilder(manager);
	}

	public function setCrossOrigin(crossOrigin:String):MeshBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function build(data:Dynamic, resourcePath:String, onProgress:Dynamic = null, onError:Dynamic = null):SkinnedMesh {
		var geometry = this.geometryBuilder.build(data);
		var material = this.materialBuilder
			.setCrossOrigin(this.crossOrigin)
			.setResourcePath(resourcePath)
			.build(data, geometry, onProgress, onError);
		var mesh = new SkinnedMesh(geometry, material);
		var skeleton = new Skeleton(initBones(mesh));
		mesh.bind(skeleton);
		return mesh;
	}

}

function initBones(mesh:SkinnedMesh):Array<Bone> {
	var geometry = mesh.geometry;
	var bones:Array<Bone> = [];
	if (geometry != null && geometry.bones != null) {
		for (i in 0...geometry.bones.length) {
			var gbone = geometry.bones[i];
			var bone = new Bone();
			bones.push(bone);
			bone.name = gbone.name;
			bone.position.fromArray(gbone.pos);
			bone.quaternion.fromArray(gbone.rotq);
			if (gbone.scl != null) bone.scale.fromArray(gbone.scl);
		}
		for (i in 0...geometry.bones.length) {
			var gbone = geometry.bones[i];
			if (gbone.parent != -1 && gbone.parent != null && bones[gbone.parent] != null) {
				bones[gbone.parent].add(bones[i]);
			} else {
				mesh.add(bones[i]);
			}
		}
	}
	mesh.updateMatrixWorld(true);
	return bones;
}

class GeometryBuilder {

	public function build(data:Dynamic):BufferGeometry {
		var positions:Array<Float> = [];
		var uvs:Array<Float> = [];
		var normals:Array<Float> = [];
		var indices:Array<Int> = [];
		var groups:Array<{offset:Int, count:Int}> = [];
		var bones:Array<{index:Int, transformationClass:Int, parent:Int, name:String, pos:Array<Float>, rotq:Array<Float>, scl:Array<Float>, rigidBodyType:Int}> = [];
		var skinIndices:Array<Float> = [];
		var skinWeights:Array<Float> = [];
		var morphTargets:Array<{name:String}> = [];
		var morphPositions:Array<Float32BufferAttribute> = [];
		var iks:Array<{target:Int, effector:Int, iteration:Int, maxAngle:Float, links:Array<{index:Int, enabled:Bool, limitation:Vector3, rotationMin:Vector3, rotationMax:Vector3}>>} = [];
		var grants:Array<{index:Int, parentIndex:Int, ratio:Float, isLocal:Bool, affectRotation:Bool, affectPosition:Bool, transformationClass:Int}> = [];
		var rigidBodies:Array<Dynamic> = [];
		var constraints:Array<Dynamic> = [];
		var offset:Int = 0;
		var boneTypeTable:Map<Int, Int> = new Map();
		for (i in 0...data.metadata.vertexCount) {
			var v = data.vertices[i];
			for (j in 0...v.position.length) {
				positions.push(v.position[j]);
			}
			for (j in 0...v.normal.length) {
				normals.push(v.normal[j]);
			}
			for (j in 0...v.uv.length) {
				uvs.push(v.uv[j]);
			}
			for (j in 0...4) {
				skinIndices.push(v.skinIndices.length - 1 >= j ? v.skinIndices[j] : 0.0);
			}
			for (j in 0...4) {
				skinWeights.push(v.skinWeights.length - 1 >= j ? v.skinWeights[j] : 0.0);
			}
		}
		for (i in 0...data.metadata.faceCount) {
			var face = data.faces[i];
			for (j in 0...face.indices.length) {
				indices.push(face.indices[j]);
			}
		}
		for (i in 0...data.metadata.materialCount) {
			var material = data.materials[i];
			groups.push({
				offset: offset * 3,
				count: material.faceCount * 3
			});
			offset += material.faceCount;
		}
		for (i in 0...data.metadata.rigidBodyCount) {
			var body = data.rigidBodies[i];
			var value = boneTypeTable.get(body.boneIndex);
			value = value == null ? body.type : Math.max(body.type, value);
			boneTypeTable.set(body.boneIndex, value);
		}
		for (i in 0...data.metadata.boneCount) {
			var boneData = data.bones[i];
			var bone = {
				index: i,
				transformationClass: boneData.transformationClass,
				parent: boneData.parentIndex,
				name: boneData.name,
				pos: boneData.position.slice(0, 3),
				rotq: [0, 0, 0, 1],
				scl: [1, 1, 1],
				rigidBodyType: boneTypeTable.get(i) != null ? boneTypeTable.get(i) : -1
			};
			if (bone.parent != -1) {
				bone.pos[0] -= data.bones[bone.parent].position[0];
				bone.pos[1] -= data.bones[bone.parent].position[1];
				bone.pos[2] -= data.bones[bone.parent].position[2];
			}
			bones.push(bone);
		}
		if (data.metadata.format == "pmd") {
			for (i in 0...data.metadata.ikCount) {
				var ik = data.iks[i];
				var param = {
					target: ik.target,
					effector: ik.effector,
					iteration: ik.iteration,
					maxAngle: ik.maxAngle * 4,
					links: []
				};
				for (j in 0...ik.links.length) {
					var link = {
						index: ik.links[j].index,
						enabled: true,
						limitation: null,
						rotationMin: null,
						rotationMax: null
					};
					if (data.bones[link.index].name.indexOf("ひざ") >= 0) {
						link.limitation = new Vector3(1.0, 0.0, 0.0);
					}
					param.links.push(link);
				}
				iks.push(param);
			}
		} else {
			for (i in 0...data.metadata.boneCount) {
				var ik = data.bones[i].ik;
				if (ik == null) continue;
				var param = {
					target: i,
					effector: ik.effector,
					iteration: ik.iteration,
					maxAngle: ik.maxAngle,
					links: []
				};
				for (j in 0...ik.links.length) {
					var link = {
						index: ik.links[j].index,
						enabled: true,
						limitation: null,
						rotationMin: null,
						rotationMax: null
					};
					if (ik.links[j].angleLimitation == 1) {
						var rotationMin = ik.links[j].lowerLimitationAngle;
						var rotationMax = ik.links[j].upperLimitationAngle;
						var tmp1 = -rotationMax[0];
						var tmp2 = -rotationMax[1];
						rotationMax[0] = -rotationMin[0];
						rotationMax[1] = -rotationMin[1];
						rotationMin[0] = tmp1;
						rotationMin[1] = tmp2;
						link.rotationMin = new Vector3().fromArray(rotationMin);
						link.rotationMax = new Vector3().fromArray(rotationMax);
					}
					param.links.push(link);
				}
				iks.push(param);
				bones[i].ik = param;
			}
		}
		if (data.metadata.format == "pmx") {
			var grantEntryMap:Map<Int, {parent:Dynamic, children:Array<Dynamic>, param:Dynamic, visited:Bool}> = new Map();
			for (i in 0...data.metadata.boneCount) {
				var boneData = data.bones[i];
				var grant = boneData.grant;
				if (grant == null) continue;
				var param = {
					index: i,
					parentIndex: grant.parentIndex,
					ratio: grant.ratio,
					isLocal: grant.isLocal,
					affectRotation: grant.affectRotation,
					affectPosition: grant.affectPosition,
					transformationClass: boneData.transformationClass
				};
				grantEntryMap.set(i, {parent: null, children: [], param: param, visited: false});
			}
			var rootEntry = {parent: null, children: [], param: null, visited: false};
			for (boneIndex in grantEntryMap.keys()) {
				var grantEntry = grantEntryMap.get(boneIndex);
				var parentGrantEntry = grantEntryMap.get(grantEntry.parentIndex) != null ? grantEntryMap.get(grantEntry.parentIndex) : rootEntry;
				grantEntry.parent = parentGrantEntry;
				parentGrantEntry.children.push(grantEntry);
			}
			function traverse(entry) {
				if (entry.param != null) {
					grants.push(entry.param);
					bones[entry.param.index].grant = entry.param;
				}
				entry.visited = true;
				for (i in 0...entry.children.length) {
					var child = entry.children[i];
					if (!child.visited) traverse(child);
				}
			}
			traverse(rootEntry);
		}
		function updateAttributes(attribute:Float32BufferAttribute, morph:Dynamic, ratio:Float) {
			for (i in 0...morph.elementCount) {
				var element = morph.elements[i];
				var index:Int;
				if (data.metadata.format == "pmd") {
					index = data.morphs[0].elements[element.index].index;
				} else {
					index = element.index;
				}
				attribute.array[index * 3 + 0] += element.position[0] * ratio;
				attribute.array[index * 3 + 1] += element.position[1] * ratio;
				attribute.array[index * 3 + 2] += element.position[2] * ratio;
			}
		}
		for (i in 0...data.metadata.morphCount) {
			var morph = data.morphs[i];
			var params = {name: morph.name};
			var attribute = new Float32BufferAttribute(data.metadata.vertexCount * 3, 3);
			attribute.name = morph.name;
			for (j in 0...data.metadata.vertexCount * 3) {
				attribute.array[j] = positions[j];
			}
			if (data.metadata.format == "pmd") {
				if (i != 0) {
					updateAttributes(attribute, morph, 1.0);
				}
			} else {
				if (morph.type == 0) {
					for (j in 0...morph.elementCount) {
						var morph2 = data.morphs[morph.elements[j].index];
						var ratio = morph.elements[j].ratio;
						if (morph2.type == 1) {
							updateAttributes(attribute, morph2, ratio);
						} else {
							// TODO: implement
						}
					}
				} else if (morph.type == 1) {
					updateAttributes(attribute, morph, 1.0);
				} else if (morph.type == 2) {
					// TODO: implement
				} else if (morph.type == 3) {
					// TODO: implement
				} else if (morph.type == 4) {
					// TODO: implement
				} else if (morph.type == 5) {
					// TODO: implement
				} else if (morph.type == 6) {
					// TODO: implement
				} else if (morph.type == 7) {
					// TODO: implement
				} else if (morph.type == 8) {
					// TODO: implement
				}
			}
			morphTargets.push(params);
			morphPositions.push(attribute);
		}
		for (i in 0...data.metadata.rigidBodyCount) {
			var rigidBody = data.rigidBodies[i];
			var params:Dynamic = {};
			for (key in Reflect.fields(rigidBody)) {
				params[key] = rigidBody[key];
			}
			if (data.metadata.format == "pmx") {
				if (params.boneIndex != -1) {
					var bone = data.bones[params.boneIndex];
					params.position[0] -= bone.position[0];
					params.position[1] -= bone.position[1];
					params.position[2] -= bone.position[2];
				}
			}
			rigidBodies.push(params);
		}
		for (i in 0...data.metadata.constraintCount) {
			var constraint = data.constraints[i];
			var params:Dynamic = {};
			for (key in Reflect.fields(constraint)) {
				params[key] = constraint[key];
			}
			var bodyA = rigidBodies[params.rigidBodyIndex1];
			var bodyB = rigidBodies[params.rigidBodyIndex2];
			if (bodyA.type != 0 && bodyB.type == 2) {
				if (bodyA.boneIndex != -1 && bodyB.boneIndex != -1 && data.bones[bodyB.boneIndex].parentIndex == bodyA.boneIndex) {
					bodyB.type = 1;
				}
			}
			constraints.push(params);
		}
		var geometry = new BufferGeometry();
		geometry.setAttribute("position", new Float32BufferAttribute(positions, 3));
		geometry.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		geometry.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
		geometry.setAttribute("skinIndex", new Uint16BufferAttribute(skinIndices, 4));
		geometry.setAttribute("skinWeight", new Float32BufferAttribute(skinWeights, 4));
		geometry.setIndex(indices);
		for (i in 0...groups.length) {
			geometry.addGroup(groups[i].offset, groups[i].count, i);
		}
		geometry.bones = bones;
		geometry.morphTargets = morphTargets;
		geometry.morphAttributes.position = morphPositions;
		geometry.morphTargetsRelative = false;
		geometry.userData.MMD = {
			bones: bones,
			iks: iks,
			grants: grants,
			rigidBodies: rigidBodies,
			constraints: constraints,
			format: data.metadata.format
		};
		geometry.computeBoundingSphere();
		return geometry;
	}

}

class MaterialBuilder {

	private var manager:LoadingManager;
	private var textureLoader:TextureLoader;
	private var tgaLoader:Dynamic;
	private var crossOrigin:String;
	private var resourcePath:String;

	public function new(manager:LoadingManager) {
		this.manager = manager;
		this.textureLoader = new TextureLoader(this.manager);
		this.tgaLoader = null;
		this.crossOrigin = "anonymous";
		this.resourcePath = null;
	}

	public function setCrossOrigin(crossOrigin:String):MaterialBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function setResourcePath(resourcePath:String):MaterialBuilder {
		this.resourcePath = resourcePath;
		return this;
	}

	public function build(data:Dynamic, geometry:BufferGeometry, onProgress:Dynamic = null, onError:Dynamic = null):Array<MMDToonMaterial> {
		var materials:Array<MMDToonMaterial> = [];
		var textures:Map<String, three.textures.Texture> = new Map();
		this.textureLoader.setCrossOrigin(this.crossOrigin);
		for (i in 0...data.metadata.materialCount) {
			var material = data.materials[i];
			var params:Dynamic = {userData: {MMD: {}}};
			if (material.name != null) params.name = material.name;
			params.diffuse = new Color().setRGB(material.diffuse[0], material.diffuse[1], material.diffuse[2], TextureEncoding.SRGB);
			params.opacity = material.diffuse[3];
			params.specular = new Color().setRGB(material.specular[0], material.specular[1], material.specular[2], TextureEncoding.SRGB);
			params.shininess = material.shininess;
			params.emissive = new Color().setRGB(material.ambient[0], material.ambient[1], material.ambient[2], TextureEncoding.SRGB);
			params.transparent = params.opacity != 1.0;
			params.fog = true;
			params.blending = BlendingEquation.CustomBlending;
			params.blendSrc = BlendingFactorSrc.SrcAlphaFactor;
			params.blendDst = BlendingFactorDest.OneMinusSrcAlphaFactor;
			params.blendSrcAlpha = BlendingFactorSrc.SrcAlphaFactor;
			params.blendDstAlpha = BlendingFactorDest.DstAlphaFactor;
			if (data.metadata.format == "pmx" && (material.flag & 0x1) == 1) {
				params.side = Side.DoubleSide;
			} else {
				params.side = params.opacity == 1.0 ? Side.FrontSide : Side.DoubleSide;
			}
			if (data.metadata.format == "pmd") {
				if (material.fileName != null) {
					var fileName = material.fileName;
					var fileNames = fileName.split("*");
					params.map = this._loadTexture(fileNames[0], textures);
					if (fileNames.length > 1) {
						var extension = fileNames[1].slice(-4).toLowerCase();
						params.matcap = this._loadTexture(fileNames[1], textures);
						params.matcapCombine = extension == ".sph" ? Combine.MultiplyOperation : Combine.AddOperation;
					}
				}
				var toonFileName = material.toonIndex == -1 ? "toon00.bmp" : data.toonTextures[material.toonIndex].fileName;
				params.gradientMap = this._loadTexture(toonFileName, textures, {
					isToonTexture: true,
					isDefaultToonTexture: this._isDefaultToonTexture(toonFileName)
				});
				params.userData.outlineParameters = {
					thickness: material.edgeFlag == 1 ? 0.003 : 0.0,
					color: [0, 0, 0],
					alpha: 1.0,
					visible: material.edgeFlag == 1
				};
			} else {
				if (material.textureIndex != -1) {
					params.map = this._loadTexture(data.textures[material.textureIndex], textures);
					params.userData.MMD.mapFileName = data.textures[material.textureIndex];
				}
				if (material.envTextureIndex != -1 && (material.envFlag == 1 || material.envFlag == 2)) {
					params.matcap = this._loadTexture(data.textures[material.envTextureIndex], textures);
					params.userData.MMD.matcapFileName = data.textures[material.envTextureIndex];
					params.matcapCombine = material.envFlag == 1 ? Combine.MultiplyOperation : Combine.AddOperation;
				}
				var toonFileName:String;
				var isDefaultToon:Bool;
				if (material.toonIndex == -1 || material.toonFlag != 0) {
					toonFileName = "toon" + ("0" + (material.toonIndex + 1)).slice(-2) + ".bmp";
					isDefaultToon = true;
				} else {
					toonFileName = data.textures[material.toonIndex];
					isDefaultToon = false;
				}
				params.gradientMap = this._loadTexture(toonFileName, textures, {
					isToonTexture: true,
					isDefaultToonTexture: isDefaultToon
				});
				params.userData.outlineParameters = {
					thickness: material.edgeSize / 300,
					color: material.edgeColor.slice(0, 3),
					alpha: material.edgeColor[3],
					visible: (material.flag & 0x10) != 0 && material.edgeSize > 0.0
				};
			}
			if (params.map != null) {
				if (!params.transparent) {
					this._checkImageTransparency(params.map, geometry, i);
				}
				params.emissive.multiplyScalar(0.2);
			}
			materials.push(new MMDToonMaterial(params));
		}
		if (data.metadata.format == "pmx") {
			function checkAlphaMorph(elements:Array<Dynamic>, materials:Array<MMDToonMaterial>) {
				for (i in 0...elements.length) {
					var element = elements[i];
					if (element.index == -1) continue;
					var material = materials[element.index];
					if (material.opacity != element.diffuse[3]) {
						material.transparent = true;
					}
				}
			}
			for (i in 0...data.morphs.length) {
				var morph = data.morphs[i];
				var elements = morph.elements;
				if (morph.type == 0) {
					for (j in 0...elements.length) {
						var morph2 = data.morphs[elements[j].index];
						if (morph2.type != 8) continue;
						checkAlphaMorph(morph2.elements, materials);
					}
				} else if (morph.type == 8) {
					checkAlphaMorph(elements, materials);
				}
			}
		}
		return materials;
	}

	private function _getTGALoader():Dynamic {
		if (this.tgaLoader == null) {
			throw new Error("THREE.MMDLoader: Import TGALoader");
		}
		return this.tgaLoader;
	}

	private function _isDefaultToonTexture(name:String):Bool {
		if (name.length != 10) return false;
		return /toon(10|0[0-9])\.bmp/.test(name);
	}

	private function _loadTexture(filePath:String, textures:Map<String, three.textures.Texture>, params:Dynamic = null, onProgress:Dynamic = null, onError:Dynamic = null):three.textures.Texture {
		params = params != null ? params : {};
		var scope = this;
		var fullPath:String;
		if (params.isDefaultToonTexture == true) {
			var index:Int;
			try {
				index = Std.parseInt(filePath.match(/toon([0-9]{2})\.bmp$/)[1]);
			} catch (e:Dynamic) {
				js.Lib.warn("THREE.MMDLoader: " + filePath + " seems like a " + "not right default texture path. Using toon00.bmp instead.");
				index = 0;
			}
			fullPath = DEFAULT_TOON_TEXTURES[index];
		} else {
			fullPath = this.resourcePath + filePath;
		}
		if (textures.exists(fullPath)) return textures.get(fullPath);
		var loader = this.manager.getHandler(fullPath);
		if (loader == null) {
			loader = filePath.slice(-4).toLowerCase() == ".tga" ? this._getTGALoader() : this.textureLoader;
		}
		var texture = loader.load(fullPath, function(t:three.textures.Texture) {
			if (params.isToonTexture == true) {
				t.image = scope._getRotatedImage(t.image);
				t.magFilter = TextureFilter.NearestFilter;
				t.minFilter = TextureFilter.NearestFilter;
			}
			t.flipY = false;
			t.wrapS = Wrapping.RepeatWrapping;
			t.wrapT = Wrapping.RepeatWrapping;
			t.colorSpace = TextureEncoding.SRGB;
			for (i in 0...t.readyCallbacks.length) {
				t.readyCallbacks[i](t);
			}
			t.readyCallbacks = [];
		}, onProgress, onError);
		texture.readyCallbacks = [];
		textures.set(fullPath, texture);
		return texture;
	}

	private function _getRotatedImage(image:html.Image):html.ImageData {
		var canvas = document.createElement("canvas");
		var context = canvas.getContext("2d");
		var width = image.width;
		var height = image.height;
		canvas.width = width;
		canvas.height = height;
		context.clearRect(0,
import three.core.LoadingManager;
import three.loaders.FileLoader;
import three.loaders.LoaderUtils;
import three.materials.ShaderMaterial;
import three.math.Color;
import three.math.Euler;
import three.math.Quaternion;
import three.math.Vector3;
import three.objects.Bone;
import three.objects.Skeleton;
import three.objects.SkinnedMesh;
import three.textures.TextureLoader;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Uint16BufferAttribute;
import three.animation.AnimationClip;
import three.animation.NumberKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.animation.QuaternionKeyframeTrack;
import three.animation.Interpolant;
import three.extras.objects.SkinnedMesh;
import three.renderers.shaders.ShaderLib;
import three.renderers.shaders.UniformsUtils;
import three.constants.BlendingEquation;
import three.constants.BlendingFactorDest;
import three.constants.BlendingFactorSrc;
import three.constants.Side;
import three.constants.Wrapping;
import three.constants.TextureFilter;
import three.constants.TextureEncoding;
import three.constants.TextureFormat;
import three.constants.Mapping;
import three.constants.Combine;
import three.constants.NormalMapTypes;
import three.materials.Material;
import three.materials.MeshBasicMaterial;

import mmd.MMDParser;
import mmd.shaders.MMDToonShader;

class MMDLoader extends three.loaders.Loader {

	public var animationPath:String;
	public var parser:MMDParser.Parser;
	public var meshBuilder:MeshBuilder;
	public var animationBuilder:AnimationBuilder;

	public function new(manager:LoadingManager = null) {
		super(manager);
		this.loader = new FileLoader(this.manager);
		this.parser = null;
		this.meshBuilder = new MeshBuilder(this.manager);
		this.animationBuilder = new AnimationBuilder();
	}

	public function setAnimationPath(animationPath:String):MMDLoader {
		this.animationPath = animationPath;
		return this;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var builder = this.meshBuilder.setCrossOrigin(this.crossOrigin);
		var resourcePath:String;
		if (this.resourcePath != "") {
			resourcePath = this.resourcePath;
		} else if (this.path != "") {
			resourcePath = this.path;
		} else {
			resourcePath = LoaderUtils.extractUrlBase(url);
		}
		var parser = this._getParser();
		var extractModelExtension = this._extractModelExtension;

		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					var modelExtension = extractModelExtension(buffer);
					if (modelExtension != "pmd" && modelExtension != "pmx") {
						if (onError != null) onError(new Error("THREE.MMDLoader: Unknown model file extension ." + modelExtension + "."));
						return;
					}
					var data = modelExtension == "pmd" ? parser.parsePmd(buffer, true) : parser.parsePmx(buffer, true);
					onLoad(builder.build(data, resourcePath, onProgress, onError));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadAnimation(url:Dynamic, object:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var builder = this.animationBuilder;
		this.loadVMD(url, function(vmd:MMDParser.VMD) {
			onLoad(object.isCamera ? builder.buildCameraAnimation(vmd) : builder.build(vmd, object));
		}, onProgress, onError);
	}

	public function loadWithAnimation(modelUrl:String, vmdUrl:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var scope = this;
		this.load(modelUrl, function(mesh:SkinnedMesh) {
			scope.loadAnimation(vmdUrl, mesh, function(animation:AnimationClip) {
				onLoad({
					mesh: mesh,
					animation: animation
				});
			}, onProgress, onError);
		}, onProgress, onError);
	}

	public function loadPMD(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmd(buffer, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadPMX(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmx(buffer, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadVMD(url:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var urls:Array<String> = Std.isOfType(url, Array) ? url : [url];
		var vmds:Array<MMDParser.VMD> = [];
		var vmdNum = urls.length;
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.animationPath)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials);
		for (i in 0...urls.length) {
			this.loader.load(urls[i], function(buffer:haxe.io.Bytes) {
				try {
					vmds.push(parser.parseVmd(buffer, true));
					if (vmds.length == vmdNum) onLoad(parser.mergeVmds(vmds));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
		}
	}

	public function loadVPD(url:String, isUnicode:Bool, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(isUnicode ? null : "text/plain; charset=shift_jis")
			.setPath(this.animationPath)
			.setResponseType("text")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(text:String) {
				try {
					onLoad(parser.parseVpd(text, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	private function _extractModelExtension(buffer:haxe.io.Bytes):String {
		var decoder = new haxe.io.BytesInput(buffer).readString(3);
		return decoder.toLowerCase();
	}

	private function _getParser():MMDParser.Parser {
		if (this.parser == null) {
			this.parser = new MMDParser.Parser();
		}
		return this.parser;
	}

}

class MeshBuilder {

	private var crossOrigin:String;
	private var geometryBuilder:GeometryBuilder;
	private var materialBuilder:MaterialBuilder;

	public function new(manager:LoadingManager) {
		this.crossOrigin = "anonymous";
		this.geometryBuilder = new GeometryBuilder();
		this.materialBuilder = new MaterialBuilder(manager);
	}

	public function setCrossOrigin(crossOrigin:String):MeshBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function build(data:Dynamic, resourcePath:String, onProgress:Dynamic = null, onError:Dynamic = null):SkinnedMesh {
		var geometry = this.geometryBuilder.build(data);
		var material = this.materialBuilder
			.setCrossOrigin(this.crossOrigin)
			.setResourcePath(resourcePath)
			.build(data, geometry, onProgress, onError);
		var mesh = new SkinnedMesh(geometry, material);
		var skeleton = new Skeleton(initBones(mesh));
		mesh.bind(skeleton);
		return mesh;
	}

}

function initBones(mesh:SkinnedMesh):Array<Bone> {
	var geometry = mesh.geometry;
	var bones:Array<Bone> = [];
	if (geometry != null && geometry.bones != null) {
		for (i in 0...geometry.bones.length) {
			var gbone = geometry.bones[i];
			var bone = new Bone();
			bones.push(bone);
			bone.name = gbone.name;
			bone.position.fromArray(gbone.pos);
			bone.quaternion.fromArray(gbone.rotq);
			if (gbone.scl != null) bone.scale.fromArray(gbone.scl);
		}
		for (i in 0...geometry.bones.length) {
			var gbone = geometry.bones[i];
			if (gbone.parent != -1 && gbone.parent != null && bones[gbone.parent] != null) {
				bones[gbone.parent].add(bones[i]);
			} else {
				mesh.add(bones[i]);
			}
		}
	}
	mesh.updateMatrixWorld(true);
	return bones;
}

class GeometryBuilder {

	public function build(data:Dynamic):BufferGeometry {
		var positions:Array<Float> = [];
		var uvs:Array<Float> = [];
		var normals:Array<Float> = [];
		var indices:Array<Int> = [];
		var groups:Array<{offset:Int, count:Int}> = [];
		var bones:Array<{index:Int, transformationClass:Int, parent:Int, name:String, pos:Array<Float>, rotq:Array<Float>, scl:Array<Float>, rigidBodyType:Int}> = [];
		var skinIndices:Array<Float> = [];
		var skinWeights:Array<Float> = [];
		var morphTargets:Array<{name:String}> = [];
		var morphPositions:Array<Float32BufferAttribute> = [];
		var iks:Array<{target:Int, effector:Int, iteration:Int, maxAngle:Float, links:Array<{index:Int, enabled:Bool, limitation:Vector3, rotationMin:Vector3, rotationMax:Vector3}>>} = [];
		var grants:Array<{index:Int, parentIndex:Int, ratio:Float, isLocal:Bool, affectRotation:Bool, affectPosition:Bool, transformationClass:Int}> = [];
		var rigidBodies:Array<Dynamic> = [];
		var constraints:Array<Dynamic> = [];
		var offset:Int = 0;
		var boneTypeTable:Map<Int, Int> = new Map();
		for (i in 0...data.metadata.vertexCount) {
			var v = data.vertices[i];
			for (j in 0...v.position.length) {
				positions.push(v.position[j]);
			}
			for (j in 0...v.normal.length) {
				normals.push(v.normal[j]);
			}
			for (j in 0...v.uv.length) {
				uvs.push(v.uv[j]);
			}
			for (j in 0...4) {
				skinIndices.push(v.skinIndices.length - 1 >= j ? v.skinIndices[j] : 0.0);
			}
			for (j in 0...4) {
				skinWeights.push(v.skinWeights.length - 1 >= j ? v.skinWeights[j] : 0.0);
			}
		}
		for (i in 0...data.metadata.faceCount) {
			var face = data.faces[i];
			for (j in 0...face.indices.length) {
				indices.push(face.indices[j]);
			}
		}
		for (i in 0...data.metadata.materialCount) {
			var material = data.materials[i];
			groups.push({
				offset: offset * 3,
				count: material.faceCount * 3
			});
			offset += material.faceCount;
		}
		for (i in 0...data.metadata.rigidBodyCount) {
			var body = data.rigidBodies[i];
			var value = boneTypeTable.get(body.boneIndex);
			value = value == null ? body.type : Math.max(body.type, value);
			boneTypeTable.set(body.boneIndex, value);
		}
		for (i in 0...data.metadata.boneCount) {
			var boneData = data.bones[i];
			var bone = {
				index: i,
				transformationClass: boneData.transformationClass,
				parent: boneData.parentIndex,
				name: boneData.name,
				pos: boneData.position.slice(0, 3),
				rotq: [0, 0, 0, 1],
				scl: [1, 1, 1],
				rigidBodyType: boneTypeTable.get(i) != null ? boneTypeTable.get(i) : -1
			};
			if (bone.parent != -1) {
				bone.pos[0] -= data.bones[bone.parent].position[0];
				bone.pos[1] -= data.bones[bone.parent].position[1];
				bone.pos[2] -= data.bones[bone.parent].position[2];
			}
			bones.push(bone);
		}
		if (data.metadata.format == "pmd") {
			for (i in 0...data.metadata.ikCount) {
				var ik = data.iks[i];
				var param = {
					target: ik.target,
					effector: ik.effector,
					iteration: ik.iteration,
					maxAngle: ik.maxAngle * 4,
					links: []
				};
				for (j in 0...ik.links.length) {
					var link = {
						index: ik.links[j].index,
						enabled: true,
						limitation: null,
						rotationMin: null,
						rotationMax: null
					};
					if (data.bones[link.index].name.indexOf("ひざ") >= 0) {
						link.limitation = new Vector3(1.0, 0.0, 0.0);
					}
					param.links.push(link);
				}
				iks.push(param);
			}
		} else {
			for (i in 0...data.metadata.boneCount) {
				var ik = data.bones[i].ik;
				if (ik == null) continue;
				var param = {
					target: i,
					effector: ik.effector,
					iteration: ik.iteration,
					maxAngle: ik.maxAngle,
					links: []
				};
				for (j in 0...ik.links.length) {
					var link = {
						index: ik.links[j].index,
						enabled: true,
						limitation: null,
						rotationMin: null,
						rotationMax: null
					};
					if (ik.links[j].angleLimitation == 1) {
						var rotationMin = ik.links[j].lowerLimitationAngle;
						var rotationMax = ik.links[j].upperLimitationAngle;
						var tmp1 = -rotationMax[0];
						var tmp2 = -rotationMax[1];
						rotationMax[0] = -rotationMin[0];
						rotationMax[1] = -rotationMin[1];
						rotationMin[0] = tmp1;
						rotationMin[1] = tmp2;
						link.rotationMin = new Vector3().fromArray(rotationMin);
						link.rotationMax = new Vector3().fromArray(rotationMax);
					}
					param.links.push(link);
				}
				iks.push(param);
				bones[i].ik = param;
			}
		}
		if (data.metadata.format == "pmx") {
			var grantEntryMap:Map<Int, {parent:Dynamic, children:Array<Dynamic>, param:Dynamic, visited:Bool}> = new Map();
			for (i in 0...data.metadata.boneCount) {
				var boneData = data.bones[i];
				var grant = boneData.grant;
				if (grant == null) continue;
				var param = {
					index: i,
					parentIndex: grant.parentIndex,
					ratio: grant.ratio,
					isLocal: grant.isLocal,
					affectRotation: grant.affectRotation,
					affectPosition: grant.affectPosition,
					transformationClass: boneData.transformationClass
				};
				grantEntryMap.set(i, {parent: null, children: [], param: param, visited: false});
			}
			var rootEntry = {parent: null, children: [], param: null, visited: false};
			for (boneIndex in grantEntryMap.keys()) {
				var grantEntry = grantEntryMap.get(boneIndex);
				var parentGrantEntry = grantEntryMap.get(grantEntry.parentIndex) != null ? grantEntryMap.get(grantEntry.parentIndex) : rootEntry;
				grantEntry.parent = parentGrantEntry;
				parentGrantEntry.children.push(grantEntry);
			}
			function traverse(entry) {
				if (entry.param != null) {
					grants.push(entry.param);
					bones[entry.param.index].grant = entry.param;
				}
				entry.visited = true;
				for (i in 0...entry.children.length) {
					var child = entry.children[i];
					if (!child.visited) traverse(child);
				}
			}
			traverse(rootEntry);
		}
		function updateAttributes(attribute:Float32BufferAttribute, morph:Dynamic, ratio:Float) {
			for (i in 0...morph.elementCount) {
				var element = morph.elements[i];
				var index:Int;
				if (data.metadata.format == "pmd") {
					index = data.morphs[0].elements[element.index].index;
				} else {
					index = element.index;
				}
				attribute.array[index * 3 + 0] += element.position[0] * ratio;
				attribute.array[index * 3 + 1] += element.position[1] * ratio;
				attribute.array[index * 3 + 2] += element.position[2] * ratio;
			}
		}
		for (i in 0...data.metadata.morphCount) {
			var morph = data.morphs[i];
			var params = {name: morph.name};
			var attribute = new Float32BufferAttribute(data.metadata.vertexCount * 3, 3);
			attribute.name = morph.name;
			for (j in 0...data.metadata.vertexCount * 3) {
				attribute.array[j] = positions[j];
			}
			if (data.metadata.format == "pmd") {
				if (i != 0) {
					updateAttributes(attribute, morph, 1.0);
				}
			} else {
				if (morph.type == 0) {
					for (j in 0...morph.elementCount) {
						var morph2 = data.morphs[morph.elements[j].index];
						var ratio = morph.elements[j].ratio;
						if (morph2.type == 1) {
							updateAttributes(attribute, morph2, ratio);
						} else {
							// TODO: implement
						}
					}
				} else if (morph.type == 1) {
					updateAttributes(attribute, morph, 1.0);
				} else if (morph.type == 2) {
					// TODO: implement
				} else if (morph.type == 3) {
					// TODO: implement
				} else if (morph.type == 4) {
					// TODO: implement
				} else if (morph.type == 5) {
					// TODO: implement
				} else if (morph.type == 6) {
					// TODO: implement
				} else if (morph.type == 7) {
					// TODO: implement
				} else if (morph.type == 8) {
					// TODO: implement
				}
			}
			morphTargets.push(params);
			morphPositions.push(attribute);
		}
		for (i in 0...data.metadata.rigidBodyCount) {
			var rigidBody = data.rigidBodies[i];
			var params:Dynamic = {};
			for (key in Reflect.fields(rigidBody)) {
				params[key] = rigidBody[key];
			}
			if (data.metadata.format == "pmx") {
				if (params.boneIndex != -1) {
					var bone = data.bones[params.boneIndex];
					params.position[0] -= bone.position[0];
					params.position[1] -= bone.position[1];
					params.position[2] -= bone.position[2];
				}
			}
			rigidBodies.push(params);
		}
		for (i in 0...data.metadata.constraintCount) {
			var constraint = data.constraints[i];
			var params:Dynamic = {};
			for (key in Reflect.fields(constraint)) {
				params[key] = constraint[key];
			}
			var bodyA = rigidBodies[params.rigidBodyIndex1];
			var bodyB = rigidBodies[params.rigidBodyIndex2];
			if (bodyA.type != 0 && bodyB.type == 2) {
				if (bodyA.boneIndex != -1 && bodyB.boneIndex != -1 && data.bones[bodyB.boneIndex].parentIndex == bodyA.boneIndex) {
					bodyB.type = 1;
				}
			}
			constraints.push(params);
		}
		var geometry = new BufferGeometry();
		geometry.setAttribute("position", new Float32BufferAttribute(positions, 3));
		geometry.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		geometry.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
		geometry.setAttribute("skinIndex", new Uint16BufferAttribute(skinIndices, 4));
		geometry.setAttribute("skinWeight", new Float32BufferAttribute(skinWeights, 4));
		geometry.setIndex(indices);
		for (i in 0...groups.length) {
			geometry.addGroup(groups[i].offset, groups[i].count, i);
		}
		geometry.bones = bones;
		geometry.morphTargets = morphTargets;
		geometry.morphAttributes.position = morphPositions;
		geometry.morphTargetsRelative = false;
		geometry.userData.MMD = {
			bones: bones,
			iks: iks,
			grants: grants,
			rigidBodies: rigidBodies,
			constraints: constraints,
			format: data.metadata.format
		};
		geometry.computeBoundingSphere();
		return geometry;
	}

}

class MaterialBuilder {

	private var manager:LoadingManager;
	private var textureLoader:TextureLoader;
	private var tgaLoader:Dynamic;
	private var crossOrigin:String;
	private var resourcePath:String;

	public function new(manager:LoadingManager) {
		this.manager = manager;
		this.textureLoader = new TextureLoader(this.manager);
		this.tgaLoader = null;
		this.crossOrigin = "anonymous";
		this.resourcePath = null;
	}

	public function setCrossOrigin(crossOrigin:String):MaterialBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function setResourcePath(resourcePath:String):MaterialBuilder {
		this.resourcePath = resourcePath;
		return this;
	}

	public function build(data:Dynamic, geometry:BufferGeometry, onProgress:Dynamic = null, onError:Dynamic = null):Array<MMDToonMaterial> {
		var materials:Array<MMDToonMaterial> = [];
		var textures:Map<String, three.textures.Texture> = new Map();
		this.textureLoader.setCrossOrigin(this.crossOrigin);
		for (i in 0...data.metadata.materialCount) {
			var material = data.materials[i];
			var params:Dynamic = {userData: {MMD: {}}};
			if (material.name != null) params.name = material.name;
			params.diffuse = new Color().setRGB(material.diffuse[0], material.diffuse[1], material.diffuse[2], TextureEncoding.SRGB);
			params.opacity = material.diffuse[3];
			params.specular = new Color().setRGB(material.specular[0], material.specular[1], material.specular[2], TextureEncoding.SRGB);
			params.shininess = material.shininess;
			params.emissive = new Color().setRGB(material.ambient[0], material.ambient[1], material.ambient[2], TextureEncoding.SRGB);
			params.transparent = params.opacity != 1.0;
			params.fog = true;
			params.blending = BlendingEquation.CustomBlending;
			params.blendSrc = BlendingFactorSrc.SrcAlphaFactor;
			params.blendDst = BlendingFactorDest.OneMinusSrcAlphaFactor;
			params.blendSrcAlpha = BlendingFactorSrc.SrcAlphaFactor;
			params.blendDstAlpha = BlendingFactorDest.DstAlphaFactor;
			if (data.metadata.format == "pmx" && (material.flag & 0x1) == 1) {
				params.side = Side.DoubleSide;
			} else {
				params.side = params.opacity == 1.0 ? Side.FrontSide : Side.DoubleSide;
			}
			if (data.metadata.format == "pmd") {
				if (material.fileName != null) {
					var fileName = material.fileName;
					var fileNames = fileName.split("*");
					params.map = this._loadTexture(fileNames[0], textures);
					if (fileNames.length > 1) {
						var extension = fileNames[1].slice(-4).toLowerCase();
						params.matcap = this._loadTexture(fileNames[1], textures);
						params.matcapCombine = extension == ".sph" ? Combine.MultiplyOperation : Combine.AddOperation;
					}
				}
				var toonFileName = material.toonIndex == -1 ? "toon00.bmp" : data.toonTextures[material.toonIndex].fileName;
				params.gradientMap = this._loadTexture(toonFileName, textures, {
					isToonTexture: true,
					isDefaultToonTexture: this._isDefaultToonTexture(toonFileName)
				});
				params.userData.outlineParameters = {
					thickness: material.edgeFlag == 1 ? 0.003 : 0.0,
					color: [0, 0, 0],
					alpha: 1.0,
					visible: material.edgeFlag == 1
				};
			} else {
				if (material.textureIndex != -1) {
					params.map = this._loadTexture(data.textures[material.textureIndex], textures);
					params.userData.MMD.mapFileName = data.textures[material.textureIndex];
				}
				if (material.envTextureIndex != -1 && (material.envFlag == 1 || material.envFlag == 2)) {
					params.matcap = this._loadTexture(data.textures[material.envTextureIndex], textures);
					params.userData.MMD.matcapFileName = data.textures[material.envTextureIndex];
					params.matcapCombine = material.envFlag == 1 ? Combine.MultiplyOperation : Combine.AddOperation;
				}
				var toonFileName:String;
				var isDefaultToon:Bool;
				if (material.toonIndex == -1 || material.toonFlag != 0) {
					toonFileName = "toon" + ("0" + (material.toonIndex + 1)).slice(-2) + ".bmp";
					isDefaultToon = true;
				} else {
					toonFileName = data.textures[material.toonIndex];
					isDefaultToon = false;
				}
				params.gradientMap = this._loadTexture(toonFileName, textures, {
					isToonTexture: true,
					isDefaultToonTexture: isDefaultToon
				});
				params.userData.outlineParameters = {
					thickness: material.edgeSize / 300,
					color: material.edgeColor.slice(0, 3),
					alpha: material.edgeColor[3],
					visible: (material.flag & 0x10) != 0 && material.edgeSize > 0.0
				};
			}
			if (params.map != null) {
				if (!params.transparent) {
					this._checkImageTransparency(params.map, geometry, i);
				}
				params.emissive.multiplyScalar(0.2);
			}
			materials.push(new MMDToonMaterial(params));
		}
		if (data.metadata.format == "pmx") {
			function checkAlphaMorph(elements:Array<Dynamic>, materials:Array<MMDToonMaterial>) {
				for (i in 0...elements.length) {
					var element = elements[i];
					if (element.index == -1) continue;
					var material = materials[element.index];
					if (material.opacity != element.diffuse[3]) {
						material.transparent = true;
					}
				}
			}
			for (i in 0...data.morphs.length) {
				var morph = data.morphs[i];
				var elements = morph.elements;
				if (morph.type == 0) {
					for (j in 0...elements.length) {
						var morph2 = data.morphs[elements[j].index];
						if (morph2.type != 8) continue;
						checkAlphaMorph(morph2.elements, materials);
					}
				} else if (morph.type == 8) {
					checkAlphaMorph(elements, materials);
				}
			}
		}
		return materials;
	}

	private function _getTGALoader():Dynamic {
		if (this.tgaLoader == null) {
			throw new Error("THREE.MMDLoader: Import TGALoader");
		}
		return this.tgaLoader;
	}

	private function _isDefaultToonTexture(name:String):Bool {
		if (name.length != 10) return false;
		return /toon(10|0[0-9])\.bmp/.test(name);
	}

	private function _loadTexture(filePath:String, textures:Map<String, three.textures.Texture>, params:Dynamic = null, onProgress:Dynamic = null, onError:Dynamic = null):three.textures.Texture {
		params = params != null ? params : {};
		var scope = this;
		var fullPath:String;
		if (params.isDefaultToonTexture == true) {
			var index:Int;
			try {
				index = Std.parseInt(filePath.match(/toon([0-9]{2})\.bmp$/)[1]);
			} catch (e:Dynamic) {
				js.Lib.warn("THREE.MMDLoader: " + filePath + " seems like a " + "not right default texture path. Using toon00.bmp instead.");
				index = 0;
			}
			fullPath = DEFAULT_TOON_TEXTURES[index];
		} else {
			fullPath = this.resourcePath + filePath;
		}
		if (textures.exists(fullPath)) return textures.get(fullPath);
		var loader = this.manager.getHandler(fullPath);
		if (loader == null) {
			loader = filePath.slice(-4).toLowerCase() == ".tga" ? this._getTGALoader() : this.textureLoader;
		}
		var texture = loader.load(fullPath, function(t:three.textures.Texture) {
			if (params.isToonTexture == true) {
				t.image = scope._getRotatedImage(t.image);
				t.magFilter = TextureFilter.NearestFilter;
				t.minFilter = TextureFilter.NearestFilter;
			}
			t.flipY = false;
			t.wrapS = Wrapping.RepeatWrapping;
			t.wrapT = Wrapping.RepeatWrapping;
			t.colorSpace = TextureEncoding.SRGB;
			for (i in 0...t.readyCallbacks.length) {
				t.readyCallbacks[i](t);
			}
			t.readyCallbacks = [];
		}, onProgress, onError);
		texture.readyCallbacks = [];
		textures.set(fullPath, texture);
		return texture;
	}

	private function _getRotatedImage(image:html.Image):html.ImageData {
		var canvas = document.createElement("canvas");
		var context = canvas.getContext("2d");
		var width = image.width;
		var height = image.height;
		canvas.width = width;
		canvas.height = height;
		context.clearRect(0,
import three.core.LoadingManager;
import three.loaders.FileLoader;
import three.loaders.LoaderUtils;
import three.materials.ShaderMaterial;
import three.math.Color;
import three.math.Euler;
import three.math.Quaternion;
import three.math.Vector3;
import three.objects.Bone;
import three.objects.Skeleton;
import three.objects.SkinnedMesh;
import three.textures.TextureLoader;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Uint16BufferAttribute;
import three.animation.AnimationClip;
import three.animation.NumberKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.animation.QuaternionKeyframeTrack;
import three.animation.Interpolant;
import three.extras.objects.SkinnedMesh;
import three.renderers.shaders.ShaderLib;
import three.renderers.shaders.UniformsUtils;
import three.constants.BlendingEquation;
import three.constants.BlendingFactorDest;
import three.constants.BlendingFactorSrc;
import three.constants.Side;
import three.constants.Wrapping;
import three.constants.TextureFilter;
import three.constants.TextureEncoding;
import three.constants.TextureFormat;
import three.constants.Mapping;
import three.constants.Combine;
import three.constants.NormalMapTypes;
import three.materials.Material;
import three.materials.MeshBasicMaterial;

import mmd.MMDParser;
import mmd.shaders.MMDToonShader;

class MMDLoader extends three.loaders.Loader {

	public var animationPath:String;
	public var parser:MMDParser.Parser;
	public var meshBuilder:MeshBuilder;
	public var animationBuilder:AnimationBuilder;

	public function new(manager:LoadingManager = null) {
		super(manager);
		this.loader = new FileLoader(this.manager);
		this.parser = null;
		this.meshBuilder = new MeshBuilder(this.manager);
		this.animationBuilder = new AnimationBuilder();
	}

	public function setAnimationPath(animationPath:String):MMDLoader {
		this.animationPath = animationPath;
		return this;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var builder = this.meshBuilder.setCrossOrigin(this.crossOrigin);
		var resourcePath:String;
		if (this.resourcePath != "") {
			resourcePath = this.resourcePath;
		} else if (this.path != "") {
			resourcePath = this.path;
		} else {
			resourcePath = LoaderUtils.extractUrlBase(url);
		}
		var parser = this._getParser();
		var extractModelExtension = this._extractModelExtension;

		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					var modelExtension = extractModelExtension(buffer);
					if (modelExtension != "pmd" && modelExtension != "pmx") {
						if (onError != null) onError(new Error("THREE.MMDLoader: Unknown model file extension ." + modelExtension + "."));
						return;
					}
					var data = modelExtension == "pmd" ? parser.parsePmd(buffer, true) : parser.parsePmx(buffer, true);
					onLoad(builder.build(data, resourcePath, onProgress, onError));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadAnimation(url:Dynamic, object:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var builder = this.animationBuilder;
		this.loadVMD(url, function(vmd:MMDParser.VMD) {
			onLoad(object.isCamera ? builder.buildCameraAnimation(vmd) : builder.build(vmd, object));
		}, onProgress, onError);
	}

	public function loadWithAnimation(modelUrl:String, vmdUrl:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var scope = this;
		this.load(modelUrl, function(mesh:SkinnedMesh) {
			scope.loadAnimation(vmdUrl, mesh, function(animation:AnimationClip) {
				onLoad({
					mesh: mesh,
					animation: animation
				});
			}, onProgress, onError);
		}, onProgress, onError);
	}

	public function loadPMD(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmd(buffer, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadPMX(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmx(buffer, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadVMD(url:Dynamic, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var urls:Array<String> = Std.isOfType(url, Array) ? url : [url];
		var vmds:Array<MMDParser.VMD> = [];
		var vmdNum = urls.length;
		var parser = this._getParser();
		this.loader
			.setMimeType(null)
			.setPath(this.animationPath)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials);
		for (i in 0...urls.length) {
			this.loader.load(urls[i], function(buffer:haxe.io.Bytes) {
				try {
					vmds.push(parser.parseVmd(buffer, true));
					if (vmds.length == vmdNum) onLoad(parser.mergeVmds(vmds));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
		}
	}

	public function loadVPD(url:String, isUnicode:Bool, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		var parser = this._getParser();
		this.loader
			.setMimeType(isUnicode ? null : "text/plain; charset=shift_jis")
			.setPath(this.animationPath)
			.setResponseType("text")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(text:String) {
				try {
					onLoad(parser.parseVpd(text, true));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	private function _extractModelExtension(buffer:haxe.io.Bytes):String {
		var decoder = new haxe.io.BytesInput(buffer).readString(3);
		return decoder.toLowerCase();
	}

	private function _getParser():MMDParser.Parser {
		if (this.parser == null) {
			this.parser = new MMDParser.Parser();
		}
		return this.parser;
	}

}

class MeshBuilder {

	private var crossOrigin:String;
	private var geometryBuilder:GeometryBuilder;
	private var materialBuilder:MaterialBuilder;

	public function new(manager:LoadingManager) {
		this.crossOrigin = "anonymous";
		this.geometryBuilder = new GeometryBuilder();
		this.materialBuilder = new MaterialBuilder(manager);
	}

	public function setCrossOrigin(crossOrigin:String):MeshBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function build(data:Dynamic, resourcePath:String, onProgress:Dynamic = null, onError:Dynamic = null):SkinnedMesh {
		var geometry = this.geometryBuilder.build(data);
		var material = this.materialBuilder
			.setCrossOrigin(this.crossOrigin)
			.setResourcePath(resourcePath)
			.build(data, geometry, onProgress, onError);
		var mesh = new SkinnedMesh(geometry, material);
		var skeleton = new Skeleton(initBones(mesh));
		mesh.bind(skeleton);
		return mesh;
	}

}

function initBones(mesh:SkinnedMesh):Array<Bone> {
	var geometry = mesh.geometry;
	var bones:Array<Bone> = [];
	if (geometry != null && geometry.bones != null) {
		for (i in 0...geometry.bones.length) {
			var gbone = geometry.bones[i];
			var bone = new Bone();
			bones.push(bone);
			bone.name = gbone.name;
			bone.position.fromArray(gbone.pos);
			bone.quaternion.fromArray(gbone.rotq);
			if (gbone.scl != null) bone.scale.fromArray(gbone.scl);
		}
		for (i in 0...geometry.bones.length) {
			var gbone = geometry.bones[i];
			if (gbone.parent != -1 && gbone.parent != null && bones[gbone.parent] != null) {
				bones[gbone.parent].add(bones[i]);
			} else {
				mesh.add(bones[i]);
			}
		}
	}
	mesh.updateMatrixWorld(true);
	return bones;
}

class GeometryBuilder {

	public function build(data:Dynamic):BufferGeometry {
		var positions:Array<Float> = [];
		var uvs:Array<Float> = [];
		var normals:Array<Float> = [];
		var indices:Array<Int> = [];
		var groups:Array<{offset:Int, count:Int}> = [];
		var bones:Array<{index:Int, transformationClass:Int, parent:Int, name:String, pos:Array<Float>, rotq:Array<Float>, scl:Array<Float>, rigidBodyType:Int}> = [];
		var skinIndices:Array<Float> = [];
		var skinWeights:Array<Float> = [];
		var morphTargets:Array<{name:String}> = [];
		var morphPositions:Array<Float32BufferAttribute> = [];
		var iks:Array<{target:Int, effector:Int, iteration:Int, maxAngle:Float, links:Array<{index:Int, enabled:Bool, limitation:Vector3, rotationMin:Vector3, rotationMax:Vector3}>>} = [];
		var grants:Array<{index:Int, parentIndex:Int, ratio:Float, isLocal:Bool, affectRotation:Bool, affectPosition:Bool, transformationClass:Int}> = [];
		var rigidBodies:Array<Dynamic> = [];
		var constraints:Array<Dynamic> = [];
		var offset:Int = 0;
		var boneTypeTable:Map<Int, Int> = new Map();
		for (i in 0...data.metadata.vertexCount) {
			var v = data.vertices[i];
			for (j in 0...v.position.length) {
				positions.push(v.position[j]);
			}
			for (j in 0...v.normal.length) {
				normals.push(v.normal[j]);
			}
			for (j in 0...v.uv.length) {
				uvs.push(v.uv[j]);
			}
			for (j in 0...4) {
				skinIndices.push(v.skinIndices.length - 1 >= j ? v.skinIndices[j] : 0.0);
			}
			for (j in 0...4) {
				skinWeights.push(v.skinWeights.length - 1 >= j ? v.skinWeights[j] : 0.0);
			}
		}
		for (i in 0...data.metadata.faceCount) {
			var face = data.faces[i];
			for (j in 0...face.indices.length) {
				indices.push(face.indices[j]);
			}
		}
		for (i in 0...data.metadata.materialCount) {
			var material = data.materials[i];
			groups.push({
				offset: offset * 3,
				count: material.faceCount * 3
			});
			offset += material.faceCount;
		}
		for (i in 0...data.metadata.rigidBodyCount) {
			var body = data.rigidBodies[i];
			var value = boneTypeTable.get(body.boneIndex);
			value = value == null ? body.type : Math.max(body.type, value);
			boneTypeTable.set(body.boneIndex, value);
		}
		for (i in 0...data.metadata.boneCount) {
			var boneData = data.bones[i];
			var bone = {
				index: i,
				transformationClass: boneData.transformationClass,
				parent: boneData.parentIndex,
				name: boneData.name,
				pos: boneData.position.slice(0, 3),
				rotq: [0, 0, 0, 1],
				scl: [1, 1, 1],
				rigidBodyType: boneTypeTable.get(i) != null ? boneTypeTable.get(i) : -1
			};
			if (bone.parent != -1) {
				bone.pos[0] -= data.bones[bone.parent].position[0];
				bone.pos[1] -= data.bones[bone.parent].position[1];
				bone.pos[2] -= data.bones[bone.parent].position[2];
			}
			bones.push(bone);
		}
		if (data.metadata.format == "pmd") {
			for (i in 0...data.metadata.ikCount) {
				var ik = data.iks[i];
				var param = {
					target: ik.target,
					effector: ik.effector,
					iteration: ik.iteration,
					maxAngle: ik.maxAngle * 4,
					links: []
				};
				for (j in 0...ik.links.length) {
					var link = {
						index: ik.links[j].index,
						enabled: true,
						limitation: null,
						rotationMin: null,
						rotationMax: null
					};
					if (data.bones[link.index].name.indexOf("ひざ") >= 0) {
						link.limitation = new Vector3(1.0, 0.0, 0.0);
					}
					param.links.push(link);
				}
				iks.push(param);
			}
		} else {
			for (i in 0...data.metadata.boneCount) {
				var ik = data.bones[i].ik;
				if (ik == null) continue;
				var param = {
					target: i,
					effector: ik.effector,
					iteration: ik.iteration,
					maxAngle: ik.maxAngle,
					links: []
				};
				for (j in 0...ik.links.length) {
					var link = {
						index: ik.links[j].index,
						enabled: true,
						limitation: null,
						rotationMin: null,
						rotationMax: null
					};
					if (ik.links[j].angleLimitation == 1) {
						var rotationMin = ik.links[j].lowerLimitationAngle;
						var rotationMax = ik.links[j].upperLimitationAngle;
						var tmp1 = -rotationMax[0];
						var tmp2 = -rotationMax[1];
						rotationMax[0] = -rotationMin[0];
						rotationMax[1] = -rotationMin[1];
						rotationMin[0] = tmp1;
						rotationMin[1] = tmp2;
						link.rotationMin = new Vector3().fromArray(rotationMin);
						link.rotationMax = new Vector3().fromArray(rotationMax);
					}
					param.links.push(link);
				}
				iks.push(param);
				bones[i].ik = param;
			}
		}
		if (data.metadata.format == "pmx") {
			var grantEntryMap:Map<Int, {parent:Dynamic, children:Array<Dynamic>, param:Dynamic, visited:Bool}> = new Map();
			for (i in 0...data.metadata.boneCount) {
				var boneData = data.bones[i];
				var grant = boneData.grant;
				if (grant == null) continue;
				var param = {
					index: i,
					parentIndex: grant.parentIndex,
					ratio: grant.ratio,
					isLocal: grant.isLocal,
					affectRotation: grant.affectRotation,
					affectPosition: grant.affectPosition,
					transformationClass: boneData.transformationClass
				};
				grantEntryMap.set(i, {parent: null, children: [], param: param, visited: false});
			}
			var rootEntry = {parent: null, children: [], param: null, visited: false};
			for (boneIndex in grantEntryMap.keys()) {
				var grantEntry = grantEntryMap.get(boneIndex);
				var parentGrantEntry = grantEntryMap.get(grantEntry.parentIndex) != null ? grantEntryMap.get(grantEntry.parentIndex) : rootEntry;
				grantEntry.parent = parentGrantEntry;
				parentGrantEntry.children.push(grantEntry);
			}
			function traverse(entry) {
				if (entry.param != null) {
					grants.push(entry.param);
					bones[entry.param.index].grant = entry.param;
				}
				entry.visited = true;
				for (i in 0...entry.children.length) {
					var child = entry.children[i];
					if (!child.visited) traverse(child);
				}
			}
			traverse(rootEntry);
		}
		function updateAttributes(attribute:Float32BufferAttribute, morph:Dynamic, ratio:Float) {
			for (i in 0...morph.elementCount) {
				var element = morph.elements[i];
				var index:Int;
				if (data.metadata.format == "pmd") {
					index = data.morphs[0].elements[element.index].index;
				} else {
					index = element.index;
				}
				attribute.array[index * 3 + 0] += element.position[0] * ratio;
				attribute.array[index * 3 + 1] += element.position[1] * ratio;
				attribute.array[index * 3 + 2] += element.position[2] * ratio;
			}
		}
		for (i in 0...data.metadata.morphCount) {
			var morph = data.morphs[i];
			var params = {name: morph.name};
			var attribute = new Float32BufferAttribute(data.metadata.vertexCount * 3, 3);
			attribute.name = morph.name;
			for (j in 0...data.metadata.vertexCount * 3) {
				attribute.array[j] = positions[j];
			}
			if (data.metadata.format == "pmd") {
				if (i != 0) {
					updateAttributes(attribute, morph, 1.0);
				}
			} else {
				if (morph.type == 0) {
					for (j in 0...morph.elementCount) {
						var morph2 = data.morphs[morph.elements[j].index];
						var ratio = morph.elements[j].ratio;
						if (morph2.type == 1) {
							updateAttributes(attribute, morph2, ratio);
						} else {
							// TODO: implement
						}
					}
				} else if (morph.type == 1) {
					updateAttributes(attribute, morph, 1.0);
				} else if (morph.type == 2) {
					// TODO: implement
				} else if (morph.type == 3) {
					// TODO: implement
				} else if (morph.type == 4) {
					// TODO: implement
				} else if (morph.type == 5) {
					// TODO: implement
				} else if (morph.type == 6) {
					// TODO: implement
				} else if (morph.type == 7) {
					// TODO: implement
				} else if (morph.type == 8) {
					// TODO: implement
				}
			}
			morphTargets.push(params);
			morphPositions.push(attribute);
		}
		for (i in 0...data.metadata.rigidBodyCount) {
			var rigidBody = data.rigidBodies[i];
			var params:Dynamic = {};
			for (key in Reflect.fields(rigidBody)) {
				params[key] = rigidBody[key];
			}
			if (data.metadata.format == "pmx") {
				if (params.boneIndex != -1) {
					var bone = data.bones[params.boneIndex];
					params.position[0] -= bone.position[0];
					params.position[1] -= bone.position[1];
					params.position[2] -= bone.position[2];
				}
			}
			rigidBodies.push(params);
		}
		for (i in 0...data.metadata.constraintCount) {
			var constraint = data.constraints[i];
			var params:Dynamic = {};
			for (key in Reflect.fields(constraint)) {
				params[key] = constraint[key];
			}
			var bodyA = rigidBodies[params.rigidBodyIndex1];
			var bodyB = rigidBodies[params.rigidBodyIndex2];
			if (bodyA.type != 0 && bodyB.type == 2) {
				if (bodyA.boneIndex != -1 && bodyB.boneIndex != -1 && data.bones[bodyB.boneIndex].parentIndex == bodyA.boneIndex) {
					bodyB.type = 1;
				}
			}
			constraints.push(params);
		}
		var geometry = new BufferGeometry();
		geometry.setAttribute("position", new Float32BufferAttribute(positions, 3));
		geometry.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		geometry.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
		geometry.setAttribute("skinIndex", new Uint16BufferAttribute(skinIndices, 4));
		geometry.setAttribute("skinWeight", new Float32BufferAttribute(skinWeights, 4));
		geometry.setIndex(indices);
		for (i in 0...groups.length) {
			geometry.addGroup(groups[i].offset, groups[i].count, i);
		}
		geometry.bones = bones;
		geometry.morphTargets = morphTargets;
		geometry.morphAttributes.position = morphPositions;
		geometry.morphTargetsRelative = false;
		geometry.userData.MMD = {
			bones: bones,
			iks: iks,
			grants: grants,
			rigidBodies: rigidBodies,
			constraints: constraints,
			format: data.metadata.format
		};
		geometry.computeBoundingSphere();
		return geometry;
	}

}

class MaterialBuilder {

	private var manager:LoadingManager;
	private var textureLoader:TextureLoader;
	private var tgaLoader:Dynamic;
	private var crossOrigin:String;
	private var resourcePath:String;

	public function new(manager:LoadingManager) {
		this.manager = manager;
		this.textureLoader = new TextureLoader(this.manager);
		this.tgaLoader = null;
		this.crossOrigin = "anonymous";
		this.resourcePath = null;
	}

	public function setCrossOrigin(crossOrigin:String):MaterialBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function setResourcePath(resourcePath:String):MaterialBuilder {
		this.resourcePath = resourcePath;
		return this;
	}

	public function build(data:Dynamic, geometry:BufferGeometry, onProgress:Dynamic = null, onError:Dynamic = null):Array<MMDToonMaterial> {
		var materials:Array<MMDToonMaterial> = [];
		var textures:Map<String, three.textures.Texture> = new Map();
		this.textureLoader.setCrossOrigin(this.crossOrigin);
		for (i in 0...data.metadata.materialCount) {
			var material = data.materials[i];
			var params:Dynamic = {userData: {MMD: {}}};
			if (material.name != null) params.name = material.name;
			params.diffuse = new Color().setRGB(material.diffuse[0], material.diffuse[1], material.diffuse[2], TextureEncoding.SRGB);
			params.opacity = material.diffuse[3];
			params.specular = new Color().setRGB(material.specular[0], material.specular[1], material.specular[2], TextureEncoding.SRGB);
			params.shininess = material.shininess;
			params.emissive = new Color().setRGB(material.ambient[0], material.ambient[1], material.ambient[2], TextureEncoding.SRGB);
			params.transparent = params.opacity != 1.0;
			params.fog = true;
			params.blending = BlendingEquation.CustomBlending;
			params.blendSrc = BlendingFactorSrc.SrcAlphaFactor;
			params.blendDst = BlendingFactorDest.OneMinusSrcAlphaFactor;
			params.blendSrcAlpha = BlendingFactorSrc.SrcAlphaFactor;
			params.blendDstAlpha = BlendingFactorDest.DstAlphaFactor;
			if (data.metadata.format == "pmx" && (material.flag & 0x1) == 1) {
				params.side = Side.DoubleSide;
			} else {
				params.side = params.opacity == 1.0 ? Side.FrontSide : Side.DoubleSide;
			}
			if (data.metadata.format == "pmd") {
				if (material.fileName != null) {
					var fileName = material.fileName;
					var fileNames = fileName.split("*");
					params.map = this._loadTexture(fileNames[0], textures);
					if (fileNames.length > 1) {
						var extension = fileNames[1].slice(-4).toLowerCase();
						params.matcap = this._loadTexture(fileNames[1], textures);
						params.matcapCombine = extension == ".sph" ? Combine.MultiplyOperation : Combine.AddOperation;
					}
				}
				var toonFileName = material.toonIndex == -1 ? "toon00.bmp" : data.toonTextures[material.toonIndex].fileName;
				params.gradientMap = this._loadTexture(toonFileName, textures, {
					isToonTexture: true,
					isDefaultToonTexture: this._isDefaultToonTexture(toonFileName)
				});
				params.userData.outlineParameters = {
					thickness: material.edgeFlag == 1 ? 0.003 : 0.0,
					color: [0, 0, 0],
					alpha: 1.0,
					visible: material.edgeFlag == 1
				};
			} else {
				if (material.textureIndex != -1) {
					params.map = this._loadTexture(data.textures[material.textureIndex], textures);
					params.userData.MMD.mapFileName = data.textures[material.textureIndex];
				}
				if (material.envTextureIndex != -1 && (material.envFlag == 1 || material.envFlag == 2)) {
					params.matcap = this._loadTexture(data.textures[material.envTextureIndex], textures);
					params.userData.MMD.matcapFileName = data.textures[material.envTextureIndex];
					params.matcapCombine = material.envFlag == 1 ? Combine.MultiplyOperation : Combine.AddOperation;
				}
				var toonFileName:String;
				var isDefaultToon:Bool;
				if (material.toonIndex == -1 || material.toonFlag != 0) {
					toonFileName = "toon" + ("0" + (material.toonIndex + 1)).slice(-2) + ".bmp";
					isDefaultToon = true;
				} else {
					toonFileName = data.textures[material.toonIndex];
					isDefaultToon = false;
				}
				params.gradientMap = this._loadTexture(toonFileName, textures, {
					isToonTexture: true,
					isDefaultToonTexture: isDefaultToon
				});
				params.userData.outlineParameters = {
					thickness: material.edgeSize / 300,
					color: material.edgeColor.slice(0, 3),
					alpha: material.edgeColor[3],
					visible: (material.flag & 0x10) != 0 && material.edgeSize > 0.0
				};
			}
			if (params.map != null) {
				if (!params.transparent) {
					this._checkImageTransparency(params.map, geometry, i);
				}
				params.emissive.multiplyScalar(0.2);
			}
			materials.push(new MMDToonMaterial(params));
		}
		if (data.metadata.format == "pmx") {
			function checkAlphaMorph(elements:Array<Dynamic>, materials:Array<MMDToonMaterial>) {
				for (i in 0...elements.length) {
					var element = elements[i];
					if (element.index == -1) continue;
					var material = materials[element.index];
					if (material.opacity != element.diffuse[3]) {
						material.transparent = true;
					}
				}
			}
			for (i in 0...data.morphs.length) {
				var morph = data.morphs[i];
				var elements = morph.elements;
				if (morph.type == 0) {
					for (j in 0...elements.length) {
						var morph2 = data.morphs[elements[j].index];
						if (morph2.type != 8) continue;
						checkAlphaMorph(morph2.elements, materials);
					}
				} else if (morph.type == 8) {
					checkAlphaMorph(elements, materials);
				}
			}
		}
		return materials;
	}

	private function _getTGALoader():Dynamic {
		if (this.tgaLoader == null) {
			throw new Error("THREE.MMDLoader: Import TGALoader");
		}
		return this.tgaLoader;
	}

	private function _isDefaultToonTexture(name:String):Bool {
		if (name.length != 10) return false;
		return /toon(10|0[0-9])\.bmp/.test(name);
	}

	private function _loadTexture(filePath:String, textures:Map<String, three.textures.Texture>, params:Dynamic = null, onProgress:Dynamic = null, onError:Dynamic = null):three.textures.Texture {
		params = params != null ? params : {};
		var scope = this;
		var fullPath:String;
		if (params.isDefaultToonTexture == true) {
			var index:Int;
			try {
				index = Std.parseInt(filePath.match(/toon([0-9]{2})\.bmp$/)[1]);
			} catch (e:Dynamic) {
				js.Lib.warn("THREE.MMDLoader: " + filePath + " seems like a " + "not right default texture path. Using toon00.bmp instead.");
				index = 0;
			}
			fullPath = DEFAULT_TOON_TEXTURES[index];
		} else {
			fullPath = this.resourcePath + filePath;
		}
		if (textures.exists(fullPath)) return textures.get(fullPath);
		var loader = this.manager.getHandler(fullPath);
		if (loader == null) {
			loader = filePath.slice(-4).toLowerCase() == ".tga" ? this._getTGALoader() : this.textureLoader;
		}
		var texture = loader.load(fullPath, function(t:three.textures.Texture) {
			if (params.isToonTexture == true) {
				t.image = scope._getRotatedImage(t.image);
				t.magFilter = TextureFilter.NearestFilter;
				t.minFilter = TextureFilter.NearestFilter;
			}
			t.flipY = false;
			t.wrapS = Wrapping.RepeatWrapping;
			t.wrapT = Wrapping.RepeatWrapping;
			t.colorSpace = TextureEncoding.SRGB;
			for (i in 0...t.readyCallbacks.length) {
				t.readyCallbacks[i](t);
			}
			t.readyCallbacks = [];
		}, onProgress, onError);
		texture.readyCallbacks = [];
		textures.set(fullPath, texture);
		return texture;
	}

	private function _getRotatedImage(image:html.Image):html.ImageData {
		var canvas = document.createElement("canvas");
		var context = canvas.getContext("2d");
		var width = image.width;
		var height = image.height;
		canvas.width = width;
		canvas.height = height;
		context.clearRect(0,