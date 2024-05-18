class MaterialParser {

	constructor( textureLoader ) {

		this.textureLoader = textureLoader;

	}

	parse() {

		const materials = [];
		this.textures = {};

		for ( const name in _lwoTree.materials ) {

			if ( _lwoTree.format === 'LWO3' ) {

				materials.push( this.parseMaterial( _lwoTree.materials[ name ], name, _lwoTree.textures ) );

			} else if ( _lwoTree.format === 'LWO2' ) {

				materials.push( this.parseMaterialLwo2( _lwoTree.materials[ name ], name, _lwoTree.textures ) );

			}

		}

		return materials;

	}

	parseMaterial( materialData, name, textures ) {

		let params = {
			name: name,
			side: this.getSide( materialData.attributes ),
			flatShading: this.getSmooth( materialData.attributes ),
		};

		const connections = this.parseConnections( materialData.connections, materialData.nodes );

		const maps = this.parseTextureNodes( connections.maps );

		this.parseAttributeImageMaps( connections.attributes, textures, maps, materialData.maps );

		const attributes = this.parseAttributes( connections.attributes, maps );

		this.parseEnvMap( connections, maps, attributes );

		params = Object.assign( maps, params );
		params = Object.assign( params, attributes );

		const materialType = this.getMaterialType( connections.attributes );

		if ( materialType !== MeshPhongMaterial ) delete params.refractionRatio; // PBR materials do not support "refractionRatio"

		return new materialType( params );

	}

	parseMaterialLwo2( materialData, name/*, textures*/ ) {

		let params = {
			name: name,
			side: this.getSide( materialData.attributes ),
			flatShading: this.getSmooth( materialData.attributes ),
		};

		const attributes = this.parseAttributes( materialData.attributes, {} );
		params = Object.assign( params, attributes );
		return new MeshPhongMaterial( params );

	}

	// Note: converting from left to right handed coords by switching x -> -x in vertices, and
	// then switching mat FrontSide -> BackSide
	// NB: this means that FrontSide and BackSide have been switched!
	getSide( attributes ) {

		if ( ! attributes.side ) return BackSide;

		switch ( attributes.side ) {

			case 0:
			case 1:
				return BackSide;
			case 2: return FrontSide;
			case 3: return DoubleSide;

		}

	}

	getSmooth( attributes ) {

		if ( ! attributes.smooth ) return true;
		return ! attributes.smooth;

	}

	parseConnections( connections, nodes ) {

		const materialConnections = {
			maps: {}
		};

		const inputName = connections.inputName;
		const inputNodeName = connections.inputNodeName;
		const nodeName = connections.nodeName;

		const scope = this;
		inputName.forEach( function ( name, index ) {

			if ( name === 'Material' ) {

				const matNode = scope.getNodeByRefName( inputNodeName[ index ], nodes );
				materialConnections.attributes = matNode.attributes;
				materialConnections.envMap = matNode.fileName;
				materialConnections.name = inputNodeName[ index ];

			}

		} );

		nodeName.forEach( function ( name, index ) {

			if ( name === materialConnections.name ) {

				materialConnections.maps[ inputName[ index ] ] = scope.getNodeByRefName( inputNodeName[ index ], nodes );

			}

		} );

		return materialConnections;

	}

	getNodeByRefName( refName, nodes ) {

		for ( const name in nodes ) {

			if ( nodes[ name ].refName === refName ) return nodes[ name ];

		}

	}

	parseTextureNodes( textureNodes ) {

		const maps = {};

		for ( const name in textureNodes ) {

			const node = textureNodes[ name ];
			const path = node.fileName;

			if ( ! path ) return;

			const texture = this.loadTexture( path );

			if ( node.widthWrappingMode !== undefined ) texture.wrapS = this.getWrappingType( node.widthWrappingMode );
			if ( node.heightWrappingMode !== undefined ) texture.wrapT = this.getWrappingType( node.heightWrappingMode );

			switch ( name ) {

				case 'Color':
					maps.map = texture;
					maps.map.colorSpace = SRGBColorSpace;
					break;
				case 'Roughness':
					maps.roughnessMap = texture;
					maps.roughness = 1;
					break;
				case 'Specular':
					maps.specularMap = texture;
					maps.specularMap.colorSpace = SRGBColorSpace;
					maps.specular = 0xffffff;
					break;
				case 'Luminous':
					maps.emissiveMap = texture;
					maps.emissiveMap.colorSpace = SRGBColorSpace;
					maps.emissive = 0x808080;
					break;
				case 'Luminous Color':
					maps.emissive = 0x808080;
					break;
				case 'Metallic':
					maps.metalnessMap = texture;
					maps.metalness = 1;
					break;
				case 'Transparency':
				case 'Alpha':
					maps.alphaMap = texture;
					maps.transparent = true;
					break;
				case 'Normal':
					maps.normalMap = texture;
					if ( node.amplitude !== undefined ) maps.normalScale = new Vector2( node.amplitude, node.amplitude );
					break;
				case 'Bump':
					maps.bumpMap = texture;
					break;

			}

		}

		// LWO BSDF materials can have both spec and rough, but this is not valid in three
		if ( maps.roughnessMap && maps.specularMap ) delete maps.specularMap;

		return maps;

	}

	// maps can also be defined on individual material attributes, parse those here
	// This occurs on Standard (Phong) surfaces
	parseAttributeImageMaps( attributes, textures, maps ) {

		for ( const name in attributes ) {

			const attribute = attributes[ name ];

			if ( attribute.maps ) {

				const mapData = attribute.maps[ 0 ];

				const path = this.getTexturePathByIndex( mapData.imageIndex, textures );
				if ( ! path ) return;

				const texture = this.loadTexture( path );

				if ( mapData.wrap !== undefined ) texture.wrapS = this.getWrappingType( mapData.wrap.w );
				if ( mapData.wrap !== undefined ) texture.wrapT = this.getWrappingType( mapData.wrap.h );

				switch ( name ) {

					case 'Color':
						maps.map = texture;
						maps.map.colorSpace = SRGBColorSpace;
						break;
					case 'Diffuse':
						maps.aoMap = texture;
						break;
					case 'Roughness':
						maps.roughnessMap = texture;
						maps.roughness = 1;
						break;
					case 'Specular':
						maps.specularMap = texture;
						maps.specularMap.colorSpace = SRGBColorSpace;
						maps.specular = 0xffffff;
						break;
					case 'Luminosity':
						maps.emissiveMap = texture;
						maps.emissiveMap.colorSpace = SRGBColorSpace;
						maps.emissive = 0x808080;
						break;
					case 'Metallic':
						maps.metalnessMap = texture;
						maps.metalness = 1;
						break;
					case 'Transparency':
					case 'Alpha':
						maps.alphaMap = texture;
						maps.transparent = true;
						break;
					case 'Normal':
						maps.normalMap = texture;
						break;
					case 'Bump':
						maps.bumpMap = texture;
						break;

				}

			}

		}

	}

	parseAttributes( attributes, maps ) {

		const params = {};

		// don't use color data if color map is present
		if ( attributes.Color && ! maps.map ) {

			params.color = new Color().fromArray( attributes.Color.value );

		} else {

			params.color = new Color();

		}


		if ( attributes.Transparency && attributes.Transparency.value !== 0 ) {

			params.opacity = 1 - attributes.Transparency.value;
			params.transparent = true;

		}

		if ( attributes[ 'Bump Height' ] ) params.bumpScale = attributes[ 'Bump Height' ].value * 0.1;

		this.parsePhysicalAttributes( params, attributes, maps );
		this.parseStandardAttributes( params, attributes, maps );
		this.parsePhongAttributes( params, attributes, maps );

		return params;

	}

	parsePhysicalAttributes( params, attributes/*, maps*/ ) {

		if ( attributes.Clearcoat && attributes.Clearcoat.value > 0 ) {

			params.clearcoat = attributes.Clearcoat.value;

			if ( attributes[ 'Clearcoat Gloss' ] ) {

				params.clearcoatRoughness = 0.5 * ( 1 - attributes[ 'Clearcoat Gloss' ].value );

			}

		}

	}

	parseStandardAttributes( params, attributes, maps ) {


		if ( attributes.Luminous ) {

			params.emissiveIntensity = attributes.Luminous.value;

			if ( attributes[ 'Luminous Color' ] && ! maps.emissive ) {

				params.emissive = new Color().fromArray( attributes[ 'Luminous Color' ].value );

			} else {

				params.emissive = new Color( 0x808080 );

			}

		}

		if ( attributes.Roughness && ! maps.roughnessMap ) params.roughness = attributes.Roughness.value;
		if ( attributes.Metallic && ! maps.metalnessMap ) params.metalness = attributes.Metallic.value;

	}

	parsePhongAttributes( params, attributes, maps ) {

		if ( attributes[ 'Refraction Index' ] ) params.refractionRatio = 0.98 / attributes[ 'Refraction Index' ].value;

		if ( attributes.Diffuse ) params.color.multiplyScalar( attributes.Diffuse.value );

		if ( attributes.Reflection ) {

			params.reflectivity = attributes.Reflection.value;
			params.combine = AddOperation;

		}

		if ( attributes.Luminosity ) {

			params.emissiveIntensity = attributes.Luminosity.value;

			if ( ! maps.emissiveMap && ! maps.map ) {

				params.emissive = params.color;

			} else {

				params.emissive = new Color( 0x808080 );

			}

		}

		// parse specular if there is no roughness - we will interpret the material as 'Phong' in this case
		if ( ! attributes.Roughness && attributes.Specular && ! maps.specularMap ) {

			if ( attributes[ 'Color Highlight' ] ) {

				params.specular = new Color().setScalar( attributes.Specular.value ).lerp( params.color.clone().multiplyScalar( attributes.Specular.value ), attributes[ 'Color Highlight' ].value );

			} else {

				params.specular = new Color().setScalar( attributes.Specular.value );

			}

		}

		if ( params.specular && attributes.Glossiness ) params.shininess = 7 + Math.pow( 2, attributes.Glossiness.value * 12 + 2 );

	}

	parseEnvMap( connections, maps, attributes ) {

		if ( connections.envMap ) {

			const envMap = this.loadTexture( connections.envMap );

			if ( attributes.transparent && attributes.opacity < 0.999 ) {

				envMap.mapping = EquirectangularRefractionMapping;

				// Reflectivity and refraction mapping don't work well together in Phong materials
				if ( attributes.reflectivity !== undefined ) {

					delete attributes.reflectivity;
					delete attributes.combine;

				}

				if ( attributes.metalness !== undefined ) {

					attributes.metalness = 1; // For most transparent materials metalness should be set to 1 if not otherwise defined. If set to 0 no refraction will be visible

				}

				attributes.opacity = 1; // transparency fades out refraction, forcing opacity to 1 ensures a closer visual match to the material in Lightwave.

			} else envMap.mapping = EquirectangularReflectionMapping;

			maps.envMap = envMap;

		}

	}

	// get texture defined at top level by its index
	getTexturePathByIndex( index ) {

		let fileName = '';

		if ( ! _lwoTree.textures ) return fileName;

		_lwoTree.textures.forEach( function ( texture ) {

			if ( texture.index === index ) fileName = texture.fileName;

		} );

		return fileName;

	}

	loadTexture( path ) {

		if ( ! path ) return null;

		const texture = this.textureLoader.load(
			path,
			undefined,
			undefined,
			function () {

				console.warn( 'LWOLoader: non-standard resource hierarchy. Use \`resourcePath\` parameter to specify root content directory.' );

			}
		);

		return texture;

	}

	// 0 = Reset, 1 = Repeat, 2 = Mirror, 3 = Edge
	getWrappingType( num ) {

		switch ( num ) {

			case 0:
				console.warn( 'LWOLoader: "Reset" texture wrapping type is not supported in three.js' );
				return ClampToEdgeWrapping;
			case 1: return RepeatWrapping;
			case 2: return MirroredRepeatWrapping;
			case 3: return ClampToEdgeWrapping;

		}

	}

	getMaterialType( nodeData ) {

		if ( nodeData.Clearcoat && nodeData.Clearcoat.value > 0 ) return MeshPhysicalMaterial;
		if ( nodeData.Roughness ) return MeshStandardMaterial;
		return MeshPhongMaterial;

	}

}