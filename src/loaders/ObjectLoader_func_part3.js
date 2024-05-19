	parseObject( data, geometries, materials, textures, animations ) {

		let object;

		function getGeometry( name ) {

			if ( geometries[ name ] === undefined ) {

				console.warn( 'THREE.ObjectLoader: Undefined geometry', name );

			}

			return geometries[ name ];

		}

		function getMaterial( name ) {

			if ( name === undefined ) return undefined;

			if ( Array.isArray( name ) ) {

				const array = [];

				for ( let i = 0, l = name.length; i < l; i ++ ) {

					const uuid = name[ i ];

					if ( materials[ uuid ] === undefined ) {

						console.warn( 'THREE.ObjectLoader: Undefined material', uuid );

					}

					array.push( materials[ uuid ] );

				}

				return array;

			}

			if ( materials[ name ] === undefined ) {

				console.warn( 'THREE.ObjectLoader: Undefined material', name );

			}

			return materials[ name ];

		}

		function getTexture( uuid ) {

			if ( textures[ uuid ] === undefined ) {

				console.warn( 'THREE.ObjectLoader: Undefined texture', uuid );

			}

			return textures[ uuid ];

		}

		let geometry, material;

		switch ( data.type ) {

			case 'Scene':

				object = new Scene();

				if ( data.background !== undefined ) {

					if ( Number.isInteger( data.background ) ) {

						object.background = new Color( data.background );

					} else {

						object.background = getTexture( data.background );

					}

				}

				if ( data.environment !== undefined ) {

					object.environment = getTexture( data.environment );

				}

				if ( data.fog !== undefined ) {

					if ( data.fog.type === 'Fog' ) {

						object.fog = new Fog( data.fog.color, data.fog.near, data.fog.far );

					} else if ( data.fog.type === 'FogExp2' ) {

						object.fog = new FogExp2( data.fog.color, data.fog.density );

					}

					if ( data.fog.name !== '' ) {

						object.fog.name = data.fog.name;

					}

				}

				if ( data.backgroundBlurriness !== undefined ) object.backgroundBlurriness = data.backgroundBlurriness;
				if ( data.backgroundIntensity !== undefined ) object.backgroundIntensity = data.backgroundIntensity;
				if ( data.backgroundRotation !== undefined ) object.backgroundRotation.fromArray( data.backgroundRotation );

				if ( data.environmentIntensity !== undefined ) object.environmentIntensity = data.environmentIntensity;
				if ( data.environmentRotation !== undefined ) object.environmentRotation.fromArray( data.environmentRotation );

				break;

			case 'PerspectiveCamera':

				object = new PerspectiveCamera( data.fov, data.aspect, data.near, data.far );

				if ( data.focus !== undefined ) object.focus = data.focus;
				if ( data.zoom !== undefined ) object.zoom = data.zoom;
				if ( data.filmGauge !== undefined ) object.filmGauge = data.filmGauge;
				if ( data.filmOffset !== undefined ) object.filmOffset = data.filmOffset;
				if ( data.view !== undefined ) object.view = Object.assign( {}, data.view );

				break;

			case 'OrthographicCamera':

				object = new OrthographicCamera( data.left, data.right, data.top, data.bottom, data.near, data.far );

				if ( data.zoom !== undefined ) object.zoom = data.zoom;
				if ( data.view !== undefined ) object.view = Object.assign( {}, data.view );

				break;

			case 'AmbientLight':

				object = new AmbientLight( data.color, data.intensity );

				break;

			case 'DirectionalLight':

				object = new DirectionalLight( data.color, data.intensity );

				break;

			case 'PointLight':

				object = new PointLight( data.color, data.intensity, data.distance, data.decay );

				break;

			case 'RectAreaLight':

				object = new RectAreaLight( data.color, data.intensity, data.width, data.height );

				break;

			case 'SpotLight':

				object = new SpotLight( data.color, data.intensity, data.distance, data.angle, data.penumbra, data.decay );

				break;

			case 'HemisphereLight':

				object = new HemisphereLight( data.color, data.groundColor, data.intensity );

				break;

			case 'LightProbe':

				object = new LightProbe().fromJSON( data );

				break;

			case 'SkinnedMesh':

				geometry = getGeometry( data.geometry );
			 	material = getMaterial( data.material );

				object = new SkinnedMesh( geometry, material );

				if ( data.bindMode !== undefined ) object.bindMode = data.bindMode;
				if ( data.bindMatrix !== undefined ) object.bindMatrix.fromArray( data.bindMatrix );
				if ( data.skeleton !== undefined ) object.skeleton = data.skeleton;

				break;

			case 'Mesh':

				geometry = getGeometry( data.geometry );
				material = getMaterial( data.material );

				object = new Mesh( geometry, material );

				break;

			case 'InstancedMesh':

				geometry = getGeometry( data.geometry );
				material = getMaterial( data.material );
				const count = data.count;
				const instanceMatrix = data.instanceMatrix;
				const instanceColor = data.instanceColor;

				object = new InstancedMesh( geometry, material, count );
				object.instanceMatrix = new InstancedBufferAttribute( new Float32Array( instanceMatrix.array ), 16 );
				if ( instanceColor !== undefined ) object.instanceColor = new InstancedBufferAttribute( new Float32Array( instanceColor.array ), instanceColor.itemSize );

				break;

			case 'BatchedMesh':

				geometry = getGeometry( data.geometry );
				material = getMaterial( data.material );

				object = new BatchedMesh( data.maxGeometryCount, data.maxVertexCount, data.maxIndexCount, material );
				object.geometry = geometry;
				object.perObjectFrustumCulled = data.perObjectFrustumCulled;
				object.sortObjects = data.sortObjects;

				object._drawRanges = data.drawRanges;
				object._reservedRanges = data.reservedRanges;

				object._visibility = data.visibility;
				object._active = data.active;
				object._bounds = data.bounds.map( bound => {

					const box = new Box3();
					box.min.fromArray( bound.boxMin );
					box.max.fromArray( bound.boxMax );

					const sphere = new Sphere();
					sphere.radius = bound.sphereRadius;
					sphere.center.fromArray( bound.sphereCenter );

					return {
						boxInitialized: bound.boxInitialized,
						box: box,

						sphereInitialized: bound.sphereInitialized,
						sphere: sphere
					};

				} );