import three.THREE;
import three.extras.loaders.TextureLoader;
import three.materials.MeshPhongMaterial;
import three.geometries.BufferGeometry;
import three.attributes.BufferAttribute;
import three.geometries.Geometry;
import three.objects.Mesh;
import three.objects.Object3D;
import three.math.Vector3;
import three.constants.WrappingModes;
import three.constants.Side;

class Main {

	static function main() {

		var loader = new TextureLoader();
		var texture = loader.load("/manual/examples/resources/images/star-light.png");
		texture.wrapS = WrappingModes.RepeatWrapping;
		texture.wrapT = WrappingModes.RepeatWrapping;
		texture.repeat.set(3, 1);

		function makeMesh(geometry:Geometry) {

			var material = new MeshPhongMaterial({
				color: 'hsl(300,50%,50%)',
				side: Side.DoubleSide,
				map: texture
			});
			return new Mesh(geometry, material);

		}

		// Add diagrams to the scene
		// Example: Cylinder
		var geometryCylinder = new Object3D();
		var bufferGeometryCylinder = makeMesh(new BufferGeometry().
			setAttribute('position', new BufferAttribute(new Float32Array([
				-1, -1, -1,
				-1, 1, -1,
				1, 1, -1,
				1, -1, -1,
				-1, -1, 1,
				-1, 1, 1,
				1, 1, 1,
				1, -1, 1
			]), 3)).
			setAttribute('uv', new BufferAttribute(new Float32Array([
				0, 0,
				0, 1,
				1, 1,
				1, 0,
				0, 0,
				0, 1,
				1, 1,
				1, 0
			]), 2)).
			setIndex(new Uint16Array([
				0, 1, 2,
				2, 3, 0,
				4, 5, 6,
				6, 7, 4,
				0, 4, 7,
				7, 3, 0,
				1, 5, 6,
				6, 2, 1,
				4, 5, 1,
				1, 0, 4,
				3, 2, 6,
				6, 7, 3
			])).
			computeVertexNormals().
			scale(5, 5, 5));

	}

}