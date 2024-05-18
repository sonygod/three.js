package three.js.examples.jvm.animation;

import threeDimensions.*;

class MMDPhysicsHelper extends Object3D {
    public var root:SkinnedMesh;
    public var physics:Physics;
    public var materials:Array<MeshBasicMaterial>;
    private var _matrix:Matrix4;
    private var _matrixAutoUpdate:Bool;
    private var _position:Vector3;
    private var _quaternion:Quaternion;
    private var _scale:Vector3;
    private var _matrixWorldInv:Matrix4;

    public function new(mesh:SkinnedMesh, physics:Physics) {
        super();
        this.root = mesh;
        this.physics = physics;
        this.materials = [];

        this.materials.push(new MeshBasicMaterial({
            color: new Color(0xff8888),
            wireframe: true,
            depthTest: false,
            depthWrite: false,
            opacity: 0.25,
            transparent: true
        }));

        this.materials.push(new MeshBasicMaterial({
            color: new Color(0x88ff88),
            wireframe: true,
            depthTest: false,
            depthWrite: false,
            opacity: 0.25,
            transparent: true
        }));

        this.materials.push(new MeshBasicMaterial({
            color: new Color(0x8888ff),
            wireframe: true,
            depthTest: false,
            depthWrite: false,
            opacity: 0.25,
            transparent: true
        }));

        _matrix = new Matrix4();
        _matrixAutoUpdate = false;
        _matrix.copy(mesh.matrixWorld);
        _position = new Vector3();
        _quaternion = new Quaternion();
        _scale = new Vector3();
        _matrixWorldInv = new Matrix4();

        _init();
    }

    public function dispose() {
        for (material in materials) {
            material.dispose();
        }

        for (child in children) {
            if (child.isMesh) {
                child.geometry.dispose();
            }
        }
    }

    public function updateMatrixWorld(force:Bool) {
        var mesh:SkinnedMesh = root;
        if (visible) {
            var bodies:Array<Dynamic> = physics.bodies;
            _matrixWorldInv.copy(mesh.matrixWorld);
            _matrixWorldInv.decompose(_position, _quaternion, _scale);
            _matrixWorldInv.compose(_position, _quaternion, _scale.set(1, 1, 1));
            _matrixWorldInv.invert();

            for (i in 0...bodies.length) {
                var body:Dynamic = bodies[i].body;
                var child:Object3D = children[i];
                var tr:Dynamic = body.getCenterOfMassTransform();
                var origin:Vector3 = tr.getOrigin();
                var rotation:Quaternion = tr.getRotation();

                child.position.set(origin.x, origin.y, origin.z);
                child.position.applyMatrix4(_matrixWorldInv);

                child.quaternion.setFromRotationMatrix(_matrixWorldInv);
                child.quaternion.multiply(new Quaternion(rotation.x, rotation.y, rotation.z, rotation.w));
            }
        }

        _matrix.copy(mesh.matrixWorld);
        _matrix.decompose(_position, _quaternion, _scale);
        _matrix.compose(_position, _quaternion, _scale.set(1, 1, 1));

        super.updateMatrixWorld(force);
    }

    private function _init() {
        var bodies:Array<Dynamic> = physics.bodies;

        function createGeometry(param:Dynamic):Geometry {
            switch (param.shapeType) {
                case 0:
                    return new SphereGeometry(param.width, 16, 8);
                case 1:
                    return new BoxGeometry(param.width * 2, param.height * 2, param.depth * 2, 8, 8, 8);
                case 2:
                    return new CapsuleGeometry(param.width, param.height, 8, 16);
                default:
                    return null;
            }
        }

        for (i in 0...bodies.length) {
            var param:Dynamic = bodies[i].params;
            add(new Mesh(createGeometry(param), materials[param.type]));
        }
    }
}