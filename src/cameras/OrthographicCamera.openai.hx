package three.cameras;

import three.Camera;

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

    override public function copy(source:OrthographicCamera, recursive:Bool = false):OrthographicCamera {
        super.copy(source, recursive);
        this.left = source.left;
        this.right = source.right;
        this.top = source.top;
        this.bottom = source.bottom;
        this.near = source.near;
        this.far = source.far;
        this.zoom = source.zoom;
        if (source.view != null) {
            this.view = { };
            for (field in Reflect.fields(source.view)) {
                Reflect.setField(this.view, field, Reflect.field(source.view, field));
            }
        } else {
            this.view = null;
        }
        return this;
    }

    public function setViewOffset(fullWidth:Float, fullHeight:Float, x:Float, y:Float, width:Float, height:Float) {
        if (this.view == null) {
            this.view = {
                enabled: true,
                fullWidth: 1,
                fullHeight: 1,
                offsetX: 0,
                offsetY: 0,
                width: 1,
                height: 1
            };
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
        var dx = (right - left) / (2 * zoom);
        var dy = (top - bottom) / (2 * zoom);
        var cx = (right + left) / 2;
        var cy = (top + bottom) / 2;
        var left = cx - dx;
        var right = cx + dx;
        var top = cy + dy;
        var bottom = cy - dy;
        if (this.view != null && this.view.enabled) {
            var scaleW = (right - left) / this.view.fullWidth / zoom;
            var scaleH = (top - bottom) / this.view.fullHeight / zoom;
            left += scaleW * this.view.offsetX;
            right = left + scaleW * this.view.width;
            top -= scaleH * this.view.offsetY;
            bottom = top - scaleH * this.view.height;
        }
        projectionMatrix.makeOrthographic(left, right, top, bottom, near, far, coordinateSystem);
        projectionMatrixInverse.copy(projectionMatrix).invert();
    }

    override public function toJSON(meta:Dynamic):Dynamic {
        var data = super.toJSON(meta);
        data.object.zoom = zoom;
        data.object.left = left;
        data.object.right = right;
        data.object.top = top;
        data.object.bottom = bottom;
        data.object.near = near;
        data.object.far = far;
        if (view != null) {
            data.object.view = { };
            for (field in Reflect.fields(view)) {
                Reflect.setField(data.object.view, field, Reflect.field(view, field));
            }
        }
        return data;
    }
}