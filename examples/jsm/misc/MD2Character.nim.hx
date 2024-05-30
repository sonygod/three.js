import three.examples.jsm.misc.MD2Loader;
import three.examples.jsm.loaders.MD2Loader;
import three.examples.jsm.loaders.TextureLoader;
import three.examples.jsm.objects.Mesh;
import three.examples.jsm.objects.Object3D;
import three.examples.jsm.materials.MeshLambertMaterial;
import three.examples.jsm.math.Box3;
import three.examples.jsm.animation.AnimationMixer;
import three.examples.jsm.math.UVMapping;
import three.examples.jsm.math.SRGBColorSpace;

class MD2Character {

	public var scale:Float = 1;
	public var animationFPS:Int = 6;

	public var root:Object3D;

	public var meshBody:Mesh;
	public var meshWeapon:Mesh;

	public var skinsBody:Array<Dynamic>;
	public var skinsWeapon:Array<Dynamic>;

	public var weapons:Array<Dynamic>;

	public var activeAnimation:Dynamic;

	public var mixer:AnimationMixer;

	public var onLoadComplete:Void->Void;

	public var loadCounter:Int;

	public function new() {

		this.root = new Object3D();

		this.meshBody = null;
		this.meshWeapon = null;

		this.skinsBody = [];
		this.skinsWeapon = [];

		this.weapons = [];

		this.activeAnimation = null;

		this.mixer = null;

		this.onLoadComplete = function () {};

		this.loadCounter = 0;

	}

	public function loadParts( config:Dynamic ) {

		var scope = this;

		function createPart( geometry:Dynamic, skinMap:Dynamic ) {

			var materialWireframe = new MeshLambertMaterial( { color: 0xffaa00, wireframe: true } );
			var materialTexture = new MeshLambertMaterial( { color: 0xffffff, wireframe: false, map: skinMap } );

			//

			var mesh = new Mesh( geometry, materialTexture );
			mesh.rotation.y = - Math.PI / 2;

			mesh.castShadow = true;
			mesh.receiveShadow = true;

			//

			mesh.materialTexture = materialTexture;
			mesh.materialWireframe = materialWireframe;

			return mesh;

		}

		function loadTextures( baseUrl:String, textureUrls:Array<String> ) {

			var textureLoader = new TextureLoader();
			var textures = [];

			for ( i in 0...textureUrls.length ) {

				textures[ i ] = textureLoader.load( baseUrl + textureUrls[ i ], checkLoadingComplete );
				textures[ i ].mapping = UVMapping;
				textures[ i ].name = textureUrls[ i ];
				textures[ i ].colorSpace = SRGBColorSpace;

			}

			return textures;

		}

		function checkLoadingComplete() {

			scope.loadCounter -= 1;

			if ( scope.loadCounter === 0 ) scope.onLoadComplete();

		}

		this.loadCounter = config.weapons.length * 2 + config.skins.length + 1;

		var weaponsTextures = [];
		for ( i in 0...config.weapons.length ) weaponsTextures[ i ] = config.weapons[ i ][ 1 ];
		// SKINS

		this.skinsBody = loadTextures( config.baseUrl + 'skins/', config.skins );
		this.skinsWeapon = loadTextures( config.baseUrl + 'skins/', weaponsTextures );

		// BODY

		var loader = new MD2Loader();

		loader.load( config.baseUrl + config.body, function ( geo ) {

			var boundingBox = new Box3();
			boundingBox.setFromBufferAttribute( geo.attributes.position );

			scope.root.position.y = - scope.scale * boundingBox.min.y;

			var mesh = createPart( geo, scope.skinsBody[ 0 ] );
			mesh.scale.set( scope.scale, scope.scale, scope.scale );

			scope.root.add( mesh );

			scope.meshBody = mesh;

			scope.meshBody.clipOffset = 0;
			scope.activeAnimationClipName = mesh.geometry.animations[ 0 ].name;

			scope.mixer = new AnimationMixer( mesh );

			checkLoadingComplete();

		} );

		// WEAPONS

		var generateCallback = function ( index:Int, name:String ) {

			return function ( geo ) {

				var mesh = createPart( geo, scope.skinsWeapon[ index ] );
				mesh.scale.set( scope.scale, scope.scale, scope.scale );
				mesh.visible = false;

				mesh.name = name;

				scope.root.add( mesh );

				scope.weapons[ index ] = mesh;
				scope.meshWeapon = mesh;

				checkLoadingComplete();

			};

		};

		for ( i in 0...config.weapons.length ) {

			loader.load( config.baseUrl + config.weapons[ i ][ 0 ], generateCallback( i, config.weapons[ i ][ 0 ] ) );

		}

	}

	public function setPlaybackRate( rate:Float ) {

		if ( rate !== 0 ) {

			this.mixer.timeScale = 1 / rate;

		} else {

			this.mixer.timeScale = 0;

		}

	}

	public function setWireframe( wireframeEnabled:Bool ) {

		if ( wireframeEnabled ) {

			if ( this.meshBody ) this.meshBody.material = this.meshBody.materialWireframe;
			if ( this.meshWeapon ) this.meshWeapon.material = this.meshWeapon.materialWireframe;

		} else {

			if ( this.meshBody ) this.meshBody.material = this.meshBody.materialTexture;
			if ( this.meshWeapon ) this.meshWeapon.material = this.meshWeapon.materialTexture;

		}

	}

	public function setSkin( index:Int ) {

		if ( this.meshBody && this.meshBody.material.wireframe === false ) {

			this.meshBody.material.map = this.skinsBody[ index ];

		}

	}

	public function setWeapon( index:Int ) {

		for ( i in 0...this.weapons.length ) this.weapons[ i ].visible = false;

		var activeWeapon = this.weapons[ index ];

		if ( activeWeapon ) {

			activeWeapon.visible = true;
			this.meshWeapon = activeWeapon;

			this.syncWeaponAnimation();

		}

	}

	public function setAnimation( clipName:String ) {

		if ( this.meshBody ) {

			if ( this.meshBody.activeAction ) {

				this.meshBody.activeAction.stop();
				this.meshBody.activeAction = null;

			}

			var action = this.mixer.clipAction( clipName, this.meshBody );

			if ( action ) {

				this.meshBody.activeAction = action.play();

			}

		}

		this.activeClipName = clipName;

		this.syncWeaponAnimation();

	}

	public function syncWeaponAnimation() {

		var clipName = this.activeClipName;

		if ( this.meshWeapon ) {

			if ( this.meshWeapon.activeAction ) {

				this.meshWeapon.activeAction.stop();
				this.meshWeapon.activeAction = null;

			}

			var action = this.mixer.clipAction( clipName, this.meshWeapon );

			if ( action ) {

				this.meshWeapon.activeAction = action.syncWith( this.meshBody.activeAction ).play();

			}

		}

	}

	public function update( delta:Float ) {

		if ( this.mixer ) this.mixer.update( delta );

	}

}