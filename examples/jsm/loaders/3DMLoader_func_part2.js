_createGeometry( data ) {

		const object = new Object3D();
		const instanceDefinitionObjects = [];
		const instanceDefinitions = [];
		const instanceReferences = [];

		object.userData[ 'layers' ] = data.layers;
		object.userData[ 'groups' ] = data.groups;
		object.userData[ 'settings' ] = data.settings;
		object.userData.settings[ 'renderSettings' ] = data.renderSettings;
		object.userData[ 'objectType' ] = 'File3dm';
		object.userData[ 'materials' ] = null;

		object.name = this.url;

		let objects = data.objects;
		const materials = data.materials;

		for ( let i = 0; i < objects.length; i ++ ) {

			const obj = objects[ i ];
			const attributes = obj.attributes;

			switch ( obj.objectType ) {

				case 'InstanceDefinition':

					instanceDefinitions.push( obj );

					break;

				case 'InstanceReference':

					instanceReferences.push( obj );

					break;

				default:

					let matId = null;

					switch ( attributes.materialSource.name ) {

						case 'ObjectMaterialSource_MaterialFromLayer':
							//check layer index
							if ( attributes.layerIndex >= 0 ) {

								matId = data.layers[ attributes.layerIndex ].renderMaterialIndex;

							}

							break;

						case 'ObjectMaterialSource_MaterialFromObject':

							if ( attributes.materialIndex >= 0 ) {

								matId = attributes.materialIndex;

							}

							break;

					}

					let material = null;

					if ( matId >= 0 ) {

						const rMaterial = materials[ matId ];
						material = this._createMaterial( rMaterial, data.renderEnvironment );


					}

					const _object = this._createObject( obj, material );

					if ( _object === undefined ) {

						continue;

					}

					const layer = data.layers[ attributes.layerIndex ];

					_object.visible = layer ? data.layers[ attributes.layerIndex ].visible : true;

					if ( attributes.isInstanceDefinitionObject ) {

						instanceDefinitionObjects.push( _object );

					} else {

						object.add( _object );

					}

					break;

			}

		}

		for ( let i = 0; i < instanceDefinitions.length; i ++ ) {

			const iDef = instanceDefinitions[ i ];

			objects = [];

			for ( let j = 0; j < iDef.attributes.objectIds.length; j ++ ) {

				const objId = iDef.attributes.objectIds[ j ];

				for ( let p = 0; p < instanceDefinitionObjects.length; p ++ ) {

					const idoId = instanceDefinitionObjects[ p ].userData.attributes.id;

					if ( objId === idoId ) {

						objects.push( instanceDefinitionObjects[ p ] );

					}

				}

			}

			// Currently clones geometry and does not take advantage of instancing

			for ( let j = 0; j < instanceReferences.length; j ++ ) {

				const iRef = instanceReferences[ j ];

				if ( iRef.geometry.parentIdefId === iDef.attributes.id ) {

					const iRefObject = new Object3D();
					const xf = iRef.geometry.xform.array;

					const matrix = new Matrix4();
					matrix.set( ...xf );

					iRefObject.applyMatrix4( matrix );

					for ( let p = 0; p < objects.length; p ++ ) {

						iRefObject.add( objects[ p ].clone( true ) );

					}

					object.add( iRefObject );

				}

			}

		}

		object.userData[ 'materials' ] = this.materials;
		object.name = '';
		return object;

	}
