package three.helpers;

import three.core.*;

class ArrowHelper extends Object3D {
    private var _axis:Vector3;

    public function new(dir:Vector3 = new Vector3(0, 0, 1), origin:Vector3 = new Vector3(0, 0, 0), length:Float = 1, color:Int = 0xffff00, headLength:Float = length * 0.2, headWidth:Float = headLength * 0.2) {
        super();
        type = 'ArrowHelper';

        if (_lineGeometry == null) {
            _lineGeometry = new BufferGeometry();
            _lineGeometry.setAttribute('position', new Float32BufferAttribute([0, 0, 0, 0, 1, 0], 3));

            _coneGeometry = new CylinderGeometry(0, 0.5, 1, 5, 1);
            _coneGeometry.translate(0, -0.5, 0);
        }

        position.copy(origin);

        line = new Line(_lineGeometry, new LineBasicMaterial({color: color, toneMapped: false}));
        line.matrixAutoUpdate = false;
        add(line);

        cone = new Mesh(_coneGeometry, new MeshBasicMaterial({color: color, toneMapped: false}));
        cone.matrixAutoUpdate = false;
        add(cone);

        setDirection(dir);
        setLength(length, headLength, headWidth);
    }

    public function setDirection(dir:Vector3) {
        // dir is assumed to be normalized

        if (dir.y > 0.99999) {
            quaternion.set(0, 0, 0, 1);
        } else if (dir.y < -0.99999) {
            quaternion.set(1, 0, 0, 0);
        } else {
            _axis.set(dir.z, 0, -dir.x).normalize();

            var radians = Math.acos(dir.y);

            quaternion.setFromAxisAngle(_axis, radians);
        }
    }

    public function setLength(length:Float, headLength:Float = length * 0.2, headWidth:Float = headLength * 0.2) {
        line.scale.set(1, Math.max(0.0001, length - headLength), 1); // see #17458
        line.updateMatrix();

        cone.scale.set(headWidth, headLength, headWidth);
        cone.position.y = length;
        cone.updateMatrix();
    }

    public function setColor(color:Int) {
        line.material.color.set(color);
        cone.material.color.set(color);
    }

    override public function copy(source:Object3D) {
        super.copy(source, false);

        line.copy(source.line);
        cone.copy(source.cone);

        return this;
    }

    override public function dispose() {
        line.geometry.dispose();
        line.material.dispose();
        cone.geometry.dispose();
        cone.material.dispose();
    }
}