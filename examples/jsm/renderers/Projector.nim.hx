import three.js.examples.jsm.math.Box3;
import three.js.examples.jsm.math.Color;
import three.js.examples.jsm.math.DoubleSide;
import three.js.examples.jsm.math.Frustum;
import three.js.examples.jsm.math.Matrix3;
import three.js.examples.jsm.math.Matrix4;
import three.js.examples.jsm.math.Vector2;
import three.js.examples.jsm.math.Vector3;
import three.js.examples.jsm.math.Vector4;

class RenderableObject {

	public var id:Int = 0;

	public var object:Dynamic;
	public var z:Float = 0;
	public var renderOrder:Int = 0;

	public function new() {}

}

//

class RenderableFace {

	public var id:Int = 0;

	public var v1:RenderableVertex = new RenderableVertex();
	public var v2:RenderableVertex = new RenderableVertex();
	public var v3:RenderableVertex = new RenderableVertex();

	public var normalModel:Vector3 = new Vector3();

	public var vertexNormalsModel:Array<Vector3> = [new Vector3(), new Vector3(), new Vector3()];
	public var vertexNormalsLength:Int = 0;

	public var color:Color = new Color();
	public var material:Dynamic;
	public var uvs:Array<Vector2> = [new Vector2(), new Vector2(), new Vector2()];

	public var z:Float = 0;
	public var renderOrder:Int = 0;

	public function new() {}

}

//

class RenderableVertex {

	public var position:Vector3 = new Vector3();
	public var positionWorld:Vector3 = new Vector3();
	public var positionScreen:Vector4 = new Vector4();

	public var visible:Bool = true;

	public function new() {}

	public function copy(vertex:RenderableVertex):Void {

		this.positionWorld.copy(vertex.positionWorld);
		this.positionScreen.copy(vertex.positionScreen);

	}

}

//

class RenderableLine {

	public var id:Int = 0;

	public var v1:RenderableVertex = new RenderableVertex();
	public var v2:RenderableVertex = new RenderableVertex();

	public var vertexColors:Array<Color> = [new Color(), new Color()];
	public var material:Dynamic;

	public var z:Float = 0;
	public var renderOrder:Int = 0;

	public function new() {}

}

//

class RenderableSprite {

	public var id:Int = 0;

	public var object:Dynamic;

	public var x:Float = 0;
	public var y:Float = 0;
	public var z:Float = 0;

	public var rotation:Float = 0;
	public var scale:Vector2 = new Vector2();

	public var material:Dynamic;
	public var renderOrder:Int = 0;

	public function new() {}

}

//

class Projector {

	private var _object:RenderableObject;
	private var _objectCount:Int;
	private var _objectPoolLength:Int = 0;

	private var _vertex:RenderableVertex;
	private var _vertexCount:Int;
	private var _vertexPoolLength:Int = 0;

	private var _face:RenderableFace;
	private var _faceCount:Int;
	private var _facePoolLength:Int = 0;

	private var _line:RenderableLine;
	private var _lineCount:Int;
	private var _linePoolLength:Int = 0;

	private var _sprite:RenderableSprite;
	private var _spriteCount:Int;
	private var _spritePoolLength:Int = 0;

	private var _modelMatrix:Matrix4;

	private var _renderData:Dynamic = { objects: [], lights: [], elements: [] };

	private var _vector3:Vector3 = new Vector3();
	private var _vector4:Vector4 = new Vector4();

