package three.cameras;

import three.cameras.Camera;

class OrthographicCamera extends Camera {
    public var isOrthographicCamera:Bool = true;
    public var type:String = 'OrthographicCamera';
    public var zoom:Float = 1;
    public var view:Dynamic = null;
    public var left:Float;
    public var right:Float;
    public var top:Float;
    public var bottom:Float;
    public var near:Float;
    public var far:Float;

    public function new(left:Float = -1, right:Float = 1, top:Float = 1, bottom:Float = -1, near:Float = 0.1, far:Float = 2000) {
        super();
        this.left = left;
        this.right = right;
        this.top = top;
        this.bottom = bottom;
        this.near = near;
        this.far = far;
        updateProjectionMatrix();
    }

    public function copy(source:OrthographicCamera, recursive:Bool = false):OrthographicCamera {
        super.copy(source, recursive);
        this.left = source.left;
        this.right = source.right;
        this.top = source.top;
        this.bottom = source.bottom;
        this.near = source.near;
        this.far = source.far;
        this.zoom = source.zoom;
        this.view = (source.view == null) ? null : { enabled: source.view.enabled, fullWidth: source.view.fullWidth, fullHeight: source.view.fullHeight, offsetX: source.view.offsetX, offsetY: source.view.offsetY, width: source.view.width, height: source.view.height };
        return this;
    }

    public function setViewOffset(fullWidth:Float, fullHeight:Float, x:Float, y:Float, width:Float, height:Float) {
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
        updateProjectionMatrix();
    }

    public function clearViewOffset() {
        if (this.view != null) {
            this.view.enabled = false;
        }
        updateProjectionMatrix();
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
        projectionMatrix.makeOrthographic(left, right, top, bottom, this.near, this.far, this.coordinateSystem);
        projectionMatrixInverse.copy(projectionMatrix).invert();
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);
        data.object.zoom = this.zoom;
        data.object.left = this.left;
        data.object.right = this.right;
        data.object.top = this.top;
        data.object.bottom = this.bottom;
        data.object.near = this.near;
        data.object.far = this.far;
        if (this.view != null) data.object.view = { enabled: this.view.enabled, fullWidth: this.view.fullWidth, fullHeight: this.view.fullHeight, offsetX: this.view.offsetX, offsetY: this.view.offsetY, width: this.view.width, height: this.view.height };
        return data;
    }
}