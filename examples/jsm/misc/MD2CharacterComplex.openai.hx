package three.js.examples.jsm.misc;

import three.Vector3;
import three.Matrix4;
import three.MathUtils;
import three.Box3;
import three.TextureLoader;
import three.MeshLambertMaterial;
import three.Object3D;
import three.UVMapping;
import three.SRGBColorSpace;
import md2.MD2Loader;
import morph.MorphBlendMesh;

class MD2CharacterComplex {
    public var scale:Float;
    public var animationFPS:Float;
    public var transitionFrames:Int;
    public var maxSpeed:Float;
    public var maxReverseSpeed:Float;
    public var frontAcceleration:Float;
    public var backAcceleration:Float;
    public var frontDecceleration:Float;
    public var angularSpeed:Float;
    public var root:Object3D;
    public var meshBody:MorphBlendMesh;
    public var meshWeapon:MorphBlendMesh;
    public var controls:Object;
    public var skinsBody:Array<Texture>;
    public var skinsWeapon:Array<Texture>;
    public var weapons:Array<MorphBlendMesh>;
    public var currentSkin:Int;
    public var onLoadComplete:Void->Void;
    public var meshes:Array<MorphBlendMesh>;
    public var animations:Map<String, Dynamic>;
    public var loadCounter:Int;
    public var speed:Float;
    public var bodyOrientation:Float;
    public var walkSpeed:Float;
    public var crouchSpeed:Float;
    public var activeAnimation:String;
    public var oldAnimation:String;
    public var blendCounter:Int;

    public function new() {
        scale = 1;
        animationFPS = 6;
        transitionFrames = 15;
        maxSpeed = 275;
        maxReverseSpeed = -275;
        frontAcceleration = 600;
        backAcceleration = 600;
        frontDecceleration = 600;
        angularSpeed = 2.5;
        root = new Object3D();
        meshBody = null;
        meshWeapon = null;
        controls = null;
        skinsBody = [];
        skinsWeapon = [];
        weapons = [];
        currentSkin = -1;
        onLoadComplete = function() {};
        meshes = [];
        animations = {};
        loadCounter = 0;
        speed = 0;
        bodyOrientation = 0;
        walkSpeed = maxSpeed;
        crouchSpeed = maxSpeed * 0.5;
        activeAnimation = null;
        oldAnimation = null;
        blendCounter = 0;
    }

    public function enableShadows(enable:Bool) {
        for (i in 0...meshes.length) {
            meshes[i].castShadow = enable;
            meshes[i].receiveShadow = enable;
        }
    }

    public function setVisible(enable:Bool) {
        for (i in 0...meshes.length) {
            meshes[i].visible = enable;
        }
    }

    public function shareParts(original:MD2CharacterComplex) {
        animations = original.animations;
        walkSpeed = original.walkSpeed;
        crouchSpeed = original.crouchSpeed;
        skinsBody = original.skinsBody;
        skinsWeapon = original.skinsWeapon;

        // BODY
        var mesh = _createPart(original.meshBody.geometry, skinsBody[0]);
        mesh.scale.set(scale, scale, scale);

        root.position.y = original.root.position.y;
        root.add(mesh);

        meshBody = mesh;
        meshes.push(mesh);

        // WEAPONS
        for (i in 0...original.weapons.length) {
            var meshWeapon = _createPart(original.weapons[i].geometry, skinsWeapon[i]);
            meshWeapon.scale.set(scale, scale, scale);
            meshWeapon.visible = false;

            meshWeapon.name = original.weapons[i].name;

            root.add(meshWeapon);

            weapons[i] = meshWeapon;
            meshWeapon = meshWeapon;

            meshes.push(meshWeapon);
        }
    }

