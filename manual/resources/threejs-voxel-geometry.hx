Here is the converted Haxe code:
```
package three.js.manual.resources;

import three.*;

class ThreejsVoxelGeometry {
	static var darkMatcher:js.html.MediaQueryList = window.matchMedia('(prefers-color-scheme: dark)');
	static var isDarkMode:Bool = darkMatcher.matches;

	static var darkColors = {
		wire: '#DDD'
	};

	static var lightColors = {
		wire: '#000'
	};

	static var colors = isDarkMode ? darkColors : lightColors;

	static function main() {
		threejsLessonUtils.addDiagrams({
			mergedCubes: {
				create: function() {
					var geometries:Array<Geometry> = [];
					var width:Int = 3;
					var height:Int = 2;
					var depth:Int = 2;
					for (y in 0...height) {
						for (z in 0...depth) {
							for (x in 0...width) {
								var geometry = new BoxGeometry(1, 1, 1);
								geometry.applyMatrix(new Matrix4().makeTranslation(x, y, z));
								geometries.push(geometry);
							}
						}
					}
					var mergedGeometry = BufferGeometryUtils.mergeGeometries(geometries, false);
					var material = new MeshBasicMaterial({
						color: colors.wire,
						wireframe: true
					});
					var mesh = new Mesh(mergedGeometry, material);
					mesh.position.set(
						0.5 - width / 2,
						0.5 - height / 2,
						0.5 - depth / 2
					);
					var base = new Object3D();
					base.add(mesh);
					base.scale.setScalar(3.5);
					return base;
				}
			},
			culledCubes: {
				create: function() {
					var geometry = new BoxGeometry(3, 2, 2, 3, 2, 2);
					var material = new MeshBasicMaterial({
						color: colors.wire,
						wireframe: true
					});
					var mesh = new Mesh(geometry, material);
					mesh.scale.setScalar(3.5);
					return mesh;
				}
			}
		});
	}

	static function new() {
		main();
	}
}
```
Note:

* I used the `js.html.MediaQueryList` class to represent the `window.matchMedia` result, as Haxe has built-in support for JavaScript DOM types.
* I replaced `import * as THREE from 'three';` with `import three.*;`, as Haxe uses a different syntax for importing modules.
* I replaced `import * as BufferGeometryUtils from '../../examples/jsm/utils/BufferGeometryUtils.js';` with `import three.*;`, assuming that `BufferGeometryUtils` is part of the `three` module.
* I replaced `import { threejsLessonUtils } from './threejs-lesson-utils.js';` with a simple reference to `threejsLessonUtils`, assuming that it is a global variable or a part of the `three` module.
* I used Haxe's `Array` type to represent JavaScript arrays.
* I used Haxe's `for` loop syntax, which is similar to JavaScript's.
* I used Haxe's `new` keyword to create new instances of classes, and `.` syntax to access properties and methods.

Please note that this conversion is not perfect, and you may need to adjust the code to fit your specific use case.