import three.Extensions;
import three.GLTFParser;
import js.lib.Promise;

class GLTFTextureWebPExtension {

	public var parser : GLTFParser;
	public var name : String;
	public var isSupported : Null<Promise<Bool>>;

	public function new( parser : GLTFParser ) {

		this.parser = parser;
		this.name = Extensions.EXT_TEXTURE_WEBP;
		this.isSupported = null;

	}

	public function loadTexture( textureIndex : Int ) : Null<Promise<Dynamic>> {

		var parser = this.parser;
		var json = parser.json;

		var textureDef = json.textures[ textureIndex ];

		if ( textureDef.extensions == null || ! Reflect.hasField(textureDef.extensions, this.name)  ) {

			return null;

		}

		var extension = Reflect.field(textureDef.extensions, this.name);
		var source = json.images[ extension.source ];

		var loader = parser.textureLoader;
		if ( source.uri != null ) {

			var handler = parser.options.manager.getHandler( source.uri );
			if ( handler != null ) loader = handler;

		}

		return this.detectSupport().then( function ( isSupported ) {

			if ( isSupported ) return parser.loadTextureImage( textureIndex, extension.source, loader );

			if ( json.extensionsRequired != null && json.extensionsRequired.indexOf( this.name ) >= 0 ) {

				throw new Error( 'THREE.GLTFLoader: WebP required by asset but unsupported.' );

			}

			// Fall back to PNG or JPEG.
			return parser.loadTexture( textureIndex );

		} );

	}

	public function detectSupport() : Promise<Bool> {

		if ( this.isSupported == null ) {

			this.isSupported = new Promise( function ( resolve ) {

				var image = new js.html.Image();

				// Lossy test image. Support for lossy images doesn't guarantee support for all
				// WebP images, unfortunately.
				image.src = 'data:image/webp;base64,UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA';

				image.onload = image.onerror = function () {

					resolve( image.height == 1 );

				};

			} );

		}

		return this.isSupported;

	}

}