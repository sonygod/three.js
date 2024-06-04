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

	public var scale:Float = 1;
	public var animationFPS:Int = 6;

	public var root:Object3D;

	public var meshBody:Mesh = null;
	public var meshWeapon:Mesh = null;

	public var skinsBody:Array<three.Texture> = [];
	public var skinsWeapon:Array<three.Texture> = [];

	public var weapons:Array<Mesh> = [];

	public var activeAnimation:String = null;

	public var mixer:AnimationMixer = null;

	public var onLoadComplete:Void->Void = function () {};

	public var loadCounter:Int = 0;

	public function new() {
		this.root = new Object3D();
	}

	public function loadParts( config:Dynamic ) {
		var scope = this;

		function createPart( geometry:Dynamic, skinMap:three.Texture ):Mesh {
			var materialWireframe = new MeshLambertMaterial( { color: 0xffaa00, wireframe: true } );
			var materialTexture = new MeshLambertMaterial( { color: 0xffffff, wireframe: false, map: skinMap } );

			var mesh = new Mesh( geometry, materialTexture );
			mesh.rotation.y = - Math.PI / 2;

			mesh.castShadow = true;
			mesh.receiveShadow = true;

			mesh.materialTexture = materialTexture;
			mesh.materialWireframe = materialWireframe;

			return mesh;
		}

		function loadTextures( baseUrl:String, textureUrls:Array<String> ):Array<three.Texture> {
			var textureLoader = new TextureLoader();
			var textures:Array<three.Texture> = [];

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

			if ( scope.loadCounter == 0 ) scope.onLoadComplete();
		}

		this.loadCounter = config.weapons.length * 2 + config.skins.length + 1;

		var weaponsTextures:Array<String> = [];
		for ( i in 0...config.weapons.length ) weaponsTextures[ i ] = config.weapons[ i ][ 1 ];
		// SKINS

		this.skinsBody = loadTextures( config.baseUrl + 'skins/', config.skins );
		this.skinsWeapon = loadTextures( config.baseUrl + 'skins/', weaponsTextures );

		// BODY

		var loader = new MD2Loader();

		loader.load( config.baseUrl + config.body, function ( geo:Dynamic ) {
			var boundingBox = new Box3();
			boundingBox.setFromBufferAttribute( geo.attributes.position );

			scope.root.position.y = - scope.scale * boundingBox.min.y;

			var mesh = createPart( geo, scope.skinsBody[ 0 ] );
			mesh.scale.set( scope.scale, scope.scale, scope.scale );

			scope.root.add( mesh );

			scope.meshBody = mesh;

			scope.meshBody.clipOffset = 0;
			scope.activeAnimation = mesh.geometry.animations[ 0 ].name;

			scope.mixer = new AnimationMixer( mesh );

			checkLoadingComplete();
		} );

		// WEAPONS

		var generateCallback = function ( index:Int, name:String ):Dynamic->Void {
			return function ( geo:Dynamic ) {
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
		if ( rate != 0 ) {
			this.mixer.timeScale = 1 / rate;
		} else {
			this.mixer.timeScale = 0;
		}
	}

	public function setWireframe( wireframeEnabled:Bool ) {
		if ( wireframeEnabled ) {
			if ( this.meshBody != null ) this.meshBody.material = this.meshBody.materialWireframe;
			if ( this.meshWeapon != null ) this.meshWeapon.material = this.meshWeapon.materialWireframe;
		} else {
			if ( this.meshBody != null ) this.meshBody.material = this.meshBody.materialTexture;
			if ( this.meshWeapon != null ) this.meshWeapon.material = this.meshWeapon.materialTexture;
		}
	}

	public function setSkin( index:Int ) {
		if ( this.meshBody != null && this.meshBody.material.wireframe == false ) {
			this.meshBody.material.map = this.skinsBody[ index ];
		}
	}

	public function setWeapon( index:Int ) {
		for ( i in 0...this.weapons.length ) this.weapons[ i ].visible = false;

		var activeWeapon = this.weapons[ index ];

		if ( activeWeapon != null ) {
			activeWeapon.visible = true;
			this.meshWeapon = activeWeapon;

			this.syncWeaponAnimation();
		}
	}

	public function setAnimation( clipName:String ) {
		if ( this.meshBody != null ) {
			if ( this.meshBody.activeAction != null ) {
				this.meshBody.activeAction.stop();
				this.meshBody.activeAction = null;
			}

			var action = this.mixer.clipAction( clipName, this.meshBody );

			if ( action != null ) {
				this.meshBody.activeAction = action.play();
			}
		}

		this.activeAnimation = clipName;

		this.syncWeaponAnimation();
	}

	public function syncWeaponAnimation() {
		var clipName = this.activeAnimation;

		if ( this.meshWeapon != null ) {
			if ( this.meshWeapon.activeAction != null ) {
				this.meshWeapon.activeAction.stop();
				this.meshWeapon.activeAction = null;
			}

			var action = this.mixer.clipAction( clipName, this.meshWeapon );

			if ( action != null ) {
				this.meshWeapon.activeAction = action.syncWith( this.meshBody.activeAction ).play();
			}
		}
	}

	public function update( delta:Float ) {
		if ( this.mixer != null ) this.mixer.update( delta );
	}

}