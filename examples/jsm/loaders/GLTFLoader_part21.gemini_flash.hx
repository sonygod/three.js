import three.core.BufferGeometry;
import three.loaders.gltf.GLTFLoaderParser;
import three.loaders.gltf.GLTFUtils;
import three.loaders.DRACOLoader;
import js.lib.Promise;

class GLTFDracoMeshCompressionExtension {

	public static var EXTENSION_NAME = "KHR_draco_mesh_compression";

	private var dracoLoader:DRACOLoader;

	public function new( dracoLoader:DRACOLoader ) {

		if ( dracoLoader == null ) {

			throw "THREE.GLTFLoader: No DRACOLoader instance provided.";

		}

		this.dracoLoader = dracoLoader;
		this.dracoLoader.preload();

	}

	public function decodePrimitive( primitive:Dynamic, parser:GLTFLoaderParser ):Promise<BufferGeometry> {

		var dracoLoader = this.dracoLoader;
		var bufferViewIndex = primitive.extensions[ EXTENSION_NAME ].bufferView;
		var gltfAttributeMap = primitive.extensions[ EXTENSION_NAME ].attributes;
		var threeAttributeMap:Map<String, Int> = new Map();
		var attributeNormalizedMap:Map<String, Bool> = new Map();
		var attributeTypeMap:Map<String, String> = new Map();

		for ( attributeName in GLTFUtils.getKeys( gltfAttributeMap ) ) {

			var threeAttributeName = GLTFUtils.getAttributes()[ attributeName ] != null ? GLTFUtils.getAttributes()[ attributeName ] : attributeName.toLowerCase();

			threeAttributeMap.set( threeAttributeName, gltfAttributeMap[ attributeName ] );

		}

		for ( attributeName in GLTFUtils.getKeys( primitive.attributes ) ) {

			var threeAttributeName = GLTFUtils.getAttributes()[ attributeName ] != null ? GLTFUtils.getAttributes()[ attributeName ] : attributeName.toLowerCase();

			if ( gltfAttributeMap.exists( attributeName ) ) {

				var accessorDef = parser.json.accessors[ primitive.attributes[ attributeName ] ];
				var componentType = GLTFUtils.getWebglComponentTypes()[ accessorDef.componentType ];

				attributeTypeMap.set( threeAttributeName, componentType.name );
				attributeNormalizedMap.set( threeAttributeName, accessorDef.normalized == true );

			}

		}

		return parser.getDependency( 'bufferView', bufferViewIndex ).then( function ( bufferView ) {

			return new Promise( function ( resolve, reject ) {

				dracoLoader.decodeDracoFile( bufferView, function ( geometry:BufferGeometry ) {
					
					for ( attributeName in geometry.attributes.keys() ) {

						var attribute = geometry.attributes.get( attributeName );
						var normalized = attributeNormalizedMap.get( attributeName );

						if ( normalized != null ) {
							attribute.normalized = normalized;
						}

					}

					resolve( geometry );

				}, threeAttributeMap, attributeTypeMap, GLTFUtils.LinearSRGBColorSpace, reject );

			} );

		} );

	}

}