import three.js.examples.jsm.misc.MorphBlendMesh;
import three.js.examples.jsm.loaders.MD2Loader;
import three.js.Box3;
import three.js.MathUtils;
import three.js.MeshLambertMaterial;
import three.js.Object3D;
import three.js.TextureLoader;
import three.js.UVMapping;
import three.js.SRGBColorSpace;

class MD2CharacterComplex {

	public var scale(default, null):Float = 1;

	// animation parameters

	public var animationFPS(default, null):Int = 6;
	public var transitionFrames(default, null):Int = 15;

	// movement model parameters

	public var maxSpeed(default, null):Float = 275;
	public var maxReverseSpeed(default, null):Float = -275;

	public var frontAcceleration(default, null):Float = 600;
	public var backAcceleration(default, null):Float = 600;

	public var frontDecceleration(default, null):Float = 600;

	public var angularSpeed(default, null):Float = 2.5;

	// rig

	public var root(default, null):Object3D = new Object3D();

	public var meshBody(default, null):MorphBlendMesh;
	public var meshWeapon(default, null):MorphBlendMesh;

	public var controls(default, null):Dynamic;

	// skins

	public var skinsBody(default, null):Array<Dynamic>;
	public var skinsWeapon(default, null):Array<Dynamic>;

	public var weapons(default, null):Array<Dynamic>;

	public var currentSkin(default, null):Dynamic;

	// internals

	public var meshes(default, null):Array<Dynamic>;
	public var animations(default, null):Dynamic;

	public var loadCounter(default, null):Int;

	// internal movement control variables

	public var speed(default, null):Float;
	public var bodyOrientation(default, null):Float;

	public var walkSpeed(default, null):Float;
	public var crouchSpeed(default, null):Float;

	// internal animation parameters

	public var activeAnimation(default, null):Dynamic;
	public var oldAnimation(default, null):Dynamic;

	// API

	public function new() {

		this.walkSpeed = this.maxSpeed;
		this.crouchSpeed = this.maxSpeed * 0.5;

		this.onLoadComplete = function () {};

		this.meshes = [];
		this.animations = {};

		this.loadCounter = 0;

		this.speed = 0;
		this.bodyOrientation = 0;

	}

	public function enableShadows( enable:Bool ):Void {

		for ( i in 0...this.meshes.length ) {

			this.meshes[i].castShadow = enable;
			this.meshes[i].receiveShadow = enable;

		}

	}

	public function setVisible( enable:Bool ):Void {

		for ( i in 0...this.meshes.length ) {

			this.meshes[i].visible = enable;
			this.meshes[i].visible = enable;

		}

	}

	public function shareParts( original:MD2CharacterComplex ):Void {

		this.animations = original.animations;
		this.walkSpeed = original.walkSpeed;
		this.crouchSpeed = original.crouchSpeed;

		this.skinsBody = original.skinsBody;
		this.skinsWeapon = original.skinsWeapon;

		// BODY

		var mesh = this._createPart( original.meshBody.geometry, this.skinsBody[0] );
		mesh.scale.set( this.scale, this.scale, this.scale );

		this.root.position.y = original.root.position.y;
		this.root.add( mesh );

		this.meshBody = mesh;

		this.meshes.push( mesh );

		// WEAPONS

		for ( i in 0...original.weapons.length ) {

			var meshWeapon = this._createPart( original.weapons[i].geometry, this.skinsWeapon[i] );
			meshWeapon.scale.set( this.scale, this.scale, this.scale );
			meshWeapon.visible = false;

			meshWeapon.name = original.weapons[i].name;

			this.root.add( meshWeapon );

			this.weapons[i] = meshWeapon;
			this.meshWeapon = meshWeapon;

			this.meshes.push( meshWeapon );

		}

	}

