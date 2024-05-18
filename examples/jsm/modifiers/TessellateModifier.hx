package three.js.examples.jm.modifiers;

import three.js.BufferGeometry;
import three.js.Color;
import three.js.Float32BufferAttribute;
import three.js.Vector2;
import three.js.Vector3;

/**
 * Break faces with edges longer than maxEdgeLength
 */

class TessellateModifier {
  public var maxEdgeLength:Float;
  public var maxIterations:Int;

  public function new(maxEdgeLength:Float = 0.1, maxIterations:Int = 6) {
    this.maxEdgeLength = maxEdgeLength;
    this.maxIterations = maxIterations;
  }

  public function modify(geometry:BufferGeometry):BufferGeometry {
    if (geometry.index != null) {
      geometry = geometry.toNonIndexed();
    }

    var maxIterations:Int = this.maxIterations;
    var maxEdgeLengthSquared:Float = this.maxEdgeLength * this.maxEdgeLength;

    var va:Vector3 = new Vector3();
    var vb:Vector3 = new Vector3();
    var vc:Vector3 = new Vector3();
    var vm:Vector3 = new Vector3();
    var vs:Array<Vector3> = [va, vb, vc, vm];

    var na:Vector3 = new Vector3();
    var nb:Vector3 = new Vector3();
    var nc:Vector3 = new Vector3();
    var nm:Vector3 = new Vector3();
    var ns:Array<Vector3> = [na, nb, nc, nm];

    var ca:Color = new Color();
    var cb:Color = new Color();
    var cc:Color = new Color();
    var cm:Color = new Color();
    var cs:Array<Color> = [ca, cb, cc, cm];

    var ua:Vector2 = new Vector2();
    var ub:Vector2 = new Vector2();
    var uc:Vector2 = new Vector2();
    var um:Vector2 = new Vector2();
    var us:Array<Vector2> = [ua, ub, uc, um];

    var u2a:Vector2 = new Vector2();
    var u2b:Vector2 = new Vector2();
    var u2c:Vector2 = new Vector2();
    var u2m:Vector2 = new Vector2();
    var u2s:Array<Vector2> = [u2a, u2b, u2c, u2m];

    var attributes:Dynamic = geometry.attributes;
    var hasNormals:Bool = attributes.normal != null;
    var hasColors:Bool = attributes.color != null;
    var hasUVs:Bool = attributes.uv != null;
    var hasUV1s:Bool = attributes.uv1 != null;

    var positions:Array<Float> = attributes.position.array;
    var normals:Array<Float> = hasNormals ? attributes.normal.array : null;
    var colors:Array<Float> = hasColors ? attributes.color.array : null;
    var uvs:Array<Float> = hasUVs ? attributes.uv.array : null;
    var uv1s:Array<Float> = hasUV1s ? attributes.uv1.array : null;

    var positions2:Array<Float> = positions;
    var normals2:Array<Float> = normals;
    var colors2:Array<Float> = colors;
    var uvs2:Array<Float> = uvs;
    var uv1s2:Array<Float> = uv1s;

    var iteration:Int = 0;
    var tessellating:Bool = true;

    function addTriangle(a:Int, b:Int, c:Int) {
      var v1:Vector3 = vs[a];
      var v2:Vector3 = vs[b];
      var v3:Vector3 = vs[c];

      positions2.push(v1.x);
      positions2.push(v1.y);
      positions2.push(v1.z);
      positions2.push(v2.x);
      positions2.push(v2.y);
      positions2.push(v2.z);
      positions2.push(v3.x);
      positions2.push(v3.y);
      positions2.push(v3.z);

      if (hasNormals) {
        var n1:Vector3 = ns[a];
        var n2:Vector3 = ns[b];
        var n3:Vector3 = ns[c];

        normals2.push(n1.x);
        normals2.push(n1.y);
        normals2.push(n1.z);
        normals2.push(n2.x);
        normals2.push(n2.y);
        normals2.push(n2.z);
        normals2.push(n3.x);
        normals2.push(n3.y);
        normals2.push(n3.z);
      }

      if (hasColors) {
        var c1:Color = cs[a];
        var c2:Color = cs[b];
        var c3:Color = cs[c];

        colors2.push(c1.r);
        colors2.push(c1.g);
        colors2.push(c1.b);
        colors2.push(c2.r);
        colors2.push(c2.g);
        colors2.push(c2.b);
        colors2.push(c3.r);
        colors2.push(c3.g);
        colors2.push(c3.b);
      }

      if (hasUVs) {
        var u1:Vector2 = us[a];
        var u2:Vector2 = us[b];
        var u3:Vector2 = us[c];

        uvs2.push(u1.x);
        uvs2.push(u1.y);
        uvs2.push(u2.x);
        uvs2.push(u2.y);
        uvs2.push(u3.x);
        uvs2.push(u3.y);
      }

      if (hasUV1s) {
        var u21:Vector2 = u2s[a];
        var u22:Vector2 = u2s[b];
        var u23:Vector2 = u2s[c];

        uv1s2.push(u21.x);
        uv1s2.push(u21.y);
        uv1s2.push(u22.x);
        uv1s2.push(u22.y);
        uv1s2.push(u23.x);
        uv1s2.push(u23.y);
      }
    }

    while (tessellating && iteration < maxIterations) {
      iteration++;
      tessellating = false;

      positions = positions2;
      positions2 = [];

      if (hasNormals) {
        normals = normals2;
        normals2 = [];
      }

      if (hasColors) {
        colors = colors2;
        colors2 = [];
      }

      if (hasUVs) {
        uvs = uvs2;
        uvs2 = [];
      }

      if (hasUV1s) {
        uv1s = uv1s2;
        uv1s2 = [];
      }

      for (i in 0...positions.length) {
        va.fromArray(positions, i + 0);
        vb.fromArray(positions, i + 3);
        vc.fromArray(positions, i + 6);

        if (hasNormals) {
          na.fromArray(normals, i + 0);
          nb.fromArray(normals, i + 3);
          nc.fromArray(normals, i + 6);
        }

        if (hasColors) {
          ca.fromArray(colors, i + 0);
          cb.fromArray(colors, i + 3);
          cc.fromArray(colors, i + 6);
        }

        if (hasUVs) {
          ua.fromArray(uvs, i2 + 0);
          ub.fromArray(uvs, i2 + 2);
          uc.fromArray(uvs, i2 + 4);
        }

        if (hasUV1s) {
          u2a.fromArray(uv1s, i2 + 0);
          u2b.fromArray(uv1s, i2 + 2);
          u2c.fromArray(uv1s, i2 + 4);
        }

        var dab:Float = va.distanceToSquared(vb);
        var dbc:Float = vb.distanceToSquared(vc);
        var dac:Float = va.distanceToSquared(vc);

        if (dab > maxEdgeLengthSquared || dbc > maxEdgeLengthSquared || dac > maxEdgeLengthSquared) {
          tessellating = true;

          if (dab >= dbc && dab >= dac) {
            vm.lerpVectors(va, vb, 0.5);
            if (hasNormals) nm.lerpVectors(na, nb, 0.5);
            if (hasColors) cm.lerpColors(ca, cb, 0.5);
            if (hasUVs) um.lerpVectors(ua, ub, 0.5);
            if (hasUV1s) u2m.lerpVectors(u2a, u2b, 0.5);

            addTriangle(0, 3, 2);
            addTriangle(3, 1, 2);
          } else if (dbc >= dab && dbc >= dac) {
            vm.lerpVectors(vb, vc, 0.5);
            if (hasNormals) nm.lerpVectors(nb, nc, 0.5);
            if (hasColors) cm.lerpColors(cb, cc, 0.5);
            if (hasUVs) um.lerpVectors(ub, uc, 0.5);
            if (hasUV1s) u2m.lerpVectors(u2b, u2c, 0.5);

            addTriangle(0, 1, 3);
            addTriangle(3, 2, 0);
          } else {
            vm.lerpVectors(va, vc, 0.5);
            if (hasNormals) nm.lerpVectors(na, nc, 0.5);
            if (hasColors) cm.lerpColors(ca, cc, 0.5);
            if (hasUVs) um.lerpVectors(ua, uc, 0.5);
            if (hasUV1s) u2m.lerpVectors(u2a, u2c, 0.5);

            addTriangle(0, 1, 3);
            addTriangle(3, 1, 2);
          }
        } else {
          addTriangle(0, 1, 2);
        }
      }
    }

    var geometry2:BufferGeometry = new BufferGeometry();

    geometry2.setAttribute('position', new Float32BufferAttribute(positions2, 3));

    if (hasNormals) {
      geometry2.setAttribute('normal', new Float32BufferAttribute(normals2, 3));
    }

    if (hasColors) {
      geometry2.setAttribute('color', new Float32BufferAttribute(colors2, 3));
    }

    if (hasUVs) {
      geometry2.setAttribute('uv', new Float32BufferAttribute(uvs2, 2));
    }

    if (hasUV1s) {
      geometry2.setAttribute('uv1', new Float32BufferAttribute(uv1s2, 2));
    }

    return geometry2;
  }
}