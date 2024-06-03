import three.math.WebGLCoordinateSystem;
import three.math.WebGPUCoordinateSystem;
import three.math.Vector3;

class Matrix4 {
    public var elements: Array<Float> = [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    ];

    public function new(
        ?n11: Float, ?n12: Float, ?n13: Float, ?n14: Float,
        ?n21: Float, ?n22: Float, ?n23: Float, ?n24: Float,
        ?n31: Float, ?n32: Float, ?n33: Float, ?n34: Float,
        ?n41: Float, ?n42: Float, ?n43: Float, ?n44: Float
    ) {
        if (n11 != null) {
            this.set(n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44);
        }
    }

    public function set(
        n11: Float, n12: Float, n13: Float, n14: Float,
        n21: Float, n22: Float, n23: Float, n24: Float,
        n31: Float, n32: Float, n33: Float, n34: Float,
        n41: Float, n42: Float, n43: Float, n44: Float
    ): Matrix4 {
        this.elements = [
            n11, n12, n13, n14,
            n21, n22, n23, n24,
            n31, n32, n33, n34,
            n41, n42, n43, n44
        ];
        return this;
    }

    public function identity(): Matrix4 {
        this.set(
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        );
        return this;
    }

    public function clone(): Matrix4 {
        return new Matrix4().fromArray(this.elements);
    }

    public function copy(m: Matrix4): Matrix4 {
        this.elements = m.elements.slice();
        return this;
    }

    public function copyPosition(m: Matrix4): Matrix4 {
        this.elements[12] = m.elements[12];
        this.elements[13] = m.elements[13];
        this.elements[14] = m.elements[14];
        return this;
    }

    // Continue with the rest of the methods...
}