    public function loadParts(config:Dynamic) {
        var scope = this;

        function loadTextures(baseUrl:String, textureUrls:Array<String>) {
            var textureLoader = new TextureLoader();
            var textures:Array<Texture> = [];

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

        animations = config.animations;
        walkSpeed = config.walkSpeed;
        crouchSpeed = config.crouchSpeed;

        loadCounter = config.weapons.length * 2 + config.skins.length + 1;

        var weaponsTextures:Array<String> = [];

        for (i in 0...config.weapons.length) weaponsTextures[i] = config.weapons[i][1];

        // SKINS
        skinsBody = loadTextures(config.baseUrl + 'skins/', config.skins);
        skinsWeapon = loadTextures(config.baseUrl + 'skins/', weaponsTextures);

        // BODY
        var loader = new MD2Loader();

        loader.load(config.baseUrl + config.body, function(geo) {
            var boundingBox = new Box3();
            boundingBox.setFromBufferAttribute(geo.attributes.position);

            root.position.y = -scale * boundingBox.min.y;

            var mesh = _createPart(geo, skinsBody[0]);
            mesh.scale.set(scale, scale, scale);

            root.add(mesh);

            meshBody = mesh;
            meshes.push(mesh);

            checkLoadingComplete();

        });

        // WEAPONS
        var generateCallback = function(index:Int, name:String) {
            return function(geo) {
                var mesh = _createPart(geo, skinsWeapon[index]);
                mesh.scale.set(scale, scale, scale);
                mesh.visible = false;

                mesh.name = name;

                root.add(mesh);

                weapons[index] = mesh;
                meshWeapon = mesh;
                meshes.push(mesh);

                checkLoadingComplete();

            };
        };

        for (i in 0...config.weapons.length) {
            loader.load(config.baseUrl + config.weapons[i][0], generateCallback(i, config.weapons[i][0]));
        }
    }

    public function setPlaybackRate(rate:Float) {
        if (meshBody != null) meshBody.duration = meshBody.baseDuration / rate;
        if (meshWeapon != null) meshWeapon.duration = meshWeapon.baseDuration / rate;
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
            currentSkin = index;
        }
    }

    public function setWeapon(index:Int) {
        for (i in 0...weapons.length) weapons[i].visible = false;

        var activeWeapon = weapons[index];

        if (activeWeapon != null) {
            activeWeapon.visible = true;
            meshWeapon = activeWeapon;

            if (activeAnimation != null) {
                activeWeapon.playAnimation(activeAnimation);
                meshWeapon.animationTime = meshBody.animationTime(activeAnimation);
            }
        }
    }

    public function setAnimation(animationName:String) {
        if (animationName == activeAnimation || animationName == null) return;

        if (meshBody != null) {
            meshBody.setAnimationWeight(animationName, 0);
            meshBody.playAnimation(animationName);

            oldAnimation = activeAnimation;
            activeAnimation = animationName;

            blendCounter = transitionFrames;
        }

        if (meshWeapon != null) {
            meshWeapon.setAnimationWeight(animationName, 0);
            meshWeapon.playAnimation(animationName);
        }
    }

    public function update(delta:Float) {
        if (controls != null) updateMovementModel(delta);

        if (animations != null) {
            updateBehaviors();
            updateAnimations(delta);
        }
    }

    public function updateAnimations(delta:Float) {
        var mix:Float = 1;

        if (blendCounter > 0) {
            mix = (transitionFrames - blendCounter) / transitionFrames;
            blendCounter -= 1;
        }

        if (meshBody != null) {
            meshBody.update(delta);

            meshBody.setAnimationWeight(activeAnimation, mix);
            meshBody.setAnimationWeight(oldAnimation, 1 - mix);
        }

        if (meshWeapon != null) {
            meshWeapon.update(delta);

            meshWeapon.setAnimationWeight(activeAnimation, mix);
            meshWeapon.setAnimationWeight(oldAnimation, 1 - mix);
        }
    }

