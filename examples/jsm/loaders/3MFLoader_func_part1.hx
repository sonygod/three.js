import three.math._Vector3;
import three.math._Matrix4;
import three.math._Quaternion;
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.textures.Texture;
import three.textures.TextureLoader;
import three.materials.MeshPhongMaterial;
import three.materials.MeshStandardMaterial;
import three.objects.Group;
import three.objects.Mesh;
import three.scene.Scene;
import js.Lib;
import js.Browser;
import js.flash.System;
import js.typedarrays.Float32Array;
import js.typedarrays.Uint32Array;
class ThreeMFLoader extends three.loaders.Loader {

	static COLOR_SPACE_3MF:three.SRGBColorSpace = three.SRGBColorSpace;

	private static _3MF_METADATA_NAMES:Array<String> = [
		"Title",
		"Designer",
		"Description",
		"Copyright",
		"LicenseTerms",
		"Rating",
		"CreationDate",
		"ModificationDate"
	];

	private static _threeMFMaterials:Array<Dynamic> = [
		three.materials.MeshPhongMaterial,
		three.materials.MeshStandardMaterial
	];

	public manager:three.loaders.LoadingManager;
	private availableExtensions:Array<Dynamic>;

	constructor() {
		super();
		this.availableExtensions = [];
	}

	load(url:String, onLoad:(data:Dynamic)=>Void, onProgress:(event:Dynamic)=>Void, onError:(event:Dynamic)=>Void):Void {
		const scope = this;
		const loader = new three.loaders.FileLoader( scope.manager );
		loader.setPath( scope.path );
		loader.setResponseType( 'arraybuffer' );
		loader.setRequestHeader( scope.requestHeader );
		loader.setWithCredentials( scope.withCredentials );
		loader.load( url, function ( buffer ) {
			try {
				onLoad( scope.parse( buffer ) );
			} catch ( e ) {
				if ( onError ) {
					onError( e );
				} else {
					trace( e );
				}
				scope.manager.itemError( url );
			}
		}, onProgress, onError );
	}

