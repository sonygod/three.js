import three.Box3;
import three.MathUtils;
import three.MeshLambertMaterial;
import three.Object3D;
import three.TextureLoader;
import three.UVMapping;
import three.SRGBColorSpace;
import three.loaders.MD2Loader;
import three.misc.MorphBlendMesh;

class MD2CharacterComplex {

    public var scale:Float = 1;
    public var animationFPS:Int = 6;
    public var transitionFrames:Int = 15;
    public var maxSpeed:Float = 275;
    public var maxReverseSpeed:Float = -275;
    public var frontAcceleration:Float = 600;
    public var backAcceleration:Float = 600;
    public var frontDecceleration:Float = 600;
    public var angularSpeed:Float = 2.5;
    public var root:Object3D = new Object3D();
    public var meshBody:MorphBlendMesh = null;
    public var meshWeapon:MorphBlendMesh = null;
    public var controls:Dynamic = null;
    public var skinsBody:Array<Texture> = [];
    public var skinsWeapon:Array<Texture> = [];
    public var weapons:Array<MorphBlendMesh> = [];
    public var currentSkin:Int = -1;
    public var onLoadComplete:Void->Void = () -> {};
    public var meshes:Array<MorphBlendMesh> = [];
    public var animations:haxe.ds.StringMap = new haxe.ds.StringMap();
    public var loadCounter:Int = 0;
    public var speed:Float = 0;
    public var bodyOrientation:Float = 0;
    public var walkSpeed:Float = maxSpeed;
    public var crouchSpeed:Float = maxSpeed * 0.5;
    public var activeAnimation:String = null;
    public var oldAnimation:String = null;

    public function new() {
    }

    public function enableShadows(enable:Bool) {
        for (mesh in meshes) {
            mesh.castShadow = enable;
            mesh.receiveShadow = enable;
        }
    }

    public function setVisible(enable:Bool) {
        for (mesh in meshes) {
            mesh.visible = enable;
        }
    }

    public function shareParts(original:MD2CharacterComplex) {
        this.animations = original.animations;
        this.walkSpeed = original.walkSpeed;
        this.crouchSpeed = original.crouchSpeed;
        this.skinsBody = original.skinsBody;
        this.skinsWeapon = original.skinsWeapon;

        meshBody = _createPart(original.meshBody.geometry, skinsBody[0]);
        meshBody.scale.set(scale, scale, scale);
        root.position.y = original.root.position.y;
        root.add(meshBody);
        meshes.push(meshBody);

        for (i in 0...original.weapons.length) {
            var meshWeapon = _createPart(original.weapons[i].geometry, skinsWeapon[i]);
            meshWeapon.scale.set(scale, scale, scale);
            meshWeapon.visible = false;
            meshWeapon.name = original.weapons[i].name;
            root.add(meshWeapon);
            weapons[i] = meshWeapon;
            this.meshWeapon = meshWeapon;
            meshes.push(meshWeapon);
        }
    }

    public function loadParts(config:Dynamic) {
        loadCounter = config.weapons.length * 2 + config.skins.length + 1;
        var weaponsTextures:Array<String> = [];
        for (i in 0...config.weapons.length) {
            weaponsTextures[i] = config.weapons[i][1];
        }
        skinsBody = loadTextures(config.baseUrl + 'skins/', config.skins);
        skinsWeapon = loadTextures(config.baseUrl + 'skins/', weaponsTextures);

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

        for (i in 0...config.weapons.length) {
            loader.load(config.baseUrl + config.weapons[i][0], generateCallback(i, config.weapons[i][0]));
        }
    }

    private function loadTextures(baseUrl:String, textureUrls:Array<String>):Array<Texture> {
        var textureLoader = new TextureLoader();
        var textures:Array<Texture> = [];
        for (i in 0...textureUrls.length) {
            var texture = textureLoader.load(baseUrl + textureUrls[i], checkLoadingComplete);
            texture.mapping = UVMapping;
            texture.name = textureUrls[i];
            texture.colorSpace = SRGBColorSpace;
            textures[i] = texture;
        }
        return textures;
    }

    private function checkLoadingComplete() {
        loadCounter -= 1;
        if (loadCounter === 0) {
            onLoadComplete();
        }
    }

    private function generateCallback(index:Int, name:String):Void->Void {
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
    }

    public function setPlaybackRate(rate:Float) {
        if (meshBody != null) {
            meshBody.duration = meshBody.baseDuration / rate;
        }
        if (meshWeapon != null) {
            meshWeapon.duration = meshWeapon.baseDuration / rate;
        }
    }

    public function setWireframe(wireframeEnabled:Bool) {
        if (wireframeEnabled) {
            if (meshBody != null) {
                meshBody.material = meshBody.materialWireframe;
            }
            if (meshWeapon != null) {
                meshWeapon.material = meshWeapon.materialWireframe;
            }
        } else {
            if (meshBody != null) {
                meshBody.material = meshBody.materialTexture;
            }
            if (meshWeapon != null) {
                meshWeapon.material = meshWeapon.materialTexture;
            }
        }
    }

