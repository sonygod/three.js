import three.BufferGeometry;
import three.Color;
import three.Float32BufferAttribute;
import three.Vector2;
import three.Vector3;

class TessellateModifier {
    public var maxEdgeLength:Float = 0.1;
    public var maxIterations:Int = 6;

    public function new(maxEdgeLength:Float = 0.1, maxIterations:Int = 6) {
        this.maxEdgeLength = maxEdgeLength;
        this.maxIterations = maxIterations;
    }

    public function modify(geometry:BufferGeometry):BufferGeometry {
        if (geometry.index != null) {
            geometry = geometry.toNonIndexed();
        }

        var maxEdgeLengthSquared = this.maxEdgeLength * this.maxEdgeLength;

        var vs = new Array<Vector3>();
        var ns = new Array<Vector3>();
        var cs = new Array<Color>();
        var us = new Array<Vector2>();
        var u2s = new Array<Vector2>();

        for (var i in 0...4) {
            vs.push(new Vector3());
            ns.push(new Vector3());
            cs.push(new Color());
            us.push(new Vector2());
            u2s.push(new Vector2());
        }

        var attributes = geometry.attributes;
        var hasNormals = attributes.normal != null;
        var hasColors = attributes.color != null;
        var hasUVs = attributes.uv != null;
        var hasUV1s = attributes.uv1 != null;

        var positions = attributes.position.array;
        var normals = hasNormals ? attributes.normal.array : null;
        var colors = hasColors ? attributes.color.array : null;
        var uvs = hasUVs ? attributes.uv.array : null;
        var uv1s = hasUV1s ? attributes.uv1.array : null;

        var positions2 = positions;
        var normals2 = normals;
        var colors2 = colors;
        var uvs2 = uvs;
        var uv1s2 = uv1s;

        var iteration = 0;
        var tessellating = true;

        function addTriangle(a:Int, b:Int, c:Int) {
            var v1 = vs[a];
            var v2 = vs[b];
            var v3 = vs[c];

            positions2.push(v1.x, v1.y, v1.z);
            positions2.push(v2.x, v2.y, v2.z);
            positions2.push(v3.x, v3.y, v3.z);

            if (hasNormals) {
                var n1 = ns[a];
                var n2 = ns[b];
                var n3 = ns[c];

                normals2.push(n1.x, n1.y, n1.z);
                normals2.push(n2.x, n2.y, n2.z);
                normals2.push(n3.x, n3.y, n3.z);
            }

            if (hasColors) {
                var c1 = cs[a];
                var c2 = cs[b];
                var c3 = cs[c];

                colors2.push(c1.r, c1.g, c1.b);
                colors2.push(c2.r, c2.g, c2.b);
                colors2.push(c3.r, c3.g, c3.b);
            }

            if (hasUVs) {
                var u1 = us[a];
                var u2 = us[b];
                var u3 = us[c];

                uvs2.push(u1.x, u1.y);
                uvs2.push(u2.x, u2.y);
                uvs2.push(u3.x, u3.y);
            }

            if (hasUV1s) {
                var u21 = u2s[a];
                var u22 = u2s[b];
                var u23 = u2s[c];

                uv1s2.push(u21.x, u21.y);
                uv1s2.push(u22.x, u22.y);
                uv1s2.push(u23.x, u23.y);
            }
        }

        while (tessellating && iteration < this.maxIterations) {
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

            for (var i = 0, i2 = 0; i < positions.length; i += 9, i2 += 6) {
                var va = vs[0];
                var vb = vs[1];
                var vc = vs[2];
                var vm = vs[3];

                va.fromArray(positions, i + 0);
                vb.fromArray(positions, i + 3);
                vc.fromArray(positions, i + 6);

                if (hasNormals) {
                    var na = ns[0];
                    var nb = ns[1];
                    var nc = ns[2];
                    var nm = ns[3];

                    na.fromArray(normals, i + 0);
                    nb.fromArray(normals, i + 3);
                    nc.fromArray(normals, i + 6);
                }

                if (hasColors) {
                    var ca = cs[0];
                    var cb = cs[1];
                    var cc = cs[2];
                    var cm = cs[3];

                    ca.fromArray(colors, i + 0);
                    cb.fromArray(colors, i + 3);
                    cc.fromArray(colors, i + 6);
                }

                if (hasUVs) {
                    var ua = us[0];
                    var ub = us[1];
                    var uc = us[2];
                    var um = us[3];

                    ua.fromArray(uvs, i2 + 0);
                    ub.fromArray(uvs, i2 + 2);
                    uc.fromArray(uvs, i2 + 4);
                }

                if (hasUV1s) {
                    var u2a = u2s[0];
                    var u2b = u2s[1];
                    var u2c = u2s[2];
                    var u2m = u2s[3];

                    u2a.fromArray(uv1s, i2 + 0);
                    u2b.fromArray(uv1s, i2 + 2);
                    u2c.fromArray(uv1s, i2 + 4);
                }

                var dab = va.distanceToSquared(vb);
                var dbc = vb.distanceToSquared(vc);
                var dac = va.distanceToSquared(vc);

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

        var geometry2 = new BufferGeometry();

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