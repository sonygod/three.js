import haxe.io.Bytes;
import haxe.io.StringTools;
import haxe.xml.Xml;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import three.extras.core.AnimationClip;
import three.extras.core.AnimationAction;
import three.extras.core.KeyframeTrack;
import three.extras.core.VectorKeyframeTrack;
import three.extras.core.QuaternionKeyframeTrack;
import three.extras.loaders.FileLoader;
import three.extras.loaders.TextureLoader;
import three.extras.loaders.TGALoader;
import three.core.Object3D;
import three.core.Scene;
import three.core.Group;
import three.core.Bone;
import three.core.Mesh;
import three.core.SkinnedMesh;
import three.core.LineSegments;
import three.core.Line;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Skeleton;
import three.math.Color;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Matrix4;
import three.materials.MeshBasicMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.LineBasicMaterial;
import three.textures.Texture;
import three.textures.RepeatWrapping;
import three.textures.ClampToEdgeWrapping;
import three.textures.SRGBColorSpace;

class ColladaLoader {

	public var manager:FileLoader;
	public var path:String = "";
	public var resourcePath:String = "";
	public var crossOrigin:String = null;
	public var requestHeader:StringMap<String> = new StringMap<String>();
	public var withCredentials:Bool = false;

	public function new(manager:FileLoader) {
		this.manager = manager;
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(parse(text, path));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				this.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String, path:String):Dynamic {
		var count = 0;
		var tempColor = new Color();
		var animations:Array<AnimationClip> = [];
		var kinematics:Dynamic = {};

		var library:Dynamic = {
			animations: new StringMap<Dynamic>(),
			clips: new StringMap<Dynamic>(),
			controllers: new StringMap<Dynamic>(),
			images: new StringMap<Dynamic>(),
			effects: new StringMap<Dynamic>(),
			materials: new StringMap<Dynamic>(),
			cameras: new StringMap<Dynamic>(),
			lights: new StringMap<Dynamic>(),
			geometries: new StringMap<Dynamic>(),
			nodes: new StringMap<Dynamic>(),
			visualScenes: new StringMap<Dynamic>(),
			kinematicsModels: new StringMap<Dynamic>(),
			physicsModels: new StringMap<Dynamic>(),
			kinematicsScenes: new StringMap<Dynamic>()
		};

		if (text.length == 0) {
			return { scene: new Scene() };
		}

		var xml:Xml = Xml.parse(text);

		var collada = getElementsByTagName(xml, "COLLADA")[0];

		var parserError = xml.firstElement("parsererror");
		if (parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText:String;

			if (errorElement != null) {
				errorText = errorElement.get("textContent");
			} else {
				errorText = parserErrorToText(parserError);
			}

			console.error("THREE.ColladaLoader: Failed to parse collada file.\n", errorText);
			return null;
		}

		var version = collada.get("version");
		console.debug("THREE.ColladaLoader: File version", version);

		var asset = parseAsset(getElementsByTagName(collada, "asset")[0]);
		var textureLoader = new TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		textureLoader.setCrossOrigin(this.crossOrigin);

		var tgaLoader:TGALoader;

		if (TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}

		parseLibrary(collada, "library_animations", "animation", parseAnimation);
		parseLibrary(collada, "library_animation_clips", "animation_clip", parseAnimationClip);
		parseLibrary(collada, "library_controllers", "controller", parseController);
		parseLibrary(collada, "library_images", "image", parseImage);
		parseLibrary(collada, "library_effects", "effect", parseEffect);
		parseLibrary(collada, "library_materials", "material", parseMaterial);
		parseLibrary(collada, "library_cameras", "camera", parseCamera);
		parseLibrary(collada, "library_lights", "light", parseLight);
		parseLibrary(collada, "library_geometries", "geometry", parseGeometry);
		parseLibrary(collada, "library_nodes", "node", parseNode);
		parseLibrary(collada, "library_visual_scenes", "visual_scene", parseVisualScene);
		parseLibrary(collada, "library_kinematics_models", "kinematics_model", parseKinematicsModel);
		parseLibrary(collada, "library_physics_models", "physics_model", parsePhysicsModel);
		parseLibrary(collada, "scene", "instance_kinematics_scene", parseKinematicsScene);

		buildLibrary(library.animations, buildAnimation);
		buildLibrary(library.clips, buildAnimationClip);
		buildLibrary(library.controllers, buildController);
		buildLibrary(library.images, buildImage);
		buildLibrary(library.effects, buildEffect);
		buildLibrary(library.materials, buildMaterial);
		buildLibrary(library.cameras, buildCamera);
		buildLibrary(library.lights, buildLight);
		buildLibrary(library.geometries, buildGeometry);
		buildLibrary(library.visualScenes, buildVisualScene);

		setupAnimations();
		setupKinematics();

		var scene = parseScene(getElementsByTagName(collada, "scene")[0]);
		scene.animations = animations;

		if (asset.upAxis == "Z_UP") {
			console.warn("THREE.ColladaLoader: You are loading an asset with a Z-UP coordinate system. The loader just rotates the asset to transform it into Y-UP. The vertex data are not converted, see #24289.");
			scene.rotation.set(-Math.PI / 2, 0, 0);
		}

		scene.scale.multiplyScalar(asset.unit);

		return {
			get animations() {
				console.warn("THREE.ColladaLoader: Please access animations over scene.animations now.");
				return animations;
			},
			kinematics: kinematics,
			library: library,
			scene: scene
		};
	}

	public function getElementsByTagName(xml:Xml, tagName:String):Array<Xml> {
		var result:Array<Xml> = [];
		for (element in xml.elements()) {
			if (element.nodeName == tagName) {
				result.push(element);
			}
		}
		return result;
	}

	public function parserErrorToText(parserError:Xml):String {
		var result:String = "";
		var stack:Array<Xml> = [parserError];

		while (stack.length > 0) {
			var node = stack.shift();
			if (node.nodeType == Xml.TEXT_NODE) {
				result += node.get("textContent");
			} else {
				result += "\n";
				stack.push(node.elements());
			}
		}

		return result.trim();
	}

	public function parseAsset(xml:Xml):Dynamic {
		return {
			unit: parseAssetUnit(xml.firstElement("unit")),
			upAxis: parseAssetUpAxis(xml.firstElement("up_axis"))
		};
	}

	public function parseAssetUnit(xml:Xml):Float {
		if (xml != null && xml.hasAttribute("meter")) {
			return Std.parseFloat(xml.get("meter"));
		} else {
			return 1;
		}
	}

	public function parseAssetUpAxis(xml:Xml):String {
		return xml != null ? xml.get("textContent") : "Y_UP";
	}

	public function parseLibrary(xml:Xml, libraryName:String, nodeName:String, parser:Xml->Void):Void {
		var library = xml.firstElement(libraryName);
		if (library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for (i in 0...elements.length) {
				parser(elements[i]);
			}
		}
	}

	public function buildLibrary(data:StringMap<Dynamic>, builder:Dynamic->Dynamic):Void {
		for (name in data) {
			var object = data.get(name);
			object.build = builder(data.get(name));
		}
	}

	public function getBuild(data:Dynamic, builder:Dynamic->Dynamic):Dynamic {
		if (data.build != null) return data.build;
		data.build = builder(data);
		return data.build;
	}

	public function parseAnimation(xml:Xml):Void {
		var data:Dynamic = {
			sources: new StringMap<Dynamic>(),
			samplers: new StringMap<Dynamic>(),
			channels: new StringMap<Dynamic>()
		};

		var hasChildren = false;

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			var id:String;

			switch (child.nodeName) {
				case "source":
					id = child.get("id");
					data.sources.set(id, parseSource(child));
					break;
				case "sampler":
					id = child.get("id");
					data.samplers.set(id, parseAnimationSampler(child));
					break;
				case "channel":
					id = child.get("target");
					data.channels.set(id, parseAnimationChannel(child));
					break;
				case "animation":
					parseAnimation(child);
					hasChildren = true;
					break;
				default:
					console.log(child);
			}
		}