	public function loadParts( config:Dynamic ):Void {

		var scope = this;

		function loadTextures( baseUrl:String, textureUrls:Array<String> ):Array<Dynamic> {

			var textureLoader = new TextureLoader();
			var textures = [];

			for ( i in 0...textureUrls.length ) {

				textures[i] = textureLoader.load( baseUrl + textureUrls[i], checkLoadingComplete );
				textures[i].mapping = UVMapping;
				textures[i].name = textureUrls[i];
				textures[i].colorSpace = SRGBColorSpace;

			}

			return textures;

		}

		function checkLoadingComplete():Void {

			scope.loadCounter -= 1;
			if ( scope.loadCounter === 0 ) 	scope.onLoadComplete();

		}

		this.animations = config.animations;
		this.walkSpeed = config.walkSpeed;
		this.crouchSpeed = config.crouchSpeed;

		this.loadCounter = config.weapons.length * 2 + config.skins.length + 1;

		var weaponsTextures = [];
		for ( i in 0...config.weapons.length ) weaponsTextures[i] = config.weapons[i][1];

		// SKINS

		this.skinsBody = loadTextures( config.baseUrl + 'skins/', config.skins );
		this.skinsWeapon = loadTextures( config.baseUrl + 'skins/', weaponsTextures );

		// BODY

		var loader = new MD2Loader();

		loader.load( config.baseUrl + config.body, function ( geo ) {

			var boundingBox = new Box3();
			boundingBox.setFromBufferAttribute( geo.attributes.position );

			scope.root.position.y = - scope.scale * boundingBox.min.y;

			var mesh = scope._createPart( geo, scope.skinsBody[0] );
			mesh.scale.set( scope.scale, scope.scale, scope.scale );

			scope.root.add( mesh );

			scope.meshBody = mesh;
			scope.meshes.push( mesh );

			checkLoadingComplete();

		} );

		// WEAPONS

		var generateCallback = function ( index:Int, name:String ) {

			return function ( geo ) {

				var mesh = scope._createPart( geo, scope.skinsWeapon[index] );
				mesh.scale.set( scope.scale, scope.scale, scope.scale );
				mesh.visible = false;

				mesh.name = name;

				scope.root.add( mesh );

				scope.weapons[index] = mesh;
				scope.meshWeapon = mesh;
				scope.meshes.push( mesh );

				checkLoadingComplete();

			};

		};

		for ( i in 0...config.weapons.length ) {

			loader.load( config.baseUrl + config.weapons[i][0], generateCallback( i, config.weapons[i][0] ) );

		}

	}

	public function setPlaybackRate( rate:Float ):Void {

		if ( this.meshBody ) this.meshBody.duration = this.meshBody.baseDuration / rate;
		if ( this.meshWeapon ) this.meshWeapon.duration = this.meshWeapon.baseDuration / rate;

	}

	public function setWireframe( wireframeEnabled:Bool ):Void {

		if ( wireframeEnabled ) {

			if ( this.meshBody ) this.meshBody.material = this.meshBody.materialWireframe;
			if ( this.meshWeapon ) this.meshWeapon.material = this.meshWeapon.materialWireframe;

		} else {

			if ( this.meshBody ) this.meshBody.material = this.meshBody.materialTexture;
			if ( this.meshWeapon ) this.meshWeapon.material = this.meshWeapon.materialTexture;

		}

	}

	public function setSkin( index:Int ):Void {

		if ( this.meshBody && this.meshBody.material.wireframe === false ) {

			this.meshBody.material.map = this.skinsBody[index];
			this.currentSkin = index;

		}

	}

	public function setWeapon( index:Int ):Void {

		for ( i in 0...this.weapons.length ) this.weapons[i].visible = false;

		var activeWeapon = this.weapons[index];

		if ( activeWeapon ) {

			activeWeapon.visible = true;
			this.meshWeapon = activeWeapon;

			if ( this.activeAnimation ) {

				activeWeapon.playAnimation( this.activeAnimation );
				this.meshWeapon.setAnimationTime( this.activeAnimation, this.meshBody.getAnimationTime( this.activeAnimation ) );

			}

		}

	}

	public function setAnimation( animationName:String ):Void {

		if ( animationName === this.activeAnimation || !animationName ) return;

		if ( this.meshBody ) {

			this.meshBody.setAnimationWeight( animationName, 0 );
			this.meshBody.playAnimation( animationName );

			this.oldAnimation = this.activeAnimation;
			this.activeAnimation = animationName;

			this.blendCounter = this.transitionFrames;

		}

		if ( this.meshWeapon ) {

			this.meshWeapon.setAnimationWeight( animationName, 0 );
			this.meshWeapon.playAnimation( animationName );

		}

	}

	public function update( delta:Float ):Void {

		if ( this.controls ) this.updateMovementModel( delta );

		if ( this.animations ) {

			this.updateBehaviors();
			this.updateAnimations( delta );

		}

	}

	public function updateAnimations( delta:Float ):Void {

		var mix = 1;

		if ( this.blendCounter > 0 ) {

			mix = ( this.transitionFrames - this.blendCounter ) / this.transitionFrames;
			this.blendCounter -= 1;

		}

		if ( this.meshBody ) {

			this.meshBody.update( delta );

			this.meshBody.setAnimationWeight( this.activeAnimation, mix );
			this.meshBody.setAnimationWeight( this.oldAnimation, 1 - mix );

		}

		if ( this.meshWeapon ) {

			this.meshWeapon.update( delta );

			this.meshWeapon.setAnimationWeight( this.activeAnimation, mix );
			this.meshWeapon.setAnimationWeight( this.oldAnimation, 1 - mix );

		}

	}