_createObject( obj, mat ) {

		const loader = new BufferGeometryLoader();

		const attributes = obj.attributes;

		let geometry, material, _color, color;

		switch ( obj.objectType ) {

			case 'Point':
			case 'PointSet':

				geometry = loader.parse( obj.geometry );

				if ( geometry.attributes.hasOwnProperty( 'color' ) ) {

					material = new PointsMaterial( { vertexColors: true, sizeAttenuation: false, size: 2 } );

				} else {

					_color = attributes.drawColor;
					color = new Color( _color.r / 255.0, _color.g / 255.0, _color.b / 255.0 );
					material = new PointsMaterial( { color: color, sizeAttenuation: false, size: 2 } );

				}

				material = this._compareMaterials( material );

				const points = new Points( geometry, material );
				points.userData[ 'attributes' ] = attributes;
				points.userData[ 'objectType' ] = obj.objectType;

				if ( attributes.name ) {

					points.name = attributes.name;

				}

				return points;

			case 'Mesh':
			case 'Extrusion':
			case 'SubD':
			case 'Brep':

				if ( obj.geometry === null ) return;

				geometry = loader.parse( obj.geometry );


				if ( mat === null ) {

					mat = this._createMaterial();

				}


				if ( geometry.attributes.hasOwnProperty( 'color' ) ) {

					mat.vertexColors = true;

				}

				mat = this._compareMaterials( mat );

				const mesh = new Mesh( geometry, mat );
				mesh.castShadow = attributes.castsShadows;
				mesh.receiveShadow = attributes.receivesShadows;
				mesh.userData[ 'attributes' ] = attributes;
				mesh.userData[ 'objectType' ] = obj.objectType;

				if ( attributes.name ) {

					mesh.name = attributes.name;

				}

				return mesh;

			case 'Curve':

				geometry = loader.parse( obj.geometry );

				_color = attributes.drawColor;
				color = new Color( _color.r / 255.0, _color.g / 255.0, _color.b / 255.0 );

				material = new LineBasicMaterial( { color: color } );
				material = this._compareMaterials( material );

				const lines = new Line( geometry, material );
				lines.userData[ 'attributes' ] = attributes;
				lines.userData[ 'objectType' ] = obj.objectType;

				if ( attributes.name ) {

					lines.name = attributes.name;

				}

				return lines;

			case 'TextDot':

				geometry = obj.geometry;

				const ctx = document.createElement( 'canvas' ).getContext( '2d' );
				const font = `${geometry.fontHeight}px ${geometry.fontFace}`;
				ctx.font = font;
				const width = ctx.measureText( geometry.text ).width + 10;
				const height = geometry.fontHeight + 10;

				const r = window.devicePixelRatio;

				ctx.canvas.width = width * r;
				ctx.canvas.height = height * r;
				ctx.canvas.style.width = width + 'px';
				ctx.canvas.style.height = height + 'px';
				ctx.setTransform( r, 0, 0, r, 0, 0 );

				ctx.font = font;
				ctx.textBaseline = 'middle';
				ctx.textAlign = 'center';
				color = attributes.drawColor;
				ctx.fillStyle = `rgba(${color.r},${color.g},${color.b},${color.a})`;
				ctx.fillRect( 0, 0, width, height );
				ctx.fillStyle = 'white';
				ctx.fillText( geometry.text, width / 2, height / 2 );

				const texture = new CanvasTexture( ctx.canvas );
				texture.minFilter = LinearFilter;
				texture.wrapS = ClampToEdgeWrapping;
				texture.wrapT = ClampToEdgeWrapping;

				material = new SpriteMaterial( { map: texture, depthTest: false } );
				const sprite = new Sprite( material );
				sprite.position.set( geometry.point[ 0 ], geometry.point[ 1 ], geometry.point[ 2 ] );
				sprite.scale.set( width / 10, height / 10, 1.0 );

				sprite.userData[ 'attributes' ] = attributes;
				sprite.userData[ 'objectType' ] = obj.objectType;

				if ( attributes.name ) {

					sprite.name = attributes.name;

				}

				return sprite;

			case 'Light':

				geometry = obj.geometry;

				let light;

				switch ( geometry.lightStyle.name ) {

					case 'LightStyle_WorldPoint':

						light = new PointLight();
						light.castShadow = attributes.castsShadows;
						light.position.set( geometry.location[ 0 ], geometry.location[ 1 ], geometry.location[ 2 ] );
						light.shadow.normalBias = 0.1;

						break;

					case 'LightStyle_WorldSpot':

						light = new SpotLight();
						light.castShadow = attributes.castsShadows;
						light.position.set( geometry.location[ 0 ], geometry.location[ 1 ], geometry.location[ 2 ] );
						light.target.position.set( geometry.direction[ 0 ], geometry.direction[ 1 ], geometry.direction[ 2 ] );
						light.angle = geometry.spotAngleRadians;
						light.shadow.normalBias = 0.1;

						break;

					case 'LightStyle_WorldRectangular':

						light = new RectAreaLight();
						const width = Math.abs( geometry.width[ 2 ] );
						const height = Math.abs( geometry.length[ 0 ] );
						light.position.set( geometry.location[ 0 ] - ( height / 2 ), geometry.location[ 1 ], geometry.location[ 2 ] - ( width / 2 ) );
						light.height = height;
						light.width = width;
						light.lookAt( geometry.direction[ 0 ], geometry.direction[ 1 ], geometry.direction[ 2 ] );

						break;

					case 'LightStyle_WorldDirectional':

						light = new DirectionalLight();
						light.castShadow = attributes.castsShadows;
						light.position.set( geometry.location[ 0 ], geometry.location[ 1 ], geometry.location[ 2 ] );
						light.target.position.set( geometry.direction[ 0 ], geometry.direction[ 1 ], geometry.direction[ 2 ] );
						light.shadow.normalBias = 0.1;

						break;

					case 'LightStyle_WorldLinear':
						// no conversion exists, warning has already been printed to the console
						break;

					default:
						break;

				}

				if ( light ) {

					light.intensity = geometry.intensity;
					_color = geometry.diffuse;
					color = new Color( _color.r / 255.0, _color.g / 255.0, _color.b / 255.0 );
					light.color = color;
					light.userData[ 'attributes' ] = attributes;
					light.userData[ 'objectType' ] = obj.objectType;

				}

				return light;

		}

	}
