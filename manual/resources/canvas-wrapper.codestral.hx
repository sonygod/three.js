class TransformWrapper {
    public static function duplicate(src:Dynamic):Dynamic {
        var d:Dynamic = {a: src.a, b: src.b, c: src.c, d: src.d, e: src.e, f: src.f};
        return d;
    }

    public static function patchCurrentTransform(ctx:Dynamic):Dynamic {
        if (ctx.hasOwnProperty('currentTransform')) {
            return ctx;
        }

        var stack:Array<Dynamic> = [];

        var originalScale = ctx.scale;
        ctx.scale = function(x:Float, y:Float) {
            ctx.currentTransform.scaleSelf(x, y);
            originalScale(x, y);
        };

        var originalRotate = ctx.rotate;
        ctx.rotate = function(r:Float) {
            ctx.currentTransform.rotateSelf(r * 180 / Math.PI);
            originalRotate(r);
        };

        var originalTranslate = ctx.translate;
        ctx.translate = function(x:Float, y:Float) {
            ctx.currentTransform.translateSelf(x, y);
            originalTranslate(x, y);
        };

        var originalSave = ctx.save;
        ctx.save = function() {
            stack.push(TransformWrapper.duplicate(ctx.currentTransform));
            originalSave();
        };

        var originalRestore = ctx.restore;
        ctx.restore = function() {
            if (stack.length > 0) {
                ctx.currentTransform = stack.pop();
            } else {
                throw 'transform stack empty!';
            }
            originalRestore();
        };

        var originalTransform = ctx.transform;
        ctx.transform = function(m11:Float, m12:Float, m21:Float, m22:Float, dx:Float, dy:Float) {
            var m:Dynamic = {a: m11, b: m12, c: m21, d: m22, e: dx, f: dy};
            ctx.currentTransform.multiplySelf(m);
            originalTransform(m11, m12, m21, m22, dx, dy);
        };

        var originalSetTransform = ctx.setTransform;
        ctx.setTransform = function(m11:Float, m12:Float, m21:Float, m22:Float, dx:Float, dy:Float) {
            var d:Dynamic = ctx.currentTransform;
            d.a = m11;
            d.b = m12;
            d.c = m21;
            d.d = m22;
            d.e = dx;
            d.f = dy;
            originalSetTransform(m11, m12, m21, m22, dx, dy);
        };

        ctx.currentTransform = {a: 1, b: 0, c: 0, d: 1, e: 0, f: 0};

        ctx.validateTransformStack = function() {
            if (stack.length !== 0) {
                throw 'transform stack not 0';
            }
        };

        return ctx;
    }

    public static function wrap(ctx:Dynamic):Dynamic {
        return TransformWrapper.patchCurrentTransform(ctx);
    }
}