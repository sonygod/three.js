package three.js.examples.jsm.misc;

import three.AnimationMixer;
import three.Box3;
import three.Mesh;
import three.MeshLambertMaterial;
import three.Object3D;
import three.TextureLoader;
import three.UVMapping;
import three.SRGBColorSpace;
import loaders.MD2Loader;

class MD2Character {
    public var scale:Float;
    public var animationFPS:Int;
    public var root:Object3D;
    public var meshBody:Mesh;
    public var meshWeapon:Mesh;
    public var skinsBody:Array<Texture>;
    public var skinsWeapon:Array<Texture>;
    public var weapons:Array<Mesh>;
    public var activeAnimation:String;
    public var mixer:AnimationMixer;
    public var onLoadComplete:Void->Void;
    public var loadCounter:Int;

    public function new() {
        scale = 1;
        animationFPS = 6;
        root = new Object3D();
        meshBody = null;
        meshWeapon = null;
        skinsBody = [];
        skinsWeapon = [];
        weapons = [];
        activeAnimation = null;
        mixer = null;
        onLoadComplete = function() {};
        loadCounter = 0;
    }

    public function loadParts(config:Dynamic) {
        var scope = this;

        function createPart(geometry:Geometry, skinMap:Texture) {
            var materialWireframe = new MeshLambertMaterial({ color: 0xffaa00, wireframe: true });
            var materialTexture = new MeshLambertMaterial({ color: 0xffffff, wireframe: false, map: skinMap });

            var mesh = new Mesh(geometry, materialTexture);
            mesh.rotation.y = -Math.PI / 2;

            mesh.castShadow = true;
            mesh.receiveShadow = true;

            mesh.materialTexture = materialTexture;
            mesh.materialWireframe = materialWireframe;

            return mesh;
        }

        function loadTextures(baseUrl:String, textureUrls:Array<String>) {
            var textureLoader = new TextureLoader();
            var textures = [];

            for (i in 0...textureUrls.length) {
                textures[i] = textureLoader.load(baseUrl + textureUrls[i], checkLoadingComplete);
                textures[i].mapping = UVMapping;
                textures[i].name = textureUrls[i];
                textures[i].colorSpace = SRGBColorSpace;
            }

            return textures;
        }

        function checkLoadingComplete() {
            scope.loadCounter -= 1;

            if (scope.loadCounter == 0) scope.onLoadComplete();
        }

        loadCounter = config.weapons.length * 2 + config.skins.length + 1;

        var weaponsTextures = [];
        for (i in 0...config.weapons.length) weaponsTextures[i] = config.weapons[i][1];

        skinsBody = loadTextures(config.baseUrl + 'skins/', config.skins);
        skinsWeapon = loadTextures(config.baseUrl + 'skins/', weaponsTextures);

        var loader = new MD2Loader();

        loader.load(config.baseUrl + config.body, function(geo) {
            var boundingBox = new Box3();
            boundingBox.setFromBufferAttribute(geo.attributes.position);

            scope.root.position.y = -scope.scale * boundingBox.min.y;

            var mesh = createPart(geo, scope.skinsBody[0]);
            mesh.scale.set(scope.scale, scope.scale, scope.scale);

            scope.root.add(mesh);

            scope.meshBody = mesh;

            scope.meshBody.clipOffset = 0;
            scope.activeAnimationClipName = mesh.geometry.animations[0].name;

            scope.mixer = new AnimationMixer(mesh);

            checkLoadingComplete();
        });

        var generateCallback = function(index:Int, name:String) {
            return function(geo) {
                var mesh = createPart(geo, scope.skinsWeapon[index]);
                mesh.scale.set(scope.scale, scope.scale, scope.scale);
                mesh.visible = false;

                mesh.name = name;

                scope.root.add(mesh);

                scope.weapons[index] = mesh;
                scope.meshWeapon = mesh;

                checkLoadingComplete();
            };
        };

        for (i in 0...config.weapons.length) {
            loader.load(config.baseUrl + config.weapons[i][0], generateCallback(i, config.weapons[i][0]));
        }
    }

    public function setPlaybackRate(rate:Float) {
        if (rate != 0) {
            mixer.timeScale = 1 / rate;
        } else {
            mixer.timeScale = 0;
        }
    }

    public function setWireframe(wireframeEnabled:Bool) {
        if (wireframeEnabled) {
            if (meshBody != null) meshBody.material = meshBody.materialWireframe;
            if (meshWeapon != null) meshWeapon.material = meshWeapon.materialWireframe;
        } else {
            if (meshBody != null) meshBody.material = meshBody.materialTexture;
            if (meshWeapon != null) meshWeapon.material = meshWeapon.materialTexture;
        }
    }

    public function setSkin(index:Int) {
        if (meshBody != null && meshBody.material.wireframe == false) {
            meshBody.material.map = skinsBody[index];
        }
    }

    public function setWeapon(index:Int) {
        for (i in 0...weapons.length) weapons[i].visible = false;

        var activeWeapon = weapons[index];

        if (activeWeapon != null) {
            activeWeapon.visible = true;
            meshWeapon = activeWeapon;

            syncWeaponAnimation();
        }
    }

    public function setAnimation(clipName:String) {
        if (meshBody != null) {
            if (meshBody.activeAction != null) {
                meshBody.activeAction.stop();
                meshBody.activeAction = null;
            }

            var action = mixer.clipAction(clipName, meshBody);

            if (action != null) {
                meshBody.activeAction = action.play();
            }
        }

        activeAnimation = clipName;

        syncWeaponAnimation();
    }

    public function syncWeaponAnimation() {
        var clipName = activeAnimation;

        if (meshWeapon != null) {
            if (meshWeapon.activeAction != null) {
                meshWeapon.activeAction.stop();
                meshWeapon.activeAction = null;
            }

            var action = mixer.clipAction(clipName, meshWeapon);

            if (action != null) {
                meshWeapon.activeAction = action.syncWith(meshBody.activeAction).play();
            }
        }
    }

    public function update(delta:Float) {
        if (mixer != null) mixer.update(delta);
    }
}