    public function updateBehaviors() {
        var controls = this.controls;
        var animations = this.animations;

        var moveAnimation:String, idleAnimation:String;

        // crouch vs stand

        if (controls.crouch) {
            moveAnimation = animations['crouchMove'];
            idleAnimation = animations['crouchIdle'];
        } else {
            moveAnimation = animations['move'];
            idleAnimation = animations['idle'];
        }

        // actions

        if (controls.jump) {
            moveAnimation = animations['jump'];
            idleAnimation = animations['jump'];
        }

        if (controls.attack) {
            if (controls.crouch) {
                moveAnimation = animations['crouchAttack'];
                idleAnimation = animations['crouchAttack'];
            } else {
                moveAnimation = animations['attack'];
                idleAnimation = animations['attack'];
            }
        }

        // set animations

        if (controls.moveForward || controls.moveBackward || controls.moveLeft || controls.moveRight) {
            if (activeAnimation != moveAnimation) {
                setAnimation(moveAnimation);
            }
        }

        if (Math.abs(speed) < 0.2 * maxSpeed && ! (controls.moveLeft || controls.moveRight || controls.moveForward || controls.moveBackward)) {
            if (activeAnimation != idleAnimation) {
                setAnimation(idleAnimation);
            }
        }

        // set animation direction

        if (controls.moveForward) {
            if (meshBody != null) {
                meshBody.setAnimationDirectionForward(activeAnimation);
                meshBody.setAnimationDirectionForward(oldAnimation);
            }

            if (meshWeapon != null) {
                meshWeapon.setAnimationDirectionForward(activeAnimation);
                meshWeapon.setAnimationDirectionForward(oldAnimation);
            }
        }

        if (controls.moveBackward) {
            if (meshBody != null) {
                meshBody.setAnimationDirectionBackward(activeAnimation);
                meshBody.setAnimationDirectionBackward(oldAnimation);
            }

            if (meshWeapon != null) {
                meshWeapon.setAnimationDirectionBackward(activeAnimation);
                meshWeapon.setAnimationDirectionBackward(oldAnimation);
            }
        }
    }

    public function updateMovementModel(delta:Float) {
        function exponentialEaseOut(k:Float) {
            return k == 1 ? 1 : - Math.pow(2, -10 * k) + 1;
        }

        var controls = this.controls;

        // speed based on controls

        if (controls.crouch) maxSpeed = crouchSpeed;
        else maxSpeed = walkSpeed;

        maxReverseSpeed = -maxSpeed;

        if (controls.moveForward) speed = MathUtils.clamp(speed + delta * frontAcceleration, maxReverseSpeed, maxSpeed);
        if (controls.moveBackward) speed = MathUtils.clamp(speed - delta * backAcceleration, maxReverseSpeed, maxSpeed);

        // orientation based on controls
        // (don't just stand while turning)

        var dir:Float = 1;

        if (controls.moveLeft) {
            bodyOrientation += delta * angularSpeed;
            speed = MathUtils.clamp(speed + dir * delta * frontAcceleration, maxReverseSpeed, maxSpeed);
        }

        if (controls.moveRight) {
            bodyOrientation -= delta * angularSpeed;
            speed = MathUtils.clamp(speed + dir * delta * frontAcceleration, maxReverseSpeed, maxSpeed);
        }

        // speed decay

        if (! (controls.moveForward || controls.moveBackward)) {
            if (speed > 0) {
                var k:Float = exponentialEaseOut(speed / maxSpeed);
                speed = MathUtils.clamp(speed - k * delta * frontDecceleration, 0, maxSpeed);
            } else {
                var k:Float = exponentialEaseOut(speed / maxReverseSpeed);
                speed = MathUtils.clamp(speed + k * delta * backAcceleration, maxReverseSpeed, 0);
            }
        }

        // displacement

        var forwardDelta:Float = speed * delta;

        root.position.x += Math.sin(bodyOrientation) * forwardDelta;
        root.position.z += Math.cos(bodyOrientation) * forwardDelta;

        // steering

        root.rotation.y = bodyOrientation;
    }

    private function _createPart(geometry:Geometry, skinMap:Texture) {
        var materialWireframe = new MeshLambertMaterial({ color: 0xffaa00, wireframe: true });
        var materialTexture = new MeshLambertMaterial({ color: 0xffffff, wireframe: false, map: skinMap });

        var mesh = new MorphBlendMesh(geometry, materialTexture);
        mesh.rotation.y = - Math.PI / 2;

        mesh.materialTexture = materialTexture;
        mesh.materialWireframe = materialWireframe;

        mesh.autoCreateAnimations(animationFPS);

        return mesh;
    }
}