		if (!hasChildren) {
			library.animations.set(xml.get("id") != null ? xml.get("id") : MathUtils.generateUUID(), data);
		}
	}

	public function parseAnimationSampler(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<String>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var id = parseId(child.get("source"));
					var semantic = child.get("semantic");
					data.inputs.set(semantic, id);
					break;
			}
		}

		return data;
	}

	public function parseAnimationChannel(xml:Xml):Dynamic {
		var data:Dynamic = {};

		var target = xml.get("target");

		var parts = target.split("/");

		var id = parts.shift();
		var sid = parts.shift();

		var arraySyntax = (sid.indexOf("(") != -1);
		var memberSyntax = (sid.indexOf(".") != -1);

		if (memberSyntax) {
			parts = sid.split(".");
			sid = parts.shift();
			data.member = parts.shift();
		} else if (arraySyntax) {
			var indices = sid.split("(");
			sid = indices.shift();
			for (i in 0...indices.length) {
				indices[i] = Std.parseInt(indices[i].replace(")", ""));
			}
			data.indices = indices;
		}

		data.id = id;
		data.sid = sid;

		data.arraySyntax = arraySyntax;
		data.memberSyntax = memberSyntax;

		data.sampler = parseId(xml.get("source"));

		return data;
	}

	public function buildAnimation(data:Dynamic):Array<KeyframeTrack> {
		var tracks:Array<KeyframeTrack> = [];

		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;

		for (target in channels) {
			if (channels.exists(target)) {
				var channel = channels.get(target);
				var sampler = samplers.get(channel.sampler);

				var inputId = sampler.inputs.get("INPUT");
				var outputId = sampler.inputs.get("OUTPUT");

				var inputSource = sources.get(inputId);
				var outputSource = sources.get(outputId);

				var animation = buildAnimationChannel(channel, inputSource, outputSource);

				createKeyframeTracks(animation, tracks);
			}
		}

		return tracks;
	}

	public function getAnimation(id:String):Array<KeyframeTrack> {
		return getBuild(library.animations.get(id), buildAnimation);
	}

	public function buildAnimationChannel(channel:Dynamic, inputSource:Dynamic, outputSource:Dynamic):Dynamic {
		var node = library.nodes.get(channel.id);
		var object3D = getNode(node.id);

		var transform = node.transforms.get(channel.sid);
		var defaultMatrix = node.matrix.clone().transpose();

		var time:Float, stride:Int;
		var i:Int, il:Int, j:Int, jl:Int;

		var data:Dynamic = {};

		switch (transform) {
			case "matrix":
				for (i in 0...inputSource.array.length) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;

					if (data[time] == null) data[time] = {};

					if (channel.arraySyntax) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data[time][index] = value;
					} else {
						for (j in 0...outputSource.stride) {
							data[time][j] = outputSource.array[stride + j];
						}
					}
				}
				break;
			case "translate":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
			case "rotate":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
			case "scale":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
		}

		var keyframes = prepareAnimationData(data, defaultMatrix);

		var animation:Dynamic = {
			name: object3D.uuid,
			keyframes: keyframes
		};

		return animation;
	}

	public function prepareAnimationData(data:Dynamic, defaultMatrix:Matrix4):Array<Dynamic> {
		var keyframes:Array<Dynamic> = [];

		for (time in data) {
			keyframes.push({ time: Std.parseFloat(time), value: data[time] });
		}

		keyframes.sort(ascending);

		for (i in 0...16) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}

		return keyframes;

		function ascending(a:Dynamic, b:Dynamic):Int {
			return Std.parseFloat(a.time) - Std.parseFloat(b.time);
		}
	}

	public function createKeyframeTracks(animation:Dynamic, tracks:Array<KeyframeTrack>):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;

		var times:Array<Float> = [];
		var positionData:Array<Float> = [];
		var quaternionData:Array<Float> = [];
		var scaleData:Array<Float> = [];

		var matrix = new Matrix4();
		var position = new Vector3();
		var scale = new Vector3();
		var quaternion = new Quaternion();

		for (i in 0...keyframes.length) {
			var keyframe = keyframes[i];

			var time = keyframe.time;
			var value = keyframe.value;

			matrix.fromArray(value).transpose();
			matrix.decompose(position, quaternion, scale);

			times.push(time);
			positionData.push(position.x, position.y, position.z);
			quaternionData.push(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
			scaleData.push(scale.x, scale.y, scale.z);
		}

		if (positionData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".position", times, positionData));
		if (quaternionData.length > 0) tracks.push(new QuaternionKeyframeTrack(name + ".quaternion", times, quaternionData));
		if (scaleData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".scale", times, scaleData));
	}

	public function transformAnimationData(keyframes:Array<Dynamic>, property:Int, defaultValue:Float):Void {
		var keyframe:Dynamic;

		var empty = true;

		for (i in 0...keyframes.length) {
			keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}

		if (empty) {
			for (i in 0...keyframes.length) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	public function createMissingKeyframes(keyframes:Array<Dynamic>, property:Int):Void {
		var prev:Dynamic, next:Dynamic;

		for (i in 0...keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				prev = getPrev(keyframes, i, property);
				next = getNext(keyframes, i, property);

				if (prev == null) {
					keyframe.value[property] = next.value[property];
					continue;
				}

				if (next == null) {
					keyframe.value[property] = prev.value[property];
					continue;
				}

				interpolate(keyframe, prev, next, property);
			}
		}
	}

	public function getPrev(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i >= 0) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	public function getNext(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i < keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	public function interpolate(key:Dynamic, prev:Dynamic, next:Dynamic, property:Int):Void {
		if ((Std.parseFloat(next.time) - Std.parseFloat(prev.time)) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = ((Std.parseFloat(key.time) - Std.parseFloat(prev.time)) * (Std.parseFloat(next.value[property]) - Std.parseFloat(prev.value[property])) / (Std.parseFloat(next.time) - Std.parseFloat(prev.time))) + Std.parseFloat(prev.value[property]);
	}

	public function parseAnimationClip(xml:Xml):Void {
		var data:Dynamic = {
			name: xml.get("id") != null ? xml.get("id") : "default",
			start: Std.parseFloat(xml.get("start") != null ? xml.get("start") : "0"),
			end: Std.parseFloat(xml.get("end") != null ? xml.get("end") : "0"),
			animations: []
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.get("url")));
					break;
			}
		}

		library.clips.set(xml.get("id"), data);
	}

	public function buildAnimationClip(data:Dynamic):AnimationClip {
		var tracks:Array<KeyframeTrack> = [];

		var name = data.name;
		var duration = (data.end - data.start) != 0 ? (data.end - data.start) : -1;
		var animations = data.animations;

		for (i in 0...animations.length) {
			var animationTracks = getAnimation(animations[i]);

			for (j in 0...animationTracks.length) {
				tracks.push(animationTracks[j]);
			}
		}

		return new AnimationClip(name, duration, tracks);
	}

	public function getAnimationClip(id:String):AnimationClip {
		return getBuild(library.clips.get(id), buildAnimationClip);
	}

	public function parseController(xml:Xml):Void {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "skin":
					data.id = parseId(child.get("source"));
					data.skin = parseSkin(child);
					break;
				case "morph":
					data.id = parseId(child.get("source"));
					console.warn("THREE.ColladaLoader: Morph target animation not supported yet.");
					break;
			}
		}

		library.controllers.set(xml.get("id"), data);
	}

	public function parseSkin(xml:Xml):Dynamic {
		var data:Dynamic = {
			sources: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.get("textContent"));
					break;
				case "source":
					var id = child.get("id");
					data.sources.set(id, parseSource(child));
					break;
				case "joints":
					data.joints = parseJoints(child);
					break;
				case "vertex_weights":
					data.vertexWeights = parseVertexWeights(child);
					break;
			}
		}

		return data;
	}

	public function parseJoints(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<String>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var semantic = child.get("semantic");
					var id = parseId(child.get("source"));
					data.inputs.set(semantic, id);
					break;
			}
		}

		return data;
	}

	public function parseVertexWeights(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var semantic = child.get("semantic");
					var id = parseId(child.get("source"));
					var offset = Std.parseInt(child.get("offset"));
					data.inputs.set(semantic, { id: id, offset: offset });
					break;
				case "vcount":
					data.vcount = parseInts(child.get("textContent"));
					break;
				case "v":
					data.v = parseInts(child.get("textContent"));
					break;
			}
		}

		return data;
	}

	public function buildController(data:Dynamic):Dynamic {
		var build:Dynamic = {
			id: data.id
		};

		var geometry = library.geometries.get(build.id);

		if (data.skin != null) {
			build.skin = buildSkin(data.skin);

			geometry.sources.skinIndices = build.skin.indices;
			geometry.sources.skinWeights = build.skin.weights;
		}

		return build;
	}

	public function buildSkin(data:Dynamic):Dynamic {
		var BONE_LIMIT = 4;

		var build:Dynamic = {
			joints: [],
			indices: {
				array: [],
				stride: BONE_LIMIT
			},
			weights: {
				array: [],
				stride: BONE_LIMIT
			}
		};

		var sources = data.sources;
		var vertexWeights = data.vertexWeights;

		var vcount = vertexWeights.vcount;
		var v = vertexWeights.v;
		var jointOffset = vertexWeights.inputs.get("JOINT").offset;
		var weightOffset = vertexWeights.inputs.get("WEIGHT").offset;

		var jointSource = data.sources.get(data.joints.inputs.get("JOINT"));
		var inverseSource = data.sources.get(data.joints.inputs.get("INV_BIND_MATRIX"));

		var weights = sources.get(vertexWeights.inputs.get("WEIGHT").id).array;
		var stride = 0;

		for (i in 0...vcount.length) {
			var jointCount = vcount[i];
			var vertexSkinData:Array<Dynamic> = [];

			for (j in 0...jointCount) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];

				vertexSkinData.push({ index: skinIndex, weight: skinWeight });

				stride += 2;
			}

			vertexSkinData.sort(descending);

			for (j in 0...BONE_LIMIT) {
				var d = vertexSkinData[j];

				if (d != null) {
					build.indices.array.push(d.index);
					build.weights.array.push(d.weight);
				} else {
					build.indices.array.push(0);
					build.weights.array.push(0);
				}
			}
		}

		if (data.bindShapeMatrix != null) {
			build.bindMatrix = new Matrix4().fromArray(data.bindShapeMatrix).transpose();
		} else {
			build.bindMatrix = new Matrix4().identity();
		}

		for (i in 0...jointSource.array.length) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();

			build.joints.push({ name: name, boneInverse: boneInverse });
		}

		return build;

		function descending(a:Dynamic, b:Dynamic):Int {
			return Std.parseFloat(b.weight) - Std.parseFloat(a.weight);
		}
	}

	public function getController(id:String):Dynamic {
		return getBuild(library.controllers.get(id), buildController);
	}

	public function parseImage(xml:Xml):Void {
		var data:Dynamic = {
			init_from: xml.firstElement("init_from").get("textContent")
		};

		library.images.set(xml.get("id"), data);
	}

	public function buildImage(data:Dynamic):String {
		if (data.build != null) return data.build;
		return data.init_from;
	}

	public function getImage(id:String):String {
		var data = library.images.get(id);
		if (data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	public function parseEffect(xml:Xml):Void {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}

		library.effects.set(xml.get("id"), data);
	}

	public function parseEffectProfileCOMMON(xml:Xml):Dynamic {
		var data:Dynamic = {
			surfaces: new StringMap<Dynamic>(),
			samplers: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "newparam":
					parseEffectNewparam(child, data);
					break;
				case "technique":
					data.technique = parseEffectTechnique(child);
					break;
				case "extra":
					data.extra = parseEffectExtra(child);
					break;
			}
		}

		return data;
	}

	public function parseEffectNewparam(xml:Xml, data:Dynamic):Void {
		var sid = xml.get("sid");

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "surface":
					data.surfaces.set(sid, parseEffectSurface(child));
					break;
				case "sampler2D":
					data.samplers.set(sid, parseEffectSampler(child));
					break;
			}
		}
	}

	public function parseEffectSurface(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "init_from":
					data.init_from = child.get("textContent");
					break;
			}
		}

		return data;
	}

	public function parseEffectSampler(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "source":
					data.source = child.get("textContent");
					break;
			}
		}

		return data;
	}

	public function parseEffectTechnique(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "constant":
				case "lambert":
				case "blinn":
				case "phong":
					data.type = child.nodeName;
					data.parameters = parseEffectParameters(child);
					break;
				case "extra":
					data.extra = parseEffectExtra(child);
					break;
			}
		}

		return data;
	}

	public function parseEffectParameters(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "emission":
				case "diffuse":
				case "specular":
				case "bump":
				case "ambient":
				case "shininess":
				case "transparency":
					data[child.nodeName] = parseEffectParameter(child);
					break;
				case "transparent":
					data[child.nodeName] = {
						opaque: child.hasAttribute("opaque") ? child.get("opaque") : "A_ONE",
						data: parseEffectParameter(child)
					};
					break;
			}
		}

		return data;
	}

	public function parseEffectParameter(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "color":
					data[child.nodeName] = parseFloats(child.get("textContent"));
					break;
				case "float":
					data[child.nodeName] = Std.parseFloat(child.get("textContent"));
					break;
				case "texture":
					data[child.nodeName] = { id: child.get("texture"), extra: parseEffectParameterTexture(child) };
					break;
			}
		}

		return data;
	}

	public function parseEffectParameterTexture(xml:Xml):Dynamic {
		var data:Dynamic = {
			technique: {}
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				
import haxe.io.Bytes;
import haxe.io.StringTools;
import haxe.xml.Xml;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import three.extras.core.AnimationClip;
import three.extras.core.AnimationAction;
import three.extras.core.KeyframeTrack;
import three.extras.core.VectorKeyframeTrack;
import three.extras.core.QuaternionKeyframeTrack;
import three.extras.loaders.FileLoader;
import three.extras.loaders.TextureLoader;
import three.extras.loaders.TGALoader;
import three.core.Object3D;
import three.core.Scene;
import three.core.Group;
import three.core.Bone;
import three.core.Mesh;
import three.core.SkinnedMesh;
import three.core.LineSegments;
import three.core.Line;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Skeleton;
import three.math.Color;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Matrix4;
import three.materials.MeshBasicMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.LineBasicMaterial;
import three.textures.Texture;
import three.textures.RepeatWrapping;
import three.textures.ClampToEdgeWrapping;
import three.textures.SRGBColorSpace;

class ColladaLoader {

	public var manager:FileLoader;
	public var path:String = "";
	public var resourcePath:String = "";
	public var crossOrigin:String = null;
	public var requestHeader:StringMap<String> = new StringMap<String>();
	public var withCredentials:Bool = false;

	public function new(manager:FileLoader) {
		this.manager = manager;
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(parse(text, path));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				this.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String, path:String):Dynamic {
		var count = 0;
		var tempColor = new Color();
		var animations:Array<AnimationClip> = [];
		var kinematics:Dynamic = {};

		var library:Dynamic = {
			animations: new StringMap<Dynamic>(),
			clips: new StringMap<Dynamic>(),
			controllers: new StringMap<Dynamic>(),
			images: new StringMap<Dynamic>(),
			effects: new StringMap<Dynamic>(),
			materials: new StringMap<Dynamic>(),
			cameras: new StringMap<Dynamic>(),
			lights: new StringMap<Dynamic>(),
			geometries: new StringMap<Dynamic>(),
			nodes: new StringMap<Dynamic>(),
			visualScenes: new StringMap<Dynamic>(),
			kinematicsModels: new StringMap<Dynamic>(),
			physicsModels: new StringMap<Dynamic>(),
			kinematicsScenes: new StringMap<Dynamic>()
		};

		if (text.length == 0) {
			return { scene: new Scene() };
		}

		var xml:Xml = Xml.parse(text);

		var collada = getElementsByTagName(xml, "COLLADA")[0];

		var parserError = xml.firstElement("parsererror");
		if (parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText:String;

			if (errorElement != null) {
				errorText = errorElement.get("textContent");
			} else {
				errorText = parserErrorToText(parserError);
			}

			console.error("THREE.ColladaLoader: Failed to parse collada file.\n", errorText);
			return null;
		}

		var version = collada.get("version");
		console.debug("THREE.ColladaLoader: File version", version);

		var asset = parseAsset(getElementsByTagName(collada, "asset")[0]);
		var textureLoader = new TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		textureLoader.setCrossOrigin(this.crossOrigin);

		var tgaLoader:TGALoader;

		if (TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}

		parseLibrary(collada, "library_animations", "animation", parseAnimation);
		parseLibrary(collada, "library_animation_clips", "animation_clip", parseAnimationClip);
		parseLibrary(collada, "library_controllers", "controller", parseController);
		parseLibrary(collada, "library_images", "image", parseImage);
		parseLibrary(collada, "library_effects", "effect", parseEffect);
		parseLibrary(collada, "library_materials", "material", parseMaterial);
		parseLibrary(collada, "library_cameras", "camera", parseCamera);
		parseLibrary(collada, "library_lights", "light", parseLight);
		parseLibrary(collada, "library_geometries", "geometry", parseGeometry);
		parseLibrary(collada, "library_nodes", "node", parseNode);
		parseLibrary(collada, "library_visual_scenes", "visual_scene", parseVisualScene);
		parseLibrary(collada, "library_kinematics_models", "kinematics_model", parseKinematicsModel);
		parseLibrary(collada, "library_physics_models", "physics_model", parsePhysicsModel);
		parseLibrary(collada, "scene", "instance_kinematics_scene", parseKinematicsScene);

		buildLibrary(library.animations, buildAnimation);
		buildLibrary(library.clips, buildAnimationClip);
		buildLibrary(library.controllers, buildController);
		buildLibrary(library.images, buildImage);
		buildLibrary(library.effects, buildEffect);
		buildLibrary(library.materials, buildMaterial);
		buildLibrary(library.cameras, buildCamera);
		buildLibrary(library.lights, buildLight);
		buildLibrary(library.geometries, buildGeometry);
		buildLibrary(library.visualScenes, buildVisualScene);

		setupAnimations();
		setupKinematics();

		var scene = parseScene(getElementsByTagName(collada, "scene")[0]);
		scene.animations = animations;

		if (asset.upAxis == "Z_UP") {
			console.warn("THREE.ColladaLoader: You are loading an asset with a Z-UP coordinate system. The loader just rotates the asset to transform it into Y-UP. The vertex data are not converted, see #24289.");
			scene.rotation.set(-Math.PI / 2, 0, 0);
		}

		scene.scale.multiplyScalar(asset.unit);

		return {
			get animations() {
				console.warn("THREE.ColladaLoader: Please access animations over scene.animations now.");
				return animations;
			},
			kinematics: kinematics,
			library: library,
			scene: scene
		};
	}

	public function getElementsByTagName(xml:Xml, tagName:String):Array<Xml> {
		var result:Array<Xml> = [];
		for (element in xml.elements()) {
			if (element.nodeName == tagName) {
				result.push(element);
			}
		}
		return result;
	}

	public function parserErrorToText(parserError:Xml):String {
		var result:String = "";
		var stack:Array<Xml> = [parserError];

		while (stack.length > 0) {
			var node = stack.shift();
			if (node.nodeType == Xml.TEXT_NODE) {
				result += node.get("textContent");
			} else {
				result += "\n";
				stack.push(node.elements());
			}
		}

		return result.trim();
	}

	public function parseAsset(xml:Xml):Dynamic {
		return {
			unit: parseAssetUnit(xml.firstElement("unit")),
			upAxis: parseAssetUpAxis(xml.firstElement("up_axis"))
		};
	}

	public function parseAssetUnit(xml:Xml):Float {
		if (xml != null && xml.hasAttribute("meter")) {
			return Std.parseFloat(xml.get("meter"));
		} else {
			return 1;
		}
	}

	public function parseAssetUpAxis(xml:Xml):String {
		return xml != null ? xml.get("textContent") : "Y_UP";
	}

	public function parseLibrary(xml:Xml, libraryName:String, nodeName:String, parser:Xml->Void):Void {
		var library = xml.firstElement(libraryName);
		if (library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for (i in 0...elements.length) {
				parser(elements[i]);
			}
		}
	}

	public function buildLibrary(data:StringMap<Dynamic>, builder:Dynamic->Dynamic):Void {
		for (name in data) {
			var object = data.get(name);
			object.build = builder(data.get(name));
		}
	}

	public function getBuild(data:Dynamic, builder:Dynamic->Dynamic):Dynamic {
		if (data.build != null) return data.build;
		data.build = builder(data);
		return data.build;
	}

	public function parseAnimation(xml:Xml):Void {
		var data:Dynamic = {
			sources: new StringMap<Dynamic>(),
			samplers: new StringMap<Dynamic>(),
			channels: new StringMap<Dynamic>()
		};

		var hasChildren = false;

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			var id:String;

			switch (child.nodeName) {
				case "source":
					id = child.get("id");
					data.sources.set(id, parseSource(child));
					break;
				case "sampler":
					id = child.get("id");
					data.samplers.set(id, parseAnimationSampler(child));
					break;
				case "channel":
					id = child.get("target");
					data.channels.set(id, parseAnimationChannel(child));
					break;
				case "animation":
					parseAnimation(child);
					hasChildren = true;
					break;
				default:
					console.log(child);
			}
		}

		if (!hasChildren) {
			library.animations.set(xml.get("id") != null ? xml.get("id") : MathUtils.generateUUID(), data);
		}
	}

	public function parseAnimationSampler(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<String>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var id = parseId(child.get("source"));
					var semantic = child.get("semantic");
					data.inputs.set(semantic, id);
					break;
			}
		}

		return data;
	}

	public function parseAnimationChannel(xml:Xml):Dynamic {
		var data:Dynamic = {};

		var target = xml.get("target");

		var parts = target.split("/");

		var id = parts.shift();
		var sid = parts.shift();

		var arraySyntax = (sid.indexOf("(") != -1);
		var memberSyntax = (sid.indexOf(".") != -1);

		if (memberSyntax) {
			parts = sid.split(".");
			sid = parts.shift();
			data.member = parts.shift();
		} else if (arraySyntax) {
			var indices = sid.split("(");
			sid = indices.shift();
			for (i in 0...indices.length) {
				indices[i] = Std.parseInt(indices[i].replace(")", ""));
			}
			data.indices = indices;
		}

		data.id = id;
		data.sid = sid;

		data.arraySyntax = arraySyntax;
		data.memberSyntax = memberSyntax;

		data.sampler = parseId(xml.get("source"));

		return data;
	}

	public function buildAnimation(data:Dynamic):Array<KeyframeTrack> {
		var tracks:Array<KeyframeTrack> = [];

		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;

		for (target in channels) {
			if (channels.exists(target)) {
				var channel = channels.get(target);
				var sampler = samplers.get(channel.sampler);

				var inputId = sampler.inputs.get("INPUT");
				var outputId = sampler.inputs.get("OUTPUT");

				var inputSource = sources.get(inputId);
				var outputSource = sources.get(outputId);

				var animation = buildAnimationChannel(channel, inputSource, outputSource);

				createKeyframeTracks(animation, tracks);
			}
		}

		return tracks;
	}

	public function getAnimation(id:String):Array<KeyframeTrack> {
		return getBuild(library.animations.get(id), buildAnimation);
	}

	public function buildAnimationChannel(channel:Dynamic, inputSource:Dynamic, outputSource:Dynamic):Dynamic {
		var node = library.nodes.get(channel.id);
		var object3D = getNode(node.id);

		var transform = node.transforms.get(channel.sid);
		var defaultMatrix = node.matrix.clone().transpose();

		var time:Float, stride:Int;
		var i:Int, il:Int, j:Int, jl:Int;

		var data:Dynamic = {};

		switch (transform) {
			case "matrix":
				for (i in 0...inputSource.array.length) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;

					if (data[time] == null) data[time] = {};

					if (channel.arraySyntax) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data[time][index] = value;
					} else {
						for (j in 0...outputSource.stride) {
							data[time][j] = outputSource.array[stride + j];
						}
					}
				}
				break;
			case "translate":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
			case "rotate":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
			case "scale":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
		}

		var keyframes = prepareAnimationData(data, defaultMatrix);

		var animation:Dynamic = {
			name: object3D.uuid,
			keyframes: keyframes
		};

		return animation;
	}

	public function prepareAnimationData(data:Dynamic, defaultMatrix:Matrix4):Array<Dynamic> {
		var keyframes:Array<Dynamic> = [];

		for (time in data) {
			keyframes.push({ time: Std.parseFloat(time), value: data[time] });
		}

		keyframes.sort(ascending);

		for (i in 0...16) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}

		return keyframes;

		function ascending(a:Dynamic, b:Dynamic):Int {
			return Std.parseFloat(a.time) - Std.parseFloat(b.time);
		}
	}

	public function createKeyframeTracks(animation:Dynamic, tracks:Array<KeyframeTrack>):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;

		var times:Array<Float> = [];
		var positionData:Array<Float> = [];
		var quaternionData:Array<Float> = [];
		var scaleData:Array<Float> = [];

		var matrix = new Matrix4();
		var position = new Vector3();
		var scale = new Vector3();
		var quaternion = new Quaternion();

		for (i in 0...keyframes.length) {
			var keyframe = keyframes[i];

			var time = keyframe.time;
			var value = keyframe.value;

			matrix.fromArray(value).transpose();
			matrix.decompose(position, quaternion, scale);

			times.push(time);
			positionData.push(position.x, position.y, position.z);
			quaternionData.push(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
			scaleData.push(scale.x, scale.y, scale.z);
		}

		if (positionData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".position", times, positionData));
		if (quaternionData.length > 0) tracks.push(new QuaternionKeyframeTrack(name + ".quaternion", times, quaternionData));
		if (scaleData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".scale", times, scaleData));
	}

	public function transformAnimationData(keyframes:Array<Dynamic>, property:Int, defaultValue:Float):Void {
		var keyframe:Dynamic;

		var empty = true;

		for (i in 0...keyframes.length) {
			keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}

		if (empty) {
			for (i in 0...keyframes.length) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	public function createMissingKeyframes(keyframes:Array<Dynamic>, property:Int):Void {
		var prev:Dynamic, next:Dynamic;

		for (i in 0...keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				prev = getPrev(keyframes, i, property);
				next = getNext(keyframes, i, property);

				if (prev == null) {
					keyframe.value[property] = next.value[property];
					continue;
				}

				if (next == null) {
					keyframe.value[property] = prev.value[property];
					continue;
				}

				interpolate(keyframe, prev, next, property);
			}
		}
	}

	public function getPrev(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i >= 0) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	public function getNext(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i < keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	public function interpolate(key:Dynamic, prev:Dynamic, next:Dynamic, property:Int):Void {
		if ((Std.parseFloat(next.time) - Std.parseFloat(prev.time)) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = ((Std.parseFloat(key.time) - Std.parseFloat(prev.time)) * (Std.parseFloat(next.value[property]) - Std.parseFloat(prev.value[property])) / (Std.parseFloat(next.time) - Std.parseFloat(prev.time))) + Std.parseFloat(prev.value[property]);
	}

	public function parseAnimationClip(xml:Xml):Void {
		var data:Dynamic = {
			name: xml.get("id") != null ? xml.get("id") : "default",
			start: Std.parseFloat(xml.get("start") != null ? xml.get("start") : "0"),
			end: Std.parseFloat(xml.get("end") != null ? xml.get("end") : "0"),
			animations: []
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.get("url")));
					break;
			}
		}

		library.clips.set(xml.get("id"), data);
	}

	public function buildAnimationClip(data:Dynamic):AnimationClip {
		var tracks:Array<KeyframeTrack> = [];

		var name = data.name;
		var duration = (data.end - data.start) != 0 ? (data.end - data.start) : -1;
		var animations = data.animations;

		for (i in 0...animations.length) {
			var animationTracks = getAnimation(animations[i]);

			for (j in 0...animationTracks.length) {
				tracks.push(animationTracks[j]);
			}
		}

		return new AnimationClip(name, duration, tracks);
	}

	public function getAnimationClip(id:String):AnimationClip {
		return getBuild(library.clips.get(id), buildAnimationClip);
	}

	public function parseController(xml:Xml):Void {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "skin":
					data.id = parseId(child.get("source"));
					data.skin = parseSkin(child);
					break;
				case "morph":
					data.id = parseId(child.get("source"));
					console.warn("THREE.ColladaLoader: Morph target animation not supported yet.");
					break;
			}
		}

		library.controllers.set(xml.get("id"), data);
	}

	public function parseSkin(xml:Xml):Dynamic {
		var data:Dynamic = {
			sources: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.get("textContent"));
					break;
				case "source":
					var id = child.get("id");
					data.sources.set(id, parseSource(child));
					break;
				case "joints":
					data.joints = parseJoints(child);
					break;
				case "vertex_weights":
					data.vertexWeights = parseVertexWeights(child);
					break;
			}
		}

		return data;
	}

	public function parseJoints(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<String>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var semantic = child.get("semantic");
					var id = parseId(child.get("source"));
					data.inputs.set(semantic, id);
					break;
			}
		}

		return data;
	}

	public function parseVertexWeights(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var semantic = child.get("semantic");
					var id = parseId(child.get("source"));
					var offset = Std.parseInt(child.get("offset"));
					data.inputs.set(semantic, { id: id, offset: offset });
					break;
				case "vcount":
					data.vcount = parseInts(child.get("textContent"));
					break;
				case "v":
					data.v = parseInts(child.get("textContent"));
					break;
			}
		}

		return data;
	}

	public function buildController(data:Dynamic):Dynamic {
		var build:Dynamic = {
			id: data.id
		};

		var geometry = library.geometries.get(build.id);

		if (data.skin != null) {
			build.skin = buildSkin(data.skin);

			geometry.sources.skinIndices = build.skin.indices;
			geometry.sources.skinWeights = build.skin.weights;
		}

		return build;
	}

	public function buildSkin(data:Dynamic):Dynamic {
		var BONE_LIMIT = 4;

		var build:Dynamic = {
			joints: [],
			indices: {
				array: [],
				stride: BONE_LIMIT
			},
			weights: {
				array: [],
				stride: BONE_LIMIT
			}
		};

		var sources = data.sources;
		var vertexWeights = data.vertexWeights;

		var vcount = vertexWeights.vcount;
		var v = vertexWeights.v;
		var jointOffset = vertexWeights.inputs.get("JOINT").offset;
		var weightOffset = vertexWeights.inputs.get("WEIGHT").offset;

		var jointSource = data.sources.get(data.joints.inputs.get("JOINT"));
		var inverseSource = data.sources.get(data.joints.inputs.get("INV_BIND_MATRIX"));

		var weights = sources.get(vertexWeights.inputs.get("WEIGHT").id).array;
		var stride = 0;

		for (i in 0...vcount.length) {
			var jointCount = vcount[i];
			var vertexSkinData:Array<Dynamic> = [];

			for (j in 0...jointCount) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];

				vertexSkinData.push({ index: skinIndex, weight: skinWeight });

				stride += 2;
			}

			vertexSkinData.sort(descending);

			for (j in 0...BONE_LIMIT) {
				var d = vertexSkinData[j];

				if (d != null) {
					build.indices.array.push(d.index);
					build.weights.array.push(d.weight);
				} else {
					build.indices.array.push(0);
					build.weights.array.push(0);
				}
			}
		}

		if (data.bindShapeMatrix != null) {
			build.bindMatrix = new Matrix4().fromArray(data.bindShapeMatrix).transpose();
		} else {
			build.bindMatrix = new Matrix4().identity();
		}

		for (i in 0...jointSource.array.length) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();

			build.joints.push({ name: name, boneInverse: boneInverse });
		}

		return build;

		function descending(a:Dynamic, b:Dynamic):Int {
			return Std.parseFloat(b.weight) - Std.parseFloat(a.weight);
		}
	}

	public function getController(id:String):Dynamic {
		return getBuild(library.controllers.get(id), buildController);
	}

	public function parseImage(xml:Xml):Void {
		var data:Dynamic = {
			init_from: xml.firstElement("init_from").get("textContent")
		};

		library.images.set(xml.get("id"), data);
	}

	public function buildImage(data:Dynamic):String {
		if (data.build != null) return data.build;
		return data.init_from;
	}

	public function getImage(id:String):String {
		var data = library.images.get(id);
		if (data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	public function parseEffect(xml:Xml):Void {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}

		library.effects.set(xml.get("id"), data);
	}

	public function parseEffectProfileCOMMON(xml:Xml):Dynamic {
		var data:Dynamic = {
			surfaces: new StringMap<Dynamic>(),
			samplers: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "newparam":
					parseEffectNewparam(child, data);
					break;
				case "technique":
					data.technique = parseEffectTechnique(child);
					break;
				case "extra":
					data.extra = parseEffectExtra(child);
					break;
			}
		}

		return data;
	}

	public function parseEffectNewparam(xml:Xml, data:Dynamic):Void {
		var sid = xml.get("sid");

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "surface":
					data.surfaces.set(sid, parseEffectSurface(child));
					break;
				case "sampler2D":
					data.samplers.set(sid, parseEffectSampler(child));
					break;
			}
		}
	}

	public function parseEffectSurface(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "init_from":
					data.init_from = child.get("textContent");
					break;
			}
		}

		return data;
	}

	public function parseEffectSampler(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "source":
					data.source = child.get("textContent");
					break;
			}
		}

		return data;
	}

	public function parseEffectTechnique(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "constant":
				case "lambert":
				case "blinn":
				case "phong":
					data.type = child.nodeName;
					data.parameters = parseEffectParameters(child);
					break;
				case "extra":
					data.extra = parseEffectExtra(child);
					break;
			}
		}

		return data;
	}

	public function parseEffectParameters(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "emission":
				case "diffuse":
				case "specular":
				case "bump":
				case "ambient":
				case "shininess":
				case "transparency":
					data[child.nodeName] = parseEffectParameter(child);
					break;
				case "transparent":
					data[child.nodeName] = {
						opaque: child.hasAttribute("opaque") ? child.get("opaque") : "A_ONE",
						data: parseEffectParameter(child)
					};
					break;
			}
		}

		return data;
	}

	public function parseEffectParameter(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "color":
					data[child.nodeName] = parseFloats(child.get("textContent"));
					break;
				case "float":
					data[child.nodeName] = Std.parseFloat(child.get("textContent"));
					break;
				case "texture":
					data[child.nodeName] = { id: child.get("texture"), extra: parseEffectParameterTexture(child) };
					break;
			}
		}

		return data;
	}

	public function parseEffectParameterTexture(xml:Xml):Dynamic {
		var data:Dynamic = {
			technique: {}
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				
import haxe.io.Bytes;
import haxe.io.StringTools;
import haxe.xml.Xml;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import three.extras.core.AnimationClip;
import three.extras.core.AnimationAction;
import three.extras.core.KeyframeTrack;
import three.extras.core.VectorKeyframeTrack;
import three.extras.core.QuaternionKeyframeTrack;
import three.extras.loaders.FileLoader;
import three.extras.loaders.TextureLoader;
import three.extras.loaders.TGALoader;
import three.core.Object3D;
import three.core.Scene;
import three.core.Group;
import three.core.Bone;
import three.core.Mesh;
import three.core.SkinnedMesh;
import three.core.LineSegments;
import three.core.Line;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Skeleton;
import three.math.Color;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Matrix4;
import three.materials.MeshBasicMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.LineBasicMaterial;
import three.textures.Texture;
import three.textures.RepeatWrapping;
import three.textures.ClampToEdgeWrapping;
import three.textures.SRGBColorSpace;

class ColladaLoader {

	public var manager:FileLoader;
	public var path:String = "";
	public var resourcePath:String = "";
	public var crossOrigin:String = null;
	public var requestHeader:StringMap<String> = new StringMap<String>();
	public var withCredentials:Bool = false;

	public function new(manager:FileLoader) {
		this.manager = manager;
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(parse(text, path));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				this.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String, path:String):Dynamic {
		var count = 0;
		var tempColor = new Color();
		var animations:Array<AnimationClip> = [];
		var kinematics:Dynamic = {};

		var library:Dynamic = {
			animations: new StringMap<Dynamic>(),
			clips: new StringMap<Dynamic>(),
			controllers: new StringMap<Dynamic>(),
			images: new StringMap<Dynamic>(),
			effects: new StringMap<Dynamic>(),
			materials: new StringMap<Dynamic>(),
			cameras: new StringMap<Dynamic>(),
			lights: new StringMap<Dynamic>(),
			geometries: new StringMap<Dynamic>(),
			nodes: new StringMap<Dynamic>(),
			visualScenes: new StringMap<Dynamic>(),
			kinematicsModels: new StringMap<Dynamic>(),
			physicsModels: new StringMap<Dynamic>(),
			kinematicsScenes: new StringMap<Dynamic>()
		};

		if (text.length == 0) {
			return { scene: new Scene() };
		}

		var xml:Xml = Xml.parse(text);

		var collada = getElementsByTagName(xml, "COLLADA")[0];

		var parserError = xml.firstElement("parsererror");
		if (parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText:String;

			if (errorElement != null) {
				errorText = errorElement.get("textContent");
			} else {
				errorText = parserErrorToText(parserError);
			}

			console.error("THREE.ColladaLoader: Failed to parse collada file.\n", errorText);
			return null;
		}

		var version = collada.get("version");
		console.debug("THREE.ColladaLoader: File version", version);

		var asset = parseAsset(getElementsByTagName(collada, "asset")[0]);
		var textureLoader = new TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		textureLoader.setCrossOrigin(this.crossOrigin);

		var tgaLoader:TGALoader;

		if (TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}

		parseLibrary(collada, "library_animations", "animation", parseAnimation);
		parseLibrary(collada, "library_animation_clips", "animation_clip", parseAnimationClip);
		parseLibrary(collada, "library_controllers", "controller", parseController);
		parseLibrary(collada, "library_images", "image", parseImage);
		parseLibrary(collada, "library_effects", "effect", parseEffect);
		parseLibrary(collada, "library_materials", "material", parseMaterial);
		parseLibrary(collada, "library_cameras", "camera", parseCamera);
		parseLibrary(collada, "library_lights", "light", parseLight);
		parseLibrary(collada, "library_geometries", "geometry", parseGeometry);
		parseLibrary(collada, "library_nodes", "node", parseNode);
		parseLibrary(collada, "library_visual_scenes", "visual_scene", parseVisualScene);
		parseLibrary(collada, "library_kinematics_models", "kinematics_model", parseKinematicsModel);
		parseLibrary(collada, "library_physics_models", "physics_model", parsePhysicsModel);
		parseLibrary(collada, "scene", "instance_kinematics_scene", parseKinematicsScene);

		buildLibrary(library.animations, buildAnimation);
		buildLibrary(library.clips, buildAnimationClip);
		buildLibrary(library.controllers, buildController);
		buildLibrary(library.images, buildImage);
		buildLibrary(library.effects, buildEffect);
		buildLibrary(library.materials, buildMaterial);
		buildLibrary(library.cameras, buildCamera);
		buildLibrary(library.lights, buildLight);
		buildLibrary(library.geometries, buildGeometry);
		buildLibrary(library.visualScenes, buildVisualScene);

		setupAnimations();
		setupKinematics();

		var scene = parseScene(getElementsByTagName(collada, "scene")[0]);
		scene.animations = animations;

		if (asset.upAxis == "Z_UP") {
			console.warn("THREE.ColladaLoader: You are loading an asset with a Z-UP coordinate system. The loader just rotates the asset to transform it into Y-UP. The vertex data are not converted, see #24289.");
			scene.rotation.set(-Math.PI / 2, 0, 0);
		}

		scene.scale.multiplyScalar(asset.unit);

		return {
			get animations() {
				console.warn("THREE.ColladaLoader: Please access animations over scene.animations now.");
				return animations;
			},
			kinematics: kinematics,
			library: library,
			scene: scene
		};
	}

	public function getElementsByTagName(xml:Xml, tagName:String):Array<Xml> {
		var result:Array<Xml> = [];
		for (element in xml.elements()) {
			if (element.nodeName == tagName) {
				result.push(element);
			}
		}
		return result;
	}

	public function parserErrorToText(parserError:Xml):String {
		var result:String = "";
		var stack:Array<Xml> = [parserError];

		while (stack.length > 0) {
			var node = stack.shift();
			if (node.nodeType == Xml.TEXT_NODE) {
				result += node.get("textContent");
			} else {
				result += "\n";
				stack.push(node.elements());
			}
		}

		return result.trim();
	}

	public function parseAsset(xml:Xml):Dynamic {
		return {
			unit: parseAssetUnit(xml.firstElement("unit")),
			upAxis: parseAssetUpAxis(xml.firstElement("up_axis"))
		};
	}

	public function parseAssetUnit(xml:Xml):Float {
		if (xml != null && xml.hasAttribute("meter")) {
			return Std.parseFloat(xml.get("meter"));
		} else {
			return 1;
		}
	}

	public function parseAssetUpAxis(xml:Xml):String {
		return xml != null ? xml.get("textContent") : "Y_UP";
	}

	public function parseLibrary(xml:Xml, libraryName:String, nodeName:String, parser:Xml->Void):Void {
		var library = xml.firstElement(libraryName);
		if (library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for (i in 0...elements.length) {
				parser(elements[i]);
			}
		}
	}

	public function buildLibrary(data:StringMap<Dynamic>, builder:Dynamic->Dynamic):Void {
		for (name in data) {
			var object = data.get(name);
			object.build = builder(data.get(name));
		}
	}

	public function getBuild(data:Dynamic, builder:Dynamic->Dynamic):Dynamic {
		if (data.build != null) return data.build;
		data.build = builder(data);
		return data.build;
	}

	public function parseAnimation(xml:Xml):Void {
		var data:Dynamic = {
			sources: new StringMap<Dynamic>(),
			samplers: new StringMap<Dynamic>(),
			channels: new StringMap<Dynamic>()
		};

		var hasChildren = false;

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			var id:String;

			switch (child.nodeName) {
				case "source":
					id = child.get("id");
					data.sources.set(id, parseSource(child));
					break;
				case "sampler":
					id = child.get("id");
					data.samplers.set(id, parseAnimationSampler(child));
					break;
				case "channel":
					id = child.get("target");
					data.channels.set(id, parseAnimationChannel(child));
					break;
				case "animation":
					parseAnimation(child);
					hasChildren = true;
					break;
				default:
					console.log(child);
			}
		}

		if (!hasChildren) {
			library.animations.set(xml.get("id") != null ? xml.get("id") : MathUtils.generateUUID(), data);
		}
	}

	public function parseAnimationSampler(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<String>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var id = parseId(child.get("source"));
					var semantic = child.get("semantic");
					data.inputs.set(semantic, id);
					break;
			}
		}

		return data;
	}

	public function parseAnimationChannel(xml:Xml):Dynamic {
		var data:Dynamic = {};

		var target = xml.get("target");

		var parts = target.split("/");

		var id = parts.shift();
		var sid = parts.shift();

		var arraySyntax = (sid.indexOf("(") != -1);
		var memberSyntax = (sid.indexOf(".") != -1);

		if (memberSyntax) {
			parts = sid.split(".");
			sid = parts.shift();
			data.member = parts.shift();
		} else if (arraySyntax) {
			var indices = sid.split("(");
			sid = indices.shift();
			for (i in 0...indices.length) {
				indices[i] = Std.parseInt(indices[i].replace(")", ""));
			}
			data.indices = indices;
		}

		data.id = id;
		data.sid = sid;

		data.arraySyntax = arraySyntax;
		data.memberSyntax = memberSyntax;

		data.sampler = parseId(xml.get("source"));

		return data;
	}

	public function buildAnimation(data:Dynamic):Array<KeyframeTrack> {
		var tracks:Array<KeyframeTrack> = [];

		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;

		for (target in channels) {
			if (channels.exists(target)) {
				var channel = channels.get(target);
				var sampler = samplers.get(channel.sampler);

				var inputId = sampler.inputs.get("INPUT");
				var outputId = sampler.inputs.get("OUTPUT");

				var inputSource = sources.get(inputId);
				var outputSource = sources.get(outputId);

				var animation = buildAnimationChannel(channel, inputSource, outputSource);

				createKeyframeTracks(animation, tracks);
			}
		}

		return tracks;
	}

	public function getAnimation(id:String):Array<KeyframeTrack> {
		return getBuild(library.animations.get(id), buildAnimation);
	}

	public function buildAnimationChannel(channel:Dynamic, inputSource:Dynamic, outputSource:Dynamic):Dynamic {
		var node = library.nodes.get(channel.id);
		var object3D = getNode(node.id);

		var transform = node.transforms.get(channel.sid);
		var defaultMatrix = node.matrix.clone().transpose();

		var time:Float, stride:Int;
		var i:Int, il:Int, j:Int, jl:Int;

		var data:Dynamic = {};

		switch (transform) {
			case "matrix":
				for (i in 0...inputSource.array.length) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;

					if (data[time] == null) data[time] = {};

					if (channel.arraySyntax) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data[time][index] = value;
					} else {
						for (j in 0...outputSource.stride) {
							data[time][j] = outputSource.array[stride + j];
						}
					}
				}
				break;
			case "translate":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
			case "rotate":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
			case "scale":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
		}

		var keyframes = prepareAnimationData(data, defaultMatrix);

		var animation:Dynamic = {
			name: object3D.uuid,
			keyframes: keyframes
		};

		return animation;
	}

	public function prepareAnimationData(data:Dynamic, defaultMatrix:Matrix4):Array<Dynamic> {
		var keyframes:Array<Dynamic> = [];

		for (time in data) {
			keyframes.push({ time: Std.parseFloat(time), value: data[time] });
		}

		keyframes.sort(ascending);

		for (i in 0...16) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}

		return keyframes;

		function ascending(a:Dynamic, b:Dynamic):Int {
			return Std.parseFloat(a.time) - Std.parseFloat(b.time);
		}
	}

	public function createKeyframeTracks(animation:Dynamic, tracks:Array<KeyframeTrack>):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;

		var times:Array<Float> = [];
		var positionData:Array<Float> = [];
		var quaternionData:Array<Float> = [];
		var scaleData:Array<Float> = [];

		var matrix = new Matrix4();
		var position = new Vector3();
		var scale = new Vector3();
		var quaternion = new Quaternion();

		for (i in 0...keyframes.length) {
			var keyframe = keyframes[i];

			var time = keyframe.time;
			var value = keyframe.value;

			matrix.fromArray(value).transpose();
			matrix.decompose(position, quaternion, scale);

			times.push(time);
			positionData.push(position.x, position.y, position.z);
			quaternionData.push(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
			scaleData.push(scale.x, scale.y, scale.z);
		}

		if (positionData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".position", times, positionData));
		if (quaternionData.length > 0) tracks.push(new QuaternionKeyframeTrack(name + ".quaternion", times, quaternionData));
		if (scaleData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".scale", times, scaleData));
	}

	public function transformAnimationData(keyframes:Array<Dynamic>, property:Int, defaultValue:Float):Void {
		var keyframe:Dynamic;

		var empty = true;

		for (i in 0...keyframes.length) {
			keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}

		if (empty) {
			for (i in 0...keyframes.length) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	public function createMissingKeyframes(keyframes:Array<Dynamic>, property:Int):Void {
		var prev:Dynamic, next:Dynamic;

		for (i in 0...keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				prev = getPrev(keyframes, i, property);
				next = getNext(keyframes, i, property);

				if (prev == null) {
					keyframe.value[property] = next.value[property];
					continue;
				}

				if (next == null) {
					keyframe.value[property] = prev.value[property];
					continue;
				}

				interpolate(keyframe, prev, next, property);
			}
		}
	}

	public function getPrev(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i >= 0) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	public function getNext(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i < keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	public function interpolate(key:Dynamic, prev:Dynamic, next:Dynamic, property:Int):Void {
		if ((Std.parseFloat(next.time) - Std.parseFloat(prev.time)) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = ((Std.parseFloat(key.time) - Std.parseFloat(prev.time)) * (Std.parseFloat(next.value[property]) - Std.parseFloat(prev.value[property])) / (Std.parseFloat(next.time) - Std.parseFloat(prev.time))) + Std.parseFloat(prev.value[property]);
	}

	public function parseAnimationClip(xml:Xml):Void {
		var data:Dynamic = {
			name: xml.get("id") != null ? xml.get("id") : "default",
			start: Std.parseFloat(xml.get("start") != null ? xml.get("start") : "0"),
			end: Std.parseFloat(xml.get("end") != null ? xml.get("end") : "0"),
			animations: []
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.get("url")));
					break;
			}
		}

		library.clips.set(xml.get("id"), data);
	}

	public function buildAnimationClip(data:Dynamic):AnimationClip {
		var tracks:Array<KeyframeTrack> = [];

		var name = data.name;
		var duration = (data.end - data.start) != 0 ? (data.end - data.start) : -1;
		var animations = data.animations;

		for (i in 0...animations.length) {
			var animationTracks = getAnimation(animations[i]);

			for (j in 0...animationTracks.length) {
				tracks.push(animationTracks[j]);
			}
		}

		return new AnimationClip(name, duration, tracks);
	}

	public function getAnimationClip(id:String):AnimationClip {
		return getBuild(library.clips.get(id), buildAnimationClip);
	}

	public function parseController(xml:Xml):Void {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "skin":
					data.id = parseId(child.get("source"));
					data.skin = parseSkin(child);
					break;
				case "morph":
					data.id = parseId(child.get("source"));
					console.warn("THREE.ColladaLoader: Morph target animation not supported yet.");
					break;
			}
		}

		library.controllers.set(xml.get("id"), data);
	}

	public function parseSkin(xml:Xml):Dynamic {
		var data:Dynamic = {
			sources: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.get("textContent"));
					break;
				case "source":
					var id = child.get("id");
					data.sources.set(id, parseSource(child));
					break;
				case "joints":
					data.joints = parseJoints(child);
					break;
				case "vertex_weights":
					data.vertexWeights = parseVertexWeights(child);
					break;
			}
		}

		return data;
	}

	public function parseJoints(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<String>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var semantic = child.get("semantic");
					var id = parseId(child.get("source"));
					data.inputs.set(semantic, id);
					break;
			}
		}

		return data;
	}

	public function parseVertexWeights(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var semantic = child.get("semantic");
					var id = parseId(child.get("source"));
					var offset = Std.parseInt(child.get("offset"));
					data.inputs.set(semantic, { id: id, offset: offset });
					break;
				case "vcount":
					data.vcount = parseInts(child.get("textContent"));
					break;
				case "v":
					data.v = parseInts(child.get("textContent"));
					break;
			}
		}

		return data;
	}

	public function buildController(data:Dynamic):Dynamic {
		var build:Dynamic = {
			id: data.id
		};

		var geometry = library.geometries.get(build.id);

		if (data.skin != null) {
			build.skin = buildSkin(data.skin);

			geometry.sources.skinIndices = build.skin.indices;
			geometry.sources.skinWeights = build.skin.weights;
		}

		return build;
	}

	public function buildSkin(data:Dynamic):Dynamic {
		var BONE_LIMIT = 4;

		var build:Dynamic = {
			joints: [],
			indices: {
				array: [],
				stride: BONE_LIMIT
			},
			weights: {
				array: [],
				stride: BONE_LIMIT
			}
		};

		var sources = data.sources;
		var vertexWeights = data.vertexWeights;

		var vcount = vertexWeights.vcount;
		var v = vertexWeights.v;
		var jointOffset = vertexWeights.inputs.get("JOINT").offset;
		var weightOffset = vertexWeights.inputs.get("WEIGHT").offset;

		var jointSource = data.sources.get(data.joints.inputs.get("JOINT"));
		var inverseSource = data.sources.get(data.joints.inputs.get("INV_BIND_MATRIX"));

		var weights = sources.get(vertexWeights.inputs.get("WEIGHT").id).array;
		var stride = 0;

		for (i in 0...vcount.length) {
			var jointCount = vcount[i];
			var vertexSkinData:Array<Dynamic> = [];

			for (j in 0...jointCount) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];

				vertexSkinData.push({ index: skinIndex, weight: skinWeight });

				stride += 2;
			}

			vertexSkinData.sort(descending);

			for (j in 0...BONE_LIMIT) {
				var d = vertexSkinData[j];

				if (d != null) {
					build.indices.array.push(d.index);
					build.weights.array.push(d.weight);
				} else {
					build.indices.array.push(0);
					build.weights.array.push(0);
				}
			}
		}

		if (data.bindShapeMatrix != null) {
			build.bindMatrix = new Matrix4().fromArray(data.bindShapeMatrix).transpose();
		} else {
			build.bindMatrix = new Matrix4().identity();
		}

		for (i in 0...jointSource.array.length) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();

			build.joints.push({ name: name, boneInverse: boneInverse });
		}

		return build;

		function descending(a:Dynamic, b:Dynamic):Int {
			return Std.parseFloat(b.weight) - Std.parseFloat(a.weight);
		}
	}

	public function getController(id:String):Dynamic {
		return getBuild(library.controllers.get(id), buildController);
	}

	public function parseImage(xml:Xml):Void {
		var data:Dynamic = {
			init_from: xml.firstElement("init_from").get("textContent")
		};

		library.images.set(xml.get("id"), data);
	}

	public function buildImage(data:Dynamic):String {
		if (data.build != null) return data.build;
		return data.init_from;
	}

	public function getImage(id:String):String {
		var data = library.images.get(id);
		if (data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	public function parseEffect(xml:Xml):Void {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}

		library.effects.set(xml.get("id"), data);
	}

	public function parseEffectProfileCOMMON(xml:Xml):Dynamic {
		var data:Dynamic = {
			surfaces: new StringMap<Dynamic>(),
			samplers: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "newparam":
					parseEffectNewparam(child, data);
					break;
				case "technique":
					data.technique = parseEffectTechnique(child);
					break;
				case "extra":
					data.extra = parseEffectExtra(child);
					break;
			}
		}

		return data;
	}

	public function parseEffectNewparam(xml:Xml, data:Dynamic):Void {
		var sid = xml.get("sid");

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "surface":
					data.surfaces.set(sid, parseEffectSurface(child));
					break;
				case "sampler2D":
					data.samplers.set(sid, parseEffectSampler(child));
					break;
			}
		}
	}

	public function parseEffectSurface(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "init_from":
					data.init_from = child.get("textContent");
					break;
			}
		}

		return data;
	}

	public function parseEffectSampler(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "source":
					data.source = child.get("textContent");
					break;
			}
		}

		return data;
	}

	public function parseEffectTechnique(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "constant":
				case "lambert":
				case "blinn":
				case "phong":
					data.type = child.nodeName;
					data.parameters = parseEffectParameters(child);
					break;
				case "extra":
					data.extra = parseEffectExtra(child);
					break;
			}
		}

		return data;
	}

	public function parseEffectParameters(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "emission":
				case "diffuse":
				case "specular":
				case "bump":
				case "ambient":
				case "shininess":
				case "transparency":
					data[child.nodeName] = parseEffectParameter(child);
					break;
				case "transparent":
					data[child.nodeName] = {
						opaque: child.hasAttribute("opaque") ? child.get("opaque") : "A_ONE",
						data: parseEffectParameter(child)
					};
					break;
			}
		}

		return data;
	}

	public function parseEffectParameter(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "color":
					data[child.nodeName] = parseFloats(child.get("textContent"));
					break;
				case "float":
					data[child.nodeName] = Std.parseFloat(child.get("textContent"));
					break;
				case "texture":
					data[child.nodeName] = { id: child.get("texture"), extra: parseEffectParameterTexture(child) };
					break;
			}
		}

		return data;
	}

	public function parseEffectParameterTexture(xml:Xml):Dynamic {
		var data:Dynamic = {
			technique: {}
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				
import haxe.io.Bytes;
import haxe.io.StringTools;
import haxe.xml.Xml;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import three.extras.core.AnimationClip;
import three.extras.core.AnimationAction;
import three.extras.core.KeyframeTrack;
import three.extras.core.VectorKeyframeTrack;
import three.extras.core.QuaternionKeyframeTrack;
import three.extras.loaders.FileLoader;
import three.extras.loaders.TextureLoader;
import three.extras.loaders.TGALoader;
import three.core.Object3D;
import three.core.Scene;
import three.core.Group;
import three.core.Bone;
import three.core.Mesh;
import three.core.SkinnedMesh;
import three.core.LineSegments;
import three.core.Line;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Skeleton;
import three.math.Color;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Matrix4;
import three.materials.MeshBasicMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.LineBasicMaterial;
import three.textures.Texture;
import three.textures.RepeatWrapping;
import three.textures.ClampToEdgeWrapping;
import three.textures.SRGBColorSpace;

class ColladaLoader {

	public var manager:FileLoader;
	public var path:String = "";
	public var resourcePath:String = "";
	public var crossOrigin:String = null;
	public var requestHeader:StringMap<String> = new StringMap<String>();
	public var withCredentials:Bool = false;

	public function new(manager:FileLoader) {
		this.manager = manager;
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(parse(text, path));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				this.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String, path:String):Dynamic {
		var count = 0;
		var tempColor = new Color();
		var animations:Array<AnimationClip> = [];
		var kinematics:Dynamic = {};

		var library:Dynamic = {
			animations: new StringMap<Dynamic>(),
			clips: new StringMap<Dynamic>(),
			controllers: new StringMap<Dynamic>(),
			images: new StringMap<Dynamic>(),
			effects: new StringMap<Dynamic>(),
			materials: new StringMap<Dynamic>(),
			cameras: new StringMap<Dynamic>(),
			lights: new StringMap<Dynamic>(),
			geometries: new StringMap<Dynamic>(),
			nodes: new StringMap<Dynamic>(),
			visualScenes: new StringMap<Dynamic>(),
			kinematicsModels: new StringMap<Dynamic>(),
			physicsModels: new StringMap<Dynamic>(),
			kinematicsScenes: new StringMap<Dynamic>()
		};

		if (text.length == 0) {
			return { scene: new Scene() };
		}

		var xml:Xml = Xml.parse(text);

		var collada = getElementsByTagName(xml, "COLLADA")[0];

		var parserError = xml.firstElement("parsererror");
		if (parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText:String;

			if (errorElement != null) {
				errorText = errorElement.get("textContent");
			} else {
				errorText = parserErrorToText(parserError);
			}

			console.error("THREE.ColladaLoader: Failed to parse collada file.\n", errorText);
			return null;
		}

		var version = collada.get("version");
		console.debug("THREE.ColladaLoader: File version", version);

		var asset = parseAsset(getElementsByTagName(collada, "asset")[0]);
		var textureLoader = new TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		textureLoader.setCrossOrigin(this.crossOrigin);

		var tgaLoader:TGALoader;

		if (TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}

		parseLibrary(collada, "library_animations", "animation", parseAnimation);
		parseLibrary(collada, "library_animation_clips", "animation_clip", parseAnimationClip);
		parseLibrary(collada, "library_controllers", "controller", parseController);
		parseLibrary(collada, "library_images", "image", parseImage);
		parseLibrary(collada, "library_effects", "effect", parseEffect);
		parseLibrary(collada, "library_materials", "material", parseMaterial);
		parseLibrary(collada, "library_cameras", "camera", parseCamera);
		parseLibrary(collada, "library_lights", "light", parseLight);
		parseLibrary(collada, "library_geometries", "geometry", parseGeometry);
		parseLibrary(collada, "library_nodes", "node", parseNode);
		parseLibrary(collada, "library_visual_scenes", "visual_scene", parseVisualScene);
		parseLibrary(collada, "library_kinematics_models", "kinematics_model", parseKinematicsModel);
		parseLibrary(collada, "library_physics_models", "physics_model", parsePhysicsModel);
		parseLibrary(collada, "scene", "instance_kinematics_scene", parseKinematicsScene);

		buildLibrary(library.animations, buildAnimation);
		buildLibrary(library.clips, buildAnimationClip);
		buildLibrary(library.controllers, buildController);
		buildLibrary(library.images, buildImage);
		buildLibrary(library.effects, buildEffect);
		buildLibrary(library.materials, buildMaterial);
		buildLibrary(library.cameras, buildCamera);
		buildLibrary(library.lights, buildLight);
		buildLibrary(library.geometries, buildGeometry);
		buildLibrary(library.visualScenes, buildVisualScene);

		setupAnimations();
		setupKinematics();

		var scene = parseScene(getElementsByTagName(collada, "scene")[0]);
		scene.animations = animations;

		if (asset.upAxis == "Z_UP") {
			console.warn("THREE.ColladaLoader: You are loading an asset with a Z-UP coordinate system. The loader just rotates the asset to transform it into Y-UP. The vertex data are not converted, see #24289.");
			scene.rotation.set(-Math.PI / 2, 0, 0);
		}

		scene.scale.multiplyScalar(asset.unit);

		return {
			get animations() {
				console.warn("THREE.ColladaLoader: Please access animations over scene.animations now.");
				return animations;
			},
			kinematics: kinematics,
			library: library,
			scene: scene
		};
	}

	public function getElementsByTagName(xml:Xml, tagName:String):Array<Xml> {
		var result:Array<Xml> = [];
		for (element in xml.elements()) {
			if (element.nodeName == tagName) {
				result.push(element);
			}
		}
		return result;
	}

	public function parserErrorToText(parserError:Xml):String {
		var result:String = "";
		var stack:Array<Xml> = [parserError];

		while (stack.length > 0) {
			var node = stack.shift();
			if (node.nodeType == Xml.TEXT_NODE) {
				result += node.get("textContent");
			} else {
				result += "\n";
				stack.push(node.elements());
			}
		}

		return result.trim();
	}

	public function parseAsset(xml:Xml):Dynamic {
		return {
			unit: parseAssetUnit(xml.firstElement("unit")),
			upAxis: parseAssetUpAxis(xml.firstElement("up_axis"))
		};
	}

	public function parseAssetUnit(xml:Xml):Float {
		if (xml != null && xml.hasAttribute("meter")) {
			return Std.parseFloat(xml.get("meter"));
		} else {
			return 1;
		}
	}

	public function parseAssetUpAxis(xml:Xml):String {
		return xml != null ? xml.get("textContent") : "Y_UP";
	}

	public function parseLibrary(xml:Xml, libraryName:String, nodeName:String, parser:Xml->Void):Void {
		var library = xml.firstElement(libraryName);
		if (library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for (i in 0...elements.length) {
				parser(elements[i]);
			}
		}
	}

	public function buildLibrary(data:StringMap<Dynamic>, builder:Dynamic->Dynamic):Void {
		for (name in data) {
			var object = data.get(name);
			object.build = builder(data.get(name));
		}
	}

	public function getBuild(data:Dynamic, builder:Dynamic->Dynamic):Dynamic {
		if (data.build != null) return data.build;
		data.build = builder(data);
		return data.build;
	}

	public function parseAnimation(xml:Xml):Void {
		var data:Dynamic = {
			sources: new StringMap<Dynamic>(),
			samplers: new StringMap<Dynamic>(),
			channels: new StringMap<Dynamic>()
		};

		var hasChildren = false;

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			var id:String;

			switch (child.nodeName) {
				case "source":
					id = child.get("id");
					data.sources.set(id, parseSource(child));
					break;
				case "sampler":
					id = child.get("id");
					data.samplers.set(id, parseAnimationSampler(child));
					break;
				case "channel":
					id = child.get("target");
					data.channels.set(id, parseAnimationChannel(child));
					break;
				case "animation":
					parseAnimation(child);
					hasChildren = true;
					break;
				default:
					console.log(child);
			}
		}

		if (!hasChildren) {
			library.animations.set(xml.get("id") != null ? xml.get("id") : MathUtils.generateUUID(), data);
		}
	}

	public function parseAnimationSampler(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<String>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var id = parseId(child.get("source"));
					var semantic = child.get("semantic");
					data.inputs.set(semantic, id);
					break;
			}
		}

		return data;
	}

	public function parseAnimationChannel(xml:Xml):Dynamic {
		var data:Dynamic = {};

		var target = xml.get("target");

		var parts = target.split("/");

		var id = parts.shift();
		var sid = parts.shift();

		var arraySyntax = (sid.indexOf("(") != -1);
		var memberSyntax = (sid.indexOf(".") != -1);

		if (memberSyntax) {
			parts = sid.split(".");
			sid = parts.shift();
			data.member = parts.shift();
		} else if (arraySyntax) {
			var indices = sid.split("(");
			sid = indices.shift();
			for (i in 0...indices.length) {
				indices[i] = Std.parseInt(indices[i].replace(")", ""));
			}
			data.indices = indices;
		}

		data.id = id;
		data.sid = sid;

		data.arraySyntax = arraySyntax;
		data.memberSyntax = memberSyntax;

		data.sampler = parseId(xml.get("source"));

		return data;
	}

	public function buildAnimation(data:Dynamic):Array<KeyframeTrack> {
		var tracks:Array<KeyframeTrack> = [];

		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;

		for (target in channels) {
			if (channels.exists(target)) {
				var channel = channels.get(target);
				var sampler = samplers.get(channel.sampler);

				var inputId = sampler.inputs.get("INPUT");
				var outputId = sampler.inputs.get("OUTPUT");

				var inputSource = sources.get(inputId);
				var outputSource = sources.get(outputId);

				var animation = buildAnimationChannel(channel, inputSource, outputSource);

				createKeyframeTracks(animation, tracks);
			}
		}

		return tracks;
	}

	public function getAnimation(id:String):Array<KeyframeTrack> {
		return getBuild(library.animations.get(id), buildAnimation);
	}

	public function buildAnimationChannel(channel:Dynamic, inputSource:Dynamic, outputSource:Dynamic):Dynamic {
		var node = library.nodes.get(channel.id);
		var object3D = getNode(node.id);

		var transform = node.transforms.get(channel.sid);
		var defaultMatrix = node.matrix.clone().transpose();

		var time:Float, stride:Int;
		var i:Int, il:Int, j:Int, jl:Int;

		var data:Dynamic = {};

		switch (transform) {
			case "matrix":
				for (i in 0...inputSource.array.length) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;

					if (data[time] == null) data[time] = {};

					if (channel.arraySyntax) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data[time][index] = value;
					} else {
						for (j in 0...outputSource.stride) {
							data[time][j] = outputSource.array[stride + j];
						}
					}
				}
				break;
			case "translate":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
			case "rotate":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
			case "scale":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
		}

		var keyframes = prepareAnimationData(data, defaultMatrix);

		var animation:Dynamic = {
			name: object3D.uuid,
			keyframes: keyframes
		};

		return animation;
	}

	public function prepareAnimationData(data:Dynamic, defaultMatrix:Matrix4):Array<Dynamic> {
		var keyframes:Array<Dynamic> = [];

		for (time in data) {
			keyframes.push({ time: Std.parseFloat(time), value: data[time] });
		}

		keyframes.sort(ascending);

		for (i in 0...16) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}

		return keyframes;

		function ascending(a:Dynamic, b:Dynamic):Int {
			return Std.parseFloat(a.time) - Std.parseFloat(b.time);
		}
	}

	public function createKeyframeTracks(animation:Dynamic, tracks:Array<KeyframeTrack>):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;

		var times:Array<Float> = [];
		var positionData:Array<Float> = [];
		var quaternionData:Array<Float> = [];
		var scaleData:Array<Float> = [];

		var matrix = new Matrix4();
		var position = new Vector3();
		var scale = new Vector3();
		var quaternion = new Quaternion();

		for (i in 0...keyframes.length) {
			var keyframe = keyframes[i];

			var time = keyframe.time;
			var value = keyframe.value;

			matrix.fromArray(value).transpose();
			matrix.decompose(position, quaternion, scale);

			times.push(time);
			positionData.push(position.x, position.y, position.z);
			quaternionData.push(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
			scaleData.push(scale.x, scale.y, scale.z);
		}

		if (positionData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".position", times, positionData));
		if (quaternionData.length > 0) tracks.push(new QuaternionKeyframeTrack(name + ".quaternion", times, quaternionData));
		if (scaleData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".scale", times, scaleData));
	}

	public function transformAnimationData(keyframes:Array<Dynamic>, property:Int, defaultValue:Float):Void {
		var keyframe:Dynamic;

		var empty = true;

		for (i in 0...keyframes.length) {
			keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}

		if (empty) {
			for (i in 0...keyframes.length) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	public function createMissingKeyframes(keyframes:Array<Dynamic>, property:Int):Void {
		var prev:Dynamic, next:Dynamic;

		for (i in 0...keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				prev = getPrev(keyframes, i, property);
				next = getNext(keyframes, i, property);

				if (prev == null) {
					keyframe.value[property] = next.value[property];
					continue;
				}

				if (next == null) {
					keyframe.value[property] = prev.value[property];
					continue;
				}

				interpolate(keyframe, prev, next, property);
			}
		}
	}

	public function getPrev(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i >= 0) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	public function getNext(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i < keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	public function interpolate(key:Dynamic, prev:Dynamic, next:Dynamic, property:Int):Void {
		if ((Std.parseFloat(next.time) - Std.parseFloat(prev.time)) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = ((Std.parseFloat(key.time) - Std.parseFloat(prev.time)) * (Std.parseFloat(next.value[property]) - Std.parseFloat(prev.value[property])) / (Std.parseFloat(next.time) - Std.parseFloat(prev.time))) + Std.parseFloat(prev.value[property]);
	}

	public function parseAnimationClip(xml:Xml):Void {
		var data:Dynamic = {
			name: xml.get("id") != null ? xml.get("id") : "default",
			start: Std.parseFloat(xml.get("start") != null ? xml.get("start") : "0"),
			end: Std.parseFloat(xml.get("end") != null ? xml.get("end") : "0"),
			animations: []
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.get("url")));
					break;
			}
		}

		library.clips.set(xml.get("id"), data);
	}

	public function buildAnimationClip(data:Dynamic):AnimationClip {
		var tracks:Array<KeyframeTrack> = [];

		var name = data.name;
		var duration = (data.end - data.start) != 0 ? (data.end - data.start) : -1;
		var animations = data.animations;

		for (i in 0...animations.length) {
			var animationTracks = getAnimation(animations[i]);

			for (j in 0...animationTracks.length) {
				tracks.push(animationTracks[j]);
			}
		}

		return new AnimationClip(name, duration, tracks);
	}

	public function getAnimationClip(id:String):AnimationClip {
		return getBuild(library.clips.get(id), buildAnimationClip);
	}

	public function parseController(xml:Xml):Void {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "skin":
					data.id = parseId(child.get("source"));
					data.skin = parseSkin(child);
					break;
				case "morph":
					data.id = parseId(child.get("source"));
					console.warn("THREE.ColladaLoader: Morph target animation not supported yet.");
					break;
			}
		}

		library.controllers.set(xml.get("id"), data);
	}

	public function parseSkin(xml:Xml):Dynamic {
		var data:Dynamic = {
			sources: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.get("textContent"));
					break;
				case "source":
					var id = child.get("id");
					data.sources.set(id, parseSource(child));
					break;
				case "joints":
					data.joints = parseJoints(child);
					break;
				case "vertex_weights":
					data.vertexWeights = parseVertexWeights(child);
					break;
			}
		}

		return data;
	}

	public function parseJoints(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<String>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var semantic = child.get("semantic");
					var id = parseId(child.get("source"));
					data.inputs.set(semantic, id);
					break;
			}
		}

		return data;
	}

	public function parseVertexWeights(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var semantic = child.get("semantic");
					var id = parseId(child.get("source"));
					var offset = Std.parseInt(child.get("offset"));
					data.inputs.set(semantic, { id: id, offset: offset });
					break;
				case "vcount":
					data.vcount = parseInts(child.get("textContent"));
					break;
				case "v":
					data.v = parseInts(child.get("textContent"));
					break;
			}
		}

		return data;
	}

	public function buildController(data:Dynamic):Dynamic {
		var build:Dynamic = {
			id: data.id
		};

		var geometry = library.geometries.get(build.id);

		if (data.skin != null) {
			build.skin = buildSkin(data.skin);

			geometry.sources.skinIndices = build.skin.indices;
			geometry.sources.skinWeights = build.skin.weights;
		}

		return build;
	}

	public function buildSkin(data:Dynamic):Dynamic {
		var BONE_LIMIT = 4;

		var build:Dynamic = {
			joints: [],
			indices: {
				array: [],
				stride: BONE_LIMIT
			},
			weights: {
				array: [],
				stride: BONE_LIMIT
			}
		};

		var sources = data.sources;
		var vertexWeights = data.vertexWeights;

		var vcount = vertexWeights.vcount;
		var v = vertexWeights.v;
		var jointOffset = vertexWeights.inputs.get("JOINT").offset;
		var weightOffset = vertexWeights.inputs.get("WEIGHT").offset;

		var jointSource = data.sources.get(data.joints.inputs.get("JOINT"));
		var inverseSource = data.sources.get(data.joints.inputs.get("INV_BIND_MATRIX"));

		var weights = sources.get(vertexWeights.inputs.get("WEIGHT").id).array;
		var stride = 0;

		for (i in 0...vcount.length) {
			var jointCount = vcount[i];
			var vertexSkinData:Array<Dynamic> = [];

			for (j in 0...jointCount) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];

				vertexSkinData.push({ index: skinIndex, weight: skinWeight });

				stride += 2;
			}

			vertexSkinData.sort(descending);

			for (j in 0...BONE_LIMIT) {
				var d = vertexSkinData[j];

				if (d != null) {
					build.indices.array.push(d.index);
					build.weights.array.push(d.weight);
				} else {
					build.indices.array.push(0);
					build.weights.array.push(0);
				}
			}
		}

		if (data.bindShapeMatrix != null) {
			build.bindMatrix = new Matrix4().fromArray(data.bindShapeMatrix).transpose();
		} else {
			build.bindMatrix = new Matrix4().identity();
		}

		for (i in 0...jointSource.array.length) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();

			build.joints.push({ name: name, boneInverse: boneInverse });
		}

		return build;

		function descending(a:Dynamic, b:Dynamic):Int {
			return Std.parseFloat(b.weight) - Std.parseFloat(a.weight);
		}
	}

	public function getController(id:String):Dynamic {
		return getBuild(library.controllers.get(id), buildController);
	}

	public function parseImage(xml:Xml):Void {
		var data:Dynamic = {
			init_from: xml.firstElement("init_from").get("textContent")
		};

		library.images.set(xml.get("id"), data);
	}

	public function buildImage(data:Dynamic):String {
		if (data.build != null) return data.build;
		return data.init_from;
	}

	public function getImage(id:String):String {
		var data = library.images.get(id);
		if (data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	public function parseEffect(xml:Xml):Void {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}

		library.effects.set(xml.get("id"), data);
	}

	public function parseEffectProfileCOMMON(xml:Xml):Dynamic {
		var data:Dynamic = {
			surfaces: new StringMap<Dynamic>(),
			samplers: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "newparam":
					parseEffectNewparam(child, data);
					break;
				case "technique":
					data.technique = parseEffectTechnique(child);
					break;
				case "extra":
					data.extra = parseEffectExtra(child);
					break;
			}
		}

		return data;
	}

	public function parseEffectNewparam(xml:Xml, data:Dynamic):Void {
		var sid = xml.get("sid");

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "surface":
					data.surfaces.set(sid, parseEffectSurface(child));
					break;
				case "sampler2D":
					data.samplers.set(sid, parseEffectSampler(child));
					break;
			}
		}
	}

	public function parseEffectSurface(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "init_from":
					data.init_from = child.get("textContent");
					break;
			}
		}

		return data;
	}

	public function parseEffectSampler(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "source":
					data.source = child.get("textContent");
					break;
			}
		}

		return data;
	}

	public function parseEffectTechnique(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "constant":
				case "lambert":
				case "blinn":
				case "phong":
					data.type = child.nodeName;
					data.parameters = parseEffectParameters(child);
					break;
				case "extra":
					data.extra = parseEffectExtra(child);
					break;
			}
		}

		return data;
	}

	public function parseEffectParameters(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "emission":
				case "diffuse":
				case "specular":
				case "bump":
				case "ambient":
				case "shininess":
				case "transparency":
					data[child.nodeName] = parseEffectParameter(child);
					break;
				case "transparent":
					data[child.nodeName] = {
						opaque: child.hasAttribute("opaque") ? child.get("opaque") : "A_ONE",
						data: parseEffectParameter(child)
					};
					break;
			}
		}

		return data;
	}

	public function parseEffectParameter(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "color":
					data[child.nodeName] = parseFloats(child.get("textContent"));
					break;
				case "float":
					data[child.nodeName] = Std.parseFloat(child.get("textContent"));
					break;
				case "texture":
					data[child.nodeName] = { id: child.get("texture"), extra: parseEffectParameterTexture(child) };
					break;
			}
		}

		return data;
	}

	public function parseEffectParameterTexture(xml:Xml):Dynamic {
		var data:Dynamic = {
			technique: {}
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				
import haxe.io.Bytes;
import haxe.io.StringTools;
import haxe.xml.Xml;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import three.extras.core.AnimationClip;
import three.extras.core.AnimationAction;
import three.extras.core.KeyframeTrack;
import three.extras.core.VectorKeyframeTrack;
import three.extras.core.QuaternionKeyframeTrack;
import three.extras.loaders.FileLoader;
import three.extras.loaders.TextureLoader;
import three.extras.loaders.TGALoader;
import three.core.Object3D;
import three.core.Scene;
import three.core.Group;
import three.core.Bone;
import three.core.Mesh;
import three.core.SkinnedMesh;
import three.core.LineSegments;
import three.core.Line;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Skeleton;
import three.math.Color;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Matrix4;
import three.materials.MeshBasicMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.LineBasicMaterial;
import three.textures.Texture;
import three.textures.RepeatWrapping;
import three.textures.ClampToEdgeWrapping;
import three.textures.SRGBColorSpace;

class ColladaLoader {

	public var manager:FileLoader;
	public var path:String = "";
	public var resourcePath:String = "";
	public var crossOrigin:String = null;
	public var requestHeader:StringMap<String> = new StringMap<String>();
	public var withCredentials:Bool = false;

	public function new(manager:FileLoader) {
		this.manager = manager;
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(parse(text, path));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				this.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String, path:String):Dynamic {
		var count = 0;
		var tempColor = new Color();
		var animations:Array<AnimationClip> = [];
		var kinematics:Dynamic = {};

		var library:Dynamic = {
			animations: new StringMap<Dynamic>(),
			clips: new StringMap<Dynamic>(),
			controllers: new StringMap<Dynamic>(),
			images: new StringMap<Dynamic>(),
			effects: new StringMap<Dynamic>(),
			materials: new StringMap<Dynamic>(),
			cameras: new StringMap<Dynamic>(),
			lights: new StringMap<Dynamic>(),
			geometries: new StringMap<Dynamic>(),
			nodes: new StringMap<Dynamic>(),
			visualScenes: new StringMap<Dynamic>(),
			kinematicsModels: new StringMap<Dynamic>(),
			physicsModels: new StringMap<Dynamic>(),
			kinematicsScenes: new StringMap<Dynamic>()
		};

		if (text.length == 0) {
			return { scene: new Scene() };
		}

		var xml:Xml = Xml.parse(text);

		var collada = getElementsByTagName(xml, "COLLADA")[0];

		var parserError = xml.firstElement("parsererror");
		if (parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText:String;

			if (errorElement != null) {
				errorText = errorElement.get("textContent");
			} else {
				errorText = parserErrorToText(parserError);
			}

			console.error("THREE.ColladaLoader: Failed to parse collada file.\n", errorText);
			return null;
		}

		var version = collada.get("version");
		console.debug("THREE.ColladaLoader: File version", version);

		var asset = parseAsset(getElementsByTagName(collada, "asset")[0]);
		var textureLoader = new TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		textureLoader.setCrossOrigin(this.crossOrigin);

		var tgaLoader:TGALoader;

		if (TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}

		parseLibrary(collada, "library_animations", "animation", parseAnimation);
		parseLibrary(collada, "library_animation_clips", "animation_clip", parseAnimationClip);
		parseLibrary(collada, "library_controllers", "controller", parseController);
		parseLibrary(collada, "library_images", "image", parseImage);
		parseLibrary(collada, "library_effects", "effect", parseEffect);
		parseLibrary(collada, "library_materials", "material", parseMaterial);
		parseLibrary(collada, "library_cameras", "camera", parseCamera);
		parseLibrary(collada, "library_lights", "light", parseLight);
		parseLibrary(collada, "library_geometries", "geometry", parseGeometry);
		parseLibrary(collada, "library_nodes", "node", parseNode);
		parseLibrary(collada, "library_visual_scenes", "visual_scene", parseVisualScene);
		parseLibrary(collada, "library_kinematics_models", "kinematics_model", parseKinematicsModel);
		parseLibrary(collada, "library_physics_models", "physics_model", parsePhysicsModel);
		parseLibrary(collada, "scene", "instance_kinematics_scene", parseKinematicsScene);

		buildLibrary(library.animations, buildAnimation);
		buildLibrary(library.clips, buildAnimationClip);
		buildLibrary(library.controllers, buildController);
		buildLibrary(library.images, buildImage);
		buildLibrary(library.effects, buildEffect);
		buildLibrary(library.materials, buildMaterial);
		buildLibrary(library.cameras, buildCamera);
		buildLibrary(library.lights, buildLight);
		buildLibrary(library.geometries, buildGeometry);
		buildLibrary(library.visualScenes, buildVisualScene);

		setupAnimations();
		setupKinematics();

		var scene = parseScene(getElementsByTagName(collada, "scene")[0]);
		scene.animations = animations;

		if (asset.upAxis == "Z_UP") {
			console.warn("THREE.ColladaLoader: You are loading an asset with a Z-UP coordinate system. The loader just rotates the asset to transform it into Y-UP. The vertex data are not converted, see #24289.");
			scene.rotation.set(-Math.PI / 2, 0, 0);
		}

		scene.scale.multiplyScalar(asset.unit);

		return {
			get animations() {
				console.warn("THREE.ColladaLoader: Please access animations over scene.animations now.");
				return animations;
			},
			kinematics: kinematics,
			library: library,
			scene: scene
		};
	}

	public function getElementsByTagName(xml:Xml, tagName:String):Array<Xml> {
		var result:Array<Xml> = [];
		for (element in xml.elements()) {
			if (element.nodeName == tagName) {
				result.push(element);
			}
		}
		return result;
	}

	public function parserErrorToText(parserError:Xml):String {
		var result:String = "";
		var stack:Array<Xml> = [parserError];

		while (stack.length > 0) {
			var node = stack.shift();
			if (node.nodeType == Xml.TEXT_NODE) {
				result += node.get("textContent");
			} else {
				result += "\n";
				stack.push(node.elements());
			}
		}

		return result.trim();
	}

	public function parseAsset(xml:Xml):Dynamic {
		return {
			unit: parseAssetUnit(xml.firstElement("unit")),
			upAxis: parseAssetUpAxis(xml.firstElement("up_axis"))
		};
	}

	public function parseAssetUnit(xml:Xml):Float {
		if (xml != null && xml.hasAttribute("meter")) {
			return Std.parseFloat(xml.get("meter"));
		} else {
			return 1;
		}
	}

	public function parseAssetUpAxis(xml:Xml):String {
		return xml != null ? xml.get("textContent") : "Y_UP";
	}

	public function parseLibrary(xml:Xml, libraryName:String, nodeName:String, parser:Xml->Void):Void {
		var library = xml.firstElement(libraryName);
		if (library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for (i in 0...elements.length) {
				parser(elements[i]);
			}
		}
	}

	public function buildLibrary(data:StringMap<Dynamic>, builder:Dynamic->Dynamic):Void {
		for (name in data) {
			var object = data.get(name);
			object.build = builder(data.get(name));
		}
	}

	public function getBuild(data:Dynamic, builder:Dynamic->Dynamic):Dynamic {
		if (data.build != null) return data.build;
		data.build = builder(data);
		return data.build;
	}

	public function parseAnimation(xml:Xml):Void {
		var data:Dynamic = {
			sources: new StringMap<Dynamic>(),
			samplers: new StringMap<Dynamic>(),
			channels: new StringMap<Dynamic>()
		};

		var hasChildren = false;

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			var id:String;

			switch (child.nodeName) {
				case "source":
					id = child.get("id");
					data.sources.set(id, parseSource(child));
					break;
				case "sampler":
					id = child.get("id");
					data.samplers.set(id, parseAnimationSampler(child));
					break;
				case "channel":
					id = child.get("target");
					data.channels.set(id, parseAnimationChannel(child));
					break;
				case "animation":
					parseAnimation(child);
					hasChildren = true;
					break;
				default:
					console.log(child);
			}
		}

		if (!hasChildren) {
			library.animations.set(xml.get("id") != null ? xml.get("id") : MathUtils.generateUUID(), data);
		}
	}

	public function parseAnimationSampler(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<String>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var id = parseId(child.get("source"));
					var semantic = child.get("semantic");
					data.inputs.set(semantic, id);
					break;
			}
		}

		return data;
	}

	public function parseAnimationChannel(xml:Xml):Dynamic {
		var data:Dynamic = {};

		var target = xml.get("target");

		var parts = target.split("/");

		var id = parts.shift();
		var sid = parts.shift();

		var arraySyntax = (sid.indexOf("(") != -1);
		var memberSyntax = (sid.indexOf(".") != -1);

		if (memberSyntax) {
			parts = sid.split(".");
			sid = parts.shift();
			data.member = parts.shift();
		} else if (arraySyntax) {
			var indices = sid.split("(");
			sid = indices.shift();
			for (i in 0...indices.length) {
				indices[i] = Std.parseInt(indices[i].replace(")", ""));
			}
			data.indices = indices;
		}

		data.id = id;
		data.sid = sid;

		data.arraySyntax = arraySyntax;
		data.memberSyntax = memberSyntax;

		data.sampler = parseId(xml.get("source"));

		return data;
	}

	public function buildAnimation(data:Dynamic):Array<KeyframeTrack> {
		var tracks:Array<KeyframeTrack> = [];

		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;

		for (target in channels) {
			if (channels.exists(target)) {
				var channel = channels.get(target);
				var sampler = samplers.get(channel.sampler);

				var inputId = sampler.inputs.get("INPUT");
				var outputId = sampler.inputs.get("OUTPUT");

				var inputSource = sources.get(inputId);
				var outputSource = sources.get(outputId);

				var animation = buildAnimationChannel(channel, inputSource, outputSource);

				createKeyframeTracks(animation, tracks);
			}
		}

		return tracks;
	}

	public function getAnimation(id:String):Array<KeyframeTrack> {
		return getBuild(library.animations.get(id), buildAnimation);
	}

	public function buildAnimationChannel(channel:Dynamic, inputSource:Dynamic, outputSource:Dynamic):Dynamic {
		var node = library.nodes.get(channel.id);
		var object3D = getNode(node.id);

		var transform = node.transforms.get(channel.sid);
		var defaultMatrix = node.matrix.clone().transpose();

		var time:Float, stride:Int;
		var i:Int, il:Int, j:Int, jl:Int;

		var data:Dynamic = {};

		switch (transform) {
			case "matrix":
				for (i in 0...inputSource.array.length) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;

					if (data[time] == null) data[time] = {};

					if (channel.arraySyntax) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data[time][index] = value;
					} else {
						for (j in 0...outputSource.stride) {
							data[time][j] = outputSource.array[stride + j];
						}
					}
				}
				break;
			case "translate":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
			case "rotate":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
			case "scale":
				console.warn("THREE.ColladaLoader: Animation transform type \"%s\" not yet implemented.", transform);
				break;
		}

		var keyframes = prepareAnimationData(data, defaultMatrix);

		var animation:Dynamic = {
			name: object3D.uuid,
			keyframes: keyframes
		};

		return animation;
	}

	public function prepareAnimationData(data:Dynamic, defaultMatrix:Matrix4):Array<Dynamic> {
		var keyframes:Array<Dynamic> = [];

		for (time in data) {
			keyframes.push({ time: Std.parseFloat(time), value: data[time] });
		}

		keyframes.sort(ascending);

		for (i in 0...16) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}

		return keyframes;

		function ascending(a:Dynamic, b:Dynamic):Int {
			return Std.parseFloat(a.time) - Std.parseFloat(b.time);
		}
	}

	public function createKeyframeTracks(animation:Dynamic, tracks:Array<KeyframeTrack>):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;

		var times:Array<Float> = [];
		var positionData:Array<Float> = [];
		var quaternionData:Array<Float> = [];
		var scaleData:Array<Float> = [];

		var matrix = new Matrix4();
		var position = new Vector3();
		var scale = new Vector3();
		var quaternion = new Quaternion();

		for (i in 0...keyframes.length) {
			var keyframe = keyframes[i];

			var time = keyframe.time;
			var value = keyframe.value;

			matrix.fromArray(value).transpose();
			matrix.decompose(position, quaternion, scale);

			times.push(time);
			positionData.push(position.x, position.y, position.z);
			quaternionData.push(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
			scaleData.push(scale.x, scale.y, scale.z);
		}

		if (positionData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".position", times, positionData));
		if (quaternionData.length > 0) tracks.push(new QuaternionKeyframeTrack(name + ".quaternion", times, quaternionData));
		if (scaleData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".scale", times, scaleData));
	}

	public function transformAnimationData(keyframes:Array<Dynamic>, property:Int, defaultValue:Float):Void {
		var keyframe:Dynamic;

		var empty = true;

		for (i in 0...keyframes.length) {
			keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}

		if (empty) {
			for (i in 0...keyframes.length) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	public function createMissingKeyframes(keyframes:Array<Dynamic>, property:Int):Void {
		var prev:Dynamic, next:Dynamic;

		for (i in 0...keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				prev = getPrev(keyframes, i, property);
				next = getNext(keyframes, i, property);

				if (prev == null) {
					keyframe.value[property] = next.value[property];
					continue;
				}

				if (next == null) {
					keyframe.value[property] = prev.value[property];
					continue;
				}

				interpolate(keyframe, prev, next, property);
			}
		}
	}

	public function getPrev(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i >= 0) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	public function getNext(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i < keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	public function interpolate(key:Dynamic, prev:Dynamic, next:Dynamic, property:Int):Void {
		if ((Std.parseFloat(next.time) - Std.parseFloat(prev.time)) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = ((Std.parseFloat(key.time) - Std.parseFloat(prev.time)) * (Std.parseFloat(next.value[property]) - Std.parseFloat(prev.value[property])) / (Std.parseFloat(next.time) - Std.parseFloat(prev.time))) + Std.parseFloat(prev.value[property]);
	}

	public function parseAnimationClip(xml:Xml):Void {
		var data:Dynamic = {
			name: xml.get("id") != null ? xml.get("id") : "default",
			start: Std.parseFloat(xml.get("start") != null ? xml.get("start") : "0"),
			end: Std.parseFloat(xml.get("end") != null ? xml.get("end") : "0"),
			animations: []
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.get("url")));
					break;
			}
		}

		library.clips.set(xml.get("id"), data);
	}

	public function buildAnimationClip(data:Dynamic):AnimationClip {
		var tracks:Array<KeyframeTrack> = [];

		var name = data.name;
		var duration = (data.end - data.start) != 0 ? (data.end - data.start) : -1;
		var animations = data.animations;

		for (i in 0...animations.length) {
			var animationTracks = getAnimation(animations[i]);

			for (j in 0...animationTracks.length) {
				tracks.push(animationTracks[j]);
			}
		}

		return new AnimationClip(name, duration, tracks);
	}

	public function getAnimationClip(id:String):AnimationClip {
		return getBuild(library.clips.get(id), buildAnimationClip);
	}

	public function parseController(xml:Xml):Void {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "skin":
					data.id = parseId(child.get("source"));
					data.skin = parseSkin(child);
					break;
				case "morph":
					data.id = parseId(child.get("source"));
					console.warn("THREE.ColladaLoader: Morph target animation not supported yet.");
					break;
			}
		}

		library.controllers.set(xml.get("id"), data);
	}

	public function parseSkin(xml:Xml):Dynamic {
		var data:Dynamic = {
			sources: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.get("textContent"));
					break;
				case "source":
					var id = child.get("id");
					data.sources.set(id, parseSource(child));
					break;
				case "joints":
					data.joints = parseJoints(child);
					break;
				case "vertex_weights":
					data.vertexWeights = parseVertexWeights(child);
					break;
			}
		}

		return data;
	}

	public function parseJoints(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<String>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var semantic = child.get("semantic");
					var id = parseId(child.get("source"));
					data.inputs.set(semantic, id);
					break;
			}
		}

		return data;
	}

	public function parseVertexWeights(xml:Xml):Dynamic {
		var data:Dynamic = {
			inputs: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "input":
					var semantic = child.get("semantic");
					var id = parseId(child.get("source"));
					var offset = Std.parseInt(child.get("offset"));
					data.inputs.set(semantic, { id: id, offset: offset });
					break;
				case "vcount":
					data.vcount = parseInts(child.get("textContent"));
					break;
				case "v":
					data.v = parseInts(child.get("textContent"));
					break;
			}
		}

		return data;
	}

	public function buildController(data:Dynamic):Dynamic {
		var build:Dynamic = {
			id: data.id
		};

		var geometry = library.geometries.get(build.id);

		if (data.skin != null) {
			build.skin = buildSkin(data.skin);

			geometry.sources.skinIndices = build.skin.indices;
			geometry.sources.skinWeights = build.skin.weights;
		}

		return build;
	}

	public function buildSkin(data:Dynamic):Dynamic {
		var BONE_LIMIT = 4;

		var build:Dynamic = {
			joints: [],
			indices: {
				array: [],
				stride: BONE_LIMIT
			},
			weights: {
				array: [],
				stride: BONE_LIMIT
			}
		};

		var sources = data.sources;
		var vertexWeights = data.vertexWeights;

		var vcount = vertexWeights.vcount;
		var v = vertexWeights.v;
		var jointOffset = vertexWeights.inputs.get("JOINT").offset;
		var weightOffset = vertexWeights.inputs.get("WEIGHT").offset;

		var jointSource = data.sources.get(data.joints.inputs.get("JOINT"));
		var inverseSource = data.sources.get(data.joints.inputs.get("INV_BIND_MATRIX"));

		var weights = sources.get(vertexWeights.inputs.get("WEIGHT").id).array;
		var stride = 0;

		for (i in 0...vcount.length) {
			var jointCount = vcount[i];
			var vertexSkinData:Array<Dynamic> = [];

			for (j in 0...jointCount) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];

				vertexSkinData.push({ index: skinIndex, weight: skinWeight });

				stride += 2;
			}

			vertexSkinData.sort(descending);

			for (j in 0...BONE_LIMIT) {
				var d = vertexSkinData[j];

				if (d != null) {
					build.indices.array.push(d.index);
					build.weights.array.push(d.weight);
				} else {
					build.indices.array.push(0);
					build.weights.array.push(0);
				}
			}
		}

		if (data.bindShapeMatrix != null) {
			build.bindMatrix = new Matrix4().fromArray(data.bindShapeMatrix).transpose();
		} else {
			build.bindMatrix = new Matrix4().identity();
		}

		for (i in 0...jointSource.array.length) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();

			build.joints.push({ name: name, boneInverse: boneInverse });
		}

		return build;

		function descending(a:Dynamic, b:Dynamic):Int {
			return Std.parseFloat(b.weight) - Std.parseFloat(a.weight);
		}
	}

	public function getController(id:String):Dynamic {
		return getBuild(library.controllers.get(id), buildController);
	}

	public function parseImage(xml:Xml):Void {
		var data:Dynamic = {
			init_from: xml.firstElement("init_from").get("textContent")
		};

		library.images.set(xml.get("id"), data);
	}

	public function buildImage(data:Dynamic):String {
		if (data.build != null) return data.build;
		return data.init_from;
	}

	public function getImage(id:String):String {
		var data = library.images.get(id);
		if (data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	public function parseEffect(xml:Xml):Void {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}

		library.effects.set(xml.get("id"), data);
	}

	public function parseEffectProfileCOMMON(xml:Xml):Dynamic {
		var data:Dynamic = {
			surfaces: new StringMap<Dynamic>(),
			samplers: new StringMap<Dynamic>()
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "newparam":
					parseEffectNewparam(child, data);
					break;
				case "technique":
					data.technique = parseEffectTechnique(child);
					break;
				case "extra":
					data.extra = parseEffectExtra(child);
					break;
			}
		}

		return data;
	}

	public function parseEffectNewparam(xml:Xml, data:Dynamic):Void {
		var sid = xml.get("sid");

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "surface":
					data.surfaces.set(sid, parseEffectSurface(child));
					break;
				case "sampler2D":
					data.samplers.set(sid, parseEffectSampler(child));
					break;
			}
		}
	}

	public function parseEffectSurface(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "init_from":
					data.init_from = child.get("textContent");
					break;
			}
		}

		return data;
	}

	public function parseEffectSampler(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "source":
					data.source = child.get("textContent");
					break;
			}
		}

		return data;
	}

	public function parseEffectTechnique(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "constant":
				case "lambert":
				case "blinn":
				case "phong":
					data.type = child.nodeName;
					data.parameters = parseEffectParameters(child);
					break;
				case "extra":
					data.extra = parseEffectExtra(child);
					break;
			}
		}

		return data;
	}

	public function parseEffectParameters(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "emission":
				case "diffuse":
				case "specular":
				case "bump":
				case "ambient":
				case "shininess":
				case "transparency":
					data[child.nodeName] = parseEffectParameter(child);
					break;
				case "transparent":
					data[child.nodeName] = {
						opaque: child.hasAttribute("opaque") ? child.get("opaque") : "A_ONE",
						data: parseEffectParameter(child)
					};
					break;
			}
		}

		return data;
	}

	public function parseEffectParameter(xml:Xml):Dynamic {
		var data:Dynamic = {};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {
				case "color":
					data[child.nodeName] = parseFloats(child.get("textContent"));
					break;
				case "float":
					data[child.nodeName] = Std.parseFloat(child.get("textContent"));
					break;
				case "texture":
					data[child.nodeName] = { id: child.get("texture"), extra: parseEffectParameterTexture(child) };
					break;
			}
		}

		return data;
	}

	public function parseEffectParameterTexture(xml:Xml):Dynamic {
		var data:Dynamic = {
			technique: {}
		};

		for (child in xml.elements()) {
			if (child.nodeType != Xml.ELEMENT_NODE) continue;

			switch (child.nodeName) {