    public function setSkin(index:Int) {
        if (meshBody != null && !meshBody.material.wireframe) {
            meshBody.material.map = skinsBody[index];
            currentSkin = index;
        }
    }

    public function setWeapon(index:Int) {
        for (i in 0...weapons.length) {
            weapons[i].visible = false;
        }
        var activeWeapon = weapons[index];
        if (activeWeapon != null) {
            activeWeapon.visible = true;
            meshWeapon = activeWeapon;
            if (activeAnimation != null) {
                activeWeapon.playAnimation(activeAnimation);
                meshWeapon.setAnimationTime(activeAnimation, meshBody.getAnimationTime(activeAnimation));
            }
        }
    }

    public function setAnimation(animationName:String) {
        if (animationName == activeAnimation || animationName == null) {
            return;
        }
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
        if (controls != null) {
            updateMovementModel(delta);
        }
        if (animations != null) {
            updateBehaviors();
            updateAnimations(delta);
        }
    }

    private function updateAnimations(delta:Float) {
        var mix = 1;
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

    private function updateBehaviors() {
        var moveAnimation:String;
        var idleAnimation:String;
        if (controls.crouch) {
            moveAnimation = animations.get("crouchMove");
            idleAnimation = animations.get("crouchIdle");
        } else {
            moveAnimation = animations.get("move");
            idleAnimation = animations.get("idle");
        }
        if (controls.jump) {
            moveAnimation = animations.get("jump");
            idleAnimation = animations.get("jump");
        }
        if (controls.attack) {
            if (controls.crouch) {
                moveAnimation = animations.get("crouchAttack");
                idleAnimation = animations.get("crouchAttack");
            } else {
                moveAnimation = animations.get("attack");
                idleAnimation = animations.get("attack");
            }
        }
        if (controls.moveForward || controls.moveBackward || controls.moveLeft || controls.moveRight) {
            if (activeAnimation != moveAnimation) {
                setAnimation(moveAnimation);
            }
        }
        if (Math.abs(speed) < 0.2 * maxSpeed && !controls.moveLeft && !controls.moveRight && !controls.moveForward && !controls.moveBackward) {
            if (activeAnimation != idleAnimation) {
                setAnimation(idleAnimation);
            }
        }
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

    private function updateMovementModel(delta:Float) {
        if (controls.crouch) {
            maxSpeed = crouchSpeed;
        } else {
            maxSpeed = walkSpeed;
        }
        maxReverseSpeed = -maxSpeed;
        if (controls.moveForward) {
            speed = MathUtils.clamp(speed + delta * frontAcceleration, maxReverseSpeed, maxSpeed);
        }
        if (controls.moveBackward) {
            speed = MathUtils.clamp(speed - delta * backAcceleration, maxReverseSpeed, maxSpeed);
        }
        var dir = 1;
        if (controls.moveLeft) {
            bodyOrientation += delta * angularSpeed;
            speed = MathUtils.clamp(speed + dir * delta * frontAcceleration, maxReverseSpeed, maxSpeed);
        }
        if (controls.moveRight) {
            bodyOrientation -= delta * angularSpeed;
            speed = MathUtils.clamp(speed + dir * delta * frontAcceleration, maxReverseSpeed, maxSpeed);
        }
        if (!controls.moveForward && !controls.moveBackward) {
            if (speed > 0) {
                var k = exponentialEaseOut(speed / maxSpeed);
                speed = MathUtils.clamp(speed - k * delta * frontDecceleration, 0, maxSpeed);
            } else {
                var k = exponentialEaseOut(speed / maxReverseSpeed);
                speed = MathUtils.clamp(speed + k * delta * backAcceleration, maxReverseSpeed, 0);
            }
        }
        var forwardDelta = speed * delta;
        root.position.x += Math.sin(bodyOrientation) * forwardDelta;
        root.position.z += Math.cos(bodyOrientation) * forwardDelta;
        root.rotation.y = bodyOrientation;
    }

    private function exponentialEaseOut(k:Float):Float {
        if (k == 1) {
            return 1;
        } else {
            return -Math.pow(2, -10 * k) + 1;
        }
    }

    private function _createPart(geometry:Geometry, skinMap:Texture):MorphBlendMesh {
        var materialWireframe = new MeshLambertMaterial({color:0xffaa00, wireframe:true});
        var materialTexture = new MeshLambertMaterial({color:0xffffff, wireframe:false, map:skinMap});
        var mesh = new MorphBlendMesh(geometry, materialTexture);
        mesh.rotation.y = -Math.PI / 2;
        mesh.materialTexture = materialTexture;
        mesh.materialWireframe = materialWireframe;
        mesh.autoCreateAnimations(animationFPS);
        return mesh;
    }
}