	public function updateBehaviors():Void {

		var controls = this.controls;
		var animations = this.animations;

		var moveAnimation, idleAnimation;

		// crouch vs stand

		if ( controls.crouch ) {

			moveAnimation = animations['crouchMove'];
			idleAnimation = animations['crouchIdle'];

		} else {

			moveAnimation = animations['move'];
			idleAnimation = animations['idle'];

		}

		// actions

		if ( controls.jump ) {

			moveAnimation = animations['jump'];
			idleAnimation = animations['jump'];

		}

		if ( controls.attack ) {

			if ( controls.crouch ) {

				moveAnimation = animations['crouchAttack'];
				idleAnimation = animations['crouchAttack'];

			} else {

				moveAnimation = animations['attack'];
				idleAnimation = animations['attack'];

			}

		}

		// set animations

		if ( controls.moveForward || controls.moveBackward || controls.moveLeft || controls.moveRight ) {

			if ( this.activeAnimation !== moveAnimation ) {

				this.setAnimation( moveAnimation );

			}

		}

		if ( Math.abs( this.speed ) < 0.2 * this.maxSpeed && ! ( controls.moveLeft || controls.moveRight || controls.moveForward || controls.moveBackward ) ) {

			if ( this.activeAnimation !== idleAnimation ) {

				this.setAnimation( idleAnimation );

			}

		}

		// set animation direction

		if ( controls.moveForward ) {

			if ( this.meshBody ) {

				this.meshBody.setAnimationDirectionForward( this.activeAnimation );
				this.meshBody.setAnimationDirectionForward( this.oldAnimation );

			}

			if ( this.meshWeapon ) {

				this.meshWeapon.setAnimationDirectionForward( this.activeAnimation );
				this.meshWeapon.setAnimationDirectionForward( this.oldAnimation );

			}

		}

		if ( controls.moveBackward ) {

			if ( this.meshBody ) {

				this.meshBody.setAnimationDirectionBackward( this.activeAnimation );
				this.meshBody.setAnimationDirectionBackward( this.oldAnimation );

			}

			if ( this.meshWeapon ) {

				this.meshWeapon.setAnimationDirectionBackward( this.activeAnimation );
				this.meshWeapon.setAnimationDirectionBackward( this.oldAnimation );

			}

		}

	}

	public function updateMovementModel( delta:Float ):Void {

		function exponentialEaseOut( k:Float ):Float {

			return k === 1 ? 1 : - Math.pow( 2, -10 * k ) + 1;

		}

		var controls = this.controls;

		// speed based on controls

		if ( controls.crouch ) 	this.maxSpeed = this.crouchSpeed;
		else this.maxSpeed = this.walkSpeed;

		this.maxReverseSpeed = - this.maxSpeed;

		if ( controls.moveForward ) this.speed = MathUtils.clamp( this.speed + delta * this.frontAcceleration, this.maxReverseSpeed, this.maxSpeed );
		if ( controls.moveBackward ) this.speed = MathUtils.clamp( this.speed - delta * this.backAcceleration, this.maxReverseSpeed, this.maxSpeed );

		// orientation based on controls
		// (don't just stand while turning)

		var dir = 1;

		if ( controls.moveLeft ) {

			this.bodyOrientation += delta * this.angularSpeed;
			this.speed = MathUtils.clamp( this.speed + dir * delta * this.frontAcceleration, this.maxReverseSpeed, this.maxSpeed );

		}

		if ( controls.moveRight ) {

			this.bodyOrientation -= delta * this.angularSpeed;
			this.speed = MathUtils.clamp( this.speed + dir * delta * this.frontAcceleration, this.maxReverseSpeed, this.maxSpeed );

		}

		// speed decay

		if ( ! ( controls.moveForward || controls.moveBackward ) ) {

			if ( this.speed > 0 ) {

				var k = exponentialEaseOut( this.speed / this.maxSpeed );
				this.speed = MathUtils.clamp( this.speed - k * delta * this.frontDecceleration, 0, this.maxSpeed );

			} else {

				var k = exponentialEaseOut( this.speed / this.maxReverseSpeed );
				this.speed = MathUtils.clamp( this.speed + k * delta * this.backAcceleration, this.maxReverseSpeed, 0 );

			}

		}

		// displacement

		var forwardDelta = this.speed * delta;

		this.root.position.x += Math.sin( this.bodyOrientation ) * forwardDelta;
		this.root.position.z += Math.cos( this.bodyOrientation ) * forwardDelta;

		// steering

		this.root.rotation.y = this.bodyOrientation;

	}

	// internal

	public function _createPart( geometry:Dynamic, skinMap:Dynamic ):MorphBlendMesh {

		var materialWireframe = new MeshLambertMaterial( { color: 0xffaa00, wireframe: true } );
		var materialTexture = new MeshLambertMaterial( { color: 0xffffff, wireframe: false, map: skinMap } );

		//

		var mesh = new MorphBlendMesh( geometry, materialTexture );
		mesh.rotation.y = - Math.PI / 2;

		//

		mesh.materialTexture = materialTexture;
		mesh.materialWireframe = materialWireframe;

		//

		mesh.autoCreateAnimations( this.animationFPS );

		return mesh;

	}

}