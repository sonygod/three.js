// Copyright 2014, Gregg Tavares.
// All rights reserved.

// ... ( omitted license text )

package three.js.manual.resources;

import js.html.DOMMatrix;
import js.html.CanvasRenderingContext2D;

class CanvasWrapper {
  static function duplicate(src:DOMMatrix):DOMMatrix {
    var d = new DOMMatrix();
    d.a = src.a;
    d.b = src.b;
    d.c = src.c;
    d.d = src.d;
    d.e = src.e;
    d.f = src.f;
    return d;
  }

  static function patchCurrentTransform(ctx:CanvasRenderingContext2D):CanvasRenderingContext2D {
    if (ctx.currentTransform != null) {
      return ctx;
    }

    var stack = [];

    ctx.scale = function(scale:Float->Float->Void) {
      return function(x:Float, y:Float) {
        ctx.currentTransform.scaleSelf(x, y);
        scale(x, y);
      };
    }(ctx.scale.bind(ctx));

    ctx.rotate = function(rotate:Float->Void) {
      return function(r:Float) {
        ctx.currentTransform.rotateSelf(r * 180 / Math.PI);
        rotate(r);
      };
    }(ctx.rotate.bind(ctx));

    ctx.translate = function(translate:Float->Float->Void) {
      return function(x:Float, y:Float) {
        ctx.currentTransform.translateSelf(x, y);
        translate(x, y);
      };
    }(ctx.translate.bind(ctx));

    ctx.save = function(save:Void->Void) {
      return function() {
        stack.push(duplicate(ctx.currentTransform));
        save();
      };
    }(ctx.save.bind(ctx));

    ctx.restore = function(restore:Void->Void) {
      return function() {
        if (stack.length > 0) {
          ctx.currentTransform = stack.pop();
        } else {
          throw new Error('"transform stack empty!');
        }
        restore();
      };
    }(ctx.restore.bind(ctx));

    ctx.transform = function(transform:Float->Float->Float->Float->Float->Float->Void) {
      return function(m11:Float, m12:Float, m21:Float, m22:Float, dx:Float, dy:Float) {
        var m = new DOMMatrix();
        m.a = m11;
        m.b = m12;
        m.c = m21;
        m.d = m22;
        m.e = dx;
        m.f = dy;
        ctx.currentTransform.multiplySelf(m);
        transform(m11, m12, m21, m22, dx, dy);
      };
    }(ctx.transform.bind(ctx));

    ctx.setTransform = function(setTransform:Float->Float->Float->Float->Float->Float->Void) {
      return function(m11:Float, m12:Float, m21:Float, m22:Float, dx:Float, dy:Float) {
        var d = ctx.currentTransform;
        d.a = m11;
        d.b = m12;
        d.c = m21;
        d.d = m22;
        d.e = dx;
        d.f = dy;
        setTransform(m11, m12, m21, m22, dx, dy);
      };
    }(ctx.setTransform.bind(ctx));

    ctx.currentTransform = new DOMMatrix();

    ctx.validateTransformStack = function() {
      if (stack.length != 0) {
        throw new Error('transform stack not 0');
      }
    };

    return ctx;
  }

  static public function wrap(ctx:CanvasRenderingContext2D):CanvasRenderingContext2D {
    // patchDOMMatrix();
    return patchCurrentTransform(ctx);
  }
}