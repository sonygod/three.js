import three.math.Vector3;
import three.math.Quaternion;
import three.math.Matrix4;
import three.core.Clock;

class RapierPhysics {
    static var RAPIER_PATH:String = 'https://cdn.skypack.dev/@dimforge/rapier3d-compat@0.12.0';
    static var frameRate:Int = 60;
    static var _scale:Vector3 = new Vector3( 1, 1, 1 );
    static var ZERO:Vector3 = new Vector3();
    static var RAPIER:Dynamic = null;

    static function getShape( geometry:Dynamic ) {
        var parameters:Dynamic = geometry.parameters;
        if (geometry.type == 'BoxGeometry') {
            var sx:Float = parameters.width !== undefined ? parameters.width / 2 : 0.5;
            var sy:Float = parameters.height !== undefined ? parameters.height / 2 : 0.5;
            var sz:Float = parameters.depth !== undefined ? parameters.depth / 2 : 0.5;
            return RAPIER.ColliderDesc.cuboid(sx, sy, sz);
        } else if (geometry.type == 'SphereGeometry' || geometry.type == 'IcosahedronGeometry') {
            var radius:Float = parameters.radius !== undefined ? parameters.radius : 1;
            return RAPIER.ColliderDesc.ball(radius);
        }
        return null;
    }

    static function main() {
        if (RAPIER == null) {
            RAPIER = js.Browser.require(RAPIER_PATH);
            RAPIER.init();
        }

        var gravity:Vector3 = new Vector3( 0.0, - 9.81, 0.0 );
        var world:Dynamic = new RAPIER.World(gravity);

        var meshes:Array<Dynamic> = [];
        var meshMap:Map<Dynamic, Dynamic> = new Map();

        var _vector:Vector3 = new Vector3();
        var _quaternion:Quaternion = new Quaternion();
        var _matrix:Matrix4 = new Matrix4();

        function addScene( scene:Dynamic ) {
            scene.traverse( function ( child:Dynamic ) {
                if (child.isMesh) {
                    var physics:Dynamic = child.userData.physics;
                    if (physics) {
                        addMesh(child, physics.mass, physics.restitution);
                    }
                }
            });
        }

        function addMesh( mesh:Dynamic, mass:Float = 0, restitution:Float = 0 ) {
            var shape:Dynamic = getShape(mesh.geometry);
            if (shape == null) return;
            shape.setMass(mass);
            shape.setRestitution(restitution);
            var body:Dynamic = mesh.isInstancedMesh
                ? createInstancedBody(mesh, mass, shape)
                : createBody(mesh.position, mesh.quaternion, mass, shape);
            if (mass > 0) {
                meshes.push(mesh);
                meshMap.set(mesh, body);
            }
        }

        function createInstancedBody( mesh:Dynamic, mass:Float, shape:Dynamic ) {
            var array:Array<Float> = mesh.instanceMatrix.array;
            var bodies:Array<Dynamic> = [];
            for (i in 0...mesh.count) {
                var position:Vector3 = _vector.fromArray(array, i * 16 + 12);
                bodies.push(createBody(position, null, mass, shape));
            }
            return bodies;
        }

        function createBody( position:Vector3, quaternion:Quaternion, mass:Float, shape:Dynamic ) {
            var desc:Dynamic = mass > 0 ? RAPIER.RigidBodyDesc.dynamic() : RAPIER.RigidBodyDesc.fixed();
            desc.setTranslation(position.x, position.y, position.z);
            if (quaternion != null) desc.setRotation(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
            var body:Dynamic = world.createRigidBody(desc);
            world.createCollider(shape, body);
            return body;
        }

        function setMeshPosition( mesh:Dynamic, position:Vector3, index:Int = 0 ) {
            var body:Dynamic = meshMap.get(mesh);
            if (mesh.isInstancedMesh) {
                body = body[index];
            }
            body.setAngvel(ZERO);
            body.setLinvel(ZERO);
            body.setTranslation(position.x, position.y, position.z);
        }

        function setMeshVelocity( mesh:Dynamic, velocity:Vector3, index:Int = 0 ) {
            var body:Dynamic = meshMap.get(mesh);
            if (mesh.isInstancedMesh) {
                body = body[index];
            }
            body.setLinvel(velocity.x, velocity.y, velocity.z);
        }

        var clock:Clock = new Clock();

        function step() {
            world.timestep = clock.getDelta();
            world.step();
            for (i in 0...meshes.length) {
                var mesh:Dynamic = meshes[i];
                if (mesh.isInstancedMesh) {
                    var array:Array<Float> = mesh.instanceMatrix.array;
                    var bodies:Array<Dynamic> = meshMap.get(mesh);
                    for (j in 0...bodies.length) {
                        var body:Dynamic = bodies[j];
                        var position:Vector3 = body.translation();
                        _quaternion.copy(body.rotation());
                        _matrix.compose(position, _quaternion, _scale).toArray(array, j * 16);
                    }
                    mesh.instanceMatrix.needsUpdate = true;
                    mesh.computeBoundingSphere();
                } else {
                    var body:Dynamic = meshMap.get(mesh);
                    mesh.position.copy(body.translation());
                    mesh.quaternion.copy(body.rotation());
                }
            }
        }

        var intervalId:Int = setInterval(step, 1000 / frameRate);
    }
}