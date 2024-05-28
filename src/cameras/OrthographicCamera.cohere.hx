package;

import js.Browser.Window;

class OrthographicCamera {
    public var left:Float = -1;
    public var right:Float = 1;
    public var top:Float = 1;
    public var bottom:Float = -1;
    public var near:Float = 0.1;
    public var far:Float = 2000;
    public var zoom:Float;
    public var view:View;

    public function new(left:Float, right:Float, top:Float, bottom:Float, near:Float, far:Float) {
        this.zoom = 1;
        this.view = null;

        this.left = left;
        this.right = right;
        this.top = top;
        this.bottom = bottom;
        this.near = near;
        this.far = far;

        this.updateProjectionMatrix();
    }

    public function copy(source:OrthographicCamera) {
        this.left = source.left;
        this.right = source.right;
        this.top = source.top;
        this.bottom = source.bottom;
        this.near = source.near;
        this.far = source.far;

        this.zoom = source.zoom;
        this.view = source.view != null ? { enabled: true, fullWidth: 1, fullHeight: 1, offsetX: 0, offsetY: 0, width: 1, height: 1 } : null;
    }

    public function setViewOffset(fullWidth:Int, fullHeight:Int, x:Int, y:Int, width:Int, height:Int) {
        if (this.view == null) {
            this.view = { enabled: true, fullWidth: 1, fullHeight: 1, offsetX: 0, offsetY: 0, width: 1, height: 1 };
        }

        this.view.enabled = true;
        this.view.fullWidth = fullWidth;
        this.view.fullHeight = fullHeight;
        this.view.offsetX = x;
        this.view.offsetY = y;
        this.view.width = width;
        this.view.height = height;

        this.updateProjectionMatrix();
    }

    public function clearViewOffset() {
        if (this.view != null) {
            this.view.enabled = false;
        }

        this.updateProjectionMatrix();
    }

    public function updateProjectionMatrix() {
        var dx:Float = (this.right - this.left) / (2 * this.zoom);
        var dy:Float = (this.top - this.bottom) / (2 * this.zoom);
        var cx:Float = (this.right + this.left) / 2;
        var cy:Float = (this.top + this.bottom) / 2;

        var left:Float = cx - dx;
        var right:Float = cx + dx;
        var top:Float = cy + dy;
        var bottom:Float = cy - dy;

        if (this.view != null && this.view.enabled) {
            var scaleW:Float = (this.right - this.left) / this.view.fullWidth / this.zoom;
            var scaleH:Float = (this.top - this.bottom) / this.view.fullHeight / this.zoom;

            left += scaleW * this.view.offsetX;
            right = left + scaleW * this.view.width;
            top -= scaleH * this.view.offsetY;
            bottom = top - scaleH * this.view.height;
        }

        var elements:Array<Float> = [2 / (right - left), 0, 0, 0,
                                    0, 2 / (top - bottom), 0, 0,
                                    0, 0, -2 / (far - near), 0,
                                    -(right + left) / (right - left), -(top + bottom) / (top - bottom), -(far + near) / (far - near), 1];

        var projectionMatrix:Float32Array = new Float32Array(elements);
        var projectionMatrixInverse:Float32Array = (projectionMatrix as Matrix4).invert() as Float32Array;
    }
}

typedef View = {
    enabled:Bool,
    fullWidth:Int,
    fullHeight:Int,
    offsetX:Int,
    offsetY:Int,
    width:Int,
    height:Int
}