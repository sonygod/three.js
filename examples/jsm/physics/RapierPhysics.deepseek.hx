import three.Clock;
import three.Vector3;
import three.Quaternion;
import three.Matrix4;

@:expose
class RapierPhysics {

    static var RAPIER_PATH = 'https://cdn.skypack.dev/@dimforge/rapier3d-compat@0.12.0';
    static var frameRate = 60;
    static var _scale = new Vector3( 1, 1, 1 );
    static var ZERO = new Vector3();
    static var RAPIER:RAPIERType = null;

    static function getShape(geometry:Geometry):Shape {

        var parameters = geometry.parameters;

        if (geometry.type == 'BoxGeometry') {

            var sx = parameters.width != undefined ? parameters.width / 2 : 0.5;
            var sy = parameters.height != undefined ? parameters.height / 2 : 0.5;
            var sz = parameters.depth != undefined ? parameters.depth / 2 : 0.5;

            return RAPIER.ColliderDesc.cuboid(sx, sy, sz);

        } else if (geometry.type == 'SphereGeometry' || geometry.type == 'IcosahedronGeometry') {

            var radius = parameters.radius != undefined ? parameters.radius : 1;
            return RAPIER.ColliderDesc.ball(radius);

        }

        return null;

    }

    static function addScene(scene:Scene) {

        scene.traverse(function (child) {

            if (child.isMesh) {

                var physics = child.userData.physics;

                if (physics) {

                    addMesh(child, physics.mass, physics.restitution);

                }

            }

        });

    }

    static function addMesh(mesh:Mesh, mass:Float = 0, restitution:Float = 0) {

        var shape = getShape(mesh.geometry);

        if (shape == null) return;

        shape.setMass(mass);
        shape.setRestitution(restitution);

        var body = mesh.isInstancedMesh
            ? createInstancedBody(mesh, mass, shape)
            : createBody(mesh.position, mesh.quaternion, mass, shape);

        if (mass > 0) {

            meshes.push(mesh);
            meshMap.set(mesh, body);

        }

    }

    static function createInstancedBody(mesh:Mesh, mass:Float, shape:Shape) {

        var array = mesh.instanceMatrix.array;

        var bodies = [];

        for (i in 0...mesh.count) {

            var position = _vector.fromArray(array, i * 16 + 12);
            bodies.push(createBody(position, null, mass, shape));

        }

        return bodies;

    }

    static function createBody(position:Vector3, quaternion:Quaternion, mass:Float, shape:Shape) {

        var desc = mass > 0 ? RAPIER.RigidBodyDesc.dynamic() : RAPIER.RigidBodyDesc.fixed();
        desc.setTranslation(position);
        if (quaternion != null) desc.setRotation(quaternion);

        var body = world.createRigidBody(desc);
        world.createCollider(shape, body);

        return body;

    }

    static function setMeshPosition(mesh:Mesh, position:Vector3, index:Int = 0) {

        var body = meshMap.get(mesh);

        if (mesh.isInstancedMesh) {

            body = body[index];

        }

        body.setAngvel(ZERO);
        body.setLinvel(ZERO);
        body.setTranslation(position);

    }

    static function setMeshVelocity(mesh:Mesh, velocity:Vector3, index:Int = 0) {

        var body = meshMap.get(mesh);

        if (mesh.isInstancedMesh) {

            body = body[index];

        }

        body.setLinvel(velocity);

    }

    static function step() {

        world.timestep = clock.getDelta();
        world.step();

        for (i in 0...meshes.length) {

            var mesh = meshes[i];

            if (mesh.isInstancedMesh) {

                var array = mesh.instanceMatrix.array;
                var bodies = meshMap.get(mesh);

                for (j in 0...bodies.length) {

                    var body = bodies[j];

                    var position = body.translation();
                    _quaternion.copy(body.rotation());

                    _matrix.compose(position, _quaternion, _scale).toArray(array, j * 16);

                }

                mesh.instanceMatrix.needsUpdate = true;
                mesh.computeBoundingSphere();

            } else {

                var body = meshMap.get(mesh);

                mesh.position.copy(body.translation());
                mesh.quaternion.copy(body.rotation());

            }

        }

    }

    static function init() {

        if (RAPIER == null) {

            RAPIER = js.Browser.import(RAPIER_PATH);
            RAPIER.init();

        }

        setInterval(step, 1000 / frameRate);

    }

}