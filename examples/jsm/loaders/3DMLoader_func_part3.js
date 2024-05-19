_releaseTask( worker, taskID ) {

		worker._taskLoad -= worker._taskCosts[ taskID ];
		delete worker._callbacks[ taskID ];
		delete worker._taskCosts[ taskID ];

	}
dispose() {

		for ( let i = 0; i < this.workerPool.length; ++ i ) {

			this.workerPool[ i ].terminate();

		}

		this.workerPool.length = 0;

		return this;

	}


}


/* WEB WORKER */

function Rhino3dmWorker() {

	let libraryPending;
	let libraryConfig;
	let rhino;
	let taskID;

	onmessage = function ( e ) {

		const message = e.data;

		switch ( message.type ) {

			case 'init':

				libraryConfig = message.libraryConfig;
				const wasmBinary = libraryConfig.wasmBinary;
				let RhinoModule;
				libraryPending = new Promise( function ( resolve ) {

					/* Like Basis Loader */
					RhinoModule = { wasmBinary, onRuntimeInitialized: resolve };

					rhino3dm( RhinoModule ); // eslint-disable-line no-undef

				 } ).then( () => {

					rhino = RhinoModule;

				 } );

				break;

			case 'decode':

				taskID = message.id;
				const buffer = message.buffer;
				libraryPending.then( () => {

					try {

						const data = decodeObjects( rhino, buffer );
						self.postMessage( { type: 'decode', id: message.id, data } );

					} catch ( error ) {

						self.postMessage( { type: 'error', id: message.id, error } );

					}

				} );

				break;

		}

	};

	function decodeObjects( rhino, buffer ) {

		const arr = new Uint8Array( buffer );
		const doc = rhino.File3dm.fromByteArray( arr );

		const objects = [];
		const materials = [];
		const layers = [];
		const views = [];
		const namedViews = [];
		const groups = [];
		const strings = [];

		//Handle objects

		const objs = doc.objects();
		const cnt = objs.count;

		for ( let i = 0; i < cnt; i ++ ) {

			const _object = objs.get( i );

			const object = extractObjectData( _object, doc );

			_object.delete();

			if ( object ) {

				objects.push( object );

			}

		}

		// Handle instance definitions
		// console.log( `Instance Definitions Count: ${doc.instanceDefinitions().count()}` );

		for ( let i = 0; i < doc.instanceDefinitions().count; i ++ ) {

			const idef = doc.instanceDefinitions().get( i );
			const idefAttributes = extractProperties( idef );
			idefAttributes.objectIds = idef.getObjectIds();

			objects.push( { geometry: null, attributes: idefAttributes, objectType: 'InstanceDefinition' } );

		}

		// Handle materials

		const textureTypes = [
			// rhino.TextureType.Bitmap,
			rhino.TextureType.Diffuse,
			rhino.TextureType.Bump,
			rhino.TextureType.Transparency,
			rhino.TextureType.Opacity,
			rhino.TextureType.Emap
		];

		const pbrTextureTypes = [
			rhino.TextureType.PBR_BaseColor,
			rhino.TextureType.PBR_Subsurface,
			rhino.TextureType.PBR_SubsurfaceScattering,
			rhino.TextureType.PBR_SubsurfaceScatteringRadius,
			rhino.TextureType.PBR_Metallic,
			rhino.TextureType.PBR_Specular,
			rhino.TextureType.PBR_SpecularTint,
			rhino.TextureType.PBR_Roughness,
			rhino.TextureType.PBR_Anisotropic,
			rhino.TextureType.PBR_Anisotropic_Rotation,
			rhino.TextureType.PBR_Sheen,
			rhino.TextureType.PBR_SheenTint,
			rhino.TextureType.PBR_Clearcoat,
			rhino.TextureType.PBR_ClearcoatBump,
			rhino.TextureType.PBR_ClearcoatRoughness,
			rhino.TextureType.PBR_OpacityIor,
			rhino.TextureType.PBR_OpacityRoughness,
			rhino.TextureType.PBR_Emission,
			rhino.TextureType.PBR_AmbientOcclusion,
			rhino.TextureType.PBR_Displacement
		];

		for ( let i = 0; i < doc.materials().count; i ++ ) {

			const _material = doc.materials().get( i );

			const material = extractProperties( _material );

			const textures = [];

			textures.push( ...extractTextures( _material, textureTypes, doc ) );

			material.pbrSupported = _material.physicallyBased().supported;

			if ( material.pbrSupported ) {

				textures.push( ...extractTextures( _material, pbrTextureTypes, doc ) );
				material.pbr = extractProperties( _material.physicallyBased() );

			}

			material.textures = textures;

			materials.push( material );

			_material.delete();

		}

		// Handle layers

		for ( let i = 0; i < doc.layers().count; i ++ ) {

			const _layer = doc.layers().get( i );
			const layer = extractProperties( _layer );

			layers.push( layer );

			_layer.delete();

		}

		// Handle views

		for ( let i = 0; i < doc.views().count; i ++ ) {

			const _view = doc.views().get( i );
			const view = extractProperties( _view );

			views.push( view );

			_view.delete();

		}

		// Handle named views

		for ( let i = 0; i < doc.namedViews().count; i ++ ) {

			const _namedView = doc.namedViews().get( i );
			const namedView = extractProperties( _namedView );

			namedViews.push( namedView );

			_namedView.delete();

		}

		// Handle groups

		for ( let i = 0; i < doc.groups().count; i ++ ) {

			const _group = doc.groups().get( i );
			const group = extractProperties( _group );

			groups.push( group );

			_group.delete();

		}

		// Handle settings

		const settings = extractProperties( doc.settings() );

		//TODO: Handle other document stuff like dimstyles, instance definitions, bitmaps etc.

		// Handle dimstyles
		// console.log( `Dimstyle Count: ${doc.dimstyles().count()}` );

		// Handle bitmaps
		// console.log( `Bitmap Count: ${doc.bitmaps().count()}` );

		// Handle strings
		// console.log( `Document Strings Count: ${doc.strings().count()}` );
		// Note: doc.strings().documentUserTextCount() counts any doc.strings defined in a section
		// console.log( `Document User Text Count: ${doc.strings().documentUserTextCount()}` );

		const strings_count = doc.strings().count;

		for ( let i = 0; i < strings_count; i ++ ) {

			strings.push( doc.strings().get( i ) );

		}

		// Handle Render Environments for Material Environment

		// get the id of the active render environment skylight, which we'll use for environment texture
		const reflectionId = doc.settings().renderSettings().renderEnvironments.reflectionId;

		const rc = doc.renderContent();

		let renderEnvironment = null;

		for ( let i = 0; i < rc.count; i ++ ) {

			const content = rc.get( i );

			switch ( content.kind ) {

				case 'environment':

					const id = content.id;

					// there could be multiple render environments in a 3dm file
					if ( id !== reflectionId ) break;

					const renderTexture = content.findChild( 'texture' );
					const fileName = renderTexture.fileName;

					for ( let j = 0; j < doc.embeddedFiles().count; j ++ ) {

						const _fileName = doc.embeddedFiles().get( j ).fileName;

						if ( fileName === _fileName ) {

							const background = doc.getEmbeddedFileAsBase64( fileName );
							const backgroundImage = 'data:image/png;base64,' + background;
							renderEnvironment = { type: 'renderEnvironment', image: backgroundImage, name: fileName };

						}

					}

					break;

			}

		}

		// Handle Render Settings

		const renderSettings = {
			ambientLight: doc.settings().renderSettings().ambientLight,
			backgroundColorTop: doc.settings().renderSettings().backgroundColorTop,
			backgroundColorBottom: doc.settings().renderSettings().backgroundColorBottom,
			useHiddenLights: doc.settings().renderSettings().useHiddenLights,
			depthCue: doc.settings().renderSettings().depthCue,
			flatShade: doc.settings().renderSettings().flatShade,
			renderBackFaces: doc.settings().renderSettings().renderBackFaces,
			renderPoints: doc.settings().renderSettings().renderPoints,
			renderCurves: doc.settings().renderSettings().renderCurves,
			renderIsoParams: doc.settings().renderSettings().renderIsoParams,
			renderMeshEdges: doc.settings().renderSettings().renderMeshEdges,
			renderAnnotations: doc.settings().renderSettings().renderAnnotations,
			useViewportSize: doc.settings().renderSettings().useViewportSize,
			scaleBackgroundToFit: doc.settings().renderSettings().scaleBackgroundToFit,
			transparentBackground: doc.settings().renderSettings().transparentBackground,
			imageDpi: doc.settings().renderSettings().imageDpi,
			shadowMapLevel: doc.settings().renderSettings().shadowMapLevel,
			namedView: doc.settings().renderSettings().namedView,
			snapShot: doc.settings().renderSettings().snapShot,
			specificViewport: doc.settings().renderSettings().specificViewport,
			groundPlane: extractProperties( doc.settings().renderSettings().groundPlane ),
			safeFrame: extractProperties( doc.settings().renderSettings().safeFrame ),
			dithering: extractProperties( doc.settings().renderSettings().dithering ),
			skylight: extractProperties( doc.settings().renderSettings().skylight ),
			linearWorkflow: extractProperties( doc.settings().renderSettings().linearWorkflow ),
			renderChannels: extractProperties( doc.settings().renderSettings().renderChannels ),
			sun: extractProperties( doc.settings().renderSettings().sun ),
			renderEnvironments: extractProperties( doc.settings().renderSettings().renderEnvironments ),
			postEffects: extractProperties( doc.settings().renderSettings().postEffects ),

		};

		doc.delete();

		return { objects, materials, layers, views, namedViews, groups, strings, settings, renderSettings, renderEnvironment };

	}

	function extractTextures( m, tTypes, d ) {

		const textures = [];

		for ( let i = 0; i < tTypes.length; i ++ ) {

			const _texture = m.getTexture( tTypes[ i ] );
			if ( _texture ) {

				let textureType = tTypes[ i ].constructor.name;
				textureType = textureType.substring( 12, textureType.length );
				const texture = extractTextureData( _texture, textureType, d );
				textures.push( texture );
				_texture.delete();

			}

		}

		return textures;

	}

	function extractTextureData( t, tType, d ) {

		const texture = { type: tType };

		const image = d.getEmbeddedFileAsBase64( t.fileName );

		texture.wrapU = t.wrapU;
		texture.wrapV = t.wrapV;
		texture.wrapW = t.wrapW;
		const uvw = t.uvwTransform.toFloatArray( true );

		texture.repeat = [ uvw[ 0 ], uvw[ 5 ] ];

		if ( image ) {

			texture.image = 'data:image/png;base64,' + image;

		} else {

			self.postMessage( { type: 'warning', id: taskID, data: {
				message: `THREE.3DMLoader: Image for ${tType} texture not embedded in file.`,
				type: 'missing resource'
			}

			} );

			texture.image = null;

		}

		return texture;

	}

	function extractObjectData( object, doc ) {

		const _geometry = object.geometry();
		const _attributes = object.attributes();
		let objectType = _geometry.objectType;
		let geometry, attributes, position, data, mesh;

		// skip instance definition objects
		//if( _attributes.isInstanceDefinitionObject ) { continue; }

		// TODO: handle other geometry types
		switch ( objectType ) {

			case rhino.ObjectType.Curve:

				const pts = curveToPoints( _geometry, 100 );

				position = {};
				attributes = {};
				data = {};

				position.itemSize = 3;
				position.type = 'Float32Array';
				position.array = [];

				for ( let j = 0; j < pts.length; j ++ ) {

					position.array.push( pts[ j ][ 0 ] );
					position.array.push( pts[ j ][ 1 ] );
					position.array.push( pts[ j ][ 2 ] );

				}

				attributes.position = position;
				data.attributes = attributes;

				geometry = { data };

				break;

			case rhino.ObjectType.Point:

				const pt = _geometry.location;

				position = {};
				const color = {};
				attributes = {};
				data = {};

				position.itemSize = 3;
				position.type = 'Float32Array';
				position.array = [ pt[ 0 ], pt[ 1 ], pt[ 2 ] ];

				const _color = _attributes.drawColor( doc );

				color.itemSize = 3;
				color.type = 'Float32Array';
				color.array = [ _color.r / 255.0, _color.g / 255.0, _color.b / 255.0 ];

				attributes.position = position;
				attributes.color = color;
				data.attributes = attributes;

				geometry = { data };

				break;

			case rhino.ObjectType.PointSet:
			case rhino.ObjectType.Mesh:

				geometry = _geometry.toThreejsJSON();

				break;

			case rhino.ObjectType.Brep:

				const faces = _geometry.faces();
				mesh = new rhino.Mesh();

				for ( let faceIndex = 0; faceIndex < faces.count; faceIndex ++ ) {

					const face = faces.get( faceIndex );
					const _mesh = face.getMesh( rhino.MeshType.Any );

					if ( _mesh ) {

						mesh.append( _mesh );
						_mesh.delete();

					}

					face.delete();

				}

				if ( mesh.faces().count > 0 ) {

					mesh.compact();
					geometry = mesh.toThreejsJSON();
					faces.delete();

				}

				mesh.delete();

				break;

			case rhino.ObjectType.Extrusion:

				mesh = _geometry.getMesh( rhino.MeshType.Any );

				if ( mesh ) {

					geometry = mesh.toThreejsJSON();
					mesh.delete();

				}

				break;

			case rhino.ObjectType.TextDot:

				geometry = extractProperties( _geometry );

				break;

			case rhino.ObjectType.Light:

				geometry = extractProperties( _geometry );

				if ( geometry.lightStyle.name === 'LightStyle_WorldLinear' ) {

					self.postMessage( { type: 'warning', id: taskID, data: {
						message: `THREE.3DMLoader: No conversion exists for ${objectType.constructor.name} ${geometry.lightStyle.name}`,
						type: 'no conversion',
						guid: _attributes.id
					}

					} );

				}

				break;

			case rhino.ObjectType.InstanceReference:

				geometry = extractProperties( _geometry );
				geometry.xform = extractProperties( _geometry.xform );
				geometry.xform.array = _geometry.xform.toFloatArray( true );

				break;

			case rhino.ObjectType.SubD:

				// TODO: precalculate resulting vertices and faces and warn on excessive results
				_geometry.subdivide( 3 );
				mesh = rhino.Mesh.createFromSubDControlNet( _geometry, false );
				if ( mesh ) {

					geometry = mesh.toThreejsJSON();
					mesh.delete();

				}

				break;

				/*
				case rhino.ObjectType.Annotation:
				case rhino.ObjectType.Hatch:
				case rhino.ObjectType.ClipPlane:
				*/

			default:

				self.postMessage( { type: 'warning', id: taskID, data: {
					message: `THREE.3DMLoader: Conversion not implemented for ${objectType.constructor.name}`,
					type: 'not implemented',
					guid: _attributes.id
				}

				} );

				break;

		}

		if ( geometry ) {

			attributes = extractProperties( _attributes );
			attributes.geometry = extractProperties( _geometry );

			if ( _attributes.groupCount > 0 ) {

				attributes.groupIds = _attributes.getGroupList();

			}

			if ( _attributes.userStringCount > 0 ) {

				attributes.userStrings = _attributes.getUserStrings();

			}

			if ( _geometry.userStringCount > 0 ) {

				attributes.geometry.userStrings = _geometry.getUserStrings();

			}

			if ( _attributes.decals().count > 0 ) {

				self.postMessage( { type: 'warning', id: taskID, data: {
					message: 'THREE.3DMLoader: No conversion exists for the decals associated with this object.',
					type: 'no conversion',
					guid: _attributes.id
				}

				} );

			}

			attributes.drawColor = _attributes.drawColor( doc );

			objectType = objectType.constructor.name;
			objectType = objectType.substring( 11, objectType.length );

			return { geometry, attributes, objectType };

		} else {

			self.postMessage( { type: 'warning', id: taskID, data: {
				message: `THREE.3DMLoader: ${objectType.constructor.name} has no associated mesh geometry.`,
				type: 'missing mesh',
				guid: _attributes.id
			}

			} );

		}

	}

	function extractProperties( object ) {

		const result = {};

		for ( const property in object ) {

			const value = object[ property ];

			if ( typeof value !== 'function' ) {

				if ( typeof value === 'object' && value !== null && value.hasOwnProperty( 'constructor' ) ) {

					result[ property ] = { name: value.constructor.name, value: value.value };

				} else if ( typeof value === 'object' && value !== null ) {

					result[ property ] = extractProperties( value );

				} else {

					result[ property ] = value;

				}

			} else {

				// these are functions that could be called to extract more data.
				//console.log( `${property}: ${object[ property ].constructor.name}` );

			}

		}

		return result;

	}

	function curveToPoints( curve, pointLimit ) {

		let pointCount = pointLimit;
		let rc = [];
		const ts = [];

		if ( curve instanceof rhino.LineCurve ) {

			return [ curve.pointAtStart, curve.pointAtEnd ];

		}

		if ( curve instanceof rhino.PolylineCurve ) {

			pointCount = curve.pointCount;
			for ( let i = 0; i < pointCount; i ++ ) {

				rc.push( curve.point( i ) );

			}

			return rc;

		}

		if ( curve instanceof rhino.PolyCurve ) {

			const segmentCount = curve.segmentCount;

			for ( let i = 0; i < segmentCount; i ++ ) {

				const segment = curve.segmentCurve( i );
				const segmentArray = curveToPoints( segment, pointCount );
				rc = rc.concat( segmentArray );
				segment.delete();

			}

			return rc;

		}

		if ( curve instanceof rhino.ArcCurve ) {

			pointCount = Math.floor( curve.angleDegrees / 5 );
			pointCount = pointCount < 2 ? 2 : pointCount;
			// alternative to this hardcoded version: https://stackoverflow.com/a/18499923/2179399

		}

		if ( curve instanceof rhino.NurbsCurve && curve.degree === 1 ) {

			const pLine = curve.tryGetPolyline();

			for ( let i = 0; i < pLine.count; i ++ ) {

				rc.push( pLine.get( i ) );

			}

			pLine.delete();

			return rc;

		}

		const domain = curve.domain;
		const divisions = pointCount - 1.0;

		for ( let j = 0; j < pointCount; j ++ ) {

			const t = domain[ 0 ] + ( j / divisions ) * ( domain[ 1 ] - domain[ 0 ] );

			if ( t === domain[ 0 ] || t === domain[ 1 ] ) {

				ts.push( t );
				continue;

			}

			const tan = curve.tangentAt( t );
			const prevTan = curve.tangentAt( ts.slice( - 1 )[ 0 ] );

			// Duplicated from THREE.Vector3
			// How to pass imports to worker?

			const tS = tan[ 0 ] * tan[ 0 ] + tan[ 1 ] * tan[ 1 ] + tan[ 2 ] * tan[ 2 ];
			const ptS = prevTan[ 0 ] * prevTan[ 0 ] + prevTan[ 1 ] * prevTan[ 1 ] + prevTan[ 2 ] * prevTan[ 2 ];

			const denominator = Math.sqrt( tS * ptS );

			let angle;

			if ( denominator === 0 ) {

				angle = Math.PI / 2;

			} else {

				const theta = ( tan.x * prevTan.x + tan.y * prevTan.y + tan.z * prevTan.z ) / denominator;
				angle = Math.acos( Math.max( - 1, Math.min( 1, theta ) ) );

			}

			if ( angle < 0.1 ) continue;

			ts.push( t );

		}

		rc = ts.map( t => curve.pointAt( t ) );
		return rc;

	}

}

export { Rhino3dmLoader };
