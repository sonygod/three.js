import three.extras.loaders.TGALoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.core.AnimationClip;
import three.core.Bone;
import three.core.BufferGeometry;
import three.core.Color;
import three.core.Float32BufferAttribute;
import three.core.Group;
import three.core.Line;
import three.core.LineBasicMaterial;
import three.core.LineSegments;
import three.core.Mesh;
import three.core.MeshBasicMaterial;
import three.core.MeshLambertMaterial;
import three.core.MeshPhongMaterial;
import three.core.Object3D;
import three.core.OrthographicCamera;
import three.core.PerspectiveCamera;
import three.core.PointLight;
import three.core.Scene;
import three.core.Skeleton;
import three.core.SkinnedMesh;
import three.core.SpotLight;
import three.core.AmbientLight;
import three.core.DirectionalLight;
import three.core.TextureLoader;
import three.animation.QuaternionKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.constants.WrappingModes;
import three.constants.Side;
import three.constants.ColorSpace;
import three.extras.core.AnimationAction;

class ColladaLoader extends Loader {

	public function new() {
		super();
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var path = (scope.path == "") ? LoaderUtils.extractUrlBase(url) : scope.path;
		var loader = new three.loaders.FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(text, path));
			} catch(e:Dynamic) {
				if (onError != null) onError(e);
				else console.error(e);
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String, path:String):Dynamic {
		var xml = new DOMParser().parseFromString(text, "application/xml");
		var collada = getElementsByTagName(xml, "COLLADA")[0];
		var parserError = xml.getElementsByTagName("parsererror")[0];
		if (parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText:String;
			if (errorElement != null) {
				errorText = errorElement.textContent;
			} else {
				errorText = parserErrorToText(parserError);
			}
			console.error("THREE.ColladaLoader: Failed to parse collada file.\n", errorText);
			return null;
		}
		var version = collada.getAttribute("version");
		console.debug("THREE.ColladaLoader: File version", version);
		var asset = parseAsset(getElementsByTagName(collada, "asset")[0]);
		var textureLoader = new three.core.TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		textureLoader.setCrossOrigin(this.crossOrigin);
		var tgaLoader:TGALoader;
		if (TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}
		var tempColor = new three.core.Color();
		var animations:Array<AnimationClip> = [];
		var kinematics:Dynamic = {};
		var count = 0;
		var library:Dynamic = {
			animations: {},
			clips: {},
			controllers: {},
			images: {},
			effects: {},
			materials: {},
			cameras: {},
			lights: {},
			geometries: {},
			nodes: {},
			visualScenes: {},
			kinematicsModels: {},
			physicsModels: {},
			kinematicsScenes: {}
		};
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

	function getElementsByTagName(xml:Dynamic, name:String):Array<Dynamic> {
		var array:Array<Dynamic> = [];
		var childNodes = xml.childNodes;
		for (var i = 0; i < childNodes.length; i++) {
			var child = childNodes[i];
			if (child.nodeName == name) {
				array.push(child);
			}
		}
		return array;
	}

	function parseStrings(text:String):Array<String> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<String>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = parts[i];
		}
		return array;
	}

	function parseFloats(text:String):Array<Float> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<Float>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = Std.parseFloat(parts[i]);
		}
		return array;
	}

	function parseInts(text:String):Array<Int> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<Int>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = Std.parseInt(parts[i]);
		}
		return array;
	}

	function parseId(text:String):String {
		return text.substring(1);
	}

	function generateId():String {
		return "three_default_" + (count++);
	}

	function isEmpty(object:Dynamic):Bool {
		return Reflect.field(object, "length") == 0;
	}

	function parseAsset(xml:Dynamic):Dynamic {
		return {
			unit: parseAssetUnit(getElementsByTagName(xml, "unit")[0]),
			upAxis: parseAssetUpAxis(getElementsByTagName(xml, "up_axis")[0])
		};
	}

	function parseAssetUnit(xml:Dynamic):Float {
		if ((xml != null) && (xml.hasAttribute("meter") == true)) {
			return Std.parseFloat(xml.getAttribute("meter"));
		} else {
			return 1;
		}
	}

	function parseAssetUpAxis(xml:Dynamic):String {
		return xml != null ? xml.textContent : "Y_UP";
	}

	function parseLibrary(xml:Dynamic, libraryName:String, nodeName:String, parser:Dynamic->Void):Void {
		var library = getElementsByTagName(xml, libraryName)[0];
		if (library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for (var i = 0; i < elements.length; i++) {
				parser(elements[i]);
			}
		}
	}

	function buildLibrary(data:Dynamic, builder:Dynamic->Dynamic):Void {
		for (var name in data) {
			var object = data[name];
			object.build = builder(data[name]);
		}
	}

	function getBuild(data:Dynamic, builder:Dynamic->Dynamic):Dynamic {
		if (data.build != null) return data.build;
		data.build = builder(data);
		return data.build;
	}

	function parseAnimation(xml:Dynamic):Void {
		var data:Dynamic = {
			sources: {},
			samplers: {},
			channels: {}
		};
		var hasChildren = false;
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			var id:String;
			switch (child.nodeName) {
				case "source":
					id = child.getAttribute("id");
					data.sources[id] = parseSource(child);
					break;
				case "sampler":
					id = child.getAttribute("id");
					data.samplers[id] = parseAnimationSampler(child);
					break;
				case "channel":
					id = child.getAttribute("target");
					data.channels[id] = parseAnimationChannel(child);
					break;
				case "animation":
					parseAnimation(child);
					hasChildren = true;
					break;
				default:
					console.log(child);
			}
		}
		if (hasChildren == false) {
			library.animations[xml.getAttribute("id") != null ? xml.getAttribute("id") : MathUtils.generateUUID()] = data;
		}
	}

	function parseAnimationSampler(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var id = parseId(child.getAttribute("source"));
					var semantic = child.getAttribute("semantic");
					data.inputs[semantic] = id;
					break;
			}
		}
		return data;
	}

	function parseAnimationChannel(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		var target = xml.getAttribute("target");
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
			for (var i = 0; i < indices.length; i++) {
				indices[i] = Std.parseInt(indices[i].replace(/\)/, ""));
			}
			data.indices = indices;
		}
		data.id = id;
		data.sid = sid;
		data.arraySyntax = arraySyntax;
		data.memberSyntax = memberSyntax;
		data.sampler = parseId(xml.getAttribute("source"));
		return data;
	}

	function buildAnimation(data:Dynamic):Array<VectorKeyframeTrack> {
		var tracks:Array<VectorKeyframeTrack> = [];
		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;
		for (var target in channels) {
			if (channels.hasOwnProperty(target)) {
				var channel = channels[target];
				var sampler = samplers[channel.sampler];
				var inputId = sampler.inputs.INPUT;
				var outputId = sampler.inputs.OUTPUT;
				var inputSource = sources[inputId];
				var outputSource = sources[outputId];
				var animation = buildAnimationChannel(channel, inputSource, outputSource);
				createKeyframeTracks(animation, tracks);
			}
		}
		return tracks;
	}

	function getAnimation(id:String):Array<VectorKeyframeTrack> {
		return getBuild(library.animations[id], buildAnimation);
	}

	function buildAnimationChannel(channel:Dynamic, inputSource:Dynamic, outputSource:Dynamic):Dynamic {
		var node = library.nodes[channel.id];
		var object3D = getNode(node.id);
		var transform = node.transforms[channel.sid];
		var defaultMatrix = node.matrix.clone().transpose();
		var time:Float, stride:Int;
		var i:Int, il:Int, j:Int, jl:Int;
		var data:Dynamic = {};
		switch (transform) {
			case "matrix":
				for (i = 0, il = inputSource.array.length; i < il; i++) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;
					if (data[time] == null) data[time] = {};
					if (channel.arraySyntax == true) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data[time][index] = value;
					} else {
						for (j = 0, jl = outputSource.stride; j < jl; j++) {
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

	function prepareAnimationData(data:Dynamic, defaultMatrix:Matrix4):Array<Dynamic> {
		var keyframes:Array<Dynamic> = [];
		for (var time in data) {
			keyframes.push({time: Std.parseFloat(time), value: data[time]});
		}
		keyframes.sort(ascending);
		for (var i = 0; i < 16; i++) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}
		return keyframes;
		function ascending(a:Dynamic, b:Dynamic):Int {
			return a.time - b.time;
		}
	}

	var position = new Vector3();
	var scale = new Vector3();
	var quaternion = new Quaternion();
	var matrix = new Matrix4();

	function createKeyframeTracks(animation:Dynamic, tracks:Array<VectorKeyframeTrack>):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;
		var times:Array<Float> = [];
		var positionData:Array<Float> = [];
		var quaternionData:Array<Float> = [];
		var scaleData:Array<Float> = [];
		for (var i = 0; i < keyframes.length; i++) {
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

	function transformAnimationData(keyframes:Array<Dynamic>, property:Int, defaultValue:Float):Void {
		var keyframe:Dynamic;
		var empty = true;
		var i:Int, l:Int;
		for (i = 0, l = keyframes.length; i < l; i++) {
			keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}
		if (empty == true) {
			for (i = 0, l = keyframes.length; i < l; i++) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	function createMissingKeyframes(keyframes:Array<Dynamic>, property:Int):Void {
		var prev:Dynamic, next:Dynamic;
		for (var i = 0; i < keyframes.length; i++) {
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

	function getPrev(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i >= 0) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	function getNext(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i < keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	function interpolate(key:Dynamic, prev:Dynamic, next:Dynamic, property:Int):Void {
		if ((next.time - prev.time) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = (((key.time - prev.time) * (next.value[property] - prev.value[property])) / (next.time - prev.time)) + prev.value[property];
	}

	function parseAnimationClip(xml:Dynamic):Void {
		var data:Dynamic = {
			name: xml.getAttribute("id") != null ? xml.getAttribute("id") : "default",
			start: Std.parseFloat(xml.getAttribute("start") != null ? xml.getAttribute("start") : "0"),
			end: Std.parseFloat(xml.getAttribute("end") != null ? xml.getAttribute("end") : "0"),
			animations: []
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.getAttribute("url")));
					break;
			}
		}
		library.clips[xml.getAttribute("id")] = data;
	}

	function buildAnimationClip(data:Dynamic):AnimationClip {
		var tracks:Array<VectorKeyframeTrack> = [];
		var name = data.name;
		var duration = (data.end - data.start) != 0 ? (data.end - data.start) : -1;
		var animations = data.animations;
		for (var i = 0; i < animations.length; i++) {
			var animationTracks = getAnimation(animations[i]);
			for (var j = 0; j < animationTracks.length; j++) {
				tracks.push(animationTracks[j]);
			}
		}
		return new AnimationClip(name, duration, tracks);
	}

	function getAnimationClip(id:String):AnimationClip {
		return getBuild(library.clips[id], buildAnimationClip);
	}

	function parseController(xml:Dynamic):Void {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "skin":
					data.id = parseId(child.getAttribute("source"));
					data.skin = parseSkin(child);
					break;
				case "morph":
					data.id = parseId(child.getAttribute("source"));
					console.warn("THREE.ColladaLoader: Morph target animation not supported yet.");
					break;
			}
		}
		library.controllers[xml.getAttribute("id")] = data;
	}

	function parseSkin(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			sources: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.textContent);
					break;
				case "source":
					var id = child.getAttribute("id");
					data.sources[id] = parseSource(child);
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

	function parseJoints(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					data.inputs[semantic] = id;
					break;
			}
		}
		return data;
	}

	function parseVertexWeights(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					var offset = Std.parseInt(child.getAttribute("offset"));
					data.inputs[semantic] = {id: id, offset: offset};
					break;
				case "vcount":
					data.vcount = parseInts(child.textContent);
					break;
				case "v":
					data.v = parseInts(child.textContent);
					break;
			}
		}
		return data;
	}

	function buildController(data:Dynamic):Dynamic {
		var build:Dynamic = {
			id: data.id
		};
		var geometry = library.geometries[build.id];
		if (data.skin != null) {
			build.skin = buildSkin(data.skin);
			geometry.sources.skinIndices = build.skin.indices;
			geometry.sources.skinWeights = build.skin.weights;
		}
		return build;
	}

	function buildSkin(data:Dynamic):Dynamic {
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
		var jointOffset = vertexWeights.inputs.JOINT.offset;
		var weightOffset = vertexWeights.inputs.WEIGHT.offset;
		var jointSource = data.sources[data.joints.inputs.JOINT];
		var inverseSource = data.sources[data.joints.inputs.INV_BIND_MATRIX];
		var weights = sources[vertexWeights.inputs.WEIGHT.id].array;
		var stride = 0;
		var i:Int, j:Int, l:Int;
		for (i = 0, l = vcount.length; i < l; i++) {
			var jointCount = vcount[i];
			var vertexSkinData:Array<Dynamic> = [];
			for (j = 0; j < jointCount; j++) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];
				vertexSkinData.push({index: skinIndex, weight: skinWeight});
				stride += 2;
			}
			vertexSkinData.sort(descending);
			for (j = 0; j < BONE_LIMIT; j++) {
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
		for (i = 0, l = jointSource.array.length; i < l; i++) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();
			build.joints.push({name: name, boneInverse: boneInverse});
		}
		return build;
		function descending(a:Dynamic, b:Dynamic):Int {
			return b.weight - a.weight;
		}
	}

	function getController(id:String):Dynamic {
		return getBuild(library.controllers[id], buildController);
	}

	function parseImage(xml:Dynamic):Void {
		var data:Dynamic = {
			init_from: getElementsByTagName(xml, "init_from")[0].textContent
		};
		library.images[xml.getAttribute("id")] = data;
	}

	function buildImage(data:Dynamic):String {
		if (data.build != null) return data.build;
		return data.init_from;
	}

	function getImage(id:String):String {
		var data = library.images[id];
		if (data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	function parseEffect(xml:Dynamic):Void {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}
		library.effects[xml.getAttribute("id")] = data;
	}

	function parseEffectProfileCOMMON(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			surfaces: {},
			samplers: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
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

	function parseEffectNewparam(xml:Dynamic, data:Dynamic):Void {
		var sid = xml.getAttribute("sid");
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "surface":
					data.surfaces[sid] = parseEffectSurface(child);
					break;
				case "sampler2D":
					data.samplers[sid] = parseEffectSampler(child);
					break;
			}
		}
	}

	function parseEffectSurface(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "init_from":
					data.init_from = child.textContent;
					break;
			}
		}
		return data;
	}

	function parseEffectSampler(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "source":
					data.source = child.textContent;
					break;
			}
		}
		return data;
	}

	function parseEffectTechnique(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
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

	function parseEffectParameters(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "emission":
				case "diffuse":
				case "specular":
				case "bump":
				case "ambient":
				case "shininess":
				case "transparency":
					data[child.nodeName] = parse
import three.extras.loaders.TGALoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.core.AnimationClip;
import three.core.Bone;
import three.core.BufferGeometry;
import three.core.Color;
import three.core.Float32BufferAttribute;
import three.core.Group;
import three.core.Line;
import three.core.LineBasicMaterial;
import three.core.LineSegments;
import three.core.Mesh;
import three.core.MeshBasicMaterial;
import three.core.MeshLambertMaterial;
import three.core.MeshPhongMaterial;
import three.core.Object3D;
import three.core.OrthographicCamera;
import three.core.PerspectiveCamera;
import three.core.PointLight;
import three.core.Scene;
import three.core.Skeleton;
import three.core.SkinnedMesh;
import three.core.SpotLight;
import three.core.AmbientLight;
import three.core.DirectionalLight;
import three.core.TextureLoader;
import three.animation.QuaternionKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.constants.WrappingModes;
import three.constants.Side;
import three.constants.ColorSpace;
import three.extras.core.AnimationAction;

class ColladaLoader extends Loader {

	public function new() {
		super();
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var path = (scope.path == "") ? LoaderUtils.extractUrlBase(url) : scope.path;
		var loader = new three.loaders.FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(text, path));
			} catch(e:Dynamic) {
				if (onError != null) onError(e);
				else console.error(e);
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String, path:String):Dynamic {
		var xml = new DOMParser().parseFromString(text, "application/xml");
		var collada = getElementsByTagName(xml, "COLLADA")[0];
		var parserError = xml.getElementsByTagName("parsererror")[0];
		if (parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText:String;
			if (errorElement != null) {
				errorText = errorElement.textContent;
			} else {
				errorText = parserErrorToText(parserError);
			}
			console.error("THREE.ColladaLoader: Failed to parse collada file.\n", errorText);
			return null;
		}
		var version = collada.getAttribute("version");
		console.debug("THREE.ColladaLoader: File version", version);
		var asset = parseAsset(getElementsByTagName(collada, "asset")[0]);
		var textureLoader = new three.core.TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		textureLoader.setCrossOrigin(this.crossOrigin);
		var tgaLoader:TGALoader;
		if (TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}
		var tempColor = new three.core.Color();
		var animations:Array<AnimationClip> = [];
		var kinematics:Dynamic = {};
		var count = 0;
		var library:Dynamic = {
			animations: {},
			clips: {},
			controllers: {},
			images: {},
			effects: {},
			materials: {},
			cameras: {},
			lights: {},
			geometries: {},
			nodes: {},
			visualScenes: {},
			kinematicsModels: {},
			physicsModels: {},
			kinematicsScenes: {}
		};
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

	function getElementsByTagName(xml:Dynamic, name:String):Array<Dynamic> {
		var array:Array<Dynamic> = [];
		var childNodes = xml.childNodes;
		for (var i = 0; i < childNodes.length; i++) {
			var child = childNodes[i];
			if (child.nodeName == name) {
				array.push(child);
			}
		}
		return array;
	}

	function parseStrings(text:String):Array<String> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<String>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = parts[i];
		}
		return array;
	}

	function parseFloats(text:String):Array<Float> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<Float>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = Std.parseFloat(parts[i]);
		}
		return array;
	}

	function parseInts(text:String):Array<Int> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<Int>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = Std.parseInt(parts[i]);
		}
		return array;
	}

	function parseId(text:String):String {
		return text.substring(1);
	}

	function generateId():String {
		return "three_default_" + (count++);
	}

	function isEmpty(object:Dynamic):Bool {
		return Reflect.field(object, "length") == 0;
	}

	function parseAsset(xml:Dynamic):Dynamic {
		return {
			unit: parseAssetUnit(getElementsByTagName(xml, "unit")[0]),
			upAxis: parseAssetUpAxis(getElementsByTagName(xml, "up_axis")[0])
		};
	}

	function parseAssetUnit(xml:Dynamic):Float {
		if ((xml != null) && (xml.hasAttribute("meter") == true)) {
			return Std.parseFloat(xml.getAttribute("meter"));
		} else {
			return 1;
		}
	}

	function parseAssetUpAxis(xml:Dynamic):String {
		return xml != null ? xml.textContent : "Y_UP";
	}

	function parseLibrary(xml:Dynamic, libraryName:String, nodeName:String, parser:Dynamic->Void):Void {
		var library = getElementsByTagName(xml, libraryName)[0];
		if (library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for (var i = 0; i < elements.length; i++) {
				parser(elements[i]);
			}
		}
	}

	function buildLibrary(data:Dynamic, builder:Dynamic->Dynamic):Void {
		for (var name in data) {
			var object = data[name];
			object.build = builder(data[name]);
		}
	}

	function getBuild(data:Dynamic, builder:Dynamic->Dynamic):Dynamic {
		if (data.build != null) return data.build;
		data.build = builder(data);
		return data.build;
	}

	function parseAnimation(xml:Dynamic):Void {
		var data:Dynamic = {
			sources: {},
			samplers: {},
			channels: {}
		};
		var hasChildren = false;
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			var id:String;
			switch (child.nodeName) {
				case "source":
					id = child.getAttribute("id");
					data.sources[id] = parseSource(child);
					break;
				case "sampler":
					id = child.getAttribute("id");
					data.samplers[id] = parseAnimationSampler(child);
					break;
				case "channel":
					id = child.getAttribute("target");
					data.channels[id] = parseAnimationChannel(child);
					break;
				case "animation":
					parseAnimation(child);
					hasChildren = true;
					break;
				default:
					console.log(child);
			}
		}
		if (hasChildren == false) {
			library.animations[xml.getAttribute("id") != null ? xml.getAttribute("id") : MathUtils.generateUUID()] = data;
		}
	}

	function parseAnimationSampler(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var id = parseId(child.getAttribute("source"));
					var semantic = child.getAttribute("semantic");
					data.inputs[semantic] = id;
					break;
			}
		}
		return data;
	}

	function parseAnimationChannel(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		var target = xml.getAttribute("target");
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
			for (var i = 0; i < indices.length; i++) {
				indices[i] = Std.parseInt(indices[i].replace(/\)/, ""));
			}
			data.indices = indices;
		}
		data.id = id;
		data.sid = sid;
		data.arraySyntax = arraySyntax;
		data.memberSyntax = memberSyntax;
		data.sampler = parseId(xml.getAttribute("source"));
		return data;
	}

	function buildAnimation(data:Dynamic):Array<VectorKeyframeTrack> {
		var tracks:Array<VectorKeyframeTrack> = [];
		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;
		for (var target in channels) {
			if (channels.hasOwnProperty(target)) {
				var channel = channels[target];
				var sampler = samplers[channel.sampler];
				var inputId = sampler.inputs.INPUT;
				var outputId = sampler.inputs.OUTPUT;
				var inputSource = sources[inputId];
				var outputSource = sources[outputId];
				var animation = buildAnimationChannel(channel, inputSource, outputSource);
				createKeyframeTracks(animation, tracks);
			}
		}
		return tracks;
	}

	function getAnimation(id:String):Array<VectorKeyframeTrack> {
		return getBuild(library.animations[id], buildAnimation);
	}

	function buildAnimationChannel(channel:Dynamic, inputSource:Dynamic, outputSource:Dynamic):Dynamic {
		var node = library.nodes[channel.id];
		var object3D = getNode(node.id);
		var transform = node.transforms[channel.sid];
		var defaultMatrix = node.matrix.clone().transpose();
		var time:Float, stride:Int;
		var i:Int, il:Int, j:Int, jl:Int;
		var data:Dynamic = {};
		switch (transform) {
			case "matrix":
				for (i = 0, il = inputSource.array.length; i < il; i++) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;
					if (data[time] == null) data[time] = {};
					if (channel.arraySyntax == true) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data[time][index] = value;
					} else {
						for (j = 0, jl = outputSource.stride; j < jl; j++) {
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

	function prepareAnimationData(data:Dynamic, defaultMatrix:Matrix4):Array<Dynamic> {
		var keyframes:Array<Dynamic> = [];
		for (var time in data) {
			keyframes.push({time: Std.parseFloat(time), value: data[time]});
		}
		keyframes.sort(ascending);
		for (var i = 0; i < 16; i++) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}
		return keyframes;
		function ascending(a:Dynamic, b:Dynamic):Int {
			return a.time - b.time;
		}
	}

	var position = new Vector3();
	var scale = new Vector3();
	var quaternion = new Quaternion();
	var matrix = new Matrix4();

	function createKeyframeTracks(animation:Dynamic, tracks:Array<VectorKeyframeTrack>):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;
		var times:Array<Float> = [];
		var positionData:Array<Float> = [];
		var quaternionData:Array<Float> = [];
		var scaleData:Array<Float> = [];
		for (var i = 0; i < keyframes.length; i++) {
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

	function transformAnimationData(keyframes:Array<Dynamic>, property:Int, defaultValue:Float):Void {
		var keyframe:Dynamic;
		var empty = true;
		var i:Int, l:Int;
		for (i = 0, l = keyframes.length; i < l; i++) {
			keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}
		if (empty == true) {
			for (i = 0, l = keyframes.length; i < l; i++) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	function createMissingKeyframes(keyframes:Array<Dynamic>, property:Int):Void {
		var prev:Dynamic, next:Dynamic;
		for (var i = 0; i < keyframes.length; i++) {
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

	function getPrev(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i >= 0) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	function getNext(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i < keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	function interpolate(key:Dynamic, prev:Dynamic, next:Dynamic, property:Int):Void {
		if ((next.time - prev.time) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = (((key.time - prev.time) * (next.value[property] - prev.value[property])) / (next.time - prev.time)) + prev.value[property];
	}

	function parseAnimationClip(xml:Dynamic):Void {
		var data:Dynamic = {
			name: xml.getAttribute("id") != null ? xml.getAttribute("id") : "default",
			start: Std.parseFloat(xml.getAttribute("start") != null ? xml.getAttribute("start") : "0"),
			end: Std.parseFloat(xml.getAttribute("end") != null ? xml.getAttribute("end") : "0"),
			animations: []
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.getAttribute("url")));
					break;
			}
		}
		library.clips[xml.getAttribute("id")] = data;
	}

	function buildAnimationClip(data:Dynamic):AnimationClip {
		var tracks:Array<VectorKeyframeTrack> = [];
		var name = data.name;
		var duration = (data.end - data.start) != 0 ? (data.end - data.start) : -1;
		var animations = data.animations;
		for (var i = 0; i < animations.length; i++) {
			var animationTracks = getAnimation(animations[i]);
			for (var j = 0; j < animationTracks.length; j++) {
				tracks.push(animationTracks[j]);
			}
		}
		return new AnimationClip(name, duration, tracks);
	}

	function getAnimationClip(id:String):AnimationClip {
		return getBuild(library.clips[id], buildAnimationClip);
	}

	function parseController(xml:Dynamic):Void {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "skin":
					data.id = parseId(child.getAttribute("source"));
					data.skin = parseSkin(child);
					break;
				case "morph":
					data.id = parseId(child.getAttribute("source"));
					console.warn("THREE.ColladaLoader: Morph target animation not supported yet.");
					break;
			}
		}
		library.controllers[xml.getAttribute("id")] = data;
	}

	function parseSkin(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			sources: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.textContent);
					break;
				case "source":
					var id = child.getAttribute("id");
					data.sources[id] = parseSource(child);
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

	function parseJoints(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					data.inputs[semantic] = id;
					break;
			}
		}
		return data;
	}

	function parseVertexWeights(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					var offset = Std.parseInt(child.getAttribute("offset"));
					data.inputs[semantic] = {id: id, offset: offset};
					break;
				case "vcount":
					data.vcount = parseInts(child.textContent);
					break;
				case "v":
					data.v = parseInts(child.textContent);
					break;
			}
		}
		return data;
	}

	function buildController(data:Dynamic):Dynamic {
		var build:Dynamic = {
			id: data.id
		};
		var geometry = library.geometries[build.id];
		if (data.skin != null) {
			build.skin = buildSkin(data.skin);
			geometry.sources.skinIndices = build.skin.indices;
			geometry.sources.skinWeights = build.skin.weights;
		}
		return build;
	}

	function buildSkin(data:Dynamic):Dynamic {
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
		var jointOffset = vertexWeights.inputs.JOINT.offset;
		var weightOffset = vertexWeights.inputs.WEIGHT.offset;
		var jointSource = data.sources[data.joints.inputs.JOINT];
		var inverseSource = data.sources[data.joints.inputs.INV_BIND_MATRIX];
		var weights = sources[vertexWeights.inputs.WEIGHT.id].array;
		var stride = 0;
		var i:Int, j:Int, l:Int;
		for (i = 0, l = vcount.length; i < l; i++) {
			var jointCount = vcount[i];
			var vertexSkinData:Array<Dynamic> = [];
			for (j = 0; j < jointCount; j++) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];
				vertexSkinData.push({index: skinIndex, weight: skinWeight});
				stride += 2;
			}
			vertexSkinData.sort(descending);
			for (j = 0; j < BONE_LIMIT; j++) {
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
		for (i = 0, l = jointSource.array.length; i < l; i++) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();
			build.joints.push({name: name, boneInverse: boneInverse});
		}
		return build;
		function descending(a:Dynamic, b:Dynamic):Int {
			return b.weight - a.weight;
		}
	}

	function getController(id:String):Dynamic {
		return getBuild(library.controllers[id], buildController);
	}

	function parseImage(xml:Dynamic):Void {
		var data:Dynamic = {
			init_from: getElementsByTagName(xml, "init_from")[0].textContent
		};
		library.images[xml.getAttribute("id")] = data;
	}

	function buildImage(data:Dynamic):String {
		if (data.build != null) return data.build;
		return data.init_from;
	}

	function getImage(id:String):String {
		var data = library.images[id];
		if (data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	function parseEffect(xml:Dynamic):Void {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}
		library.effects[xml.getAttribute("id")] = data;
	}

	function parseEffectProfileCOMMON(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			surfaces: {},
			samplers: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
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

	function parseEffectNewparam(xml:Dynamic, data:Dynamic):Void {
		var sid = xml.getAttribute("sid");
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "surface":
					data.surfaces[sid] = parseEffectSurface(child);
					break;
				case "sampler2D":
					data.samplers[sid] = parseEffectSampler(child);
					break;
			}
		}
	}

	function parseEffectSurface(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "init_from":
					data.init_from = child.textContent;
					break;
			}
		}
		return data;
	}

	function parseEffectSampler(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "source":
					data.source = child.textContent;
					break;
			}
		}
		return data;
	}

	function parseEffectTechnique(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
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

	function parseEffectParameters(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "emission":
				case "diffuse":
				case "specular":
				case "bump":
				case "ambient":
				case "shininess":
				case "transparency":
					data[child.nodeName] = parse
import three.extras.loaders.TGALoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.core.AnimationClip;
import three.core.Bone;
import three.core.BufferGeometry;
import three.core.Color;
import three.core.Float32BufferAttribute;
import three.core.Group;
import three.core.Line;
import three.core.LineBasicMaterial;
import three.core.LineSegments;
import three.core.Mesh;
import three.core.MeshBasicMaterial;
import three.core.MeshLambertMaterial;
import three.core.MeshPhongMaterial;
import three.core.Object3D;
import three.core.OrthographicCamera;
import three.core.PerspectiveCamera;
import three.core.PointLight;
import three.core.Scene;
import three.core.Skeleton;
import three.core.SkinnedMesh;
import three.core.SpotLight;
import three.core.AmbientLight;
import three.core.DirectionalLight;
import three.core.TextureLoader;
import three.animation.QuaternionKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.constants.WrappingModes;
import three.constants.Side;
import three.constants.ColorSpace;
import three.extras.core.AnimationAction;

class ColladaLoader extends Loader {

	public function new() {
		super();
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var path = (scope.path == "") ? LoaderUtils.extractUrlBase(url) : scope.path;
		var loader = new three.loaders.FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(text, path));
			} catch(e:Dynamic) {
				if (onError != null) onError(e);
				else console.error(e);
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String, path:String):Dynamic {
		var xml = new DOMParser().parseFromString(text, "application/xml");
		var collada = getElementsByTagName(xml, "COLLADA")[0];
		var parserError = xml.getElementsByTagName("parsererror")[0];
		if (parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText:String;
			if (errorElement != null) {
				errorText = errorElement.textContent;
			} else {
				errorText = parserErrorToText(parserError);
			}
			console.error("THREE.ColladaLoader: Failed to parse collada file.\n", errorText);
			return null;
		}
		var version = collada.getAttribute("version");
		console.debug("THREE.ColladaLoader: File version", version);
		var asset = parseAsset(getElementsByTagName(collada, "asset")[0]);
		var textureLoader = new three.core.TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		textureLoader.setCrossOrigin(this.crossOrigin);
		var tgaLoader:TGALoader;
		if (TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}
		var tempColor = new three.core.Color();
		var animations:Array<AnimationClip> = [];
		var kinematics:Dynamic = {};
		var count = 0;
		var library:Dynamic = {
			animations: {},
			clips: {},
			controllers: {},
			images: {},
			effects: {},
			materials: {},
			cameras: {},
			lights: {},
			geometries: {},
			nodes: {},
			visualScenes: {},
			kinematicsModels: {},
			physicsModels: {},
			kinematicsScenes: {}
		};
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

	function getElementsByTagName(xml:Dynamic, name:String):Array<Dynamic> {
		var array:Array<Dynamic> = [];
		var childNodes = xml.childNodes;
		for (var i = 0; i < childNodes.length; i++) {
			var child = childNodes[i];
			if (child.nodeName == name) {
				array.push(child);
			}
		}
		return array;
	}

	function parseStrings(text:String):Array<String> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<String>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = parts[i];
		}
		return array;
	}

	function parseFloats(text:String):Array<Float> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<Float>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = Std.parseFloat(parts[i]);
		}
		return array;
	}

	function parseInts(text:String):Array<Int> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<Int>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = Std.parseInt(parts[i]);
		}
		return array;
	}

	function parseId(text:String):String {
		return text.substring(1);
	}

	function generateId():String {
		return "three_default_" + (count++);
	}

	function isEmpty(object:Dynamic):Bool {
		return Reflect.field(object, "length") == 0;
	}

	function parseAsset(xml:Dynamic):Dynamic {
		return {
			unit: parseAssetUnit(getElementsByTagName(xml, "unit")[0]),
			upAxis: parseAssetUpAxis(getElementsByTagName(xml, "up_axis")[0])
		};
	}

	function parseAssetUnit(xml:Dynamic):Float {
		if ((xml != null) && (xml.hasAttribute("meter") == true)) {
			return Std.parseFloat(xml.getAttribute("meter"));
		} else {
			return 1;
		}
	}

	function parseAssetUpAxis(xml:Dynamic):String {
		return xml != null ? xml.textContent : "Y_UP";
	}

	function parseLibrary(xml:Dynamic, libraryName:String, nodeName:String, parser:Dynamic->Void):Void {
		var library = getElementsByTagName(xml, libraryName)[0];
		if (library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for (var i = 0; i < elements.length; i++) {
				parser(elements[i]);
			}
		}
	}

	function buildLibrary(data:Dynamic, builder:Dynamic->Dynamic):Void {
		for (var name in data) {
			var object = data[name];
			object.build = builder(data[name]);
		}
	}

	function getBuild(data:Dynamic, builder:Dynamic->Dynamic):Dynamic {
		if (data.build != null) return data.build;
		data.build = builder(data);
		return data.build;
	}

	function parseAnimation(xml:Dynamic):Void {
		var data:Dynamic = {
			sources: {},
			samplers: {},
			channels: {}
		};
		var hasChildren = false;
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			var id:String;
			switch (child.nodeName) {
				case "source":
					id = child.getAttribute("id");
					data.sources[id] = parseSource(child);
					break;
				case "sampler":
					id = child.getAttribute("id");
					data.samplers[id] = parseAnimationSampler(child);
					break;
				case "channel":
					id = child.getAttribute("target");
					data.channels[id] = parseAnimationChannel(child);
					break;
				case "animation":
					parseAnimation(child);
					hasChildren = true;
					break;
				default:
					console.log(child);
			}
		}
		if (hasChildren == false) {
			library.animations[xml.getAttribute("id") != null ? xml.getAttribute("id") : MathUtils.generateUUID()] = data;
		}
	}

	function parseAnimationSampler(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var id = parseId(child.getAttribute("source"));
					var semantic = child.getAttribute("semantic");
					data.inputs[semantic] = id;
					break;
			}
		}
		return data;
	}

	function parseAnimationChannel(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		var target = xml.getAttribute("target");
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
			for (var i = 0; i < indices.length; i++) {
				indices[i] = Std.parseInt(indices[i].replace(/\)/, ""));
			}
			data.indices = indices;
		}
		data.id = id;
		data.sid = sid;
		data.arraySyntax = arraySyntax;
		data.memberSyntax = memberSyntax;
		data.sampler = parseId(xml.getAttribute("source"));
		return data;
	}

	function buildAnimation(data:Dynamic):Array<VectorKeyframeTrack> {
		var tracks:Array<VectorKeyframeTrack> = [];
		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;
		for (var target in channels) {
			if (channels.hasOwnProperty(target)) {
				var channel = channels[target];
				var sampler = samplers[channel.sampler];
				var inputId = sampler.inputs.INPUT;
				var outputId = sampler.inputs.OUTPUT;
				var inputSource = sources[inputId];
				var outputSource = sources[outputId];
				var animation = buildAnimationChannel(channel, inputSource, outputSource);
				createKeyframeTracks(animation, tracks);
			}
		}
		return tracks;
	}

	function getAnimation(id:String):Array<VectorKeyframeTrack> {
		return getBuild(library.animations[id], buildAnimation);
	}

	function buildAnimationChannel(channel:Dynamic, inputSource:Dynamic, outputSource:Dynamic):Dynamic {
		var node = library.nodes[channel.id];
		var object3D = getNode(node.id);
		var transform = node.transforms[channel.sid];
		var defaultMatrix = node.matrix.clone().transpose();
		var time:Float, stride:Int;
		var i:Int, il:Int, j:Int, jl:Int;
		var data:Dynamic = {};
		switch (transform) {
			case "matrix":
				for (i = 0, il = inputSource.array.length; i < il; i++) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;
					if (data[time] == null) data[time] = {};
					if (channel.arraySyntax == true) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data[time][index] = value;
					} else {
						for (j = 0, jl = outputSource.stride; j < jl; j++) {
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

	function prepareAnimationData(data:Dynamic, defaultMatrix:Matrix4):Array<Dynamic> {
		var keyframes:Array<Dynamic> = [];
		for (var time in data) {
			keyframes.push({time: Std.parseFloat(time), value: data[time]});
		}
		keyframes.sort(ascending);
		for (var i = 0; i < 16; i++) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}
		return keyframes;
		function ascending(a:Dynamic, b:Dynamic):Int {
			return a.time - b.time;
		}
	}

	var position = new Vector3();
	var scale = new Vector3();
	var quaternion = new Quaternion();
	var matrix = new Matrix4();

	function createKeyframeTracks(animation:Dynamic, tracks:Array<VectorKeyframeTrack>):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;
		var times:Array<Float> = [];
		var positionData:Array<Float> = [];
		var quaternionData:Array<Float> = [];
		var scaleData:Array<Float> = [];
		for (var i = 0; i < keyframes.length; i++) {
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

	function transformAnimationData(keyframes:Array<Dynamic>, property:Int, defaultValue:Float):Void {
		var keyframe:Dynamic;
		var empty = true;
		var i:Int, l:Int;
		for (i = 0, l = keyframes.length; i < l; i++) {
			keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}
		if (empty == true) {
			for (i = 0, l = keyframes.length; i < l; i++) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	function createMissingKeyframes(keyframes:Array<Dynamic>, property:Int):Void {
		var prev:Dynamic, next:Dynamic;
		for (var i = 0; i < keyframes.length; i++) {
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

	function getPrev(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i >= 0) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	function getNext(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i < keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	function interpolate(key:Dynamic, prev:Dynamic, next:Dynamic, property:Int):Void {
		if ((next.time - prev.time) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = (((key.time - prev.time) * (next.value[property] - prev.value[property])) / (next.time - prev.time)) + prev.value[property];
	}

	function parseAnimationClip(xml:Dynamic):Void {
		var data:Dynamic = {
			name: xml.getAttribute("id") != null ? xml.getAttribute("id") : "default",
			start: Std.parseFloat(xml.getAttribute("start") != null ? xml.getAttribute("start") : "0"),
			end: Std.parseFloat(xml.getAttribute("end") != null ? xml.getAttribute("end") : "0"),
			animations: []
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.getAttribute("url")));
					break;
			}
		}
		library.clips[xml.getAttribute("id")] = data;
	}

	function buildAnimationClip(data:Dynamic):AnimationClip {
		var tracks:Array<VectorKeyframeTrack> = [];
		var name = data.name;
		var duration = (data.end - data.start) != 0 ? (data.end - data.start) : -1;
		var animations = data.animations;
		for (var i = 0; i < animations.length; i++) {
			var animationTracks = getAnimation(animations[i]);
			for (var j = 0; j < animationTracks.length; j++) {
				tracks.push(animationTracks[j]);
			}
		}
		return new AnimationClip(name, duration, tracks);
	}

	function getAnimationClip(id:String):AnimationClip {
		return getBuild(library.clips[id], buildAnimationClip);
	}

	function parseController(xml:Dynamic):Void {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "skin":
					data.id = parseId(child.getAttribute("source"));
					data.skin = parseSkin(child);
					break;
				case "morph":
					data.id = parseId(child.getAttribute("source"));
					console.warn("THREE.ColladaLoader: Morph target animation not supported yet.");
					break;
			}
		}
		library.controllers[xml.getAttribute("id")] = data;
	}

	function parseSkin(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			sources: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.textContent);
					break;
				case "source":
					var id = child.getAttribute("id");
					data.sources[id] = parseSource(child);
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

	function parseJoints(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					data.inputs[semantic] = id;
					break;
			}
		}
		return data;
	}

	function parseVertexWeights(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					var offset = Std.parseInt(child.getAttribute("offset"));
					data.inputs[semantic] = {id: id, offset: offset};
					break;
				case "vcount":
					data.vcount = parseInts(child.textContent);
					break;
				case "v":
					data.v = parseInts(child.textContent);
					break;
			}
		}
		return data;
	}

	function buildController(data:Dynamic):Dynamic {
		var build:Dynamic = {
			id: data.id
		};
		var geometry = library.geometries[build.id];
		if (data.skin != null) {
			build.skin = buildSkin(data.skin);
			geometry.sources.skinIndices = build.skin.indices;
			geometry.sources.skinWeights = build.skin.weights;
		}
		return build;
	}

	function buildSkin(data:Dynamic):Dynamic {
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
		var jointOffset = vertexWeights.inputs.JOINT.offset;
		var weightOffset = vertexWeights.inputs.WEIGHT.offset;
		var jointSource = data.sources[data.joints.inputs.JOINT];
		var inverseSource = data.sources[data.joints.inputs.INV_BIND_MATRIX];
		var weights = sources[vertexWeights.inputs.WEIGHT.id].array;
		var stride = 0;
		var i:Int, j:Int, l:Int;
		for (i = 0, l = vcount.length; i < l; i++) {
			var jointCount = vcount[i];
			var vertexSkinData:Array<Dynamic> = [];
			for (j = 0; j < jointCount; j++) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];
				vertexSkinData.push({index: skinIndex, weight: skinWeight});
				stride += 2;
			}
			vertexSkinData.sort(descending);
			for (j = 0; j < BONE_LIMIT; j++) {
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
		for (i = 0, l = jointSource.array.length; i < l; i++) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();
			build.joints.push({name: name, boneInverse: boneInverse});
		}
		return build;
		function descending(a:Dynamic, b:Dynamic):Int {
			return b.weight - a.weight;
		}
	}

	function getController(id:String):Dynamic {
		return getBuild(library.controllers[id], buildController);
	}

	function parseImage(xml:Dynamic):Void {
		var data:Dynamic = {
			init_from: getElementsByTagName(xml, "init_from")[0].textContent
		};
		library.images[xml.getAttribute("id")] = data;
	}

	function buildImage(data:Dynamic):String {
		if (data.build != null) return data.build;
		return data.init_from;
	}

	function getImage(id:String):String {
		var data = library.images[id];
		if (data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	function parseEffect(xml:Dynamic):Void {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}
		library.effects[xml.getAttribute("id")] = data;
	}

	function parseEffectProfileCOMMON(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			surfaces: {},
			samplers: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
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

	function parseEffectNewparam(xml:Dynamic, data:Dynamic):Void {
		var sid = xml.getAttribute("sid");
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "surface":
					data.surfaces[sid] = parseEffectSurface(child);
					break;
				case "sampler2D":
					data.samplers[sid] = parseEffectSampler(child);
					break;
			}
		}
	}

	function parseEffectSurface(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "init_from":
					data.init_from = child.textContent;
					break;
			}
		}
		return data;
	}

	function parseEffectSampler(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "source":
					data.source = child.textContent;
					break;
			}
		}
		return data;
	}

	function parseEffectTechnique(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
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

	function parseEffectParameters(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "emission":
				case "diffuse":
				case "specular":
				case "bump":
				case "ambient":
				case "shininess":
				case "transparency":
					data[child.nodeName] = parse
import three.extras.loaders.TGALoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.core.AnimationClip;
import three.core.Bone;
import three.core.BufferGeometry;
import three.core.Color;
import three.core.Float32BufferAttribute;
import three.core.Group;
import three.core.Line;
import three.core.LineBasicMaterial;
import three.core.LineSegments;
import three.core.Mesh;
import three.core.MeshBasicMaterial;
import three.core.MeshLambertMaterial;
import three.core.MeshPhongMaterial;
import three.core.Object3D;
import three.core.OrthographicCamera;
import three.core.PerspectiveCamera;
import three.core.PointLight;
import three.core.Scene;
import three.core.Skeleton;
import three.core.SkinnedMesh;
import three.core.SpotLight;
import three.core.AmbientLight;
import three.core.DirectionalLight;
import three.core.TextureLoader;
import three.animation.QuaternionKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.constants.WrappingModes;
import three.constants.Side;
import three.constants.ColorSpace;
import three.extras.core.AnimationAction;

class ColladaLoader extends Loader {

	public function new() {
		super();
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var path = (scope.path == "") ? LoaderUtils.extractUrlBase(url) : scope.path;
		var loader = new three.loaders.FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(text, path));
			} catch(e:Dynamic) {
				if (onError != null) onError(e);
				else console.error(e);
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String, path:String):Dynamic {
		var xml = new DOMParser().parseFromString(text, "application/xml");
		var collada = getElementsByTagName(xml, "COLLADA")[0];
		var parserError = xml.getElementsByTagName("parsererror")[0];
		if (parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText:String;
			if (errorElement != null) {
				errorText = errorElement.textContent;
			} else {
				errorText = parserErrorToText(parserError);
			}
			console.error("THREE.ColladaLoader: Failed to parse collada file.\n", errorText);
			return null;
		}
		var version = collada.getAttribute("version");
		console.debug("THREE.ColladaLoader: File version", version);
		var asset = parseAsset(getElementsByTagName(collada, "asset")[0]);
		var textureLoader = new three.core.TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		textureLoader.setCrossOrigin(this.crossOrigin);
		var tgaLoader:TGALoader;
		if (TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}
		var tempColor = new three.core.Color();
		var animations:Array<AnimationClip> = [];
		var kinematics:Dynamic = {};
		var count = 0;
		var library:Dynamic = {
			animations: {},
			clips: {},
			controllers: {},
			images: {},
			effects: {},
			materials: {},
			cameras: {},
			lights: {},
			geometries: {},
			nodes: {},
			visualScenes: {},
			kinematicsModels: {},
			physicsModels: {},
			kinematicsScenes: {}
		};
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

	function getElementsByTagName(xml:Dynamic, name:String):Array<Dynamic> {
		var array:Array<Dynamic> = [];
		var childNodes = xml.childNodes;
		for (var i = 0; i < childNodes.length; i++) {
			var child = childNodes[i];
			if (child.nodeName == name) {
				array.push(child);
			}
		}
		return array;
	}

	function parseStrings(text:String):Array<String> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<String>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = parts[i];
		}
		return array;
	}

	function parseFloats(text:String):Array<Float> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<Float>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = Std.parseFloat(parts[i]);
		}
		return array;
	}

	function parseInts(text:String):Array<Int> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<Int>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = Std.parseInt(parts[i]);
		}
		return array;
	}

	function parseId(text:String):String {
		return text.substring(1);
	}

	function generateId():String {
		return "three_default_" + (count++);
	}

	function isEmpty(object:Dynamic):Bool {
		return Reflect.field(object, "length") == 0;
	}

	function parseAsset(xml:Dynamic):Dynamic {
		return {
			unit: parseAssetUnit(getElementsByTagName(xml, "unit")[0]),
			upAxis: parseAssetUpAxis(getElementsByTagName(xml, "up_axis")[0])
		};
	}

	function parseAssetUnit(xml:Dynamic):Float {
		if ((xml != null) && (xml.hasAttribute("meter") == true)) {
			return Std.parseFloat(xml.getAttribute("meter"));
		} else {
			return 1;
		}
	}

	function parseAssetUpAxis(xml:Dynamic):String {
		return xml != null ? xml.textContent : "Y_UP";
	}

	function parseLibrary(xml:Dynamic, libraryName:String, nodeName:String, parser:Dynamic->Void):Void {
		var library = getElementsByTagName(xml, libraryName)[0];
		if (library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for (var i = 0; i < elements.length; i++) {
				parser(elements[i]);
			}
		}
	}

	function buildLibrary(data:Dynamic, builder:Dynamic->Dynamic):Void {
		for (var name in data) {
			var object = data[name];
			object.build = builder(data[name]);
		}
	}

	function getBuild(data:Dynamic, builder:Dynamic->Dynamic):Dynamic {
		if (data.build != null) return data.build;
		data.build = builder(data);
		return data.build;
	}

	function parseAnimation(xml:Dynamic):Void {
		var data:Dynamic = {
			sources: {},
			samplers: {},
			channels: {}
		};
		var hasChildren = false;
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			var id:String;
			switch (child.nodeName) {
				case "source":
					id = child.getAttribute("id");
					data.sources[id] = parseSource(child);
					break;
				case "sampler":
					id = child.getAttribute("id");
					data.samplers[id] = parseAnimationSampler(child);
					break;
				case "channel":
					id = child.getAttribute("target");
					data.channels[id] = parseAnimationChannel(child);
					break;
				case "animation":
					parseAnimation(child);
					hasChildren = true;
					break;
				default:
					console.log(child);
			}
		}
		if (hasChildren == false) {
			library.animations[xml.getAttribute("id") != null ? xml.getAttribute("id") : MathUtils.generateUUID()] = data;
		}
	}

	function parseAnimationSampler(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var id = parseId(child.getAttribute("source"));
					var semantic = child.getAttribute("semantic");
					data.inputs[semantic] = id;
					break;
			}
		}
		return data;
	}

	function parseAnimationChannel(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		var target = xml.getAttribute("target");
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
			for (var i = 0; i < indices.length; i++) {
				indices[i] = Std.parseInt(indices[i].replace(/\)/, ""));
			}
			data.indices = indices;
		}
		data.id = id;
		data.sid = sid;
		data.arraySyntax = arraySyntax;
		data.memberSyntax = memberSyntax;
		data.sampler = parseId(xml.getAttribute("source"));
		return data;
	}

	function buildAnimation(data:Dynamic):Array<VectorKeyframeTrack> {
		var tracks:Array<VectorKeyframeTrack> = [];
		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;
		for (var target in channels) {
			if (channels.hasOwnProperty(target)) {
				var channel = channels[target];
				var sampler = samplers[channel.sampler];
				var inputId = sampler.inputs.INPUT;
				var outputId = sampler.inputs.OUTPUT;
				var inputSource = sources[inputId];
				var outputSource = sources[outputId];
				var animation = buildAnimationChannel(channel, inputSource, outputSource);
				createKeyframeTracks(animation, tracks);
			}
		}
		return tracks;
	}

	function getAnimation(id:String):Array<VectorKeyframeTrack> {
		return getBuild(library.animations[id], buildAnimation);
	}

	function buildAnimationChannel(channel:Dynamic, inputSource:Dynamic, outputSource:Dynamic):Dynamic {
		var node = library.nodes[channel.id];
		var object3D = getNode(node.id);
		var transform = node.transforms[channel.sid];
		var defaultMatrix = node.matrix.clone().transpose();
		var time:Float, stride:Int;
		var i:Int, il:Int, j:Int, jl:Int;
		var data:Dynamic = {};
		switch (transform) {
			case "matrix":
				for (i = 0, il = inputSource.array.length; i < il; i++) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;
					if (data[time] == null) data[time] = {};
					if (channel.arraySyntax == true) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data[time][index] = value;
					} else {
						for (j = 0, jl = outputSource.stride; j < jl; j++) {
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

	function prepareAnimationData(data:Dynamic, defaultMatrix:Matrix4):Array<Dynamic> {
		var keyframes:Array<Dynamic> = [];
		for (var time in data) {
			keyframes.push({time: Std.parseFloat(time), value: data[time]});
		}
		keyframes.sort(ascending);
		for (var i = 0; i < 16; i++) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}
		return keyframes;
		function ascending(a:Dynamic, b:Dynamic):Int {
			return a.time - b.time;
		}
	}

	var position = new Vector3();
	var scale = new Vector3();
	var quaternion = new Quaternion();
	var matrix = new Matrix4();

	function createKeyframeTracks(animation:Dynamic, tracks:Array<VectorKeyframeTrack>):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;
		var times:Array<Float> = [];
		var positionData:Array<Float> = [];
		var quaternionData:Array<Float> = [];
		var scaleData:Array<Float> = [];
		for (var i = 0; i < keyframes.length; i++) {
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

	function transformAnimationData(keyframes:Array<Dynamic>, property:Int, defaultValue:Float):Void {
		var keyframe:Dynamic;
		var empty = true;
		var i:Int, l:Int;
		for (i = 0, l = keyframes.length; i < l; i++) {
			keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}
		if (empty == true) {
			for (i = 0, l = keyframes.length; i < l; i++) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	function createMissingKeyframes(keyframes:Array<Dynamic>, property:Int):Void {
		var prev:Dynamic, next:Dynamic;
		for (var i = 0; i < keyframes.length; i++) {
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

	function getPrev(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i >= 0) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	function getNext(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i < keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	function interpolate(key:Dynamic, prev:Dynamic, next:Dynamic, property:Int):Void {
		if ((next.time - prev.time) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = (((key.time - prev.time) * (next.value[property] - prev.value[property])) / (next.time - prev.time)) + prev.value[property];
	}

	function parseAnimationClip(xml:Dynamic):Void {
		var data:Dynamic = {
			name: xml.getAttribute("id") != null ? xml.getAttribute("id") : "default",
			start: Std.parseFloat(xml.getAttribute("start") != null ? xml.getAttribute("start") : "0"),
			end: Std.parseFloat(xml.getAttribute("end") != null ? xml.getAttribute("end") : "0"),
			animations: []
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.getAttribute("url")));
					break;
			}
		}
		library.clips[xml.getAttribute("id")] = data;
	}

	function buildAnimationClip(data:Dynamic):AnimationClip {
		var tracks:Array<VectorKeyframeTrack> = [];
		var name = data.name;
		var duration = (data.end - data.start) != 0 ? (data.end - data.start) : -1;
		var animations = data.animations;
		for (var i = 0; i < animations.length; i++) {
			var animationTracks = getAnimation(animations[i]);
			for (var j = 0; j < animationTracks.length; j++) {
				tracks.push(animationTracks[j]);
			}
		}
		return new AnimationClip(name, duration, tracks);
	}

	function getAnimationClip(id:String):AnimationClip {
		return getBuild(library.clips[id], buildAnimationClip);
	}

	function parseController(xml:Dynamic):Void {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "skin":
					data.id = parseId(child.getAttribute("source"));
					data.skin = parseSkin(child);
					break;
				case "morph":
					data.id = parseId(child.getAttribute("source"));
					console.warn("THREE.ColladaLoader: Morph target animation not supported yet.");
					break;
			}
		}
		library.controllers[xml.getAttribute("id")] = data;
	}

	function parseSkin(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			sources: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.textContent);
					break;
				case "source":
					var id = child.getAttribute("id");
					data.sources[id] = parseSource(child);
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

	function parseJoints(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					data.inputs[semantic] = id;
					break;
			}
		}
		return data;
	}

	function parseVertexWeights(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					var offset = Std.parseInt(child.getAttribute("offset"));
					data.inputs[semantic] = {id: id, offset: offset};
					break;
				case "vcount":
					data.vcount = parseInts(child.textContent);
					break;
				case "v":
					data.v = parseInts(child.textContent);
					break;
			}
		}
		return data;
	}

	function buildController(data:Dynamic):Dynamic {
		var build:Dynamic = {
			id: data.id
		};
		var geometry = library.geometries[build.id];
		if (data.skin != null) {
			build.skin = buildSkin(data.skin);
			geometry.sources.skinIndices = build.skin.indices;
			geometry.sources.skinWeights = build.skin.weights;
		}
		return build;
	}

	function buildSkin(data:Dynamic):Dynamic {
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
		var jointOffset = vertexWeights.inputs.JOINT.offset;
		var weightOffset = vertexWeights.inputs.WEIGHT.offset;
		var jointSource = data.sources[data.joints.inputs.JOINT];
		var inverseSource = data.sources[data.joints.inputs.INV_BIND_MATRIX];
		var weights = sources[vertexWeights.inputs.WEIGHT.id].array;
		var stride = 0;
		var i:Int, j:Int, l:Int;
		for (i = 0, l = vcount.length; i < l; i++) {
			var jointCount = vcount[i];
			var vertexSkinData:Array<Dynamic> = [];
			for (j = 0; j < jointCount; j++) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];
				vertexSkinData.push({index: skinIndex, weight: skinWeight});
				stride += 2;
			}
			vertexSkinData.sort(descending);
			for (j = 0; j < BONE_LIMIT; j++) {
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
		for (i = 0, l = jointSource.array.length; i < l; i++) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();
			build.joints.push({name: name, boneInverse: boneInverse});
		}
		return build;
		function descending(a:Dynamic, b:Dynamic):Int {
			return b.weight - a.weight;
		}
	}

	function getController(id:String):Dynamic {
		return getBuild(library.controllers[id], buildController);
	}

	function parseImage(xml:Dynamic):Void {
		var data:Dynamic = {
			init_from: getElementsByTagName(xml, "init_from")[0].textContent
		};
		library.images[xml.getAttribute("id")] = data;
	}

	function buildImage(data:Dynamic):String {
		if (data.build != null) return data.build;
		return data.init_from;
	}

	function getImage(id:String):String {
		var data = library.images[id];
		if (data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	function parseEffect(xml:Dynamic):Void {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}
		library.effects[xml.getAttribute("id")] = data;
	}

	function parseEffectProfileCOMMON(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			surfaces: {},
			samplers: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
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

	function parseEffectNewparam(xml:Dynamic, data:Dynamic):Void {
		var sid = xml.getAttribute("sid");
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "surface":
					data.surfaces[sid] = parseEffectSurface(child);
					break;
				case "sampler2D":
					data.samplers[sid] = parseEffectSampler(child);
					break;
			}
		}
	}

	function parseEffectSurface(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "init_from":
					data.init_from = child.textContent;
					break;
			}
		}
		return data;
	}

	function parseEffectSampler(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "source":
					data.source = child.textContent;
					break;
			}
		}
		return data;
	}

	function parseEffectTechnique(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
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

	function parseEffectParameters(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "emission":
				case "diffuse":
				case "specular":
				case "bump":
				case "ambient":
				case "shininess":
				case "transparency":
					data[child.nodeName] = parse
import three.extras.loaders.TGALoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.core.AnimationClip;
import three.core.Bone;
import three.core.BufferGeometry;
import three.core.Color;
import three.core.Float32BufferAttribute;
import three.core.Group;
import three.core.Line;
import three.core.LineBasicMaterial;
import three.core.LineSegments;
import three.core.Mesh;
import three.core.MeshBasicMaterial;
import three.core.MeshLambertMaterial;
import three.core.MeshPhongMaterial;
import three.core.Object3D;
import three.core.OrthographicCamera;
import three.core.PerspectiveCamera;
import three.core.PointLight;
import three.core.Scene;
import three.core.Skeleton;
import three.core.SkinnedMesh;
import three.core.SpotLight;
import three.core.AmbientLight;
import three.core.DirectionalLight;
import three.core.TextureLoader;
import three.animation.QuaternionKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.constants.WrappingModes;
import three.constants.Side;
import three.constants.ColorSpace;
import three.extras.core.AnimationAction;

class ColladaLoader extends Loader {

	public function new() {
		super();
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var path = (scope.path == "") ? LoaderUtils.extractUrlBase(url) : scope.path;
		var loader = new three.loaders.FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(text, path));
			} catch(e:Dynamic) {
				if (onError != null) onError(e);
				else console.error(e);
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String, path:String):Dynamic {
		var xml = new DOMParser().parseFromString(text, "application/xml");
		var collada = getElementsByTagName(xml, "COLLADA")[0];
		var parserError = xml.getElementsByTagName("parsererror")[0];
		if (parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText:String;
			if (errorElement != null) {
				errorText = errorElement.textContent;
			} else {
				errorText = parserErrorToText(parserError);
			}
			console.error("THREE.ColladaLoader: Failed to parse collada file.\n", errorText);
			return null;
		}
		var version = collada.getAttribute("version");
		console.debug("THREE.ColladaLoader: File version", version);
		var asset = parseAsset(getElementsByTagName(collada, "asset")[0]);
		var textureLoader = new three.core.TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		textureLoader.setCrossOrigin(this.crossOrigin);
		var tgaLoader:TGALoader;
		if (TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}
		var tempColor = new three.core.Color();
		var animations:Array<AnimationClip> = [];
		var kinematics:Dynamic = {};
		var count = 0;
		var library:Dynamic = {
			animations: {},
			clips: {},
			controllers: {},
			images: {},
			effects: {},
			materials: {},
			cameras: {},
			lights: {},
			geometries: {},
			nodes: {},
			visualScenes: {},
			kinematicsModels: {},
			physicsModels: {},
			kinematicsScenes: {}
		};
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

	function getElementsByTagName(xml:Dynamic, name:String):Array<Dynamic> {
		var array:Array<Dynamic> = [];
		var childNodes = xml.childNodes;
		for (var i = 0; i < childNodes.length; i++) {
			var child = childNodes[i];
			if (child.nodeName == name) {
				array.push(child);
			}
		}
		return array;
	}

	function parseStrings(text:String):Array<String> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<String>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = parts[i];
		}
		return array;
	}

	function parseFloats(text:String):Array<Float> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<Float>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = Std.parseFloat(parts[i]);
		}
		return array;
	}

	function parseInts(text:String):Array<Int> {
		if (text.length == 0) return [];
		var parts = text.trim().split(/\s+/);
		var array = new Array<Int>(parts.length);
		for (var i = 0; i < parts.length; i++) {
			array[i] = Std.parseInt(parts[i]);
		}
		return array;
	}

	function parseId(text:String):String {
		return text.substring(1);
	}

	function generateId():String {
		return "three_default_" + (count++);
	}

	function isEmpty(object:Dynamic):Bool {
		return Reflect.field(object, "length") == 0;
	}

	function parseAsset(xml:Dynamic):Dynamic {
		return {
			unit: parseAssetUnit(getElementsByTagName(xml, "unit")[0]),
			upAxis: parseAssetUpAxis(getElementsByTagName(xml, "up_axis")[0])
		};
	}

	function parseAssetUnit(xml:Dynamic):Float {
		if ((xml != null) && (xml.hasAttribute("meter") == true)) {
			return Std.parseFloat(xml.getAttribute("meter"));
		} else {
			return 1;
		}
	}

	function parseAssetUpAxis(xml:Dynamic):String {
		return xml != null ? xml.textContent : "Y_UP";
	}

	function parseLibrary(xml:Dynamic, libraryName:String, nodeName:String, parser:Dynamic->Void):Void {
		var library = getElementsByTagName(xml, libraryName)[0];
		if (library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for (var i = 0; i < elements.length; i++) {
				parser(elements[i]);
			}
		}
	}

	function buildLibrary(data:Dynamic, builder:Dynamic->Dynamic):Void {
		for (var name in data) {
			var object = data[name];
			object.build = builder(data[name]);
		}
	}

	function getBuild(data:Dynamic, builder:Dynamic->Dynamic):Dynamic {
		if (data.build != null) return data.build;
		data.build = builder(data);
		return data.build;
	}

	function parseAnimation(xml:Dynamic):Void {
		var data:Dynamic = {
			sources: {},
			samplers: {},
			channels: {}
		};
		var hasChildren = false;
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			var id:String;
			switch (child.nodeName) {
				case "source":
					id = child.getAttribute("id");
					data.sources[id] = parseSource(child);
					break;
				case "sampler":
					id = child.getAttribute("id");
					data.samplers[id] = parseAnimationSampler(child);
					break;
				case "channel":
					id = child.getAttribute("target");
					data.channels[id] = parseAnimationChannel(child);
					break;
				case "animation":
					parseAnimation(child);
					hasChildren = true;
					break;
				default:
					console.log(child);
			}
		}
		if (hasChildren == false) {
			library.animations[xml.getAttribute("id") != null ? xml.getAttribute("id") : MathUtils.generateUUID()] = data;
		}
	}

	function parseAnimationSampler(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var id = parseId(child.getAttribute("source"));
					var semantic = child.getAttribute("semantic");
					data.inputs[semantic] = id;
					break;
			}
		}
		return data;
	}

	function parseAnimationChannel(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		var target = xml.getAttribute("target");
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
			for (var i = 0; i < indices.length; i++) {
				indices[i] = Std.parseInt(indices[i].replace(/\)/, ""));
			}
			data.indices = indices;
		}
		data.id = id;
		data.sid = sid;
		data.arraySyntax = arraySyntax;
		data.memberSyntax = memberSyntax;
		data.sampler = parseId(xml.getAttribute("source"));
		return data;
	}

	function buildAnimation(data:Dynamic):Array<VectorKeyframeTrack> {
		var tracks:Array<VectorKeyframeTrack> = [];
		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;
		for (var target in channels) {
			if (channels.hasOwnProperty(target)) {
				var channel = channels[target];
				var sampler = samplers[channel.sampler];
				var inputId = sampler.inputs.INPUT;
				var outputId = sampler.inputs.OUTPUT;
				var inputSource = sources[inputId];
				var outputSource = sources[outputId];
				var animation = buildAnimationChannel(channel, inputSource, outputSource);
				createKeyframeTracks(animation, tracks);
			}
		}
		return tracks;
	}

	function getAnimation(id:String):Array<VectorKeyframeTrack> {
		return getBuild(library.animations[id], buildAnimation);
	}

	function buildAnimationChannel(channel:Dynamic, inputSource:Dynamic, outputSource:Dynamic):Dynamic {
		var node = library.nodes[channel.id];
		var object3D = getNode(node.id);
		var transform = node.transforms[channel.sid];
		var defaultMatrix = node.matrix.clone().transpose();
		var time:Float, stride:Int;
		var i:Int, il:Int, j:Int, jl:Int;
		var data:Dynamic = {};
		switch (transform) {
			case "matrix":
				for (i = 0, il = inputSource.array.length; i < il; i++) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;
					if (data[time] == null) data[time] = {};
					if (channel.arraySyntax == true) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data[time][index] = value;
					} else {
						for (j = 0, jl = outputSource.stride; j < jl; j++) {
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

	function prepareAnimationData(data:Dynamic, defaultMatrix:Matrix4):Array<Dynamic> {
		var keyframes:Array<Dynamic> = [];
		for (var time in data) {
			keyframes.push({time: Std.parseFloat(time), value: data[time]});
		}
		keyframes.sort(ascending);
		for (var i = 0; i < 16; i++) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}
		return keyframes;
		function ascending(a:Dynamic, b:Dynamic):Int {
			return a.time - b.time;
		}
	}

	var position = new Vector3();
	var scale = new Vector3();
	var quaternion = new Quaternion();
	var matrix = new Matrix4();

	function createKeyframeTracks(animation:Dynamic, tracks:Array<VectorKeyframeTrack>):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;
		var times:Array<Float> = [];
		var positionData:Array<Float> = [];
		var quaternionData:Array<Float> = [];
		var scaleData:Array<Float> = [];
		for (var i = 0; i < keyframes.length; i++) {
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

	function transformAnimationData(keyframes:Array<Dynamic>, property:Int, defaultValue:Float):Void {
		var keyframe:Dynamic;
		var empty = true;
		var i:Int, l:Int;
		for (i = 0, l = keyframes.length; i < l; i++) {
			keyframe = keyframes[i];
			if (keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}
		if (empty == true) {
			for (i = 0, l = keyframes.length; i < l; i++) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	function createMissingKeyframes(keyframes:Array<Dynamic>, property:Int):Void {
		var prev:Dynamic, next:Dynamic;
		for (var i = 0; i < keyframes.length; i++) {
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

	function getPrev(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i >= 0) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	function getNext(keyframes:Array<Dynamic>, i:Int, property:Int):Dynamic {
		while (i < keyframes.length) {
			var keyframe = keyframes[i];
			if (keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	function interpolate(key:Dynamic, prev:Dynamic, next:Dynamic, property:Int):Void {
		if ((next.time - prev.time) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = (((key.time - prev.time) * (next.value[property] - prev.value[property])) / (next.time - prev.time)) + prev.value[property];
	}

	function parseAnimationClip(xml:Dynamic):Void {
		var data:Dynamic = {
			name: xml.getAttribute("id") != null ? xml.getAttribute("id") : "default",
			start: Std.parseFloat(xml.getAttribute("start") != null ? xml.getAttribute("start") : "0"),
			end: Std.parseFloat(xml.getAttribute("end") != null ? xml.getAttribute("end") : "0"),
			animations: []
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.getAttribute("url")));
					break;
			}
		}
		library.clips[xml.getAttribute("id")] = data;
	}

	function buildAnimationClip(data:Dynamic):AnimationClip {
		var tracks:Array<VectorKeyframeTrack> = [];
		var name = data.name;
		var duration = (data.end - data.start) != 0 ? (data.end - data.start) : -1;
		var animations = data.animations;
		for (var i = 0; i < animations.length; i++) {
			var animationTracks = getAnimation(animations[i]);
			for (var j = 0; j < animationTracks.length; j++) {
				tracks.push(animationTracks[j]);
			}
		}
		return new AnimationClip(name, duration, tracks);
	}

	function getAnimationClip(id:String):AnimationClip {
		return getBuild(library.clips[id], buildAnimationClip);
	}

	function parseController(xml:Dynamic):Void {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "skin":
					data.id = parseId(child.getAttribute("source"));
					data.skin = parseSkin(child);
					break;
				case "morph":
					data.id = parseId(child.getAttribute("source"));
					console.warn("THREE.ColladaLoader: Morph target animation not supported yet.");
					break;
			}
		}
		library.controllers[xml.getAttribute("id")] = data;
	}

	function parseSkin(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			sources: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.textContent);
					break;
				case "source":
					var id = child.getAttribute("id");
					data.sources[id] = parseSource(child);
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

	function parseJoints(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					data.inputs[semantic] = id;
					break;
			}
		}
		return data;
	}

	function parseVertexWeights(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			inputs: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					var offset = Std.parseInt(child.getAttribute("offset"));
					data.inputs[semantic] = {id: id, offset: offset};
					break;
				case "vcount":
					data.vcount = parseInts(child.textContent);
					break;
				case "v":
					data.v = parseInts(child.textContent);
					break;
			}
		}
		return data;
	}

	function buildController(data:Dynamic):Dynamic {
		var build:Dynamic = {
			id: data.id
		};
		var geometry = library.geometries[build.id];
		if (data.skin != null) {
			build.skin = buildSkin(data.skin);
			geometry.sources.skinIndices = build.skin.indices;
			geometry.sources.skinWeights = build.skin.weights;
		}
		return build;
	}

	function buildSkin(data:Dynamic):Dynamic {
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
		var jointOffset = vertexWeights.inputs.JOINT.offset;
		var weightOffset = vertexWeights.inputs.WEIGHT.offset;
		var jointSource = data.sources[data.joints.inputs.JOINT];
		var inverseSource = data.sources[data.joints.inputs.INV_BIND_MATRIX];
		var weights = sources[vertexWeights.inputs.WEIGHT.id].array;
		var stride = 0;
		var i:Int, j:Int, l:Int;
		for (i = 0, l = vcount.length; i < l; i++) {
			var jointCount = vcount[i];
			var vertexSkinData:Array<Dynamic> = [];
			for (j = 0; j < jointCount; j++) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];
				vertexSkinData.push({index: skinIndex, weight: skinWeight});
				stride += 2;
			}
			vertexSkinData.sort(descending);
			for (j = 0; j < BONE_LIMIT; j++) {
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
		for (i = 0, l = jointSource.array.length; i < l; i++) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();
			build.joints.push({name: name, boneInverse: boneInverse});
		}
		return build;
		function descending(a:Dynamic, b:Dynamic):Int {
			return b.weight - a.weight;
		}
	}

	function getController(id:String):Dynamic {
		return getBuild(library.controllers[id], buildController);
	}

	function parseImage(xml:Dynamic):Void {
		var data:Dynamic = {
			init_from: getElementsByTagName(xml, "init_from")[0].textContent
		};
		library.images[xml.getAttribute("id")] = data;
	}

	function buildImage(data:Dynamic):String {
		if (data.build != null) return data.build;
		return data.init_from;
	}

	function getImage(id:String):String {
		var data = library.images[id];
		if (data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	function parseEffect(xml:Dynamic):Void {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}
		library.effects[xml.getAttribute("id")] = data;
	}

	function parseEffectProfileCOMMON(xml:Dynamic):Dynamic {
		var data:Dynamic = {
			surfaces: {},
			samplers: {}
		};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
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

	function parseEffectNewparam(xml:Dynamic, data:Dynamic):Void {
		var sid = xml.getAttribute("sid");
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "surface":
					data.surfaces[sid] = parseEffectSurface(child);
					break;
				case "sampler2D":
					data.samplers[sid] = parseEffectSampler(child);
					break;
			}
		}
	}

	function parseEffectSurface(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "init_from":
					data.init_from = child.textContent;
					break;
			}
		}
		return data;
	}

	function parseEffectSampler(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "source":
					data.source = child.textContent;
					break;
			}
		}
		return data;
	}

	function parseEffectTechnique(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
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

	function parseEffectParameters(xml:Dynamic):Dynamic {
		var data:Dynamic = {};
		for (var i = 0; i < xml.childNodes.length; i++) {
			var child = xml.childNodes[i];
			if (child.nodeType != 1) continue;
			switch (child.nodeName) {
				case "emission":
				case "diffuse":
				case "specular":
				case "bump":
				case "ambient":
				case "shininess":
				case "transparency":
					data[child.nodeName] = parse