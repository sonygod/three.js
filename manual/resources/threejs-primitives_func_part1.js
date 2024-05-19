import * as THREE from 'three';
import { threejsLessonUtils } from './threejs-lesson-utils.js';
import { FontLoader } from '../../examples/jsm/loaders/FontLoader.js';
import { ParametricGeometry } from '../../examples/jsm/geometries/ParametricGeometry.js';
import { TextGeometry } from '../../examples/jsm/geometries/TextGeometry.js';

{

	const darkColors = {
		lines: '#DDD',
	};
	const lightColors = {
		lines: '#000',
	};

	const darkMatcher = window.matchMedia( '(prefers-color-scheme: dark)' );
	const isDarkMode = darkMatcher.matches;
	const colors = isDarkMode ? darkColors : lightColors;

	const fontLoader = new FontLoader();
	const fontPromise = new Promise( ( resolve ) => {

		fontLoader.load( '/examples/fonts/helvetiker_regular.typeface.json', resolve );

	} );

	const diagrams = {
		BoxGeometry: {
			ui: {
				width: { type: 'range', min: 1, max: 10, precision: 1, },
				height: { type: 'range', min: 1, max: 10, precision: 1, },
				depth: { type: 'range', min: 1, max: 10, precision: 1, },
				widthSegments: { type: 'range', min: 1, max: 10, },
				heightSegments: { type: 'range', min: 1, max: 10, },
				depthSegments: { type: 'range', min: 1, max: 10, },
			},
			create( width = 8, height = 8, depth = 8 ) {

				return new THREE.BoxGeometry( width, height, depth );

			},
			create2( width = 8, height = 8, depth = 8, widthSegments = 4, heightSegments = 4, depthSegments = 4 ) {

				return new THREE.BoxGeometry(
					width, height, depth,
					widthSegments, heightSegments, depthSegments );

			},
		},
		CircleGeometry: {
			ui: {
				radius: { type: 'range', min: 1, max: 10, precision: 1, },
				segments: { type: 'range', min: 1, max: 50, },
				thetaStart: { type: 'range', min: 0, max: 2, mult: Math.PI },
				thetaLength: { type: 'range', min: 0, max: 2, mult: Math.PI },
			},
			create( radius = 7, segments = 24 ) {

				return new THREE.CircleGeometry( radius, segments );

			},
			create2( radius = 7, segments = 24, thetaStart = Math.PI * 0.25, thetaLength = Math.PI * 1.5 ) {

				return new THREE.CircleGeometry(
					radius, segments, thetaStart, thetaLength );

			},
		},
		ConeGeometry: {
			ui: {
				radius: { type: 'range', min: 1, max: 10, precision: 1, },
				height: { type: 'range', min: 1, max: 10, precision: 1, },
				radialSegments: { type: 'range', min: 1, max: 50, },
				heightSegments: { type: 'range', min: 1, max: 10, },
				openEnded: { type: 'bool', },
				thetaStart: { type: 'range', min: 0, max: 2, mult: Math.PI },
				thetaLength: { type: 'range', min: 0, max: 2, mult: Math.PI },
			},
			create( radius = 6, height = 8, radialSegments = 16 ) {

				return new THREE.ConeGeometry( radius, height, radialSegments );

			},
			create2( radius = 6, height = 8, radialSegments = 16, heightSegments = 2, openEnded = true, thetaStart = Math.PI * 0.25, thetaLength = Math.PI * 1.5 ) {

				return new THREE.ConeGeometry(
					radius, height,
					radialSegments, heightSegments,
					openEnded,
					thetaStart, thetaLength );

			},
		},
		CylinderGeometry: {
			ui: {
				radiusTop: { type: 'range', min: 0, max: 10, precision: 1, },
				radiusBottom: { type: 'range', min: 0, max: 10, precision: 1, },
				height: { type: 'range', min: 1, max: 10, precision: 1, },
				radialSegments: { type: 'range', min: 1, max: 50, },
				heightSegments: { type: 'range', min: 1, max: 10, },
				openEnded: { type: 'bool', },
				thetaStart: { type: 'range', min: 0, max: 2, mult: Math.PI },
				thetaLength: { type: 'range', min: 0, max: 2, mult: Math.PI },
			},
			create( radiusTop = 4, radiusBottom = 4, height = 8, radialSegments = 12 ) {

				return new THREE.CylinderGeometry(
					radiusTop, radiusBottom, height, radialSegments );

			},
			create2( radiusTop = 4, radiusBottom = 4, height = 8, radialSegments = 12, heightSegments = 2, openEnded = false, thetaStart = Math.PI * 0.25, thetaLength = Math.PI * 1.5 ) {

				return new THREE.CylinderGeometry(
					radiusTop, radiusBottom, height,
					radialSegments, heightSegments,
					openEnded,
					thetaStart, thetaLength );

			},
		},
		DodecahedronGeometry: {
			ui: {
				radius: { type: 'range', min: 1, max: 10, precision: 1, },
				detail: { type: 'range', min: 0, max: 5, precision: 0, },
			},
			create( radius = 7 ) {

				return new THREE.DodecahedronGeometry( radius );

			},
			create2( radius = 7, detail = 2 ) {

				return new THREE.DodecahedronGeometry( radius, detail );

			},
		},
		ExtrudeGeometry: {
			ui: {
				steps: { type: 'range', min: 1, max: 100, },
				depth: { type: 'range', min: 1, max: 20, precision: 1, },
				bevelEnabled: { type: 'bool', },
				bevelThickness: { type: 'range', min: 0.1, max: 3, },
				bevelSize: { type: 'range', min: 0.1, max: 3, },
				bevelSegments: { type: 'range', min: 0, max: 8, },
			},
			addConstCode: false,
			create( steps = 2, depth = 2, bevelEnabled = true, bevelThickness = 1, bevelSize = 1, bevelSegments = 2 ) {

				const shape = new THREE.Shape();
				const x = - 2.5;
				const y = - 5;
				shape.moveTo( x + 2.5, y + 2.5 );
				shape.bezierCurveTo( x + 2.5, y + 2.5, x + 2, y, x, y );
				shape.bezierCurveTo( x - 3, y, x - 3, y + 3.5, x - 3, y + 3.5 );
				shape.bezierCurveTo( x - 3, y + 5.5, x - 1.5, y + 7.7, x + 2.5, y + 9.5 );
				shape.bezierCurveTo( x + 6, y + 7.7, x + 8, y + 4.5, x + 8, y + 3.5 );
				shape.bezierCurveTo( x + 8, y + 3.5, x + 8, y, x + 5, y );
				shape.bezierCurveTo( x + 3.5, y, x + 2.5, y + 2.5, x + 2.5, y + 2.5 );

				const extrudeSettings = {
					steps,
					depth,
					bevelEnabled,
					bevelThickness,
					bevelSize,
					bevelSegments,
				};

				const geometry = new THREE.ExtrudeGeometry( shape, extrudeSettings );
				return geometry;

			},
			src: `
const shape = new THREE.Shape();
const x = -2.5;
const y = -5;
shape.moveTo(x + 2.5, y + 2.5);
shape.bezierCurveTo(x + 2.5, y + 2.5, x + 2, y, x, y);
shape.bezierCurveTo(x - 3, y, x - 3, y + 3.5, x - 3, y + 3.5);
shape.bezierCurveTo(x - 3, y + 5.5, x - 1.5, y + 7.7, x + 2.5, y + 9.5);
shape.bezierCurveTo(x + 6, y + 7.7, x + 8, y + 4.5, x + 8, y + 3.5);
shape.bezierCurveTo(x + 8, y + 3.5, x + 8, y, x + 5, y);
shape.bezierCurveTo(x + 3.5, y, x + 2.5, y + 2.5, x + 2.5, y + 2.5);

const extrudeSettings = {
  steps: 2,  // ui: steps
  depth: 2,  // ui: depth
  bevelEnabled: true,  // ui: bevelEnabled
  bevelThickness: 1,  // ui: bevelThickness
  bevelSize: 1,  // ui: bevelSize
  bevelSegments: 2,  // ui: bevelSegments
};

const geometry = THREE.ExtrudeGeometry(shape, extrudeSettings);
`,
			create2( steps = 100 ) {

				const outline = new THREE.Shape( [
					[ - 2, - 0.1 ], [ 2, - 0.1 ], [ 2, 0.6 ],
					[ 1.6, 0.6 ], [ 1.6, 0.1 ], [ - 2, 0.1 ],
				].map( p => new THREE.Vector2( ...p ) ) );

				const x = - 2.5;
				const y = - 5;
				const shape = new THREE.CurvePath();
				const points = [
					[ x + 2.5, y + 2.5 ],
					[ x + 2.5, y + 2.5 ], [ x + 2, y ], [ x, y ],
					[ x - 3, y ], [ x - 3, y + 3.5 ], [ x - 3, y + 3.5 ],
					[ x - 3, y + 5.5 ], [ x - 1.5, y + 7.7 ], [ x + 2.5, y + 9.5 ],
					[ x + 6, y + 7.7 ], [ x + 8, y + 4.5 ], [ x + 8, y + 3.5 ],
					[ x + 8, y + 3.5 ], [ x + 8, y ], [ x + 5, y ],
					[ x + 3.5, y ], [ x + 2.5, y + 2.5 ], [ x + 2.5, y + 2.5 ],
				].map( p => new THREE.Vector3( ...p, 0 ) );
				for ( let i = 0; i < points.length; i += 3 ) {

					shape.add( new THREE.CubicBezierCurve3( ...points.slice( i, i + 4 ) ) );

				}

				const extrudeSettings = {
					steps,
					bevelEnabled: false,
					extrudePath: shape,
				};

				const geometry = new THREE.ExtrudeGeometry( outline, extrudeSettings );
				return geometry;

			},
			src2: `
const outline = new THREE.Shape([
  [ -2, -0.1], [  2, -0.1], [ 2,  0.6],
  [1.6,  0.6], [1.6,  0.1], [-2,  0.1],
].map(p => new THREE.Vector2(...p)));

const x = -2.5;
const y = -5;
const shape = new THREE.CurvePath();
const points = [
  [x + 2.5, y + 2.5],
  [x + 2.5, y + 2.5], [x + 2,   y      ], [x,       y      ],
  [x - 3,   y      ], [x - 3,   y + 3.5], [x - 3,   y + 3.5],
  [x - 3,   y + 5.5], [x - 1.5, y + 7.7], [x + 2.5, y + 9.5],
  [x + 6,   y + 7.7], [x + 8,   y + 4.5], [x + 8,   y + 3.5],
  [x + 8,   y + 3.5], [x + 8,   y      ], [x + 5,   y      ],
  [x + 3.5, y      ], [x + 2.5, y + 2.5], [x + 2.5, y + 2.5],
].map(p => new THREE.Vector3(...p, 0));
for (let i = 0; i < points.length; i += 3) {
  shape.add(new THREE.CubicBezierCurve3(...points.slice(i, i + 4)));
}

const extrudeSettings = {
  steps: 100,  // ui: steps
  bevelEnabled: false,
  extrudePath: shape,
};

const geometry =  new THREE.ExtrudeGeometry(outline, extrudeSettings);
return geometry;
      `,
		},
		IcosahedronGeometry: {
			ui: {
				radius: { type: 'range', min: 1, max: 10, precision: 1, },
				detail: { type: 'range', min: 0, max: 5, precision: 0, },
			},
			create( radius = 7 ) {

				return new THREE.IcosahedronGeometry( radius );

			},
			create2( radius = 7, detail = 2 ) {

				return new THREE.IcosahedronGeometry( radius, detail );

			},
		},
		LatheGeometry: {
			ui: {
				segments: { type: 'range', min: 1, max: 50, },
				phiStart: { type: 'range', min: 0, max: 2, mult: Math.PI },
				phiLength: { type: 'range', min: 0, max: 2, mult: Math.PI },
			},
			create() {

				const points = [];
				for ( let i = 0; i < 10; ++ i ) {

					points.push( new THREE.Vector2( Math.sin( i * 0.2 ) * 3 + 3, ( i - 5 ) * .8 ) );

				}

				return new THREE.LatheGeometry( points );

			},
			create2( segments = 12, phiStart = Math.PI * 0.25, phiLength = Math.PI * 1.5 ) {

				const points = [];
				for ( let i = 0; i < 10; ++ i ) {

					points.push( new THREE.Vector2( Math.sin( i * 0.2 ) * 3 + 3, ( i - 5 ) * .8 ) );

				}

				return new THREE.LatheGeometry(
					points, segments, phiStart, phiLength );

			},
		},
		OctahedronGeometry: {
			ui: {
				radius: { type: 'range', min: 1, max: 10, precision: 1, },
				detail: { type: 'range', min: 0, max: 5, precision: 0, },
			},
			create( radius = 7 ) {

				return new THREE.OctahedronGeometry( radius );

			},
			create2( radius = 7, detail = 2 ) {

				return new THREE.OctahedronGeometry( radius, detail );

			},
		},
		ParametricGeometry: {
			ui: {
				stacks: { type: 'range', min: 1, max: 50, },
				slices: { type: 'range', min: 1, max: 50, },
			},
			/*
      from: https://github.com/mrdoob/three.js/blob/b8d8a8625465bd634aa68e5846354d69f34d2ff5/examples/js/ParametricGeometries.js

      The MIT License

      Copyright © 2010-2018 three.js authors

      Permission is hereby granted, free of charge, to any person obtaining a copy
      of this software and associated documentation files (the "Software"), to deal
      in the Software without restriction, including without limitation the rights
      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
      copies of the Software, and to permit persons to whom the Software is
      furnished to do so, subject to the following conditions:

      The above copyright notice and this permission notice shall be included in
      all copies or substantial portions of the Software.

      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
      THE SOFTWARE.

      */
			create( slices = 25, stacks = 25 ) {

				// from: https://github.com/mrdoob/three.js/blob/b8d8a8625465bd634aa68e5846354d69f34d2ff5/examples/js/ParametricGeometries.js
				function klein( v, u, target ) {

					u *= Math.PI;
					v *= 2 * Math.PI;
					u = u * 2;

					let x;
					let z;

					if ( u < Math.PI ) {

						x = 3 * Math.cos( u ) * ( 1 + Math.sin( u ) ) + ( 2 * ( 1 - Math.cos( u ) / 2 ) ) * Math.cos( u ) * Math.cos( v );
						z = - 8 * Math.sin( u ) - 2 * ( 1 - Math.cos( u ) / 2 ) * Math.sin( u ) * Math.cos( v );

					} else {

						x = 3 * Math.cos( u ) * ( 1 + Math.sin( u ) ) + ( 2 * ( 1 - Math.cos( u ) / 2 ) ) * Math.cos( v + Math.PI );
						z = - 8 * Math.sin( u );

					}

					const y = - 2 * ( 1 - Math.cos( u ) / 2 ) * Math.sin( v );

					target.set( x, y, z ).multiplyScalar( 0.75 );

				}

				return new ParametricGeometry(
					klein, slices, stacks );

			},
		},
		PlaneGeometry: {
			ui: {
				width: { type: 'range', min: 1, max: 10, precision: 1, },
				height: { type: 'range', min: 1, max: 10, precision: 1, },
				widthSegments: { type: 'range', min: 1, max: 10, },
				heightSegments: { type: 'range', min: 1, max: 10, },
			},
			create( width = 9, height = 9 ) {

				return new THREE.PlaneGeometry( width, height );

			},
			create2( width = 9, height = 9, widthSegments = 2, heightSegments = 2 ) {

				return new THREE.PlaneGeometry(
					width, height,
					widthSegments, heightSegments );

			},
		},
		PolyhedronGeometry: {
			ui: {
				radius: { type: 'range', min: 1, max: 10, precision: 1, },
				detail: { type: 'range', min: 0, max: 5, precision: 0, },
			},
			create( radius = 7, detail = 2 ) {

				const verticesOfCube = [
					- 1, - 1, - 1, 1, - 1, - 1, 1, 1, - 1, - 1, 1, - 1,
					- 1, - 1, 1, 1, - 1, 1, 1, 1, 1, - 1, 1, 1,
				];
				const indicesOfFaces = [
					2, 1, 0, 0, 3, 2,
					0, 4, 7, 7, 3, 0,
					0, 1, 5, 5, 4, 0,
					1, 2, 6, 6, 5, 1,
					2, 3, 7, 7, 6, 2,
					4, 5, 6, 6, 7, 4,
				];
				return new THREE.PolyhedronGeometry(
					verticesOfCube, indicesOfFaces, radius, detail );

			},
		},
		RingGeometry: {
			ui: {
				innerRadius: { type: 'range', min: 1, max: 10, precision: 1, },
				outerRadius: { type: 'range', min: 1, max: 10, precision: 1, },
				thetaSegments: { type: 'range', min: 1, max: 30, },
				phiSegments: { type: 'range', min: 1, max: 10, },
				thetaStart: { type: 'range', min: 0, max: 2, mult: Math.PI },
				thetaLength: { type: 'range', min: 0, max: 2, mult: Math.PI },
			},
			create( innerRadius = 2, outerRadius = 7, thetaSegments = 18 ) {

				return new THREE.RingGeometry(
					innerRadius, outerRadius, thetaSegments );

			},
			create2( innerRadius = 2, outerRadius = 7, thetaSegments = 18, phiSegments = 2, thetaStart = Math.PI * 0.25, thetaLength = Math.PI * 1.5 ) {

				return new THREE.RingGeometry(
					innerRadius, outerRadius,
					thetaSegments, phiSegments,
					thetaStart, thetaLength );

			},
		},
		ShapeGeometry: {
			ui: {
				curveSegments: { type: 'range', min: 1, max: 30, },
			},
			create() {

				const shape = new THREE.Shape();
				const x = - 2.5;
				const y = - 5;
				shape.moveTo( x + 2.5, y + 2.5 );
				shape.bezierCurveTo( x + 2.5, y + 2.5, x + 2, y, x, y );
				shape.bezierCurveTo( x - 3, y, x - 3, y + 3.5, x - 3, y + 3.5 );
				shape.bezierCurveTo( x - 3, y + 5.5, x - 1.5, y + 7.7, x + 2.5, y + 9.5 );
				shape.bezierCurveTo( x + 6, y + 7.7, x + 8, y + 4.5, x + 8, y + 3.5 );
				shape.bezierCurveTo( x + 8, y + 3.5, x + 8, y, x + 5, y );
				shape.bezierCurveTo( x + 3.5, y, x + 2.5, y + 2.5, x + 2.5, y + 2.5 );
				return new THREE.ShapeGeometry( shape );

			},
			create2( curveSegments = 5 ) {

				const shape = new THREE.Shape();
				const x = - 2.5;
				const y = - 5;
				shape.moveTo( x + 2.5, y + 2.5 );
				shape.bezierCurveTo( x + 2.5, y + 2.5, x + 2, y, x, y );
				shape.bezierCurveTo( x - 3, y, x - 3, y + 3.5, x - 3, y + 3.5 );
				shape.bezierCurveTo( x - 3, y + 5.5, x - 1.5, y + 7.7, x + 2.5, y + 9.5 );
				shape.bezierCurveTo( x + 6, y + 7.7, x + 8, y + 4.5, x + 8, y + 3.5 );
				shape.bezierCurveTo( x + 8, y + 3.5, x + 8, y, x + 5, y );
				shape.bezierCurveTo( x + 3.5, y, x + 2.5, y + 2.5, x + 2.5, y + 2.5 );
				return new THREE.ShapeGeometry( shape, curveSegments );

			},
		},
		SphereGeometry: {
			ui: {
				radius: { type: 'range', min: 1, max: 10, precision: 1, },
				widthSegments: { type: 'range', min: 1, max: 30, },
				heightSegments: { type: 'range', min: 1, max: 30, },
				phiStart: { type: 'range', min: 0, max: 2, mult: Math.PI },
				phiLength: { type: 'range', min: 0, max: 2, mult: Math.PI },
				thetaStart: { type: 'range', min: 0, max: 1, mult: Math.PI },
				thetaLength: { type: 'range', min: 0, max: 1, mult: Math.PI },
			},
			create( radius = 7, widthSegments = 12, heightSegments = 8 ) {

				return new THREE.SphereGeometry( radius, widthSegments, heightSegments );

			},
			create2( radius = 7, widthSegments = 12, heightSegments = 8, phiStart = Math.PI * 0.25, phiLength = Math.PI * 1.5, thetaStart = Math.PI * 0.25, thetaLength = Math.PI * 0.5 ) {

				return new THREE.SphereGeometry(
					radius,
					widthSegments, heightSegments,
					phiStart, phiLength,
					thetaStart, thetaLength );

			},
		},
		TetrahedronGeometry: {
			ui: {
				radius: { type: 'range', min: 1, max: 10, precision: 1, },
				detail: { type: 'range', min: 0, max: 5, precision: 0, },
			},
			create( radius = 7 ) {

				return new THREE.TetrahedronGeometry( radius );

			},
			create2( radius = 7, detail = 2 ) {

				return new THREE.TetrahedronGeometry( radius, detail );

			},
		},
		TextGeometry: {
			ui: {
				text: { type: 'text', maxLength: 30, },
				size: { type: 'range', min: 1, max: 10, precision: 1, },
				depth: { type: 'range', min: 1, max: 10, precision: 1, },
				curveSegments: { type: 'range', min: 1, max: 20, },
				// font', fonts ).onChange( generateGeometry );
				// weight', weights ).onChange( generateGeometry );
				bevelEnabled: { type: 'bool', },
				bevelThickness: { type: 'range', min: 0.1, max: 3, },
				bevelSize: { type: 'range', min: 0.1, max: 3, },
				bevelSegments: { type: 'range', min: 0, max: 8, },
			},
			addConstCode: false,
			create( text = 'three.js', size = 3, depth = 0.2, curveSegments = 12, bevelEnabled = true, bevelThickness = 0.15, bevelSize = 0.3, bevelSegments = 5 ) {

				return new Promise( ( resolve ) => {

					fontPromise.then( ( font ) => {

						resolve( new TextGeometry( text, {
							font: font,
							size,
							depth,
							curveSegments,
							bevelEnabled,
							bevelThickness,
							bevelSize,
							bevelSegments,
						} ) );

					} );

				} );

			},
			src: `
const loader = new THREE.FontLoader();

loader.load('../resources/threejs/fonts/helvetiker_regular.typeface.json', (font) => {
  const text = 'three.js';  // ui: text
  const geometry = new THREE.TextGeometry(text, {
    font: font,
    size: 3,  // ui: size
    depth: 0.2,  // ui: depth
    curveSegments: 12,  // ui: curveSegments
    bevelEnabled: true,  // ui: bevelEnabled
    bevelThickness: 0.15,  // ui: bevelThickness
    bevelSize: 0.3,  // ui: bevelSize
    bevelSegments: 5,  // ui: bevelSegments
  });
  ...
});
      `,
		},
		TorusGeometry: {
			ui: {
				radius: { type: 'range', min: 1, max: 10, precision: 1, },
				tubeRadius: { type: 'range', min: 1, max: 10, precision: 1, },
				radialSegments: { type: 'range', min: 1, max: 30, },
				tubularSegments: { type: 'range', min: 1, max: 100, },
			},
			create( radius = 5, tubeRadius = 2, radialSegments = 8, tubularSegments = 24 ) {

				return new THREE.TorusGeometry(
					radius, tubeRadius,
					radialSegments, tubularSegments );

			},
		},
		TorusKnotGeometry: {
			ui: {
				radius: { type: 'range', min: 1, max: 10, precision: 1, },
				tubeRadius: { type: 'range', min: 1, max: 10, precision: 1, },
				radialSegments: { type: 'range', min: 1, max: 30, },
				tubularSegments: { type: 'range', min: 1, max: 100, },
				p: { type: 'range', min: 1, max: 20, },
				q: { type: 'range', min: 1, max: 20, },
			},
			create( radius = 3.5, tubeRadius = 1.5, radialSegments = 8, tubularSegments = 64, p = 2, q = 3 ) {

				return new THREE.TorusKnotGeometry(
					radius, tubeRadius, tubularSegments, radialSegments, p, q );

			},
		},
		TubeGeometry: {
			ui: {
				tubularSegments: { type: 'range', min: 1, max: 100, },
				radius: { type: 'range', min: 1, max: 10, precision: 1, },
				radialSegments: { type: 'range', min: 1, max: 30, },
				closed: { type: 'bool', },
			},
			create( tubularSegments = 20, radius = 1, radialSegments = 8, closed = false ) {

				