	private var _clipBox:Box3 = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1));
	private var _boundingBox:Box3 = new Box3();
	private var _points3:Array<Vector3> = new Array<Vector3>(3);

	private var _viewMatrix:Matrix4 = new Matrix4();
	private var _viewProjectionMatrix:Matrix4 = new Matrix4();

	private var _modelViewProjectionMatrix:Matrix4 = new Matrix4();

	private var _frustum:Frustum = new Frustum();

	private var _objectPool:Array<RenderableObject> = [];
	private var _vertexPool:Array<RenderableVertex> = [];
	private var _facePool:Array<RenderableFace> = [];
	private var _linePool:Array<RenderableLine> = [];
	private var _spritePool:Array<RenderableSprite> = [];

	//

	private function RenderList() {

		var normals:Array<Float> = [];
		var colors:Array<Float> = [];
		var uvs:Array<Float> = [];

		var object:Dynamic;

		var normalMatrix:Matrix3 = new Matrix3();

		function setObject(value:Dynamic):Void {

			object = value;

			normalMatrix.getNormalMatrix(object.matrixWorld);

			normals.length = 0;
			colors.length = 0;
			uvs.length = 0;

		}

		function projectVertex(vertex:RenderableVertex):Void {

			var position:Vector3 = vertex.position;
			var positionWorld:Vector3 = vertex.positionWorld;
			var positionScreen:Vector4 = vertex.positionScreen;

			positionWorld.copy(position).applyMatrix4(_modelMatrix);
			positionScreen.copy(positionWorld).applyMatrix4(_viewProjectionMatrix);

			var invW:Float = 1 / positionScreen.w;

			positionScreen.x *= invW;
			positionScreen.y *= invW;
			positionScreen.z *= invW;

			vertex.visible = positionScreen.x >= -1 && positionScreen.x <= 1 &&
							 positionScreen.y >= -1 && positionScreen.y <= 1 &&
							 positionScreen.z >= -1 && positionScreen.z <= 1;

		}

		function pushVertex(x:Float, y:Float, z:Float):Void {

			_vertex = getNextVertexInPool();
			_vertex.position.set(x, y, z);

			projectVertex(_vertex);

		}

		function pushNormal(x:Float, y:Float, z:Float):Void {

			normals.push(x, y, z);

		}

		function pushColor(r:Float, g:Float, b:Float):Void {

			colors.push(r, g, b);

		}

		function pushUv(x:Float, y:Float):Void {

			uvs.push(x, y);

		}

		function checkTriangleVisibility(v1:RenderableVertex, v2:RenderableVertex, v3:RenderableVertex):Bool {

			if (v1.visible == true || v2.visible == true || v3.visible == true) return true;

			_points3[0] = v1.positionScreen;
			_points3[1] = v2.positionScreen;
			_points3[2] = v3.positionScreen;

			return _clipBox.intersectsBox(_boundingBox.setFromPoints(_points3));

		}

		function checkBackfaceCulling(v1:RenderableVertex, v2:RenderableVertex, v3:RenderableVertex):Bool {

			return ( ( v3.positionScreen.x - v1.positionScreen.x ) *
					 ( v2.positionScreen.y - v1.positionScreen.y ) -
					 ( v3.positionScreen.y - v1.positionScreen.y ) *
					 ( v2.positionScreen.x - v1.positionScreen.x ) ) < 0;

		}

		function pushLine(a:Int, b:Int):Void {

			var v1:RenderableVertex = _vertexPool[a];
			var v2:RenderableVertex = _vertexPool[b];

			// Clip

			v1.positionScreen.copy(v1.position).applyMatrix4(_modelViewProjectionMatrix);
			v2.positionScreen.copy(v2.position).applyMatrix4(_modelViewProjectionMatrix);

			if (clipLine(v1.positionScreen, v2.positionScreen) == true) {

				// Perform the perspective divide
				v1.positionScreen.multiplyScalar(1 / v1.positionScreen.w);
				v2.positionScreen.multiplyScalar(1 / v2.positionScreen.w);

				_line = getNextLineInPool();
				_line.id = object.id;
				_line.v1.copy(v1);
				_line.v2.copy(v2);
				_line.z = Math.max(v1.positionScreen.z, v2.positionScreen.z);
				_line.renderOrder = object.renderOrder;

				_line.material = object.material;

				if (object.material.vertexColors) {

					_line.vertexColors[0].fromArray(colors, a * 3);
					_line.vertexColors[1].fromArray(colors, b * 3);

				}

				_renderData.elements.push(_line);

			}

		}

		function pushTriangle(a:Int, b:Int, c:Int, material:Dynamic):Void {

			var v1:RenderableVertex = _vertexPool[a];
			var v2:RenderableVertex = _vertexPool[b];
			var v3:RenderableVertex = _vertexPool[c];

			if (checkTriangleVisibility(v1, v2, v3) == false) return;

			if (material.side == DoubleSide || checkBackfaceCulling(v1, v2, v3) == true) {

				_face = getNextFaceInPool();

				_face.id = object.id;
				_face.v1.copy(v1);
				_face.v2.copy(v2);
				_face.v3.copy(v3);
				_face.z = (v1.positionScreen.z + v2.positionScreen.z + v3.positionScreen.z) / 3;
				_face.renderOrder = object.renderOrder;

				// face normal
				_vector3.subVectors(v3.position, v2.position);
				_vector4.subVectors(v1.position, v2.position);
				_vector3.cross(_vector4);
				_face.normalModel.copy(_vector3);
				_face.normalModel.applyMatrix3(normalMatrix).normalize();

				for (i in 0...3) {

					var normal:Vector3 = _face.vertexNormalsModel[i];
					normal.fromArray(normals, arguments[i] * 3);
					normal.applyMatrix3(normalMatrix).normalize();

					var uv:Vector2 = _face.uvs[i];
					uv.fromArray(uvs, arguments[i] * 2);

				}

				_face.vertexNormalsLength = 3;

				_face.material = material;

				if (material.vertexColors) {

					_face.color.fromArray(colors, a * 3);

				}

				_renderData.elements.push(_face);

			}

		}

		return {
			setObject: setObject,
			projectVertex: projectVertex,
			checkTriangleVisibility: checkTriangleVisibility,
			checkBackfaceCulling: checkBackfaceCulling,
			pushVertex: pushVertex,
			pushNormal: pushNormal,
			pushColor: pushColor,
			pushUv: pushUv,
			pushLine: pushLine,
			pushTriangle: pushTriangle
		};

	}

	private var renderList:RenderList = new RenderList();

	public function new() {}

	public function projectScene(scene:Dynamic, camera:Dynamic, sortObjects:Bool, sortElements:Bool):Dynamic {

		_faceCount = 0;
		_lineCount = 0;
		_spriteCount = 0;

		_renderData.elements.length = 0;

		if (scene.matrixWorldAutoUpdate == true) scene.updateMatrixWorld();
		if (camera.parent == null && camera.matrixWorldAutoUpdate == true) camera.updateMatrixWorld();

		_viewMatrix.copy(camera.matrixWorldInverse);
		_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

		_frustum.setFromProjectionMatrix(_viewProjectionMatrix);

		//

		_objectCount = 0;

		_renderData.objects.length = 0;
		_renderData.lights.length = 0;

		projectObject(scene);

		if (sortObjects == true) {

			_renderData.objects.sort(painterSort);

		}

		//

		var objects:Array<RenderableObject> = _renderData.objects;

		for (o in 0...objects.length) {

			var object:Dynamic = objects[o].object;
			var geometry:Dynamic = object.geometry;

			renderList.setObject(object);

			_modelMatrix = object.matrixWorld;

			_vertexCount = 0;

			if (object.isMesh) {

				var material:Dynamic = object.material;

				var isMultiMaterial:Bool = Array.isArray(material);

				var attributes:Dynamic = geometry.attributes;
				var groups:Array<Dynamic> = geometry.groups;

				if (attributes.position == undefined) continue;

				var positions:Array<Float> = attributes.position.array;

				for (i in 0...positions.length) {

					var x:Float = positions[i];
					var y:Float = positions[i + 1];
					var z:Float = positions[i + 2];

					var morphTargets:Dynamic = geometry.morphAttributes.position;

					if (morphTargets != undefined) {

						var morphTargetsRelative:Bool = geometry.morphTargetsRelative;
						var morphInfluences:Array<Float> = object.morphTargetInfluences;

						for (t in 0...morphTargets.length) {

							var influence:Float = morphInfluences[t];

							if (influence == 0) continue;

							var target:Dynamic = morphTargets[t];

							if (morphTargetsRelative) {

								x += target.getX(i / 3) * influence;
								y += target.getY(i / 3) * influence;
								z += target.getZ(i / 3) * influence;

							} else {

								x += (target.getX(i / 3) - positions[i]) * influence;
								y += (target.getY(i / 3) - positions[i + 1]) * influence;
								z += (target.getZ(i / 3) - positions[i + 2]) * influence;

							}

						}

					}

					renderList.pushVertex(x, y, z);

				}

				if (attributes.normal != undefined) {

					var normals:Array<Float> = attributes.normal.array;

					for (i in 0...normals.length) {

						renderList.pushNormal(normals[i], normals[i + 1], normals[i + 2]);

					}

				}

				if (attributes.color != undefined) {

					var colors:Array<Float> = attributes.color.array;

					for (i in 0...colors.length) {

						renderList.pushColor(colors[i], colors[i + 1], colors[i + 2]);

					}

				}

				if (attributes.uv != undefined) {

					var uvs:Array<Float> = attributes.uv.array;

					for (i in 0...uvs.length) {

						renderList.pushUv(uvs[i], uvs[i + 1]);

					}

				}

				if (geometry.index != null) {

					var indices:Array<Int> = geometry.index.array;

					if (groups.length > 0) {

						for (g in 0...groups.length) {

							var group:Dynamic = groups[g];

							material = isMultiMaterial == true
								? object.material[group.materialIndex]
								: object.material;

							if (material == undefined) continue;

							for (i in group.start...(group.start + group.count)) {

								renderList.pushTriangle(indices[i], indices[i + 1], indices[i + 2], material);

							}

						}

					} else {

						for (i in 0...indices.length) {

							renderList.pushTriangle(indices[i], indices[i + 1], indices[i + 2], material);

						}

					}

				} else {

					if (groups.length > 0) {

						for (g in 0...groups.length) {

							var group:Dynamic = groups[g];

							material = isMultiMaterial == true
								? object.material[group.materialIndex]
								: object.material;

							if (material == undefined) continue;

							for (i in group.start...(group.start + group.count)) {

								renderList.pushTriangle(i, i + 1, i + 2, material);

							}

						}

					} else {

						for (i in 0...(positions.length / 3)) {

							renderList.pushTriangle(i, i + 1, i + 2, material);

						}

					}

				}

			} else if (object.isLine) {

				_modelViewProjectionMatrix.multiplyMatrices(_viewProjectionMatrix, _modelMatrix);

				var attributes:Dynamic = geometry.attributes;

				if (attributes.position != undefined) {

					var positions:Array<Float> = attributes.position.array;

					for (i in 0...positions.length) {

						renderList.pushVertex(positions[i], positions[i + 1], positions[i + 2]);

					}

					if (attributes.color != undefined) {

						var colors:Array<Float> = attributes.color.array;

						for (i in 0...colors.length) {

							renderList.pushColor(colors[i], colors[i + 1], colors[i + 2]);

						}

					}

					if (geometry.index != null) {

						var indices:Array<Int> = geometry.index.array;

						for (i in 0...indices.length) {

							renderList.pushLine(indices[i], indices[i + 1]);

						}

					} else {

						var step:Int = object.isLineSegments ? 2 : 1;

						for (i in 0...(positions.length / 3 - 1)) {

							renderList.pushLine(i, i + 1);

						}

					}

				}

			} else if (object.isPoints) {

				_modelViewProjectionMatrix.multiplyMatrices(_viewProjectionMatrix, _modelMatrix);

				var attributes:Dynamic = geometry.attributes;

				if (attributes.position != undefined) {

					var positions:Array<Float> = attributes.position.array;

					for (i in 0...positions.length) {

						_vector4.set(positions[i], positions[i + 1], positions[i + 2], 1);
						_vector4.applyMatrix4(_modelViewProjectionMatrix);

						pushPoint(_vector4, object, camera);

					}

				}

			} else if (object.isSprite) {

				object.modelViewMatrix.multiplyMatrices(camera.matrixWorldInverse, object.matrixWorld);
				_vector4.set(_modelMatrix.elements[12], _modelMatrix.elements[13], _modelMatrix.elements[14], 1);
				_vector4.applyMatrix4(_viewProjectionMatrix);

				pushPoint(_vector4, object, camera);

			}

		}

		if (sortElements == true) {

			_renderData.elements.sort(painterSort);

		}

		return _renderData;

	}

	private function pushPoint(_vector4:Vector4, object:Dynamic, camera:Dynamic):Void {

		var invW:Float = 1 / _vector4.w;

		_vector4.z *= invW;

		if (_vector4.z >= -1 && _vector4.z <= 1) {

			_sprite = getNextSpriteInPool();
			_sprite.id = object.id;
			_sprite.x = _vector4.x * invW;
			_sprite.y = _vector4.y * invW;
			_sprite.z = _vector4.z;
			_sprite.renderOrder = object.renderOrder;
			_sprite.object = object;

			_sprite.rotation = object.rotation;

			_sprite.scale.x = object.scale.x * Math.abs(_sprite.x - (_vector4.x + camera.projectionMatrix.elements[0]) / (_vector4.w + camera.projectionMatrix.elements[12]));
			_sprite.scale.y = object.scale.y * Math.abs(_sprite.y - (_vector4.y + camera.projectionMatrix.elements[5]) / (_vector4.w + camera.projectionMatrix.elements[13]));

			_sprite.material = object.material;

			_renderData.elements.push(_sprite);

		}

	}

	// Pools

	private function getNextObjectInPool():RenderableObject {

		if (_objectCount == _objectPoolLength) {

			var object:RenderableObject = new RenderableObject();
			_objectPool.push(object);
			_objectPoolLength++;
			_objectCount++;
			return object;

		}

		return _objectPool[_objectCount++];

	}

	private function getNextVertexInPool():RenderableVertex {

		if (_vertexCount == _vertexPoolLength) {

			var vertex:RenderableVertex = new RenderableVertex();
			_vertexPool.push(vertex);
			_vertexPoolLength++;
			_vertexCount++;
			return vertex;

		}

		return _vertexPool[_vertexCount++];

	}

	private function getNextFaceInPool():RenderableFace {

		if (_faceCount == _facePoolLength) {

			var face:RenderableFace = new RenderableFace();
			_facePool.push(face);
			_facePoolLength++;
			_faceCount++;
			return face;

		}

		return _facePool[_faceCount++];

	}

	private function getNextLineInPool():RenderableLine {

		if (_lineCount == _linePoolLength) {

			var line:RenderableLine = new RenderableLine();
			_linePool.push(line);
			_linePoolLength++;
			_lineCount++;
			return line;

		}

		return _linePool[_lineCount++];

	}

	private function getNextSpriteInPool():RenderableSprite {

		if (_spriteCount == _spritePoolLength) {

			var sprite:RenderableSprite = new RenderableSprite();
			_spritePool.push(sprite);
			_spritePoolLength++;
			_spriteCount++;
			return sprite;

		}

		return _spritePool[_spriteCount++];

	}

	//

	private function painterSort(a:RenderableObject, b:RenderableObject):Int {

		if (a.renderOrder != b.renderOrder) {

			return a.renderOrder - b.renderOrder;

		} else if (a.z != b.z) {

			return b.z - a.z;

		} else if (a.id != b.id) {

			return a.id - b.id;

		} else {

			return 0;

		}

	}

	private function clipLine(_s1:Vector4, _s2:Vector4):Bool {

		var alpha1:Float = 0, alpha2:Float = 1;

		// Calculate the boundary coordinate of each vertex for the near and far clip planes,
		// Z = -1 and Z = +1, respectively.

		var bc1near:Float = _s1.z + _s1.w,
			bc2near:Float = _s2.z + _s2.w,
			bc1far:Float = -_s1.z + _s1.w,
			bc2far:Float = -_s2.z + _s2.w;

		if (bc1near >= 0 && bc2near >= 0 && bc1far >= 0 && bc2far >= 0) {

			// Both vertices lie entirely within all clip planes.
			return true;

		} else if ((bc1near < 0 && bc2near < 0) || (bc1far < 0 && bc2far < 0)) {

			// Both vertices lie entirely outside one of the clip planes.
			return false;

		} else {

			// The line segment spans at least one clip plane.

			if (bc1near < 0) {

				// v1 lies outside the near plane, v2 inside
				alpha1 = Math.max(alpha1, bc1near / (bc1near - bc2near));

			} else if (bc2near < 0) {

				// v2 lies outside the near plane, v1 inside
				alpha2 = Math.min(alpha2, bc1near / (bc1near - bc2near));

			}

			if (bc1far < 0) {

				// v1 lies outside the far plane, v2 inside
				alpha1 = Math.max(alpha1, bc1far / (bc1far - bc2far));

			} else if (bc2far < 0) {

				// v2 lies outside the far plane, v2 inside
				alpha2 = Math.min(alpha2, bc1far / (bc1far - bc2far));

			}

			if (alpha2 < alpha1) {

				// The line segment spans two boundaries, but is outside both of them.
				// (This can't happen when we're only clipping against just near/far but good
				//  to leave the check here for future usage if other clip planes are added.)
				return false;

			} else {

				// Update the s1 and s2 vertices to match the clipped line segment.
				_s1.lerp(_s2, alpha1);
				_s2.lerp(_s1, 1 - alpha2);

				return true;

			}

		}

	}

}

export { RenderableObject, RenderableFace, RenderableVertex, RenderableLine, RenderableSprite, Projector };