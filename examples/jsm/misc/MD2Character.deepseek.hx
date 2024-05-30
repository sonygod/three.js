import three.AnimationMixer;
import three.Box3;
import three.Mesh;
import three.MeshLambertMaterial;
import three.Object3D;
import three.TextureLoader;
import three.UVMapping;
import three.SRGBColorSpace;
import three.loaders.MD2Loader;

class MD2Character {

	var scale:Float = 1;
	var animationFPS:Int = 6;
	var root:Object3D;
	var meshBody:Mesh;
	var meshWeapon:Mesh;
	var skinsBody:Array<Texture>;
	var skinsWeapon:Array<Texture>;
	var weapons:Array<Mesh>;
	var activeAnimation:String;
	var mixer:AnimationMixer;
	var onLoadComplete:Void->Void;
	var loadCounter:Int;

	public function new() {
		root = new Object3D();
		meshBody = null;
		meshWeapon = null;
		skinsBody = [];
		skinsWeapon = [];
		weapons = [];
		activeAnimation = null;
		mixer = null;
		onLoadComplete = function () {};
		loadCounter = 0;
	}

	public function loadParts(config:Dynamic) {
		var scope = this;

		function createPart(geometry:Geometry, skinMap:Texture):Mesh {
			var materialWireframe = new MeshLambertMaterial({color: 0xffaa00, wireframe: true});
			var materialTexture = new MeshLambertMaterial({color: 0xffffff, wireframe: false, map: skinMap});

			var mesh = new Mesh(geometry, materialTexture);
			mesh.rotation.y = - Math.PI / 2;

			mesh.castShadow = true;
			mesh.receiveShadow = true;

			mesh.materialTexture = materialTexture;
			mesh.materialWireframe = materialWireframe;

			return mesh;
		}

		function loadTextures(baseUrl:String, textureUrls:Array<String>):Array<Texture> {
			var textureLoader = new TextureLoader();
			var textures:Array<Texture> = [];

			for (i in textureUrls) {
				var texture = textureLoader.load(baseUrl + textureUrls[i]);
				texture.mapping = UVMapping;
				texture.name = textureUrls[i];
				texture.colorSpace = SRGBColorSpace;
				textures.push(texture);
			}

			return textures;
		}

		function checkLoadingComplete() {
			scope.loadCounter -= 1;

			if (scope.loadCounter === 0) scope.onLoadComplete();
		}

		loadCounter = config.weapons.length * 2 + config.skins.length + 1;

		var weaponsTextures:Array<String> = [];
		for (i in config.weapons) weaponsTextures.push(config.weapons[i][1]);

		skinsBody = loadTextures(config.baseUrl + 'skins/', config.skins);
		skinsWeapon = loadTextures(config.baseUrl + 'skins/', weaponsTextures);

		var loader = new MD2Loader();

		loader.load(config.baseUrl + config.body, function(geo:Geometry) {
			var boundingBox = new Box3();
			boundingBox.setFromBufferAttribute(geo.attributes.position);

			scope.root.position.y = - scope.scale * boundingBox.min.y;

			var mesh = createPart(geo, scope.skinsBody[0]);
			mesh.scale.set(scope.scale, scope.scale, scope.scale);

			scope.root.add(mesh);

			scope.meshBody = mesh;

			scope.meshBody.clipOffset = 0;
			scope.activeAnimationClipName = mesh.geometry.animations[0].name;

			scope.mixer = new AnimationMixer(mesh);

			checkLoadingComplete();
		});

		function generateCallback(index:Int, name:String):Void->Void {
			return function(geo:Geometry) {
				var mesh = createPart(geo, scope.skinsWeapon[index]);
				mesh.scale.set(scope.scale, scope.scale, scope.scale);
				mesh.visible = false;

				mesh.name = name;

				scope.root.add(mesh);

				scope.weapons[index] = mesh;
				scope.meshWeapon = mesh;

				checkLoadingComplete();
			};
		}

		for (i in config.weapons) {
			loader.load(config.baseUrl + config.weapons[i][0], generateCallback(Std.parseInt(i), config.weapons[i][0]));
		}
	}

	public function setPlaybackRate(rate:Float) {
		if (rate !== 0) {
			mixer.timeScale = 1 / rate;
		} else {
			mixer.timeScale = 0;
		}
	}

	public function setWireframe(wireframeEnabled:Bool) {
		if (wireframeEnabled) {
			if (meshBody) meshBody.material = meshBody.materialWireframe;
			if (meshWeapon) meshWeapon.material = meshWeapon.materialWireframe;
		} else {
			if (meshBody) meshBody.material = meshBody.materialTexture;
			if (meshWeapon) meshWeapon.material = meshWeapon.materialTexture;
		}
	}

	public function setSkin(index:Int) {
		if (meshBody && meshBody.material.wireframe === false) {
			meshBody.material.map = skinsBody[index];
		}
	}

	public function setWeapon(index:Int) {
			for (i in weapons) weapons[i].visible = false;

			var activeWeapon = weapons[index];

			if (activeWeapon) {
				activeWeapon.visible = true;
				meshWeapon = activeWeapon;

				syncWeaponAnimation();
			}
		}

	public function setAnimation(clipName:String) {
		if (meshBody) {
			if (meshBody.activeAction) {
				meshBody.activeAction.stop();
				meshBody.activeAction = null;
			}

			var action = mixer.clipAction(clipName, meshBody);

			if (action) {
				meshBody.activeAction = action.play();
			}
		}

		activeClipName = clipName;

		syncWeaponAnimation();
	}

	public function syncWeaponAnimation() {
		var clipName = activeClipName;

		if (meshWeapon) {
			if (meshWeapon.activeAction) {
				meshWeapon.activeAction.stop();
				meshWeapon.activeAction = null;
			}

			var action = mixer.clipAction(clipName, meshWeapon);

			if (action) {
				meshWeapon.activeAction = action.syncWith(meshBody.activeAction).play();
			}
		}
	}

	public function update(delta:Float) {
		if (mixer) mixer.update(delta);
	}
}