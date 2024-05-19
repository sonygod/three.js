class FBXTreeParser {

	constructor( textureLoader, manager ) {

		this.textureLoader = textureLoader;
		this.manager = manager;

	}
parse() {

		connections = this.parseConnections();

		const images = this.parseImages();
		const textures = this.parseTextures( images );
		const materials = this.parseMaterials( textures );
		const deformers = this.parseDeformers();
		const geometryMap = new GeometryParser().parse( deformers );

		this.parseScene( deformers, geometryMap, materials );

		return sceneGraph;

	}
parseConnections() {

		const connectionMap = new Map();

		if ( 'Connections' in fbxTree ) {

			const rawConnections = fbxTree.Connections.connections;

			rawConnections.forEach( function ( rawConnection ) {

				const fromID = rawConnection[ 0 ];
				const toID = rawConnection[ 1 ];
				const relationship = rawConnection[ 2 ];

				if ( ! connectionMap.has( fromID ) ) {

					connectionMap.set( fromID, {
						parents: [],
						children: []
					} );

				}

				const parentRelationship = { ID: toID, relationship: relationship };
				connectionMap.get( fromID ).parents.push( parentRelationship );

				if ( ! connectionMap.has( toID ) ) {

					connectionMap.set( toID, {
						parents: [],
						children: []
					} );

				}

				const childRelationship = { ID: fromID, relationship: relationship };
				connectionMap.get( toID ).children.push( childRelationship );

			} );

		}

		return connectionMap;

	}
parseImages() {

		const images = {};
		const blobs = {};

		if ( 'Video' in fbxTree.Objects ) {

			const videoNodes = fbxTree.Objects.Video;

			for ( const nodeID in videoNodes ) {

				const videoNode = videoNodes[ nodeID ];

				const id = parseInt( nodeID );

				images[ id ] = videoNode.RelativeFilename || videoNode.Filename;

				// raw image data is in videoNode.Content
				if ( 'Content' in videoNode ) {

					const arrayBufferContent = ( videoNode.Content instanceof ArrayBuffer ) && ( videoNode.Content.byteLength > 0 );
					const base64Content = ( typeof videoNode.Content === 'string' ) && ( videoNode.Content !== '' );

					if ( arrayBufferContent || base64Content ) {

						const image = this.parseImage( videoNodes[ nodeID ] );

						blobs[ videoNode.RelativeFilename || videoNode.Filename ] = image;

					}

				}

			}

		}

		for ( const id in images ) {

			const filename = images[ id ];

			if ( blobs[ filename ] !== undefined ) images[ id ] = blobs[ filename ];
			else images[ id ] = images[ id ].split( '\\' ).pop();

		}

		return images;

	}
parseImage( videoNode ) {

		const content = videoNode.Content;
		const fileName = videoNode.RelativeFilename || videoNode.Filename;
		const extension = fileName.slice( fileName.lastIndexOf( '.' ) + 1 ).toLowerCase();

		let type;

		switch ( extension ) {

			case 'bmp':

				type = 'image/bmp';
				break;

			case 'jpg':
			case 'jpeg':

				type = 'image/jpeg';
				break;

			case 'png':

				type = 'image/png';
				break;

			case 'tif':

				type = 'image/tiff';
				break;

			case 'tga':

				if ( this.manager.getHandler( '.tga' ) === null ) {

					console.warn( 'FBXLoader: TGA loader not found, skipping ', fileName );

				}

				type = 'image/tga';
				break;

			default:

				console.warn( 'FBXLoader: Image type "' + extension + '" is not supported.' );
				return;

		}

		if ( typeof content === 'string' ) { // ASCII format

			return 'data:' + type + ';base64,' + content;

		} else { // Binary Format

			const array = new Uint8Array( content );
			return window.URL.createObjectURL( new Blob( [ array ], { type: type } ) );

		}

	}
parseTextures( images ) {

		const textureMap = new Map();

		if ( 'Texture' in fbxTree.Objects ) {

			const textureNodes = fbxTree.Objects.Texture;
			for ( const nodeID in textureNodes ) {

				const texture = this.parseTexture( textureNodes[ nodeID ], images );
				textureMap.set( parseInt( nodeID ), texture );

			}

		}

		return textureMap;

	}
parseTexture( textureNode, images ) {

		const texture = this.loadTexture( textureNode, images );

		texture.ID = textureNode.id;

		texture.name = textureNode.attrName;

		const wrapModeU = textureNode.WrapModeU;
		const wrapModeV = textureNode.WrapModeV;

		const valueU = wrapModeU !== undefined ? wrapModeU.value : 0;
		const valueV = wrapModeV !== undefined ? wrapModeV.value : 0;

		// http://download.autodesk.com/us/fbx/SDKdocs/FBX_SDK_Help/files/fbxsdkref/class_k_fbx_texture.html#889640e63e2e681259ea81061b85143a
		// 0: repeat(default), 1: clamp

		texture.wrapS = valueU === 0 ? RepeatWrapping : ClampToEdgeWrapping;
		texture.wrapT = valueV === 0 ? RepeatWrapping : ClampToEdgeWrapping;

		if ( 'Scaling' in textureNode ) {

			const values = textureNode.Scaling.value;

			texture.repeat.x = values[ 0 ];
			texture.repeat.y = values[ 1 ];

		}

		if ( 'Translation' in textureNode ) {

			const values = textureNode.Translation.value;

			texture.offset.x = values[ 0 ];
			texture.offset.y = values[ 1 ];

		}

		return texture;

	}
loadTexture( textureNode, images ) {

		let fileName;

		const currentPath = this.textureLoader.path;

		const children = connections.get( textureNode.id ).children;

		if ( children !== undefined && children.length > 0 && images[ children[ 0 ].ID ] !== undefined ) {

			fileName = images[ children[ 0 ].ID ];

			if ( fileName.indexOf( 'blob:' ) === 0 || fileName.indexOf( 'data:' ) === 0 ) {

				this.textureLoader.setPath( undefined );

			}

		}

		let texture;

		const extension = textureNode.FileName.slice( - 3 ).toLowerCase();

		if ( extension === 'tga' ) {

			const loader = this.manager.getHandler( '.tga' );

			if ( loader === null ) {

				console.warn( 'FBXLoader: TGA loader not found, creating placeholder texture for', textureNode.RelativeFilename );
				texture = new Texture();

			} else {

				loader.setPath( this.textureLoader.path );
				texture = loader.load( fileName );

			}

		} else if ( extension === 'dds' ) {

			const loader = this.manager.getHandler( '.dds' );

			if ( loader === null ) {

				console.warn( 'FBXLoader: DDS loader not found, creating placeholder texture for', textureNode.RelativeFilename );
				texture = new Texture();

			} else {

				loader.setPath( this.textureLoader.path );
				texture = loader.load( fileName );

			}

		} else if ( extension === 'psd' ) {

			console.warn( 'FBXLoader: PSD textures are not supported, creating placeholder texture for', textureNode.RelativeFilename );
			texture = new Texture();

		} else {

			texture = this.textureLoader.load( fileName );

		}

		this.textureLoader.setPath( currentPath );

		return texture;

	}
parseMaterials( textureMap ) {

		const materialMap = new Map();

		if ( 'Material' in fbxTree.Objects ) {

			const materialNodes = fbxTree.Objects.Material;

			for ( const nodeID in materialNodes ) {

				const material = this.parseMaterial( materialNodes[ nodeID ], textureMap );

				if ( material !== null ) materialMap.set( parseInt( nodeID ), material );

			}

		}

		return materialMap;

	}
parseMaterial( materialNode, textureMap ) {

		const ID = materialNode.id;
		const name = materialNode.attrName;
		let type = materialNode.ShadingModel;

		// Case where FBX wraps shading model in property object.
		if ( typeof type === 'object' ) {

			type = type.value;

		}

		// Ignore unused materials which don't have any connections.
		if ( ! connections.has( ID ) ) return null;

		const parameters = this.parseParameters( materialNode, textureMap, ID );

		let material;

		switch ( type.toLowerCase() ) {

			case 'phong':
				material = new MeshPhongMaterial();
				break;
			case 'lambert':
				material = new MeshLambertMaterial();
				break;
			default:
				console.warn( 'THREE.FBXLoader: unknown material type "%s". Defaulting to MeshPhongMaterial.', type );
				material = new MeshPhongMaterial();
				break;

		}

		material.setValues( parameters );
		material.name = name;

		return material;

	}
parseParameters( materialNode, textureMap, ID ) {

		const parameters = {};

		if ( materialNode.BumpFactor ) {

			parameters.bumpScale = materialNode.BumpFactor.value;

		}

		if ( materialNode.Diffuse ) {

			parameters.color = new Color().fromArray( materialNode.Diffuse.value ).convertSRGBToLinear();

		} else if ( materialNode.DiffuseColor && ( materialNode.DiffuseColor.type === 'Color' || materialNode.DiffuseColor.type === 'ColorRGB' ) ) {

			// The blender exporter exports diffuse here instead of in materialNode.Diffuse
			parameters.color = new Color().fromArray( materialNode.DiffuseColor.value ).convertSRGBToLinear();

		}

		if ( materialNode.DisplacementFactor ) {

			parameters.displacementScale = materialNode.DisplacementFactor.value;

		}

		if ( materialNode.Emissive ) {

			parameters.emissive = new Color().fromArray( materialNode.Emissive.value ).convertSRGBToLinear();

		} else if ( materialNode.EmissiveColor && ( materialNode.EmissiveColor.type === 'Color' || materialNode.EmissiveColor.type === 'ColorRGB' ) ) {

			// The blender exporter exports emissive color here instead of in materialNode.Emissive
			parameters.emissive = new Color().fromArray( materialNode.EmissiveColor.value ).convertSRGBToLinear();

		}

		if ( materialNode.EmissiveFactor ) {

			parameters.emissiveIntensity = parseFloat( materialNode.EmissiveFactor.value );

		}

		if ( materialNode.Opacity ) {

			parameters.opacity = parseFloat( materialNode.Opacity.value );

		}

		if ( parameters.opacity < 1.0 ) {

			parameters.transparent = true;

		}

		if ( materialNode.ReflectionFactor ) {

			parameters.reflectivity = materialNode.ReflectionFactor.value;

		}

		if ( materialNode.Shininess ) {

			parameters.shininess = materialNode.Shininess.value;

		}

		if ( materialNode.Specular ) {

			parameters.specular = new Color().fromArray( materialNode.Specular.value ).convertSRGBToLinear();

		} else if ( materialNode.SpecularColor && materialNode.SpecularColor.type === 'Color' ) {

			// The blender exporter exports specular color here instead of in materialNode.Specular
			parameters.specular = new Color().fromArray( materialNode.SpecularColor.value ).convertSRGBToLinear();

		}

		const scope = this;
		connections.get( ID ).children.forEach( function ( child ) {

			const type = child.relationship;

			switch ( type ) {

				case 'Bump':
					parameters.bumpMap = scope.getTexture( textureMap, child.ID );
					break;

				case 'Maya|TEX_ao_map':
					parameters.aoMap = scope.getTexture( textureMap, child.ID );
					break;

				case 'DiffuseColor':
				case 'Maya|TEX_color_map':
					parameters.map = scope.getTexture( textureMap, child.ID );
					if ( parameters.map !== undefined ) {

						parameters.map.colorSpace = SRGBColorSpace;

					}

					break;

				case 'DisplacementColor':
					parameters.displacementMap = scope.getTexture( textureMap, child.ID );
					break;

				case 'EmissiveColor':
					parameters.emissiveMap = scope.getTexture( textureMap, child.ID );
					if ( parameters.emissiveMap !== undefined ) {

						parameters.emissiveMap.colorSpace = SRGBColorSpace;

					}

					break;

				case 'NormalMap':
				case 'Maya|TEX_normal_map':
					parameters.normalMap = scope.getTexture( textureMap, child.ID );
					break;

				case 'ReflectionColor':
					parameters.envMap = scope.getTexture( textureMap, child.ID );
					if ( parameters.envMap !== undefined ) {

						parameters.envMap.mapping = EquirectangularReflectionMapping;
						parameters.envMap.colorSpace = SRGBColorSpace;

					}

					break;

				case 'SpecularColor':
					parameters.specularMap = scope.getTexture( textureMap, child.ID );
					if ( parameters.specularMap !== undefined ) {

						parameters.specularMap.colorSpace = SRGBColorSpace;

					}

					break;

				case 'TransparentColor':
				case 'TransparencyFactor':
					parameters.alphaMap = scope.getTexture( textureMap, child.ID );
					parameters.transparent = true;
					break;

				case 'AmbientColor':
				case 'ShininessExponent': // AKA glossiness map
				case 'SpecularFactor': // AKA specularLevel
				case 'VectorDisplacementColor': // NOTE: Seems to be a copy of DisplacementColor
				default:
					console.warn( 'THREE.FBXLoader: %s map is not supported in three.js, skipping texture.', type );
					break;

			}

		} );

		return parameters;

	}