	parse(data:ArrayBuffer):Dynamic {
		const scope = this;
		const textureLoader = new three.loaders.TextureLoader( this.manager );

		function loadDocument( data ) {

			let zip = null;
			let file = null;

			let relsName:String;
			let modelRelsName:String;
			const modelPartNames:Array<String> = [];
			const texturesPartNames:Array<String> = [];

			let modelRels:Array<Dynamic>;
			const modelParts:Object = {};
			const printTicketParts:Object = {};
			const texturesParts:Object = {};

			const textDecoder = new TextDecoder();

			try {

				zip = fflate.unzipSync( new Uint8Array( data ) );

			} catch ( e ) {

				if ( e instanceof ReferenceError ) {

					trace( "THREE.3MFLoader: fflate missing and file is compressed." );
					return null;

				}

			}

			for ( file in zip ) {

				if ( file.match( /\_rels\/.rels$/ ) ) {

					relsName = file;

				} else if ( file.match( /3D\/_rels\/.*\.model\.rels$/ ) ) {

					modelRelsName = file;

				} else if ( file.match( /^3D\/.*\.model$/ ) ) {

					modelPartNames.push( file );

				} else if ( file.match( /^3D\/Textures?\/.*/ ) ) {

					texturesPartNames.push( file );

				}

			}

			if ( relsName === undefined ) throw new Error( "THREE.ThreeMFLoader: Cannot find relationship file `rels` in 3MF archive." );

			//

			const relsView = zip[ relsName ];
			const relsFileText = textDecoder.decode( relsView );
			const rels = parseRelsXml( relsFileText );

			//

			if ( modelRelsName ) {

				const relsView = zip[ modelRelsName ];
				const relsFileText = textDecoder.decode( relsView );
				modelRels = parseRelsXml( relsFileText );

			}

			//

			for ( let i = 0; i < modelPartNames.length; i ++ ) {

				const modelPart = modelPartNames[ i ];
				const view = zip[ modelPart ];

				const fileText = textDecoder.decode( view );
				const xmlData = new DOMParser().parseFromString( fileText, 'application/xml' );

				if ( xmlData.documentElement.nodeName.toLowerCase() !== 'model' ) {

					trace( "THREE.3MFLoader: Error loading 3MF - no 3MF document found: ", modelPart );

				}

				const modelNode = xmlData.querySelector( 'model' );
				const extensions = {};

				for ( let i = 0; i < modelNode.attributes.length; i ++ ) {

					const attr = modelNode.attributes[ i ];
					if ( attr.name.match( /^xmlns:(.+)$/ ) ) {

						extensions[ attr.value ] = RegExp.$1;

					}

				}

				const modelData = parseModelNode( modelNode );
				modelData[ 'xml' ] = modelNode;

				if ( 0 < Object.keys( extensions ).length ) {

					modelData[ 'extensions' ] = extensions;

				}

				modelParts[ modelPart ] = modelData;

			}

			//

			for ( let i = 0; i < texturesPartNames.length; i ++ ) {

				const texturesPartName = texturesPartNames[ i ];
				texturesParts[ texturesPartName ] = zip[ texturesPartName ].buffer;

			}

			return {
				rels: rels,
				modelRels: modelRels,
				model: modelParts,
				printTicket: printTicketParts,
				texture: texturesParts
			};

		}

		function parseRelsXml( relsFileText:String ):Array<Dynamic> {

			const relationships:Array<Dynamic> = [];

			const relsXmlData = new DOMParser().parseFromString( relsFileText, 'application/xml' );

			const relsNodes = relsXmlData.querySelectorAll( 'Relationship' );

			for ( let i = 0; i < relsNodes.length; i ++ ) {

				const relsNode = relsNodes[ i ];

				const relationship = {
					target: relsNode.getAttribute( 'Target' ), //required
					id: relsNode.getAttribute( 'Id' ), //required
					type: relsNode.getAttribute( 'Type' ) //required
				};

				relationships.push( relationship );

			}

			return relationships;

		}

		function parseMetadataNodes( metadataNodes:NodeList ):Object {

			const metadataData:Object = {};

			for ( let i = 0; i < metadataNodes.length; i ++ ) {

				const metadataNode = metadataNodes[ i ];
				const name = metadataNode.getAttribute( 'name' );

				if ( ThreeMFLoader._3MF_METADATA_NAMES.indexOf( name ) > -1 ) {

					metadataData[ name ] = metadataNode.textContent;

				}

			}

			return metadataData;

		}

		function parseBasematerialsNode( basematerialsNode:Element ):Object {

			const basematerialsData:Object = {
				id: basematerialsNode.getAttribute( 'id' ), // required
				basematerials: []
			};

			const basematerialNodes = basematerialsNode.querySelectorAll( 'base' );

			for ( let i = 0; i < basematerialNodes.length; i ++ ) {

				const basematerialNode = basematerialNodes[ i ];
				const basematerialData = parseBasematerialNode( basematerialNode );
				basematerialData.index = i; // the order and count of the material nodes form an implicit 0-based index
				basematerialsData.basematerials.push( basematerialData );

			}

			return basematerialsData;

		}

		function parseTexture2DNode( texture2DNode:Element ):Object {

			const texture2dData:Object = {
				id: texture2DNode.getAttribute( 'id' ), // required
				path: texture2DNode.getAttribute( 'path' ), // required
				contenttype: texture2DNode.getAttribute( 'contenttype' ), // required
				tilestyleu: texture2DNode.getAttribute( 'tilestyleu' ),
				tilestylev: texture2DNode.getAttribute( 'tilestylev' ),
				filter: texture2DNode.getAttribute( 'filter' ),
			};

			return texture2dData;

		}

		function parseTextures2DGroupNode( texture2DGroupNode:Element ):Object {

			const texture2DGroupData:Object = {
				id: texture2DGroupNode.getAttribute( 'id' ), // required
				texid: texture2DGroupNode.getAttribute( 'texid' ), // required
				displaypropertiesid: texture2DGroupNode.getAttribute( 'displaypropertiesid' ),
			};

			const tex2coordNodes = texture2DGroupNode.querySelectorAll( 'tex2coord' );

			const uvs:Array<Float> = [];

			for ( let i = 0; i < tex2coordNodes.length; i ++ ) {

				const tex2coordNode = tex2coordNodes[ i ];
				const u = parseFloat( tex2coordNode.getAttribute( 'u' ) );
				const v = parseFloat( tex2coordNode.getAttribute( 'v' ) );

				uvs.push( u, v );

			}

			texture2DGroupData[ 'uvs' ] = new Float32Array( uvs );

			return texture2DGroupData;

		}

		function parseColorGroupNode( colorGroupNode:Element ):Object {

			const colorGroupData:Object = {
				id: colorGroupNode.getAttribute( 'id' ), // required
				displaypropertiesid: colorGroupNode.getAttribute( 'displaypropertiesid' )
			};

			const colorNodes = colorGroupNode.querySelectorAll( 'color' );

			const colors:Array<Float> = [];
			const colorObject = new three.math._Color();

			for ( let i = 0; i < colorNodes.length; i ++ ) {

				const colorNode = colorNodes[ i ];
				const color = colorNode.getAttribute( 'color' );

				colorObject.setStyle( color.substring( 0, 7 ), ThreeMFLoader.COLOR_SPACE_3MF );

				colors.push( colorObject.r, colorObject.g, colorObject.b );

			}

			colorGroupData[ 'colors' ] = new Float32Array( colors );

			return colorGroupData;

		}

		function parseMetallicDisplaypropertiesNode( metallicDisplaypropetiesNode:Element ):Object {

			const metallicDisplaypropertiesData:Object = {
				id: metallicDisplaypropetiesNode.getAttribute( 'id' ) // required
			};

			const metallicNodes = metallicDisplaypropetiesNode.querySelectorAll( 'pbmetallic' );

			const metallicData:Array<Dynamic> = [];

			for ( let i = 0; i < metallicNodes.length; i ++ ) {

				const metallicNode = metallicNodes[ i ];

				metallicData.push( {
					name: metallicNode.getAttribute( 'name' ), // required
					metallicness: parseFloat( metallicNode.getAttribute( 'metallicness' ) ), // required
					roughness: parseFloat( metallicNode.getAttribute( 'roughness' ) ) // required
				} );

			}

			metallicDisplaypropertiesData.data = metallicData;

			return metallicDisplaypropertiesData;

		}

		function parseBasematerialNode( basematerialNode:Element ):Object {

			const basematerialData:Object = {};

			basematerialData[ 'name' ] = basematerialNode.getAttribute( 'name' ); // required
			basematerialData[ 'displaycolor' ] = basematerialNode.getAttribute( 'displaycolor' ); // required
			basematerialData[ 'displaypropertiesid' ] = basematerialNode.getAttribute( 'displaypropertiesid' );

			return basematerialData;

		}

		function parseMeshNode( meshNode:Element ):Object {

			const meshData:Object = {
				vertices: [],
				triangleProperties: []
			};

			const vertices = [];
			const vertexNodes = meshNode.querySelectorAll( 'vertices vertex' );

			for ( let i = 0; i < vertexNodes.length; i ++ ) {

				const vertexNode = vertexNodes[ i ];
				const x = vertexNode.getAttribute( 'x' );
				const y = vertexNode.getAttribute( 'y' );
				const z = vertexNode.getAttribute( 'z' );

				vertices.push( parseFloat( x ), parseFloat( y ), parseFloat( z ) );

			}

			meshData[ 'vertices' ] = new Float32Array( vertices );

			const triangleProperties = [];
			const triangles = [];
			const triangleNodes = meshNode.querySelectorAll( 'triangles triangle' );

			for ( let i = 0; i < triangleNodes.length; i ++ ) {

				const triangleNode = triangleNodes[ i ];
				const v1 = triangleNode.getAttribute( 'v1' );
				const v2 = triangleNode.getAttribute( 'v2' );
				const v3 = triangleNode.getAttribute( 'v3' );
				const p1 = triangleNode.getAttribute( 'p1' );
				const p2 = triangleNode.getAttribute( 'p2' );
				const p3 = triangleNode.getAttribute( 'p3' );
				const pid = triangleNode.getAttribute( 'pid' );

				const triangleProperty = {};

				triangleProperty[ 'v1' ] = parseInt( v1 );
				triangleProperty[ 'v2' ] = parseInt( v2 );
				triangleProperty[ 'v3' ] = parseInt( v3 );
				triangleProperties.push( triangleProperty );

				// optional

				if ( p1 !== null ) {

					triangleProperty[ 'p1' ] = parseInt( p1 );

				}

				if ( p2 !== null ) {

					triangleProperty[ 'p2' ] =