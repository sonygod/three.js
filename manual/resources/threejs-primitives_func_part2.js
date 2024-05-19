class CustomSinCurve extends THREE.Curve {

					constructor( scale ) {

						super();
						this.scale = scale;

					}
getPoint( t ) {

						const tx = t * 3 - 1.5;
						const ty = Math.sin( 2 * Math.PI * t );
						const tz = 0;
						return new THREE.Vector3( tx, ty, tz ).multiplyScalar( this.scale );

					}


				}


				const path = new CustomSinCurve( 4 );
				return new THREE.TubeGeometry(
					path, tubularSegments, radius, radialSegments, closed );

			},
		},
		EdgesGeometry: {
			ui: {
				thresholdAngle: { type: 'range', min: 1, max: 180, },
			},
			create() {

				return {
					lineGeometry: new THREE.EdgesGeometry(
						new THREE.BoxGeometry( 8, 8, 8 ) ),
				};

			},
			create2( thresholdAngle = 1 ) {

				return {
					lineGeometry: new THREE.EdgesGeometry(
						new THREE.SphereGeometry( 7, 6, 3 ), thresholdAngle ),
				};

			},
			addConstCode: false,
			src: `
const size = 8;
const widthSegments = 2;
const heightSegments = 2;
const depthSegments = 2;
const boxGeometry = new THREE.BoxGeometry(
    size, size, size,
    widthSegments, heightSegments, depthSegments);
const geometry = new THREE.EdgesGeometry(boxGeometry);
`,
			src2: `
const radius = 7;
const widthSegments = 6;
const heightSegments = 3;
const sphereGeometry = new THREE.SphereGeometry(
    radius, widthSegments, heightSegments);
const thresholdAngle = 1;  // ui: thresholdAngle
const geometry = new THREE.EdgesGeometry(sphereGeometry, thresholdAngle);
`,
		},
		WireframeGeometry: {
			ui: {
				widthSegments: { type: 'range', min: 1, max: 10, },
				heightSegments: { type: 'range', min: 1, max: 10, },
				depthSegments: { type: 'range', min: 1, max: 10, },
			},
			create( widthSegments = 2, heightSegments = 2, depthSegments = 2 ) {

				const size = 8;
				return {
					lineGeometry: new THREE.WireframeGeometry( new THREE.BoxGeometry(
						size, size, size,
						widthSegments, heightSegments, depthSegments ) ),
				};

			},
			addConstCode: false,
			src: `
const size = 8;
const widthSegments = 2;  // ui: widthSegments
const heightSegments = 2;  // ui: heightSegments
const depthSegments = 2;  // ui: depthSegments
const geometry = new THREE.WireframeGeometry(
    new THREE.BoxGeometry(
      size, size, size,
      widthSegments, heightSegments, depthSegments));
`,
		},
		Points: {
			create() {

				const radius = 7;
				const widthSegments = 12;
				const heightSegments = 8;
				const geometry = new THREE.SphereGeometry( radius, widthSegments, heightSegments );
				const material = new THREE.PointsMaterial( {
					color: 'red',
					size: 0.2,
				} );
				const points = new THREE.Points( geometry, material );
				return {
					showLines: false,
					mesh: points,
				};

			},
		},
		PointsUniformSize: {
			create() {

				const radius = 7;
				const widthSegments = 12;
				const heightSegments = 8;
				const geometry = new THREE.SphereGeometry( radius, widthSegments, heightSegments );
				const material = new THREE.PointsMaterial( {
					color: 'red',
					size: 3 * window.devicePixelRatio,
					sizeAttenuation: false,
				} );
				const points = new THREE.Points( geometry, material );
				return {
					showLines: false,
					mesh: points,
				};

			},
		},
		SphereGeometryLow: {
			create( radius = 7, widthSegments = 5, heightSegments = 3 ) {

				return new THREE.SphereGeometry( radius, widthSegments, heightSegments );

			},
		},
		SphereGeometryMedium: {
			create( radius = 7, widthSegments = 24, heightSegments = 10 ) {

				return new THREE.SphereGeometry( radius, widthSegments, heightSegments );

			},
		},
		SphereGeometryHigh: {
			create( radius = 7, widthSegments = 50, heightSegments = 50 ) {

				return new THREE.SphereGeometry( radius, widthSegments, heightSegments );

			},
		},
		SphereGeometryLowSmooth: {
			create( radius = 7, widthSegments = 5, heightSegments = 3 ) {

				return new THREE.SphereGeometry( radius, widthSegments, heightSegments );

			},
			showLines: false,
			flatShading: false,
		},
		SphereGeometryMediumSmooth: {
			create( radius = 7, widthSegments = 24, heightSegments = 10 ) {

				return new THREE.SphereGeometry( radius, widthSegments, heightSegments );

			},
			showLines: false,
			flatShading: false,
		},
		SphereGeometryHighSmooth: {
			create( radius = 7, widthSegments = 50, heightSegments = 50 ) {

				return new THREE.SphereGeometry( radius, widthSegments, heightSegments );

			},
			showLines: false,
			flatShading: false,
		},
		PlaneGeometryLow: {
			create( width = 9, height = 9, widthSegments = 1, heightSegments = 1 ) {

				return new THREE.PlaneGeometry( width, height, widthSegments, heightSegments );

			},
		},
		PlaneGeometryHigh: {
			create( width = 9, height = 9, widthSegments = 10, heightSegments = 10 ) {

				return new THREE.PlaneGeometry( width, height, widthSegments, heightSegments );

			},
		},
	};

	function addLink( parent, name, href ) {

		const a = document.createElement( 'a' );
		a.setAttribute( 'target', '_blank' );
		a.href = href || `https://threejs.org/docs/#api/geometries/${name}`;
		const code = document.createElement( 'code' );
		code.textContent = name;
		a.appendChild( code );
		parent.appendChild( a );
		return a;

	}

	function addDeepLink( parent, name, href ) {

		const a = document.createElement( 'a' );
		a.href = href || `https://threejs.org/docs/#api/geometries/${name}`;
		a.textContent = name;
		a.className = 'deep-link';
		parent.appendChild( a );
		return a;

	}

	function addElem( parent, type, className, text ) {

		const elem = document.createElement( type );
		elem.className = className;
		if ( text ) {

			elem.textContent = text;

		}

		parent.appendChild( elem );
		return elem;

	}

	function addDiv( parent, className ) {

		return addElem( parent, 'div', className );

	}

	function createPrimitiveDOM( base ) {

		const name = base.dataset.primitive;
		const info = diagrams[ name ];
		if ( ! info ) {

			throw new Error( `no primitive ${name}` );

		}

		const text = base.innerHTML;
		base.innerHTML = '';

		const pair = addDiv( base, 'pair' );
		const elem = addDiv( pair, 'shape' );

		const right = addDiv( pair, 'desc' );
		addDeepLink( right, '#', `#${base.id}` );
		addLink( right, name );
		addDiv( right, '.note' ).innerHTML = text;

		// I get that this is super brittle. I think I'd have to
		// work through a bunch more examples to come up with a better
		// structure. Also, I don't want to generate actual code and
		// use eval. (maybe a bad striction)

		function makeExample( elem, createFn, src ) {

			const rawLines = createFn.toString().replace( /return (new THREE\.[a-zA-Z]+Geometry)/, 'const geometry = $1' ).split( /\n/ );
			const createRE = /^\s*(?:function *)*create\d*\((.*?)\)/;
			const indentRE = /^(\s*)[^\s]/;
			const m = indentRE.exec( rawLines[ 2 ] );
			const prefixLen = m[ 1 ].length;
			const m2 = createRE.exec( rawLines[ 0 ] );
			const argString = m2[ 1 ].trim();
			const trimmedLines = src
				? src.split( '\n' ).slice( 1, - 1 )
				: rawLines.slice( 1, rawLines.length - 1 ).map( line => line.substring( prefixLen ) );
			if ( info.addConstCode !== false && argString ) {

				const lines = argString.split( ',' ).map( ( arg ) => {

					return `const ${arg.trim()};  // ui: ${arg.trim().split( ' ' )[ 0 ]}`;

				} );
				const lineNdx = trimmedLines.findIndex( l => l.indexOf( 'const geometry' ) >= 0 );
				trimmedLines.splice( lineNdx < 0 ? 0 : lineNdx, 0, ...lines );

			}

			addElem( base, 'pre', 'prettyprint showmods', trimmedLines.join( '\n' ) );

			createLiveImage( elem, { ...info, create: createFn }, name );

		}

		makeExample( elem, info.create, info.src );

		{

			let i = 2;
			for ( ;; ) {

				const createFn = info[ `create${i}` ];
				if ( ! createFn ) {

					break;

				}

				const shapeElem = addDiv( base, 'shape' );
				makeExample( shapeElem, createFn, info[ `src${i}` ] );
				++ i;

			}

		}

	}

	function createDiagram( base ) {

		const name = base.dataset.diagram;
		const info = diagrams[ name ];
		if ( ! info ) {

			throw new Error( `no primitive ${name}` );

		}

		createLiveImage( base, info, name );

	}

	async function addGeometry( root, info, args = [] ) {

		const result = info.create( ...args );
		const promise = ( result instanceof Promise ) ? result : Promise.resolve( result );

		let diagramInfo = await promise;
		if ( diagramInfo instanceof THREE.BufferGeometry ) {

			const geometry = diagramInfo;
			diagramInfo = {
				geometry,
			};

		}

		const geometry = diagramInfo.geometry || diagramInfo.lineGeometry || diagramInfo.mesh.geometry;
		geometry.computeBoundingBox();
		const centerOffset = new THREE.Vector3();
		geometry.boundingBox.getCenter( centerOffset ).multiplyScalar( - 1 );

		let mesh = diagramInfo.mesh;
		if ( diagramInfo.geometry ) {

			if ( ! info.material ) {

				const material = new THREE.MeshPhongMaterial( {
					flatShading: info.flatShading === false ? false : true,
					side: THREE.DoubleSide,
				} );
				material.color.setHSL( Math.random(), .5, .5 );
				info.material = material;

			}

			mesh = new THREE.Mesh( diagramInfo.geometry, info.material );

		}

		if ( mesh ) {

			mesh.position.copy( centerOffset );
			root.add( mesh );

		}

		if ( info.showLines !== false ) {

			const lineMesh = new THREE.LineSegments(
				diagramInfo.lineGeometry || diagramInfo.geometry,
				new THREE.LineBasicMaterial( {
					color: diagramInfo.geometry ? 0xffffff : colors.lines,
					transparent: true,
					opacity: 0.5,
				} ) );
			lineMesh.position.copy( centerOffset );
			root.add( lineMesh );

		}

	}

	async function updateGeometry( root, info, params ) {

		const oldChildren = root.children.slice();
		await addGeometry( root, info, Object.values( params ) );
		oldChildren.forEach( ( child ) => {

			root.remove( child );
			child.geometry.dispose();

		} );

	}

	const primitives = {};

	async function createLiveImage( elem, info, name ) {

		const root = new THREE.Object3D();

		primitives[ name ] = primitives[ name ] || [];
		primitives[ name ].push( {
			root,
			info,
		} );

		await addGeometry( root, info );
		threejsLessonUtils.addDiagram( elem, { create: () => root } );

	}

	function getValueElem( commentElem ) {

		return commentElem.previousElementSibling &&
           commentElem.previousElementSibling.previousElementSibling &&
           commentElem.previousElementSibling.previousElementSibling.previousElementSibling;

	}

	threejsLessonUtils.onAfterPrettify( () => {

		document.querySelectorAll( '[data-primitive]' ).forEach( ( base ) => {

			const primitiveName = base.dataset.primitive;
			const infos = primitives[ primitiveName ];
			base.querySelectorAll( 'pre.prettyprint' ).forEach( ( shape, ndx ) => {

				const { root, info } = infos[ ndx ];
				const params = {};
				[ ...shape.querySelectorAll( 'span.com' ) ]
					.filter( span => span.textContent.indexOf( '// ui:' ) >= 0 )
					.forEach( ( span ) => {

						const nameRE = /ui: ([a-zA-Z0-9_]+) *$/;
						const name = nameRE.exec( span.textContent )[ 1 ];
						span.textContent = '';
						if ( ! info.ui ) {

            console.error(`no ui for ${primitiveName}:${ndx}`);  // eslint-disable-line
							return;
							// throw new Error(`no ui for ${primitiveName}:${ndx}`);

						}

						const ui = info.ui[ name ];
						if ( ! ui ) {

							throw new Error( `no ui for ${primitiveName}:${ndx} param: ${name}` );

						}

						const valueElem = getValueElem( span );
						if ( ! valueElem ) {

            console.error(`no value element for ${primitiveName}:${ndx} param: ${name}`);  // eslint-disable-line
							return;

						}

						const inputHolderHolder = document.createElement( 'div' );
						inputHolderHolder.className = 'input';
						const inputHolder = document.createElement( 'div' );
						span.appendChild( inputHolderHolder );
						inputHolderHolder.appendChild( inputHolder );
						switch ( ui.type ) {

							case 'range': {

								const valueRange = ui.max - ui.min;
								const input = document.createElement( 'input' );
								const inputMax = 100;
								input.type = 'range';
								input.min = 0;
								input.max = inputMax;
								const value = parseFloat( valueElem.textContent );
								params[ name ] = value * ( ui.mult || 1 );
								input.value = ( value - ui.min ) / valueRange * inputMax;
								inputHolder.appendChild( input );
								const precision = ui.precision === undefined ? ( valueRange > 4 ? 0 : 2 ) : ui.precision;
								const padding = ui.max.toFixed( precision ).length;
								input.addEventListener( 'input', () => {

									let newValue = input.value * valueRange / inputMax + ui.min;
									if ( precision === 0 ) {

										newValue = Math.round( newValue );

									}

									params[ name ] = newValue * ( ui.mult || 1 );
									valueElem.textContent = newValue.toFixed( precision ).padStart( padding, ' ' );
									updateGeometry( root, info, params );

								} );
								break;

							}

							case 'bool': {

								const input = document.createElement( 'input' );
								input.type = 'checkbox';
								params[ name ] = valueElem.textContent === 'true';
								input.checked = params[ name ];
								inputHolder.appendChild( input );
								input.addEventListener( 'change', () => {

									params[ name ] = input.checked;
									valueElem.textContent = params[ name ] ? 'true' : 'false';
									updateGeometry( root, info, params );

								} );
								break;

							}

							case 'text': {

								const input = document.createElement( 'input' );
								input.type = 'text';
								params[ name ] = valueElem.textContent.slice( 1, - 1 );
								input.value = params[ name ];
								input.maxlength = ui.maxLength || 50;
								inputHolder.appendChild( input );
								input.addEventListener( 'input', () => {

									params[ name ] = input.value;
									valueElem.textContent = `'${input.value}'`;
									updateGeometry( root, info, params );

								} );
								break;

							}

							default:
								throw new Error( `unknown type for ${primitiveName}:${ndx} param: ${name}` );

						}

					} );

			} );

		} );

	} );

	document.querySelectorAll( '[data-diagram]' ).forEach( createDiagram );
	document.querySelectorAll( '[data-primitive]' ).forEach( createPrimitiveDOM );

}
