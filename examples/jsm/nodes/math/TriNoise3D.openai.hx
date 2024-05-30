package three.js.examples.jsm.nodes.math;

import three.js.shadernode.ShaderNode;

class TriNoise3D {
  static var tri:TSLFunction = tslFn((x:Array<Float>) -> {
    return x.fract().sub(0.5).abs();
  });

  static var tri3:TSLFunction = tslFn((p:Array<Float>) -> {
    return new Vec3(
      tri([p[2] + tri([p[1] * 1.0])]),
      tri([p[2] + tri([p[0] * 1.0])]),
      tri([p[1] + tri([p[0] * 1.0])])
    );
  });

  static var triNoise3D:TSLFunction = tslFn((p_immutable:Array<Float>, spd:Float, time:Float) -> {
    var p:Vec3 = new Vec3(p_immutable).toVar();
    var z:Float = 1.4.toVar();
    var rz:Float = 0.0.toVar();
    var bp:Vec3 = new Vec3(p).toVar();

    loop({
      start: 0.0,
      end: 3.0,
      type: 'float',
      condition: '<=',
    }, () -> {
      var dg:Vec3 = new Vec3(tri3(bp.mul(2.0))).toVar();
      p.addAssign(dg.add(time * 0.1 * spd));
      bp.mulAssign(1.8);
      z.mulAssign(1.5);
      p.mulAssign(1.2);

      var t:Float = tri([p[2] + tri([p[0] + tri([p[1]])])]).toVar();
      rz.addAssign(t / z);
      bp.addAssign(0.14);
    });

    return rz;
  });

  // layouts

  tri.setLayout({
    name: 'tri',
    type: 'float',
    inputs: [
      { name: 'x', type: 'float' }
    ]
  });

  tri3.setLayout({
    name: 'tri3',
    type: 'vec3',
    inputs: [
      { name: 'p', type: 'vec3' }
    ]
  });

  triNoise3D.setLayout({
    name: 'triNoise3D',
    type: 'float',
    inputs: [
      { name: 'p', type: 'vec3' },
      { name: 'spd', type: 'float' },
      { name: 'time', type: 'float' }
    ]
  });
}