_initLibrary() {

		if ( ! this.libraryPending ) {

			// Load rhino3dm wrapper.
			const jsLoader = new FileLoader( this.manager );
			jsLoader.setPath( this.libraryPath );
			const jsContent = new Promise( ( resolve, reject ) => {

				jsLoader.load( 'rhino3dm.js', resolve, undefined, reject );

			} );

			// Load rhino3dm WASM binary.
			const binaryLoader = new FileLoader( this.manager );
			binaryLoader.setPath( this.libraryPath );
			binaryLoader.setResponseType( 'arraybuffer' );
			const binaryContent = new Promise( ( resolve, reject ) => {

				binaryLoader.load( 'rhino3dm.wasm', resolve, undefined, reject );

			} );

			this.libraryPending = Promise.all( [ jsContent, binaryContent ] )
				.then( ( [ jsContent, binaryContent ] ) => {

					//this.libraryBinary = binaryContent;
					this.libraryConfig.wasmBinary = binaryContent;

					const fn = Rhino3dmWorker.toString();

					const body = [
						'/* rhino3dm.js */',
						jsContent,
						'/* worker */',
						fn.substring( fn.indexOf( '{' ) + 1, fn.lastIndexOf( '}' ) )
					].join( '\n' );

					this.workerSourceURL = URL.createObjectURL( new Blob( [ body ] ) );

				} );

		}

		return this.libraryPending;

	}
_getWorker( taskCost ) {

		return this._initLibrary().then( () => {

			if ( this.workerPool.length < this.workerLimit ) {

				const worker = new Worker( this.workerSourceURL );

				worker._callbacks = {};
				worker._taskCosts = {};
				worker._taskLoad = 0;

				worker.postMessage( {
					type: 'init',
					libraryConfig: this.libraryConfig
				} );

				worker.onmessage = e => {

					const message = e.data;

					switch ( message.type ) {

						case 'warning':
							this.warnings.push( message.data );
							console.warn( message.data );
							break;

						case 'decode':
							worker._callbacks[ message.id ].resolve( message );
							break;

						case 'error':
							worker._callbacks[ message.id ].reject( message );
							break;

						default:
							console.error( 'THREE.Rhino3dmLoader: Unexpected message, "' + message.type + '"' );

					}

				};

				this.workerPool.push( worker );

			} else {

				this.workerPool.sort( function ( a, b ) {

					return a._taskLoad > b._taskLoad ? - 1 : 1;

				} );

			}

			const worker = this.workerPool[ this.workerPool.length - 1 ];

			worker._taskLoad += taskCost;

			return worker;

		} );

	}