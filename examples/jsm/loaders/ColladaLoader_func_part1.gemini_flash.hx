import three.extras.loaders.TGALoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.animation.AnimationClip;
import three.animation.QuaternionKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Object3D;
import three.core.Scene;
import three.core.Skeleton;
import three.core.SkinnedMesh;
import three.geometries.Line;
import three.geometries.LineSegments;
import three.lights.AmbientLight;
import three.lights.DirectionalLight;
import three.lights.PointLight;
import three.lights.SpotLight;
import three.materials.LineBasicMaterial;
import three.materials.MeshBasicMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshPhongMaterial;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.textures.TextureLoader;
import three.constants.Wrapping;
import three.constants.Side;
import three.constants.ColorSpace;
import three.core.Bone;
import three.core.Group;
import three.materials.Material;

class ColladaLoader extends Loader {

	public function new( manager:Loader = null ) {
		super(manager);
	}

	public function load( url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void ):Void {
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
				if(onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse( text:String, path:String ):Dynamic {
		var xml = new DOMParser().parseFromString(text, "application/xml");
		var collada = getElementsByTagName(xml, "COLLADA")[0];
		var parserError = xml.getElementsByTagName("parsererror")[0];
		if(parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText = null;
			if(errorElement != null) {
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
		var textureLoader = new TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path).setCrossOrigin(this.crossOrigin);
		var tgaLoader = null;
		if(TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}
		var tempColor = new three.math.Color();
		var animations = new Array<AnimationClip>();
		var kinematics = new Kinematics();
		var count = 0;
		var library = {
			animations: new Map<String, AnimationData>(),
			clips: new Map<String, AnimationClipData>(),
			controllers: new Map<String, ControllerData>(),
			images: new Map<String, String>(),
			effects: new Map<String, EffectData>(),
			materials: new Map<String, MaterialData>(),
			cameras: new Map<String, CameraData>(),
			lights: new Map<String, LightData>(),
			geometries: new Map<String, GeometryData>(),
			nodes: new Map<String, NodeData>(),
			visualScenes: new Map<String, VisualSceneData>(),
			kinematicsModels: new Map<String, KinematicsModelData>(),
			physicsModels: new Map<String, PhysicsModelData>(),
			kinematicsScenes: new Map<String, KinematicsSceneData>()
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
		if(asset.upAxis == "Z_UP") {
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

	function getElementsByTagName( xml:Dynamic, name:String ):Array<Dynamic> {
		var array = new Array<Dynamic>();
		var childNodes = xml.childNodes;
		for(i in 0...childNodes.length) {
			var child = childNodes[i];
			if(child.nodeName == name) {
				array.push(child);
			}
		}
		return array;
	}

	function parseStrings( text:String ):Array<String> {
		if(text.length == 0) return new Array<String>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<String>(parts.length);
		for(i in 0...parts.length) {
			array[i] = parts[i];
		}
		return array;
	}

	function parseFloats( text:String ):Array<Float> {
		if(text.length == 0) return new Array<Float>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<Float>(parts.length);
		for(i in 0...parts.length) {
			array[i] = Std.parseFloat(parts[i]);
		}
		return array;
	}

	function parseInts( text:String ):Array<Int> {
		if(text.length == 0) return new Array<Int>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<Int>(parts.length);
		for(i in 0...parts.length) {
			array[i] = Std.parseInt(parts[i]);
		}
		return array;
	}

	function parseId( text:String ):String {
		return text.substring(1);
	}

	function generateId():String {
		return "three_default_" + (count++);
	}

	function isEmpty( object:Dynamic ):Bool {
		return Reflect.field(object, "length") == 0;
	}

	function parseAsset( xml:Dynamic ):{ unit:Float, upAxis:String } {
		return {
			unit: parseAssetUnit(getElementsByTagName(xml, "unit")[0]),
			upAxis: parseAssetUpAxis(getElementsByTagName(xml, "up_axis")[0])
		};
	}

	function parseAssetUnit( xml:Dynamic ):Float {
		if(xml != null && xml.hasAttribute("meter") == true) {
			return Std.parseFloat(xml.getAttribute("meter"));
		} else {
			return 1.0;
		}
	}

	function parseAssetUpAxis( xml:Dynamic ):String {
		return xml != null ? xml.textContent : "Y_UP";
	}

	function parseLibrary( xml:Dynamic, libraryName:String, nodeName:String, parser:Dynamic->Void ):Void {
		var library = getElementsByTagName(xml, libraryName)[0];
		if(library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for(i in 0...elements.length) {
				parser(elements[i]);
			}
		}
	}

	function buildLibrary( data:Dynamic, builder:Dynamic->Dynamic ):Void {
		for(name in Reflect.fields(data)) {
			var object = Reflect.field(data, name);
			Reflect.setField(object, "build", builder(Reflect.field(data, name)));
		}
	}

	function getBuild( data:Dynamic, builder:Dynamic->Dynamic ):Dynamic {
		if(Reflect.field(data, "build") != null) return Reflect.field(data, "build");
		Reflect.setField(data, "build", builder(data));
		return Reflect.field(data, "build");
	}

	function parseAnimation( xml:Dynamic ):Void {
		var data = {
			sources: new Map<String, SourceData>(),
			samplers: new Map<String, AnimationSamplerData>(),
			channels: new Map<String, AnimationChannelData>()
		};
		var hasChildren = false;
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			var id = null;
			switch(child.nodeName) {
				case "source":
					id = child.getAttribute("id");
					data.sources.set(id, parseSource(child));
					break;
				case "sampler":
					id = child.getAttribute("id");
					data.samplers.set(id, parseAnimationSampler(child));
					break;
				case "channel":
					id = child.getAttribute("target");
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
		if(hasChildren == false) {
			library.animations.set(xml.getAttribute("id") != null ? xml.getAttribute("id") : MathUtils.generateUUID(), data);
		}
	}

	function parseAnimationSampler( xml:Dynamic ):{ inputs:Map<String, String> } {
		var data = {
			inputs: new Map<String, String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var id = parseId(child.getAttribute("source"));
					var semantic = child.getAttribute("semantic");
					data.inputs.set(semantic, id);
					break;
			}
		}
		return data;
	}

	function parseAnimationChannel( xml:Dynamic ):{ id:String, sid:String, arraySyntax:Bool, memberSyntax:Bool, sampler:String, indices:Array<Int>, member:String } {
		var data = {
			id: null,
			sid: null,
			arraySyntax: false,
			memberSyntax: false,
			sampler: null,
			indices: new Array<Int>(),
			member: null
		};
		var target = xml.getAttribute("target");
		var parts = target.split("/");
		data.id = parts.shift();
		data.sid = parts.shift();
		var arraySyntax = (data.sid.indexOf("(") != - 1);
		var memberSyntax = (data.sid.indexOf(".") != - 1);
		if(memberSyntax) {
			parts = data.sid.split(".");
			data.sid = parts.shift();
			data.member = parts.shift();
		} else if(arraySyntax) {
			var indices = data.sid.split("(");
			data.sid = indices.shift();
			for(i in 0...indices.length) {
				indices[i] = Std.parseInt(indices[i].replace(new EReg("\\)"), ""), 10);
			}
			data.indices = indices;
		}
		data.sampler = parseId(xml.getAttribute("source"));
		return data;
	}

	function buildAnimation( data:AnimationData ):Array<VectorKeyframeTrack | QuaternionKeyframeTrack> {
		var tracks = new Array<VectorKeyframeTrack | QuaternionKeyframeTrack>();
		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;
		for(target in channels.keys()) {
			var channel = channels.get(target);
			var sampler = samplers.get(channel.sampler);
			var inputId = sampler.inputs.get("INPUT");
			var outputId = sampler.inputs.get("OUTPUT");
			var inputSource = sources.get(inputId);
			var outputSource = sources.get(outputId);
			var animation = buildAnimationChannel(channel, inputSource, outputSource);
			createKeyframeTracks(animation, tracks);
		}
		return tracks;
	}

	function getAnimation( id:String ):Array<VectorKeyframeTrack | QuaternionKeyframeTrack> {
		return getBuild(library.animations.get(id), buildAnimation);
	}

	function buildAnimationChannel( channel:AnimationChannelData, inputSource:SourceData, outputSource:SourceData ):{ name:String, keyframes:Array<{ time:Float, value:Array<Float> }> } {
		var node = library.nodes.get(channel.id);
		var object3D = getNode(node.id);
		var transform = node.transforms.get(channel.sid);
		var defaultMatrix = node.matrix.clone().transpose();
		var time = 0.0;
		var stride = 0;
		var i = 0;
		var il = 0;
		var j = 0;
		var jl = 0;
		var data = new Map<Float, Array<Float>>();
		switch(transform) {
			case "matrix":
				il = inputSource.array.length;
				for(i in 0...il) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;
					if(!data.exists(time)) data.set(time, new Array<Float>());
					if(channel.arraySyntax == true) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data.get(time)[index] = value;
					} else {
						jl = outputSource.stride;
						for(j in 0...jl) {
							data.get(time)[j] = outputSource.array[stride + j];
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
		var animation = {
			name: object3D.uuid,
			keyframes: keyframes
		};
		return animation;
	}

	function prepareAnimationData( data:Map<Float, Array<Float>>, defaultMatrix:Matrix4 ):Array<{ time:Float, value:Array<Float> }> {
		var keyframes = new Array<{ time:Float, value:Array<Float> }>();
		for(time in data.keys()) {
			keyframes.push({ time: Std.parseFloat(time), value: data.get(time) });
		}
		keyframes.sort(ascending);
		for(i in 0...16) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}
		return keyframes;
		function ascending( a:{ time:Float, value:Array<Float> }, b:{ time:Float, value:Array<Float> } ):Int {
			return a.time - b.time;
		}
	}

	var position = new Vector3();
	var scale = new Vector3();
	var quaternion = new Quaternion();
	var matrix = new Matrix4();

	function createKeyframeTracks( animation:{ name:String, keyframes:Array<{ time:Float, value:Array<Float> }> }, tracks:Array<VectorKeyframeTrack | QuaternionKeyframeTrack> ):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;
		var times = new Array<Float>();
		var positionData = new Array<Float>();
		var quaternionData = new Array<Float>();
		var scaleData = new Array<Float>();
		for(i in 0...keyframes.length) {
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
		if(positionData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".position", times, positionData));
		if(quaternionData.length > 0) tracks.push(new QuaternionKeyframeTrack(name + ".quaternion", times, quaternionData));
		if(scaleData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".scale", times, scaleData));
	}

	function transformAnimationData( keyframes:Array<{ time:Float, value:Array<Float> }>, property:Int, defaultValue:Float ):Void {
		var keyframe = null;
		var empty = true;
		var i = 0;
		var l = 0;
		l = keyframes.length;
		for(i in 0...l) {
			keyframe = keyframes[i];
			if(keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}
		if(empty == true) {
			l = keyframes.length;
			for(i in 0...l) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	function createMissingKeyframes( keyframes:Array<{ time:Float, value:Array<Float> }>, property:Int ):Void {
		var prev = null;
		var next = null;
		for(i in 0...keyframes.length) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] == null) {
				prev = getPrev(keyframes, i, property);
				next = getNext(keyframes, i, property);
				if(prev == null) {
					keyframe.value[property] = next.value[property];
					continue;
				}
				if(next == null) {
					keyframe.value[property] = prev.value[property];
					continue;
				}
				interpolate(keyframe, prev, next, property);
			}
		}
	}

	function getPrev( keyframes:Array<{ time:Float, value:Array<Float> }>, i:Int, property:Int ):{ time:Float, value:Array<Float> } {
		while(i >= 0) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	function getNext( keyframes:Array<{ time:Float, value:Array<Float> }>, i:Int, property:Int ):{ time:Float, value:Array<Float> } {
		while(i < keyframes.length) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	function interpolate( key:{ time:Float, value:Array<Float> }, prev:{ time:Float, value:Array<Float> }, next:{ time:Float, value:Array<Float> }, property:Int ):Void {
		if((next.time - prev.time) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = (((key.time - prev.time) * (next.value[property] - prev.value[property])) / (next.time - prev.time)) + prev.value[property];
	}

	function parseAnimationClip( xml:Dynamic ):Void {
		var data = {
			name: xml.getAttribute("id") != null ? xml.getAttribute("id") : "default",
			start: Std.parseFloat(xml.getAttribute("start") != null ? xml.getAttribute("start") : "0"),
			end: Std.parseFloat(xml.getAttribute("end") != null ? xml.getAttribute("end") : "0"),
			animations: new Array<String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.getAttribute("url")));
					break;
			}
		}
		library.clips.set(xml.getAttribute("id"), data);
	}

	function buildAnimationClip( data:AnimationClipData ):AnimationClip {
		var tracks = new Array<VectorKeyframeTrack | QuaternionKeyframeTrack>();
		var name = data.name;
		var duration = (data.end - data.start) != -1 ? (data.end - data.start) : -1;
		var animations = data.animations;
		for(i in 0...animations.length) {
			var animationTracks = getAnimation(animations[i]);
			for(j in 0...animationTracks.length) {
				tracks.push(animationTracks[j]);
			}
		}
		return new AnimationClip(name, duration, tracks);
	}

	function getAnimationClip( id:String ):AnimationClip {
		return getBuild(library.clips.get(id), buildAnimationClip);
	}

	function parseController( xml:Dynamic ):Void {
		var data = {
			sources: new Map<String, SourceData>(),
			skin: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
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
		library.controllers.set(xml.getAttribute("id"), data);
	}

	function parseSkin( xml:Dynamic ):{ sources:Map<String, SourceData>, bindShapeMatrix:Array<Float>, joints:JointsData, vertexWeights:VertexWeightsData } {
		var data = {
			sources: new Map<String, SourceData>(),
			bindShapeMatrix: null,
			joints: null,
			vertexWeights: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.textContent);
					break;
				case "source":
					var id = child.getAttribute("id");
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

	function parseJoints( xml:Dynamic ):{ inputs:Map<String, String> } {
		var data = {
			inputs: new Map<String, String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					data.inputs.set(semantic, id);
					break;
			}
		}
		return data;
	}

	function parseVertexWeights( xml:Dynamic ):{ inputs:Map<String, { id:String, offset:Int }>, vcount:Array<Int>, v:Array<Int> } {
		var data = {
			inputs: new Map<String, { id:String, offset:Int }>(),
			vcount: null,
			v: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					var offset = Std.parseInt(child.getAttribute("offset"));
					data.inputs.set(semantic, { id: id, offset: offset });
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

	function buildController( data:ControllerData ):{ id:String, skin:SkinData } {
		var build = {
			id: data.id,
			skin: null
		};
		var geometry = library.geometries.get(build.id);
		if(data.skin != null) {
			build.skin = buildSkin(data.skin);
			geometry.sources.set("skinIndices", build.skin.indices);
			geometry.sources.set("skinWeights", build.skin.weights);
		}
		return build;
	}

	function buildSkin( data:SkinData ):{ joints:Array<{ name:String, boneInverse:Matrix4 }>, indices:{ array:Array<Float>, stride:Int }, weights:{ array:Array<Float>, stride:Int }, bindMatrix:Matrix4 } {
		var BONE_LIMIT = 4;
		var build = {
			joints: new Array<{ name:String, boneInverse:Matrix4 }>(),
			indices: {
				array: new Array<Float>(),
				stride: BONE_LIMIT
			},
			weights: {
				array: new Array<Float>(),
				stride: BONE_LIMIT
			},
			bindMatrix: null
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
		var i = 0;
		var j = 0;
		var l = 0;
		l = vcount.length;
		for(i in 0...l) {
			var jointCount = vcount[i];
			var vertexSkinData = new Array<{ index:Int, weight:Float }>();
			for(j in 0...jointCount) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];
				vertexSkinData.push({ index: skinIndex, weight: skinWeight });
				stride += 2;
			}
			vertexSkinData.sort(descending);
			for(j in 0...BONE_LIMIT) {
				var d = vertexSkinData[j];
				if(d != null) {
					build.indices.array.push(d.index);
					build.weights.array.push(d.weight);
				} else {
					build.indices.array.push(0);
					build.weights.array.push(0);
				}
			}
		}
		if(data.bindShapeMatrix != null) {
			build.bindMatrix = new Matrix4().fromArray(data.bindShapeMatrix).transpose();
		} else {
			build.bindMatrix = new Matrix4().identity();
		}
		l = jointSource.array.length;
		for(i in 0...l) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();
			build.joints.push({ name: name, boneInverse: boneInverse });
		}
		return build;
		function descending( a:{ index:Int, weight:Float }, b:{ index:Int, weight:Float } ):Int {
			return b.weight - a.weight;
		}
	}

	function getController( id:String ):{ id:String, skin:SkinData } {
		return getBuild(library.controllers.get(id), buildController);
	}

	function parseImage( xml:Dynamic ):Void {
		var data = {
			init_from: getElementsByTagName(xml, "init_from")[0].textContent
		};
		library.images.set(xml.getAttribute("id"), data);
	}

	function buildImage( data:ImageData ):String {
		if(Reflect.field(data, "build") != null) return Reflect.field(data, "build");
		return data.init_from;
	}

	function getImage( id:String ):String {
		var data = library.images.get(id);
		if(data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	function parseEffect( xml:Dynamic ):Void {
		var data = {
			profile: null,
			extra: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}
		library.effects.set(xml.getAttribute("id"), data);
	}

	function parseEffectProfileCOMMON( xml:Dynamic ):{ surfaces:Map<String, EffectSurfaceData>, samplers:Map<String, EffectSamplerData>, technique:EffectTechniqueData, extra:EffectExtraData } {
		var data = {
			surfaces: new Map<String, EffectSurfaceData>(),
			samplers: new Map<String, EffectSamplerData>(),
			technique: null,
			extra: null
		};
		for(i in 0...xml.childNodes.length) {
			
import three.extras.loaders.TGALoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.animation.AnimationClip;
import three.animation.QuaternionKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Object3D;
import three.core.Scene;
import three.core.Skeleton;
import three.core.SkinnedMesh;
import three.geometries.Line;
import three.geometries.LineSegments;
import three.lights.AmbientLight;
import three.lights.DirectionalLight;
import three.lights.PointLight;
import three.lights.SpotLight;
import three.materials.LineBasicMaterial;
import three.materials.MeshBasicMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshPhongMaterial;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.textures.TextureLoader;
import three.constants.Wrapping;
import three.constants.Side;
import three.constants.ColorSpace;
import three.core.Bone;
import three.core.Group;
import three.materials.Material;

class ColladaLoader extends Loader {

	public function new( manager:Loader = null ) {
		super(manager);
	}

	public function load( url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void ):Void {
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
				if(onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse( text:String, path:String ):Dynamic {
		var xml = new DOMParser().parseFromString(text, "application/xml");
		var collada = getElementsByTagName(xml, "COLLADA")[0];
		var parserError = xml.getElementsByTagName("parsererror")[0];
		if(parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText = null;
			if(errorElement != null) {
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
		var textureLoader = new TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path).setCrossOrigin(this.crossOrigin);
		var tgaLoader = null;
		if(TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}
		var tempColor = new three.math.Color();
		var animations = new Array<AnimationClip>();
		var kinematics = new Kinematics();
		var count = 0;
		var library = {
			animations: new Map<String, AnimationData>(),
			clips: new Map<String, AnimationClipData>(),
			controllers: new Map<String, ControllerData>(),
			images: new Map<String, String>(),
			effects: new Map<String, EffectData>(),
			materials: new Map<String, MaterialData>(),
			cameras: new Map<String, CameraData>(),
			lights: new Map<String, LightData>(),
			geometries: new Map<String, GeometryData>(),
			nodes: new Map<String, NodeData>(),
			visualScenes: new Map<String, VisualSceneData>(),
			kinematicsModels: new Map<String, KinematicsModelData>(),
			physicsModels: new Map<String, PhysicsModelData>(),
			kinematicsScenes: new Map<String, KinematicsSceneData>()
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
		if(asset.upAxis == "Z_UP") {
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

	function getElementsByTagName( xml:Dynamic, name:String ):Array<Dynamic> {
		var array = new Array<Dynamic>();
		var childNodes = xml.childNodes;
		for(i in 0...childNodes.length) {
			var child = childNodes[i];
			if(child.nodeName == name) {
				array.push(child);
			}
		}
		return array;
	}

	function parseStrings( text:String ):Array<String> {
		if(text.length == 0) return new Array<String>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<String>(parts.length);
		for(i in 0...parts.length) {
			array[i] = parts[i];
		}
		return array;
	}

	function parseFloats( text:String ):Array<Float> {
		if(text.length == 0) return new Array<Float>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<Float>(parts.length);
		for(i in 0...parts.length) {
			array[i] = Std.parseFloat(parts[i]);
		}
		return array;
	}

	function parseInts( text:String ):Array<Int> {
		if(text.length == 0) return new Array<Int>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<Int>(parts.length);
		for(i in 0...parts.length) {
			array[i] = Std.parseInt(parts[i]);
		}
		return array;
	}

	function parseId( text:String ):String {
		return text.substring(1);
	}

	function generateId():String {
		return "three_default_" + (count++);
	}

	function isEmpty( object:Dynamic ):Bool {
		return Reflect.field(object, "length") == 0;
	}

	function parseAsset( xml:Dynamic ):{ unit:Float, upAxis:String } {
		return {
			unit: parseAssetUnit(getElementsByTagName(xml, "unit")[0]),
			upAxis: parseAssetUpAxis(getElementsByTagName(xml, "up_axis")[0])
		};
	}

	function parseAssetUnit( xml:Dynamic ):Float {
		if(xml != null && xml.hasAttribute("meter") == true) {
			return Std.parseFloat(xml.getAttribute("meter"));
		} else {
			return 1.0;
		}
	}

	function parseAssetUpAxis( xml:Dynamic ):String {
		return xml != null ? xml.textContent : "Y_UP";
	}

	function parseLibrary( xml:Dynamic, libraryName:String, nodeName:String, parser:Dynamic->Void ):Void {
		var library = getElementsByTagName(xml, libraryName)[0];
		if(library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for(i in 0...elements.length) {
				parser(elements[i]);
			}
		}
	}

	function buildLibrary( data:Dynamic, builder:Dynamic->Dynamic ):Void {
		for(name in Reflect.fields(data)) {
			var object = Reflect.field(data, name);
			Reflect.setField(object, "build", builder(Reflect.field(data, name)));
		}
	}

	function getBuild( data:Dynamic, builder:Dynamic->Dynamic ):Dynamic {
		if(Reflect.field(data, "build") != null) return Reflect.field(data, "build");
		Reflect.setField(data, "build", builder(data));
		return Reflect.field(data, "build");
	}

	function parseAnimation( xml:Dynamic ):Void {
		var data = {
			sources: new Map<String, SourceData>(),
			samplers: new Map<String, AnimationSamplerData>(),
			channels: new Map<String, AnimationChannelData>()
		};
		var hasChildren = false;
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			var id = null;
			switch(child.nodeName) {
				case "source":
					id = child.getAttribute("id");
					data.sources.set(id, parseSource(child));
					break;
				case "sampler":
					id = child.getAttribute("id");
					data.samplers.set(id, parseAnimationSampler(child));
					break;
				case "channel":
					id = child.getAttribute("target");
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
		if(hasChildren == false) {
			library.animations.set(xml.getAttribute("id") != null ? xml.getAttribute("id") : MathUtils.generateUUID(), data);
		}
	}

	function parseAnimationSampler( xml:Dynamic ):{ inputs:Map<String, String> } {
		var data = {
			inputs: new Map<String, String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var id = parseId(child.getAttribute("source"));
					var semantic = child.getAttribute("semantic");
					data.inputs.set(semantic, id);
					break;
			}
		}
		return data;
	}

	function parseAnimationChannel( xml:Dynamic ):{ id:String, sid:String, arraySyntax:Bool, memberSyntax:Bool, sampler:String, indices:Array<Int>, member:String } {
		var data = {
			id: null,
			sid: null,
			arraySyntax: false,
			memberSyntax: false,
			sampler: null,
			indices: new Array<Int>(),
			member: null
		};
		var target = xml.getAttribute("target");
		var parts = target.split("/");
		data.id = parts.shift();
		data.sid = parts.shift();
		var arraySyntax = (data.sid.indexOf("(") != - 1);
		var memberSyntax = (data.sid.indexOf(".") != - 1);
		if(memberSyntax) {
			parts = data.sid.split(".");
			data.sid = parts.shift();
			data.member = parts.shift();
		} else if(arraySyntax) {
			var indices = data.sid.split("(");
			data.sid = indices.shift();
			for(i in 0...indices.length) {
				indices[i] = Std.parseInt(indices[i].replace(new EReg("\\)"), ""), 10);
			}
			data.indices = indices;
		}
		data.sampler = parseId(xml.getAttribute("source"));
		return data;
	}

	function buildAnimation( data:AnimationData ):Array<VectorKeyframeTrack | QuaternionKeyframeTrack> {
		var tracks = new Array<VectorKeyframeTrack | QuaternionKeyframeTrack>();
		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;
		for(target in channels.keys()) {
			var channel = channels.get(target);
			var sampler = samplers.get(channel.sampler);
			var inputId = sampler.inputs.get("INPUT");
			var outputId = sampler.inputs.get("OUTPUT");
			var inputSource = sources.get(inputId);
			var outputSource = sources.get(outputId);
			var animation = buildAnimationChannel(channel, inputSource, outputSource);
			createKeyframeTracks(animation, tracks);
		}
		return tracks;
	}

	function getAnimation( id:String ):Array<VectorKeyframeTrack | QuaternionKeyframeTrack> {
		return getBuild(library.animations.get(id), buildAnimation);
	}

	function buildAnimationChannel( channel:AnimationChannelData, inputSource:SourceData, outputSource:SourceData ):{ name:String, keyframes:Array<{ time:Float, value:Array<Float> }> } {
		var node = library.nodes.get(channel.id);
		var object3D = getNode(node.id);
		var transform = node.transforms.get(channel.sid);
		var defaultMatrix = node.matrix.clone().transpose();
		var time = 0.0;
		var stride = 0;
		var i = 0;
		var il = 0;
		var j = 0;
		var jl = 0;
		var data = new Map<Float, Array<Float>>();
		switch(transform) {
			case "matrix":
				il = inputSource.array.length;
				for(i in 0...il) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;
					if(!data.exists(time)) data.set(time, new Array<Float>());
					if(channel.arraySyntax == true) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data.get(time)[index] = value;
					} else {
						jl = outputSource.stride;
						for(j in 0...jl) {
							data.get(time)[j] = outputSource.array[stride + j];
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
		var animation = {
			name: object3D.uuid,
			keyframes: keyframes
		};
		return animation;
	}

	function prepareAnimationData( data:Map<Float, Array<Float>>, defaultMatrix:Matrix4 ):Array<{ time:Float, value:Array<Float> }> {
		var keyframes = new Array<{ time:Float, value:Array<Float> }>();
		for(time in data.keys()) {
			keyframes.push({ time: Std.parseFloat(time), value: data.get(time) });
		}
		keyframes.sort(ascending);
		for(i in 0...16) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}
		return keyframes;
		function ascending( a:{ time:Float, value:Array<Float> }, b:{ time:Float, value:Array<Float> } ):Int {
			return a.time - b.time;
		}
	}

	var position = new Vector3();
	var scale = new Vector3();
	var quaternion = new Quaternion();
	var matrix = new Matrix4();

	function createKeyframeTracks( animation:{ name:String, keyframes:Array<{ time:Float, value:Array<Float> }> }, tracks:Array<VectorKeyframeTrack | QuaternionKeyframeTrack> ):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;
		var times = new Array<Float>();
		var positionData = new Array<Float>();
		var quaternionData = new Array<Float>();
		var scaleData = new Array<Float>();
		for(i in 0...keyframes.length) {
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
		if(positionData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".position", times, positionData));
		if(quaternionData.length > 0) tracks.push(new QuaternionKeyframeTrack(name + ".quaternion", times, quaternionData));
		if(scaleData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".scale", times, scaleData));
	}

	function transformAnimationData( keyframes:Array<{ time:Float, value:Array<Float> }>, property:Int, defaultValue:Float ):Void {
		var keyframe = null;
		var empty = true;
		var i = 0;
		var l = 0;
		l = keyframes.length;
		for(i in 0...l) {
			keyframe = keyframes[i];
			if(keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}
		if(empty == true) {
			l = keyframes.length;
			for(i in 0...l) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	function createMissingKeyframes( keyframes:Array<{ time:Float, value:Array<Float> }>, property:Int ):Void {
		var prev = null;
		var next = null;
		for(i in 0...keyframes.length) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] == null) {
				prev = getPrev(keyframes, i, property);
				next = getNext(keyframes, i, property);
				if(prev == null) {
					keyframe.value[property] = next.value[property];
					continue;
				}
				if(next == null) {
					keyframe.value[property] = prev.value[property];
					continue;
				}
				interpolate(keyframe, prev, next, property);
			}
		}
	}

	function getPrev( keyframes:Array<{ time:Float, value:Array<Float> }>, i:Int, property:Int ):{ time:Float, value:Array<Float> } {
		while(i >= 0) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	function getNext( keyframes:Array<{ time:Float, value:Array<Float> }>, i:Int, property:Int ):{ time:Float, value:Array<Float> } {
		while(i < keyframes.length) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	function interpolate( key:{ time:Float, value:Array<Float> }, prev:{ time:Float, value:Array<Float> }, next:{ time:Float, value:Array<Float> }, property:Int ):Void {
		if((next.time - prev.time) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = (((key.time - prev.time) * (next.value[property] - prev.value[property])) / (next.time - prev.time)) + prev.value[property];
	}

	function parseAnimationClip( xml:Dynamic ):Void {
		var data = {
			name: xml.getAttribute("id") != null ? xml.getAttribute("id") : "default",
			start: Std.parseFloat(xml.getAttribute("start") != null ? xml.getAttribute("start") : "0"),
			end: Std.parseFloat(xml.getAttribute("end") != null ? xml.getAttribute("end") : "0"),
			animations: new Array<String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.getAttribute("url")));
					break;
			}
		}
		library.clips.set(xml.getAttribute("id"), data);
	}

	function buildAnimationClip( data:AnimationClipData ):AnimationClip {
		var tracks = new Array<VectorKeyframeTrack | QuaternionKeyframeTrack>();
		var name = data.name;
		var duration = (data.end - data.start) != -1 ? (data.end - data.start) : -1;
		var animations = data.animations;
		for(i in 0...animations.length) {
			var animationTracks = getAnimation(animations[i]);
			for(j in 0...animationTracks.length) {
				tracks.push(animationTracks[j]);
			}
		}
		return new AnimationClip(name, duration, tracks);
	}

	function getAnimationClip( id:String ):AnimationClip {
		return getBuild(library.clips.get(id), buildAnimationClip);
	}

	function parseController( xml:Dynamic ):Void {
		var data = {
			sources: new Map<String, SourceData>(),
			skin: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
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
		library.controllers.set(xml.getAttribute("id"), data);
	}

	function parseSkin( xml:Dynamic ):{ sources:Map<String, SourceData>, bindShapeMatrix:Array<Float>, joints:JointsData, vertexWeights:VertexWeightsData } {
		var data = {
			sources: new Map<String, SourceData>(),
			bindShapeMatrix: null,
			joints: null,
			vertexWeights: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.textContent);
					break;
				case "source":
					var id = child.getAttribute("id");
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

	function parseJoints( xml:Dynamic ):{ inputs:Map<String, String> } {
		var data = {
			inputs: new Map<String, String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					data.inputs.set(semantic, id);
					break;
			}
		}
		return data;
	}

	function parseVertexWeights( xml:Dynamic ):{ inputs:Map<String, { id:String, offset:Int }>, vcount:Array<Int>, v:Array<Int> } {
		var data = {
			inputs: new Map<String, { id:String, offset:Int }>(),
			vcount: null,
			v: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					var offset = Std.parseInt(child.getAttribute("offset"));
					data.inputs.set(semantic, { id: id, offset: offset });
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

	function buildController( data:ControllerData ):{ id:String, skin:SkinData } {
		var build = {
			id: data.id,
			skin: null
		};
		var geometry = library.geometries.get(build.id);
		if(data.skin != null) {
			build.skin = buildSkin(data.skin);
			geometry.sources.set("skinIndices", build.skin.indices);
			geometry.sources.set("skinWeights", build.skin.weights);
		}
		return build;
	}

	function buildSkin( data:SkinData ):{ joints:Array<{ name:String, boneInverse:Matrix4 }>, indices:{ array:Array<Float>, stride:Int }, weights:{ array:Array<Float>, stride:Int }, bindMatrix:Matrix4 } {
		var BONE_LIMIT = 4;
		var build = {
			joints: new Array<{ name:String, boneInverse:Matrix4 }>(),
			indices: {
				array: new Array<Float>(),
				stride: BONE_LIMIT
			},
			weights: {
				array: new Array<Float>(),
				stride: BONE_LIMIT
			},
			bindMatrix: null
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
		var i = 0;
		var j = 0;
		var l = 0;
		l = vcount.length;
		for(i in 0...l) {
			var jointCount = vcount[i];
			var vertexSkinData = new Array<{ index:Int, weight:Float }>();
			for(j in 0...jointCount) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];
				vertexSkinData.push({ index: skinIndex, weight: skinWeight });
				stride += 2;
			}
			vertexSkinData.sort(descending);
			for(j in 0...BONE_LIMIT) {
				var d = vertexSkinData[j];
				if(d != null) {
					build.indices.array.push(d.index);
					build.weights.array.push(d.weight);
				} else {
					build.indices.array.push(0);
					build.weights.array.push(0);
				}
			}
		}
		if(data.bindShapeMatrix != null) {
			build.bindMatrix = new Matrix4().fromArray(data.bindShapeMatrix).transpose();
		} else {
			build.bindMatrix = new Matrix4().identity();
		}
		l = jointSource.array.length;
		for(i in 0...l) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();
			build.joints.push({ name: name, boneInverse: boneInverse });
		}
		return build;
		function descending( a:{ index:Int, weight:Float }, b:{ index:Int, weight:Float } ):Int {
			return b.weight - a.weight;
		}
	}

	function getController( id:String ):{ id:String, skin:SkinData } {
		return getBuild(library.controllers.get(id), buildController);
	}

	function parseImage( xml:Dynamic ):Void {
		var data = {
			init_from: getElementsByTagName(xml, "init_from")[0].textContent
		};
		library.images.set(xml.getAttribute("id"), data);
	}

	function buildImage( data:ImageData ):String {
		if(Reflect.field(data, "build") != null) return Reflect.field(data, "build");
		return data.init_from;
	}

	function getImage( id:String ):String {
		var data = library.images.get(id);
		if(data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	function parseEffect( xml:Dynamic ):Void {
		var data = {
			profile: null,
			extra: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}
		library.effects.set(xml.getAttribute("id"), data);
	}

	function parseEffectProfileCOMMON( xml:Dynamic ):{ surfaces:Map<String, EffectSurfaceData>, samplers:Map<String, EffectSamplerData>, technique:EffectTechniqueData, extra:EffectExtraData } {
		var data = {
			surfaces: new Map<String, EffectSurfaceData>(),
			samplers: new Map<String, EffectSamplerData>(),
			technique: null,
			extra: null
		};
		for(i in 0...xml.childNodes.length) {
			
import three.extras.loaders.TGALoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.animation.AnimationClip;
import three.animation.QuaternionKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Object3D;
import three.core.Scene;
import three.core.Skeleton;
import three.core.SkinnedMesh;
import three.geometries.Line;
import three.geometries.LineSegments;
import three.lights.AmbientLight;
import three.lights.DirectionalLight;
import three.lights.PointLight;
import three.lights.SpotLight;
import three.materials.LineBasicMaterial;
import three.materials.MeshBasicMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshPhongMaterial;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.textures.TextureLoader;
import three.constants.Wrapping;
import three.constants.Side;
import three.constants.ColorSpace;
import three.core.Bone;
import three.core.Group;
import three.materials.Material;

class ColladaLoader extends Loader {

	public function new( manager:Loader = null ) {
		super(manager);
	}

	public function load( url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void ):Void {
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
				if(onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse( text:String, path:String ):Dynamic {
		var xml = new DOMParser().parseFromString(text, "application/xml");
		var collada = getElementsByTagName(xml, "COLLADA")[0];
		var parserError = xml.getElementsByTagName("parsererror")[0];
		if(parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText = null;
			if(errorElement != null) {
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
		var textureLoader = new TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path).setCrossOrigin(this.crossOrigin);
		var tgaLoader = null;
		if(TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}
		var tempColor = new three.math.Color();
		var animations = new Array<AnimationClip>();
		var kinematics = new Kinematics();
		var count = 0;
		var library = {
			animations: new Map<String, AnimationData>(),
			clips: new Map<String, AnimationClipData>(),
			controllers: new Map<String, ControllerData>(),
			images: new Map<String, String>(),
			effects: new Map<String, EffectData>(),
			materials: new Map<String, MaterialData>(),
			cameras: new Map<String, CameraData>(),
			lights: new Map<String, LightData>(),
			geometries: new Map<String, GeometryData>(),
			nodes: new Map<String, NodeData>(),
			visualScenes: new Map<String, VisualSceneData>(),
			kinematicsModels: new Map<String, KinematicsModelData>(),
			physicsModels: new Map<String, PhysicsModelData>(),
			kinematicsScenes: new Map<String, KinematicsSceneData>()
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
		if(asset.upAxis == "Z_UP") {
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

	function getElementsByTagName( xml:Dynamic, name:String ):Array<Dynamic> {
		var array = new Array<Dynamic>();
		var childNodes = xml.childNodes;
		for(i in 0...childNodes.length) {
			var child = childNodes[i];
			if(child.nodeName == name) {
				array.push(child);
			}
		}
		return array;
	}

	function parseStrings( text:String ):Array<String> {
		if(text.length == 0) return new Array<String>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<String>(parts.length);
		for(i in 0...parts.length) {
			array[i] = parts[i];
		}
		return array;
	}

	function parseFloats( text:String ):Array<Float> {
		if(text.length == 0) return new Array<Float>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<Float>(parts.length);
		for(i in 0...parts.length) {
			array[i] = Std.parseFloat(parts[i]);
		}
		return array;
	}

	function parseInts( text:String ):Array<Int> {
		if(text.length == 0) return new Array<Int>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<Int>(parts.length);
		for(i in 0...parts.length) {
			array[i] = Std.parseInt(parts[i]);
		}
		return array;
	}

	function parseId( text:String ):String {
		return text.substring(1);
	}

	function generateId():String {
		return "three_default_" + (count++);
	}

	function isEmpty( object:Dynamic ):Bool {
		return Reflect.field(object, "length") == 0;
	}

	function parseAsset( xml:Dynamic ):{ unit:Float, upAxis:String } {
		return {
			unit: parseAssetUnit(getElementsByTagName(xml, "unit")[0]),
			upAxis: parseAssetUpAxis(getElementsByTagName(xml, "up_axis")[0])
		};
	}

	function parseAssetUnit( xml:Dynamic ):Float {
		if(xml != null && xml.hasAttribute("meter") == true) {
			return Std.parseFloat(xml.getAttribute("meter"));
		} else {
			return 1.0;
		}
	}

	function parseAssetUpAxis( xml:Dynamic ):String {
		return xml != null ? xml.textContent : "Y_UP";
	}

	function parseLibrary( xml:Dynamic, libraryName:String, nodeName:String, parser:Dynamic->Void ):Void {
		var library = getElementsByTagName(xml, libraryName)[0];
		if(library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for(i in 0...elements.length) {
				parser(elements[i]);
			}
		}
	}

	function buildLibrary( data:Dynamic, builder:Dynamic->Dynamic ):Void {
		for(name in Reflect.fields(data)) {
			var object = Reflect.field(data, name);
			Reflect.setField(object, "build", builder(Reflect.field(data, name)));
		}
	}

	function getBuild( data:Dynamic, builder:Dynamic->Dynamic ):Dynamic {
		if(Reflect.field(data, "build") != null) return Reflect.field(data, "build");
		Reflect.setField(data, "build", builder(data));
		return Reflect.field(data, "build");
	}

	function parseAnimation( xml:Dynamic ):Void {
		var data = {
			sources: new Map<String, SourceData>(),
			samplers: new Map<String, AnimationSamplerData>(),
			channels: new Map<String, AnimationChannelData>()
		};
		var hasChildren = false;
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			var id = null;
			switch(child.nodeName) {
				case "source":
					id = child.getAttribute("id");
					data.sources.set(id, parseSource(child));
					break;
				case "sampler":
					id = child.getAttribute("id");
					data.samplers.set(id, parseAnimationSampler(child));
					break;
				case "channel":
					id = child.getAttribute("target");
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
		if(hasChildren == false) {
			library.animations.set(xml.getAttribute("id") != null ? xml.getAttribute("id") : MathUtils.generateUUID(), data);
		}
	}

	function parseAnimationSampler( xml:Dynamic ):{ inputs:Map<String, String> } {
		var data = {
			inputs: new Map<String, String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var id = parseId(child.getAttribute("source"));
					var semantic = child.getAttribute("semantic");
					data.inputs.set(semantic, id);
					break;
			}
		}
		return data;
	}

	function parseAnimationChannel( xml:Dynamic ):{ id:String, sid:String, arraySyntax:Bool, memberSyntax:Bool, sampler:String, indices:Array<Int>, member:String } {
		var data = {
			id: null,
			sid: null,
			arraySyntax: false,
			memberSyntax: false,
			sampler: null,
			indices: new Array<Int>(),
			member: null
		};
		var target = xml.getAttribute("target");
		var parts = target.split("/");
		data.id = parts.shift();
		data.sid = parts.shift();
		var arraySyntax = (data.sid.indexOf("(") != - 1);
		var memberSyntax = (data.sid.indexOf(".") != - 1);
		if(memberSyntax) {
			parts = data.sid.split(".");
			data.sid = parts.shift();
			data.member = parts.shift();
		} else if(arraySyntax) {
			var indices = data.sid.split("(");
			data.sid = indices.shift();
			for(i in 0...indices.length) {
				indices[i] = Std.parseInt(indices[i].replace(new EReg("\\)"), ""), 10);
			}
			data.indices = indices;
		}
		data.sampler = parseId(xml.getAttribute("source"));
		return data;
	}

	function buildAnimation( data:AnimationData ):Array<VectorKeyframeTrack | QuaternionKeyframeTrack> {
		var tracks = new Array<VectorKeyframeTrack | QuaternionKeyframeTrack>();
		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;
		for(target in channels.keys()) {
			var channel = channels.get(target);
			var sampler = samplers.get(channel.sampler);
			var inputId = sampler.inputs.get("INPUT");
			var outputId = sampler.inputs.get("OUTPUT");
			var inputSource = sources.get(inputId);
			var outputSource = sources.get(outputId);
			var animation = buildAnimationChannel(channel, inputSource, outputSource);
			createKeyframeTracks(animation, tracks);
		}
		return tracks;
	}

	function getAnimation( id:String ):Array<VectorKeyframeTrack | QuaternionKeyframeTrack> {
		return getBuild(library.animations.get(id), buildAnimation);
	}

	function buildAnimationChannel( channel:AnimationChannelData, inputSource:SourceData, outputSource:SourceData ):{ name:String, keyframes:Array<{ time:Float, value:Array<Float> }> } {
		var node = library.nodes.get(channel.id);
		var object3D = getNode(node.id);
		var transform = node.transforms.get(channel.sid);
		var defaultMatrix = node.matrix.clone().transpose();
		var time = 0.0;
		var stride = 0;
		var i = 0;
		var il = 0;
		var j = 0;
		var jl = 0;
		var data = new Map<Float, Array<Float>>();
		switch(transform) {
			case "matrix":
				il = inputSource.array.length;
				for(i in 0...il) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;
					if(!data.exists(time)) data.set(time, new Array<Float>());
					if(channel.arraySyntax == true) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data.get(time)[index] = value;
					} else {
						jl = outputSource.stride;
						for(j in 0...jl) {
							data.get(time)[j] = outputSource.array[stride + j];
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
		var animation = {
			name: object3D.uuid,
			keyframes: keyframes
		};
		return animation;
	}

	function prepareAnimationData( data:Map<Float, Array<Float>>, defaultMatrix:Matrix4 ):Array<{ time:Float, value:Array<Float> }> {
		var keyframes = new Array<{ time:Float, value:Array<Float> }>();
		for(time in data.keys()) {
			keyframes.push({ time: Std.parseFloat(time), value: data.get(time) });
		}
		keyframes.sort(ascending);
		for(i in 0...16) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}
		return keyframes;
		function ascending( a:{ time:Float, value:Array<Float> }, b:{ time:Float, value:Array<Float> } ):Int {
			return a.time - b.time;
		}
	}

	var position = new Vector3();
	var scale = new Vector3();
	var quaternion = new Quaternion();
	var matrix = new Matrix4();

	function createKeyframeTracks( animation:{ name:String, keyframes:Array<{ time:Float, value:Array<Float> }> }, tracks:Array<VectorKeyframeTrack | QuaternionKeyframeTrack> ):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;
		var times = new Array<Float>();
		var positionData = new Array<Float>();
		var quaternionData = new Array<Float>();
		var scaleData = new Array<Float>();
		for(i in 0...keyframes.length) {
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
		if(positionData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".position", times, positionData));
		if(quaternionData.length > 0) tracks.push(new QuaternionKeyframeTrack(name + ".quaternion", times, quaternionData));
		if(scaleData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".scale", times, scaleData));
	}

	function transformAnimationData( keyframes:Array<{ time:Float, value:Array<Float> }>, property:Int, defaultValue:Float ):Void {
		var keyframe = null;
		var empty = true;
		var i = 0;
		var l = 0;
		l = keyframes.length;
		for(i in 0...l) {
			keyframe = keyframes[i];
			if(keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}
		if(empty == true) {
			l = keyframes.length;
			for(i in 0...l) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	function createMissingKeyframes( keyframes:Array<{ time:Float, value:Array<Float> }>, property:Int ):Void {
		var prev = null;
		var next = null;
		for(i in 0...keyframes.length) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] == null) {
				prev = getPrev(keyframes, i, property);
				next = getNext(keyframes, i, property);
				if(prev == null) {
					keyframe.value[property] = next.value[property];
					continue;
				}
				if(next == null) {
					keyframe.value[property] = prev.value[property];
					continue;
				}
				interpolate(keyframe, prev, next, property);
			}
		}
	}

	function getPrev( keyframes:Array<{ time:Float, value:Array<Float> }>, i:Int, property:Int ):{ time:Float, value:Array<Float> } {
		while(i >= 0) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	function getNext( keyframes:Array<{ time:Float, value:Array<Float> }>, i:Int, property:Int ):{ time:Float, value:Array<Float> } {
		while(i < keyframes.length) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	function interpolate( key:{ time:Float, value:Array<Float> }, prev:{ time:Float, value:Array<Float> }, next:{ time:Float, value:Array<Float> }, property:Int ):Void {
		if((next.time - prev.time) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = (((key.time - prev.time) * (next.value[property] - prev.value[property])) / (next.time - prev.time)) + prev.value[property];
	}

	function parseAnimationClip( xml:Dynamic ):Void {
		var data = {
			name: xml.getAttribute("id") != null ? xml.getAttribute("id") : "default",
			start: Std.parseFloat(xml.getAttribute("start") != null ? xml.getAttribute("start") : "0"),
			end: Std.parseFloat(xml.getAttribute("end") != null ? xml.getAttribute("end") : "0"),
			animations: new Array<String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.getAttribute("url")));
					break;
			}
		}
		library.clips.set(xml.getAttribute("id"), data);
	}

	function buildAnimationClip( data:AnimationClipData ):AnimationClip {
		var tracks = new Array<VectorKeyframeTrack | QuaternionKeyframeTrack>();
		var name = data.name;
		var duration = (data.end - data.start) != -1 ? (data.end - data.start) : -1;
		var animations = data.animations;
		for(i in 0...animations.length) {
			var animationTracks = getAnimation(animations[i]);
			for(j in 0...animationTracks.length) {
				tracks.push(animationTracks[j]);
			}
		}
		return new AnimationClip(name, duration, tracks);
	}

	function getAnimationClip( id:String ):AnimationClip {
		return getBuild(library.clips.get(id), buildAnimationClip);
	}

	function parseController( xml:Dynamic ):Void {
		var data = {
			sources: new Map<String, SourceData>(),
			skin: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
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
		library.controllers.set(xml.getAttribute("id"), data);
	}

	function parseSkin( xml:Dynamic ):{ sources:Map<String, SourceData>, bindShapeMatrix:Array<Float>, joints:JointsData, vertexWeights:VertexWeightsData } {
		var data = {
			sources: new Map<String, SourceData>(),
			bindShapeMatrix: null,
			joints: null,
			vertexWeights: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.textContent);
					break;
				case "source":
					var id = child.getAttribute("id");
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

	function parseJoints( xml:Dynamic ):{ inputs:Map<String, String> } {
		var data = {
			inputs: new Map<String, String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					data.inputs.set(semantic, id);
					break;
			}
		}
		return data;
	}

	function parseVertexWeights( xml:Dynamic ):{ inputs:Map<String, { id:String, offset:Int }>, vcount:Array<Int>, v:Array<Int> } {
		var data = {
			inputs: new Map<String, { id:String, offset:Int }>(),
			vcount: null,
			v: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					var offset = Std.parseInt(child.getAttribute("offset"));
					data.inputs.set(semantic, { id: id, offset: offset });
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

	function buildController( data:ControllerData ):{ id:String, skin:SkinData } {
		var build = {
			id: data.id,
			skin: null
		};
		var geometry = library.geometries.get(build.id);
		if(data.skin != null) {
			build.skin = buildSkin(data.skin);
			geometry.sources.set("skinIndices", build.skin.indices);
			geometry.sources.set("skinWeights", build.skin.weights);
		}
		return build;
	}

	function buildSkin( data:SkinData ):{ joints:Array<{ name:String, boneInverse:Matrix4 }>, indices:{ array:Array<Float>, stride:Int }, weights:{ array:Array<Float>, stride:Int }, bindMatrix:Matrix4 } {
		var BONE_LIMIT = 4;
		var build = {
			joints: new Array<{ name:String, boneInverse:Matrix4 }>(),
			indices: {
				array: new Array<Float>(),
				stride: BONE_LIMIT
			},
			weights: {
				array: new Array<Float>(),
				stride: BONE_LIMIT
			},
			bindMatrix: null
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
		var i = 0;
		var j = 0;
		var l = 0;
		l = vcount.length;
		for(i in 0...l) {
			var jointCount = vcount[i];
			var vertexSkinData = new Array<{ index:Int, weight:Float }>();
			for(j in 0...jointCount) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];
				vertexSkinData.push({ index: skinIndex, weight: skinWeight });
				stride += 2;
			}
			vertexSkinData.sort(descending);
			for(j in 0...BONE_LIMIT) {
				var d = vertexSkinData[j];
				if(d != null) {
					build.indices.array.push(d.index);
					build.weights.array.push(d.weight);
				} else {
					build.indices.array.push(0);
					build.weights.array.push(0);
				}
			}
		}
		if(data.bindShapeMatrix != null) {
			build.bindMatrix = new Matrix4().fromArray(data.bindShapeMatrix).transpose();
		} else {
			build.bindMatrix = new Matrix4().identity();
		}
		l = jointSource.array.length;
		for(i in 0...l) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();
			build.joints.push({ name: name, boneInverse: boneInverse });
		}
		return build;
		function descending( a:{ index:Int, weight:Float }, b:{ index:Int, weight:Float } ):Int {
			return b.weight - a.weight;
		}
	}

	function getController( id:String ):{ id:String, skin:SkinData } {
		return getBuild(library.controllers.get(id), buildController);
	}

	function parseImage( xml:Dynamic ):Void {
		var data = {
			init_from: getElementsByTagName(xml, "init_from")[0].textContent
		};
		library.images.set(xml.getAttribute("id"), data);
	}

	function buildImage( data:ImageData ):String {
		if(Reflect.field(data, "build") != null) return Reflect.field(data, "build");
		return data.init_from;
	}

	function getImage( id:String ):String {
		var data = library.images.get(id);
		if(data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	function parseEffect( xml:Dynamic ):Void {
		var data = {
			profile: null,
			extra: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}
		library.effects.set(xml.getAttribute("id"), data);
	}

	function parseEffectProfileCOMMON( xml:Dynamic ):{ surfaces:Map<String, EffectSurfaceData>, samplers:Map<String, EffectSamplerData>, technique:EffectTechniqueData, extra:EffectExtraData } {
		var data = {
			surfaces: new Map<String, EffectSurfaceData>(),
			samplers: new Map<String, EffectSamplerData>(),
			technique: null,
			extra: null
		};
		for(i in 0...xml.childNodes.length) {
			
import three.extras.loaders.TGALoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.animation.AnimationClip;
import three.animation.QuaternionKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Object3D;
import three.core.Scene;
import three.core.Skeleton;
import three.core.SkinnedMesh;
import three.geometries.Line;
import three.geometries.LineSegments;
import three.lights.AmbientLight;
import three.lights.DirectionalLight;
import three.lights.PointLight;
import three.lights.SpotLight;
import three.materials.LineBasicMaterial;
import three.materials.MeshBasicMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshPhongMaterial;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.textures.TextureLoader;
import three.constants.Wrapping;
import three.constants.Side;
import three.constants.ColorSpace;
import three.core.Bone;
import three.core.Group;
import three.materials.Material;

class ColladaLoader extends Loader {

	public function new( manager:Loader = null ) {
		super(manager);
	}

	public function load( url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void ):Void {
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
				if(onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse( text:String, path:String ):Dynamic {
		var xml = new DOMParser().parseFromString(text, "application/xml");
		var collada = getElementsByTagName(xml, "COLLADA")[0];
		var parserError = xml.getElementsByTagName("parsererror")[0];
		if(parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText = null;
			if(errorElement != null) {
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
		var textureLoader = new TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path).setCrossOrigin(this.crossOrigin);
		var tgaLoader = null;
		if(TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}
		var tempColor = new three.math.Color();
		var animations = new Array<AnimationClip>();
		var kinematics = new Kinematics();
		var count = 0;
		var library = {
			animations: new Map<String, AnimationData>(),
			clips: new Map<String, AnimationClipData>(),
			controllers: new Map<String, ControllerData>(),
			images: new Map<String, String>(),
			effects: new Map<String, EffectData>(),
			materials: new Map<String, MaterialData>(),
			cameras: new Map<String, CameraData>(),
			lights: new Map<String, LightData>(),
			geometries: new Map<String, GeometryData>(),
			nodes: new Map<String, NodeData>(),
			visualScenes: new Map<String, VisualSceneData>(),
			kinematicsModels: new Map<String, KinematicsModelData>(),
			physicsModels: new Map<String, PhysicsModelData>(),
			kinematicsScenes: new Map<String, KinematicsSceneData>()
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
		if(asset.upAxis == "Z_UP") {
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

	function getElementsByTagName( xml:Dynamic, name:String ):Array<Dynamic> {
		var array = new Array<Dynamic>();
		var childNodes = xml.childNodes;
		for(i in 0...childNodes.length) {
			var child = childNodes[i];
			if(child.nodeName == name) {
				array.push(child);
			}
		}
		return array;
	}

	function parseStrings( text:String ):Array<String> {
		if(text.length == 0) return new Array<String>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<String>(parts.length);
		for(i in 0...parts.length) {
			array[i] = parts[i];
		}
		return array;
	}

	function parseFloats( text:String ):Array<Float> {
		if(text.length == 0) return new Array<Float>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<Float>(parts.length);
		for(i in 0...parts.length) {
			array[i] = Std.parseFloat(parts[i]);
		}
		return array;
	}

	function parseInts( text:String ):Array<Int> {
		if(text.length == 0) return new Array<Int>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<Int>(parts.length);
		for(i in 0...parts.length) {
			array[i] = Std.parseInt(parts[i]);
		}
		return array;
	}

	function parseId( text:String ):String {
		return text.substring(1);
	}

	function generateId():String {
		return "three_default_" + (count++);
	}

	function isEmpty( object:Dynamic ):Bool {
		return Reflect.field(object, "length") == 0;
	}

	function parseAsset( xml:Dynamic ):{ unit:Float, upAxis:String } {
		return {
			unit: parseAssetUnit(getElementsByTagName(xml, "unit")[0]),
			upAxis: parseAssetUpAxis(getElementsByTagName(xml, "up_axis")[0])
		};
	}

	function parseAssetUnit( xml:Dynamic ):Float {
		if(xml != null && xml.hasAttribute("meter") == true) {
			return Std.parseFloat(xml.getAttribute("meter"));
		} else {
			return 1.0;
		}
	}

	function parseAssetUpAxis( xml:Dynamic ):String {
		return xml != null ? xml.textContent : "Y_UP";
	}

	function parseLibrary( xml:Dynamic, libraryName:String, nodeName:String, parser:Dynamic->Void ):Void {
		var library = getElementsByTagName(xml, libraryName)[0];
		if(library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for(i in 0...elements.length) {
				parser(elements[i]);
			}
		}
	}

	function buildLibrary( data:Dynamic, builder:Dynamic->Dynamic ):Void {
		for(name in Reflect.fields(data)) {
			var object = Reflect.field(data, name);
			Reflect.setField(object, "build", builder(Reflect.field(data, name)));
		}
	}

	function getBuild( data:Dynamic, builder:Dynamic->Dynamic ):Dynamic {
		if(Reflect.field(data, "build") != null) return Reflect.field(data, "build");
		Reflect.setField(data, "build", builder(data));
		return Reflect.field(data, "build");
	}

	function parseAnimation( xml:Dynamic ):Void {
		var data = {
			sources: new Map<String, SourceData>(),
			samplers: new Map<String, AnimationSamplerData>(),
			channels: new Map<String, AnimationChannelData>()
		};
		var hasChildren = false;
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			var id = null;
			switch(child.nodeName) {
				case "source":
					id = child.getAttribute("id");
					data.sources.set(id, parseSource(child));
					break;
				case "sampler":
					id = child.getAttribute("id");
					data.samplers.set(id, parseAnimationSampler(child));
					break;
				case "channel":
					id = child.getAttribute("target");
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
		if(hasChildren == false) {
			library.animations.set(xml.getAttribute("id") != null ? xml.getAttribute("id") : MathUtils.generateUUID(), data);
		}
	}

	function parseAnimationSampler( xml:Dynamic ):{ inputs:Map<String, String> } {
		var data = {
			inputs: new Map<String, String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var id = parseId(child.getAttribute("source"));
					var semantic = child.getAttribute("semantic");
					data.inputs.set(semantic, id);
					break;
			}
		}
		return data;
	}

	function parseAnimationChannel( xml:Dynamic ):{ id:String, sid:String, arraySyntax:Bool, memberSyntax:Bool, sampler:String, indices:Array<Int>, member:String } {
		var data = {
			id: null,
			sid: null,
			arraySyntax: false,
			memberSyntax: false,
			sampler: null,
			indices: new Array<Int>(),
			member: null
		};
		var target = xml.getAttribute("target");
		var parts = target.split("/");
		data.id = parts.shift();
		data.sid = parts.shift();
		var arraySyntax = (data.sid.indexOf("(") != - 1);
		var memberSyntax = (data.sid.indexOf(".") != - 1);
		if(memberSyntax) {
			parts = data.sid.split(".");
			data.sid = parts.shift();
			data.member = parts.shift();
		} else if(arraySyntax) {
			var indices = data.sid.split("(");
			data.sid = indices.shift();
			for(i in 0...indices.length) {
				indices[i] = Std.parseInt(indices[i].replace(new EReg("\\)"), ""), 10);
			}
			data.indices = indices;
		}
		data.sampler = parseId(xml.getAttribute("source"));
		return data;
	}

	function buildAnimation( data:AnimationData ):Array<VectorKeyframeTrack | QuaternionKeyframeTrack> {
		var tracks = new Array<VectorKeyframeTrack | QuaternionKeyframeTrack>();
		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;
		for(target in channels.keys()) {
			var channel = channels.get(target);
			var sampler = samplers.get(channel.sampler);
			var inputId = sampler.inputs.get("INPUT");
			var outputId = sampler.inputs.get("OUTPUT");
			var inputSource = sources.get(inputId);
			var outputSource = sources.get(outputId);
			var animation = buildAnimationChannel(channel, inputSource, outputSource);
			createKeyframeTracks(animation, tracks);
		}
		return tracks;
	}

	function getAnimation( id:String ):Array<VectorKeyframeTrack | QuaternionKeyframeTrack> {
		return getBuild(library.animations.get(id), buildAnimation);
	}

	function buildAnimationChannel( channel:AnimationChannelData, inputSource:SourceData, outputSource:SourceData ):{ name:String, keyframes:Array<{ time:Float, value:Array<Float> }> } {
		var node = library.nodes.get(channel.id);
		var object3D = getNode(node.id);
		var transform = node.transforms.get(channel.sid);
		var defaultMatrix = node.matrix.clone().transpose();
		var time = 0.0;
		var stride = 0;
		var i = 0;
		var il = 0;
		var j = 0;
		var jl = 0;
		var data = new Map<Float, Array<Float>>();
		switch(transform) {
			case "matrix":
				il = inputSource.array.length;
				for(i in 0...il) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;
					if(!data.exists(time)) data.set(time, new Array<Float>());
					if(channel.arraySyntax == true) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data.get(time)[index] = value;
					} else {
						jl = outputSource.stride;
						for(j in 0...jl) {
							data.get(time)[j] = outputSource.array[stride + j];
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
		var animation = {
			name: object3D.uuid,
			keyframes: keyframes
		};
		return animation;
	}

	function prepareAnimationData( data:Map<Float, Array<Float>>, defaultMatrix:Matrix4 ):Array<{ time:Float, value:Array<Float> }> {
		var keyframes = new Array<{ time:Float, value:Array<Float> }>();
		for(time in data.keys()) {
			keyframes.push({ time: Std.parseFloat(time), value: data.get(time) });
		}
		keyframes.sort(ascending);
		for(i in 0...16) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}
		return keyframes;
		function ascending( a:{ time:Float, value:Array<Float> }, b:{ time:Float, value:Array<Float> } ):Int {
			return a.time - b.time;
		}
	}

	var position = new Vector3();
	var scale = new Vector3();
	var quaternion = new Quaternion();
	var matrix = new Matrix4();

	function createKeyframeTracks( animation:{ name:String, keyframes:Array<{ time:Float, value:Array<Float> }> }, tracks:Array<VectorKeyframeTrack | QuaternionKeyframeTrack> ):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;
		var times = new Array<Float>();
		var positionData = new Array<Float>();
		var quaternionData = new Array<Float>();
		var scaleData = new Array<Float>();
		for(i in 0...keyframes.length) {
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
		if(positionData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".position", times, positionData));
		if(quaternionData.length > 0) tracks.push(new QuaternionKeyframeTrack(name + ".quaternion", times, quaternionData));
		if(scaleData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".scale", times, scaleData));
	}

	function transformAnimationData( keyframes:Array<{ time:Float, value:Array<Float> }>, property:Int, defaultValue:Float ):Void {
		var keyframe = null;
		var empty = true;
		var i = 0;
		var l = 0;
		l = keyframes.length;
		for(i in 0...l) {
			keyframe = keyframes[i];
			if(keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}
		if(empty == true) {
			l = keyframes.length;
			for(i in 0...l) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	function createMissingKeyframes( keyframes:Array<{ time:Float, value:Array<Float> }>, property:Int ):Void {
		var prev = null;
		var next = null;
		for(i in 0...keyframes.length) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] == null) {
				prev = getPrev(keyframes, i, property);
				next = getNext(keyframes, i, property);
				if(prev == null) {
					keyframe.value[property] = next.value[property];
					continue;
				}
				if(next == null) {
					keyframe.value[property] = prev.value[property];
					continue;
				}
				interpolate(keyframe, prev, next, property);
			}
		}
	}

	function getPrev( keyframes:Array<{ time:Float, value:Array<Float> }>, i:Int, property:Int ):{ time:Float, value:Array<Float> } {
		while(i >= 0) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	function getNext( keyframes:Array<{ time:Float, value:Array<Float> }>, i:Int, property:Int ):{ time:Float, value:Array<Float> } {
		while(i < keyframes.length) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	function interpolate( key:{ time:Float, value:Array<Float> }, prev:{ time:Float, value:Array<Float> }, next:{ time:Float, value:Array<Float> }, property:Int ):Void {
		if((next.time - prev.time) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = (((key.time - prev.time) * (next.value[property] - prev.value[property])) / (next.time - prev.time)) + prev.value[property];
	}

	function parseAnimationClip( xml:Dynamic ):Void {
		var data = {
			name: xml.getAttribute("id") != null ? xml.getAttribute("id") : "default",
			start: Std.parseFloat(xml.getAttribute("start") != null ? xml.getAttribute("start") : "0"),
			end: Std.parseFloat(xml.getAttribute("end") != null ? xml.getAttribute("end") : "0"),
			animations: new Array<String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.getAttribute("url")));
					break;
			}
		}
		library.clips.set(xml.getAttribute("id"), data);
	}

	function buildAnimationClip( data:AnimationClipData ):AnimationClip {
		var tracks = new Array<VectorKeyframeTrack | QuaternionKeyframeTrack>();
		var name = data.name;
		var duration = (data.end - data.start) != -1 ? (data.end - data.start) : -1;
		var animations = data.animations;
		for(i in 0...animations.length) {
			var animationTracks = getAnimation(animations[i]);
			for(j in 0...animationTracks.length) {
				tracks.push(animationTracks[j]);
			}
		}
		return new AnimationClip(name, duration, tracks);
	}

	function getAnimationClip( id:String ):AnimationClip {
		return getBuild(library.clips.get(id), buildAnimationClip);
	}

	function parseController( xml:Dynamic ):Void {
		var data = {
			sources: new Map<String, SourceData>(),
			skin: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
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
		library.controllers.set(xml.getAttribute("id"), data);
	}

	function parseSkin( xml:Dynamic ):{ sources:Map<String, SourceData>, bindShapeMatrix:Array<Float>, joints:JointsData, vertexWeights:VertexWeightsData } {
		var data = {
			sources: new Map<String, SourceData>(),
			bindShapeMatrix: null,
			joints: null,
			vertexWeights: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.textContent);
					break;
				case "source":
					var id = child.getAttribute("id");
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

	function parseJoints( xml:Dynamic ):{ inputs:Map<String, String> } {
		var data = {
			inputs: new Map<String, String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					data.inputs.set(semantic, id);
					break;
			}
		}
		return data;
	}

	function parseVertexWeights( xml:Dynamic ):{ inputs:Map<String, { id:String, offset:Int }>, vcount:Array<Int>, v:Array<Int> } {
		var data = {
			inputs: new Map<String, { id:String, offset:Int }>(),
			vcount: null,
			v: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					var offset = Std.parseInt(child.getAttribute("offset"));
					data.inputs.set(semantic, { id: id, offset: offset });
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

	function buildController( data:ControllerData ):{ id:String, skin:SkinData } {
		var build = {
			id: data.id,
			skin: null
		};
		var geometry = library.geometries.get(build.id);
		if(data.skin != null) {
			build.skin = buildSkin(data.skin);
			geometry.sources.set("skinIndices", build.skin.indices);
			geometry.sources.set("skinWeights", build.skin.weights);
		}
		return build;
	}

	function buildSkin( data:SkinData ):{ joints:Array<{ name:String, boneInverse:Matrix4 }>, indices:{ array:Array<Float>, stride:Int }, weights:{ array:Array<Float>, stride:Int }, bindMatrix:Matrix4 } {
		var BONE_LIMIT = 4;
		var build = {
			joints: new Array<{ name:String, boneInverse:Matrix4 }>(),
			indices: {
				array: new Array<Float>(),
				stride: BONE_LIMIT
			},
			weights: {
				array: new Array<Float>(),
				stride: BONE_LIMIT
			},
			bindMatrix: null
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
		var i = 0;
		var j = 0;
		var l = 0;
		l = vcount.length;
		for(i in 0...l) {
			var jointCount = vcount[i];
			var vertexSkinData = new Array<{ index:Int, weight:Float }>();
			for(j in 0...jointCount) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];
				vertexSkinData.push({ index: skinIndex, weight: skinWeight });
				stride += 2;
			}
			vertexSkinData.sort(descending);
			for(j in 0...BONE_LIMIT) {
				var d = vertexSkinData[j];
				if(d != null) {
					build.indices.array.push(d.index);
					build.weights.array.push(d.weight);
				} else {
					build.indices.array.push(0);
					build.weights.array.push(0);
				}
			}
		}
		if(data.bindShapeMatrix != null) {
			build.bindMatrix = new Matrix4().fromArray(data.bindShapeMatrix).transpose();
		} else {
			build.bindMatrix = new Matrix4().identity();
		}
		l = jointSource.array.length;
		for(i in 0...l) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();
			build.joints.push({ name: name, boneInverse: boneInverse });
		}
		return build;
		function descending( a:{ index:Int, weight:Float }, b:{ index:Int, weight:Float } ):Int {
			return b.weight - a.weight;
		}
	}

	function getController( id:String ):{ id:String, skin:SkinData } {
		return getBuild(library.controllers.get(id), buildController);
	}

	function parseImage( xml:Dynamic ):Void {
		var data = {
			init_from: getElementsByTagName(xml, "init_from")[0].textContent
		};
		library.images.set(xml.getAttribute("id"), data);
	}

	function buildImage( data:ImageData ):String {
		if(Reflect.field(data, "build") != null) return Reflect.field(data, "build");
		return data.init_from;
	}

	function getImage( id:String ):String {
		var data = library.images.get(id);
		if(data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	function parseEffect( xml:Dynamic ):Void {
		var data = {
			profile: null,
			extra: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}
		library.effects.set(xml.getAttribute("id"), data);
	}

	function parseEffectProfileCOMMON( xml:Dynamic ):{ surfaces:Map<String, EffectSurfaceData>, samplers:Map<String, EffectSamplerData>, technique:EffectTechniqueData, extra:EffectExtraData } {
		var data = {
			surfaces: new Map<String, EffectSurfaceData>(),
			samplers: new Map<String, EffectSamplerData>(),
			technique: null,
			extra: null
		};
		for(i in 0...xml.childNodes.length) {
			
import three.extras.loaders.TGALoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.animation.AnimationClip;
import three.animation.QuaternionKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.Object3D;
import three.core.Scene;
import three.core.Skeleton;
import three.core.SkinnedMesh;
import three.geometries.Line;
import three.geometries.LineSegments;
import three.lights.AmbientLight;
import three.lights.DirectionalLight;
import three.lights.PointLight;
import three.lights.SpotLight;
import three.materials.LineBasicMaterial;
import three.materials.MeshBasicMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshPhongMaterial;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.textures.TextureLoader;
import three.constants.Wrapping;
import three.constants.Side;
import three.constants.ColorSpace;
import three.core.Bone;
import three.core.Group;
import three.materials.Material;

class ColladaLoader extends Loader {

	public function new( manager:Loader = null ) {
		super(manager);
	}

	public function load( url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void ):Void {
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
				if(onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse( text:String, path:String ):Dynamic {
		var xml = new DOMParser().parseFromString(text, "application/xml");
		var collada = getElementsByTagName(xml, "COLLADA")[0];
		var parserError = xml.getElementsByTagName("parsererror")[0];
		if(parserError != null) {
			var errorElement = getElementsByTagName(parserError, "div")[0];
			var errorText = null;
			if(errorElement != null) {
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
		var textureLoader = new TextureLoader(this.manager);
		textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path).setCrossOrigin(this.crossOrigin);
		var tgaLoader = null;
		if(TGALoader != null) {
			tgaLoader = new TGALoader(this.manager);
			tgaLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
		}
		var tempColor = new three.math.Color();
		var animations = new Array<AnimationClip>();
		var kinematics = new Kinematics();
		var count = 0;
		var library = {
			animations: new Map<String, AnimationData>(),
			clips: new Map<String, AnimationClipData>(),
			controllers: new Map<String, ControllerData>(),
			images: new Map<String, String>(),
			effects: new Map<String, EffectData>(),
			materials: new Map<String, MaterialData>(),
			cameras: new Map<String, CameraData>(),
			lights: new Map<String, LightData>(),
			geometries: new Map<String, GeometryData>(),
			nodes: new Map<String, NodeData>(),
			visualScenes: new Map<String, VisualSceneData>(),
			kinematicsModels: new Map<String, KinematicsModelData>(),
			physicsModels: new Map<String, PhysicsModelData>(),
			kinematicsScenes: new Map<String, KinematicsSceneData>()
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
		if(asset.upAxis == "Z_UP") {
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

	function getElementsByTagName( xml:Dynamic, name:String ):Array<Dynamic> {
		var array = new Array<Dynamic>();
		var childNodes = xml.childNodes;
		for(i in 0...childNodes.length) {
			var child = childNodes[i];
			if(child.nodeName == name) {
				array.push(child);
			}
		}
		return array;
	}

	function parseStrings( text:String ):Array<String> {
		if(text.length == 0) return new Array<String>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<String>(parts.length);
		for(i in 0...parts.length) {
			array[i] = parts[i];
		}
		return array;
	}

	function parseFloats( text:String ):Array<Float> {
		if(text.length == 0) return new Array<Float>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<Float>(parts.length);
		for(i in 0...parts.length) {
			array[i] = Std.parseFloat(parts[i]);
		}
		return array;
	}

	function parseInts( text:String ):Array<Int> {
		if(text.length == 0) return new Array<Int>();
		var parts = text.trim().split(new EReg("\\s+"));
		var array = new Array<Int>(parts.length);
		for(i in 0...parts.length) {
			array[i] = Std.parseInt(parts[i]);
		}
		return array;
	}

	function parseId( text:String ):String {
		return text.substring(1);
	}

	function generateId():String {
		return "three_default_" + (count++);
	}

	function isEmpty( object:Dynamic ):Bool {
		return Reflect.field(object, "length") == 0;
	}

	function parseAsset( xml:Dynamic ):{ unit:Float, upAxis:String } {
		return {
			unit: parseAssetUnit(getElementsByTagName(xml, "unit")[0]),
			upAxis: parseAssetUpAxis(getElementsByTagName(xml, "up_axis")[0])
		};
	}

	function parseAssetUnit( xml:Dynamic ):Float {
		if(xml != null && xml.hasAttribute("meter") == true) {
			return Std.parseFloat(xml.getAttribute("meter"));
		} else {
			return 1.0;
		}
	}

	function parseAssetUpAxis( xml:Dynamic ):String {
		return xml != null ? xml.textContent : "Y_UP";
	}

	function parseLibrary( xml:Dynamic, libraryName:String, nodeName:String, parser:Dynamic->Void ):Void {
		var library = getElementsByTagName(xml, libraryName)[0];
		if(library != null) {
			var elements = getElementsByTagName(library, nodeName);
			for(i in 0...elements.length) {
				parser(elements[i]);
			}
		}
	}

	function buildLibrary( data:Dynamic, builder:Dynamic->Dynamic ):Void {
		for(name in Reflect.fields(data)) {
			var object = Reflect.field(data, name);
			Reflect.setField(object, "build", builder(Reflect.field(data, name)));
		}
	}

	function getBuild( data:Dynamic, builder:Dynamic->Dynamic ):Dynamic {
		if(Reflect.field(data, "build") != null) return Reflect.field(data, "build");
		Reflect.setField(data, "build", builder(data));
		return Reflect.field(data, "build");
	}

	function parseAnimation( xml:Dynamic ):Void {
		var data = {
			sources: new Map<String, SourceData>(),
			samplers: new Map<String, AnimationSamplerData>(),
			channels: new Map<String, AnimationChannelData>()
		};
		var hasChildren = false;
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			var id = null;
			switch(child.nodeName) {
				case "source":
					id = child.getAttribute("id");
					data.sources.set(id, parseSource(child));
					break;
				case "sampler":
					id = child.getAttribute("id");
					data.samplers.set(id, parseAnimationSampler(child));
					break;
				case "channel":
					id = child.getAttribute("target");
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
		if(hasChildren == false) {
			library.animations.set(xml.getAttribute("id") != null ? xml.getAttribute("id") : MathUtils.generateUUID(), data);
		}
	}

	function parseAnimationSampler( xml:Dynamic ):{ inputs:Map<String, String> } {
		var data = {
			inputs: new Map<String, String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var id = parseId(child.getAttribute("source"));
					var semantic = child.getAttribute("semantic");
					data.inputs.set(semantic, id);
					break;
			}
		}
		return data;
	}

	function parseAnimationChannel( xml:Dynamic ):{ id:String, sid:String, arraySyntax:Bool, memberSyntax:Bool, sampler:String, indices:Array<Int>, member:String } {
		var data = {
			id: null,
			sid: null,
			arraySyntax: false,
			memberSyntax: false,
			sampler: null,
			indices: new Array<Int>(),
			member: null
		};
		var target = xml.getAttribute("target");
		var parts = target.split("/");
		data.id = parts.shift();
		data.sid = parts.shift();
		var arraySyntax = (data.sid.indexOf("(") != - 1);
		var memberSyntax = (data.sid.indexOf(".") != - 1);
		if(memberSyntax) {
			parts = data.sid.split(".");
			data.sid = parts.shift();
			data.member = parts.shift();
		} else if(arraySyntax) {
			var indices = data.sid.split("(");
			data.sid = indices.shift();
			for(i in 0...indices.length) {
				indices[i] = Std.parseInt(indices[i].replace(new EReg("\\)"), ""), 10);
			}
			data.indices = indices;
		}
		data.sampler = parseId(xml.getAttribute("source"));
		return data;
	}

	function buildAnimation( data:AnimationData ):Array<VectorKeyframeTrack | QuaternionKeyframeTrack> {
		var tracks = new Array<VectorKeyframeTrack | QuaternionKeyframeTrack>();
		var channels = data.channels;
		var samplers = data.samplers;
		var sources = data.sources;
		for(target in channels.keys()) {
			var channel = channels.get(target);
			var sampler = samplers.get(channel.sampler);
			var inputId = sampler.inputs.get("INPUT");
			var outputId = sampler.inputs.get("OUTPUT");
			var inputSource = sources.get(inputId);
			var outputSource = sources.get(outputId);
			var animation = buildAnimationChannel(channel, inputSource, outputSource);
			createKeyframeTracks(animation, tracks);
		}
		return tracks;
	}

	function getAnimation( id:String ):Array<VectorKeyframeTrack | QuaternionKeyframeTrack> {
		return getBuild(library.animations.get(id), buildAnimation);
	}

	function buildAnimationChannel( channel:AnimationChannelData, inputSource:SourceData, outputSource:SourceData ):{ name:String, keyframes:Array<{ time:Float, value:Array<Float> }> } {
		var node = library.nodes.get(channel.id);
		var object3D = getNode(node.id);
		var transform = node.transforms.get(channel.sid);
		var defaultMatrix = node.matrix.clone().transpose();
		var time = 0.0;
		var stride = 0;
		var i = 0;
		var il = 0;
		var j = 0;
		var jl = 0;
		var data = new Map<Float, Array<Float>>();
		switch(transform) {
			case "matrix":
				il = inputSource.array.length;
				for(i in 0...il) {
					time = inputSource.array[i];
					stride = i * outputSource.stride;
					if(!data.exists(time)) data.set(time, new Array<Float>());
					if(channel.arraySyntax == true) {
						var value = outputSource.array[stride];
						var index = channel.indices[0] + 4 * channel.indices[1];
						data.get(time)[index] = value;
					} else {
						jl = outputSource.stride;
						for(j in 0...jl) {
							data.get(time)[j] = outputSource.array[stride + j];
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
		var animation = {
			name: object3D.uuid,
			keyframes: keyframes
		};
		return animation;
	}

	function prepareAnimationData( data:Map<Float, Array<Float>>, defaultMatrix:Matrix4 ):Array<{ time:Float, value:Array<Float> }> {
		var keyframes = new Array<{ time:Float, value:Array<Float> }>();
		for(time in data.keys()) {
			keyframes.push({ time: Std.parseFloat(time), value: data.get(time) });
		}
		keyframes.sort(ascending);
		for(i in 0...16) {
			transformAnimationData(keyframes, i, defaultMatrix.elements[i]);
		}
		return keyframes;
		function ascending( a:{ time:Float, value:Array<Float> }, b:{ time:Float, value:Array<Float> } ):Int {
			return a.time - b.time;
		}
	}

	var position = new Vector3();
	var scale = new Vector3();
	var quaternion = new Quaternion();
	var matrix = new Matrix4();

	function createKeyframeTracks( animation:{ name:String, keyframes:Array<{ time:Float, value:Array<Float> }> }, tracks:Array<VectorKeyframeTrack | QuaternionKeyframeTrack> ):Void {
		var keyframes = animation.keyframes;
		var name = animation.name;
		var times = new Array<Float>();
		var positionData = new Array<Float>();
		var quaternionData = new Array<Float>();
		var scaleData = new Array<Float>();
		for(i in 0...keyframes.length) {
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
		if(positionData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".position", times, positionData));
		if(quaternionData.length > 0) tracks.push(new QuaternionKeyframeTrack(name + ".quaternion", times, quaternionData));
		if(scaleData.length > 0) tracks.push(new VectorKeyframeTrack(name + ".scale", times, scaleData));
	}

	function transformAnimationData( keyframes:Array<{ time:Float, value:Array<Float> }>, property:Int, defaultValue:Float ):Void {
		var keyframe = null;
		var empty = true;
		var i = 0;
		var l = 0;
		l = keyframes.length;
		for(i in 0...l) {
			keyframe = keyframes[i];
			if(keyframe.value[property] == null) {
				keyframe.value[property] = null;
			} else {
				empty = false;
			}
		}
		if(empty == true) {
			l = keyframes.length;
			for(i in 0...l) {
				keyframe = keyframes[i];
				keyframe.value[property] = defaultValue;
			}
		} else {
			createMissingKeyframes(keyframes, property);
		}
	}

	function createMissingKeyframes( keyframes:Array<{ time:Float, value:Array<Float> }>, property:Int ):Void {
		var prev = null;
		var next = null;
		for(i in 0...keyframes.length) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] == null) {
				prev = getPrev(keyframes, i, property);
				next = getNext(keyframes, i, property);
				if(prev == null) {
					keyframe.value[property] = next.value[property];
					continue;
				}
				if(next == null) {
					keyframe.value[property] = prev.value[property];
					continue;
				}
				interpolate(keyframe, prev, next, property);
			}
		}
	}

	function getPrev( keyframes:Array<{ time:Float, value:Array<Float> }>, i:Int, property:Int ):{ time:Float, value:Array<Float> } {
		while(i >= 0) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] != null) return keyframe;
			i--;
		}
		return null;
	}

	function getNext( keyframes:Array<{ time:Float, value:Array<Float> }>, i:Int, property:Int ):{ time:Float, value:Array<Float> } {
		while(i < keyframes.length) {
			var keyframe = keyframes[i];
			if(keyframe.value[property] != null) return keyframe;
			i++;
		}
		return null;
	}

	function interpolate( key:{ time:Float, value:Array<Float> }, prev:{ time:Float, value:Array<Float> }, next:{ time:Float, value:Array<Float> }, property:Int ):Void {
		if((next.time - prev.time) == 0) {
			key.value[property] = prev.value[property];
			return;
		}
		key.value[property] = (((key.time - prev.time) * (next.value[property] - prev.value[property])) / (next.time - prev.time)) + prev.value[property];
	}

	function parseAnimationClip( xml:Dynamic ):Void {
		var data = {
			name: xml.getAttribute("id") != null ? xml.getAttribute("id") : "default",
			start: Std.parseFloat(xml.getAttribute("start") != null ? xml.getAttribute("start") : "0"),
			end: Std.parseFloat(xml.getAttribute("end") != null ? xml.getAttribute("end") : "0"),
			animations: new Array<String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "instance_animation":
					data.animations.push(parseId(child.getAttribute("url")));
					break;
			}
		}
		library.clips.set(xml.getAttribute("id"), data);
	}

	function buildAnimationClip( data:AnimationClipData ):AnimationClip {
		var tracks = new Array<VectorKeyframeTrack | QuaternionKeyframeTrack>();
		var name = data.name;
		var duration = (data.end - data.start) != -1 ? (data.end - data.start) : -1;
		var animations = data.animations;
		for(i in 0...animations.length) {
			var animationTracks = getAnimation(animations[i]);
			for(j in 0...animationTracks.length) {
				tracks.push(animationTracks[j]);
			}
		}
		return new AnimationClip(name, duration, tracks);
	}

	function getAnimationClip( id:String ):AnimationClip {
		return getBuild(library.clips.get(id), buildAnimationClip);
	}

	function parseController( xml:Dynamic ):Void {
		var data = {
			sources: new Map<String, SourceData>(),
			skin: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
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
		library.controllers.set(xml.getAttribute("id"), data);
	}

	function parseSkin( xml:Dynamic ):{ sources:Map<String, SourceData>, bindShapeMatrix:Array<Float>, joints:JointsData, vertexWeights:VertexWeightsData } {
		var data = {
			sources: new Map<String, SourceData>(),
			bindShapeMatrix: null,
			joints: null,
			vertexWeights: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "bind_shape_matrix":
					data.bindShapeMatrix = parseFloats(child.textContent);
					break;
				case "source":
					var id = child.getAttribute("id");
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

	function parseJoints( xml:Dynamic ):{ inputs:Map<String, String> } {
		var data = {
			inputs: new Map<String, String>()
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					data.inputs.set(semantic, id);
					break;
			}
		}
		return data;
	}

	function parseVertexWeights( xml:Dynamic ):{ inputs:Map<String, { id:String, offset:Int }>, vcount:Array<Int>, v:Array<Int> } {
		var data = {
			inputs: new Map<String, { id:String, offset:Int }>(),
			vcount: null,
			v: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "input":
					var semantic = child.getAttribute("semantic");
					var id = parseId(child.getAttribute("source"));
					var offset = Std.parseInt(child.getAttribute("offset"));
					data.inputs.set(semantic, { id: id, offset: offset });
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

	function buildController( data:ControllerData ):{ id:String, skin:SkinData } {
		var build = {
			id: data.id,
			skin: null
		};
		var geometry = library.geometries.get(build.id);
		if(data.skin != null) {
			build.skin = buildSkin(data.skin);
			geometry.sources.set("skinIndices", build.skin.indices);
			geometry.sources.set("skinWeights", build.skin.weights);
		}
		return build;
	}

	function buildSkin( data:SkinData ):{ joints:Array<{ name:String, boneInverse:Matrix4 }>, indices:{ array:Array<Float>, stride:Int }, weights:{ array:Array<Float>, stride:Int }, bindMatrix:Matrix4 } {
		var BONE_LIMIT = 4;
		var build = {
			joints: new Array<{ name:String, boneInverse:Matrix4 }>(),
			indices: {
				array: new Array<Float>(),
				stride: BONE_LIMIT
			},
			weights: {
				array: new Array<Float>(),
				stride: BONE_LIMIT
			},
			bindMatrix: null
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
		var i = 0;
		var j = 0;
		var l = 0;
		l = vcount.length;
		for(i in 0...l) {
			var jointCount = vcount[i];
			var vertexSkinData = new Array<{ index:Int, weight:Float }>();
			for(j in 0...jointCount) {
				var skinIndex = v[stride + jointOffset];
				var weightId = v[stride + weightOffset];
				var skinWeight = weights[weightId];
				vertexSkinData.push({ index: skinIndex, weight: skinWeight });
				stride += 2;
			}
			vertexSkinData.sort(descending);
			for(j in 0...BONE_LIMIT) {
				var d = vertexSkinData[j];
				if(d != null) {
					build.indices.array.push(d.index);
					build.weights.array.push(d.weight);
				} else {
					build.indices.array.push(0);
					build.weights.array.push(0);
				}
			}
		}
		if(data.bindShapeMatrix != null) {
			build.bindMatrix = new Matrix4().fromArray(data.bindShapeMatrix).transpose();
		} else {
			build.bindMatrix = new Matrix4().identity();
		}
		l = jointSource.array.length;
		for(i in 0...l) {
			var name = jointSource.array[i];
			var boneInverse = new Matrix4().fromArray(inverseSource.array, i * inverseSource.stride).transpose();
			build.joints.push({ name: name, boneInverse: boneInverse });
		}
		return build;
		function descending( a:{ index:Int, weight:Float }, b:{ index:Int, weight:Float } ):Int {
			return b.weight - a.weight;
		}
	}

	function getController( id:String ):{ id:String, skin:SkinData } {
		return getBuild(library.controllers.get(id), buildController);
	}

	function parseImage( xml:Dynamic ):Void {
		var data = {
			init_from: getElementsByTagName(xml, "init_from")[0].textContent
		};
		library.images.set(xml.getAttribute("id"), data);
	}

	function buildImage( data:ImageData ):String {
		if(Reflect.field(data, "build") != null) return Reflect.field(data, "build");
		return data.init_from;
	}

	function getImage( id:String ):String {
		var data = library.images.get(id);
		if(data != null) {
			return getBuild(data, buildImage);
		}
		console.warn("THREE.ColladaLoader: Couldn't find image with ID:", id);
		return null;
	}

	function parseEffect( xml:Dynamic ):Void {
		var data = {
			profile: null,
			extra: null
		};
		for(i in 0...xml.childNodes.length) {
			var child = xml.childNodes[i];
			if(child.nodeType != 1) continue;
			switch(child.nodeName) {
				case "profile_COMMON":
					data.profile = parseEffectProfileCOMMON(child);
					break;
			}
		}
		library.effects.set(xml.getAttribute("id"), data);
	}

	function parseEffectProfileCOMMON( xml:Dynamic ):{ surfaces:Map<String, EffectSurfaceData>, samplers:Map<String, EffectSamplerData>, technique:EffectTechniqueData, extra:EffectExtraData } {
		var data = {
			surfaces: new Map<String, EffectSurfaceData>(),
			samplers: new Map<String, EffectSamplerData>(),
			technique: null,
			extra: null
		};
		for(i in 0...xml.childNodes.length) {