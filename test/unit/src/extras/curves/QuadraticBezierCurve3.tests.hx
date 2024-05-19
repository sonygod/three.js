import haxe.unit.TestCase;
import three.extras.curves.QuadraticBezierCurve3;
import three.math.Vector3;
import three.core.Curve;

class QuadraticBezierCurve3Tests {
  public function new() {}

  public function testExtending():Void {
    var object:QuadraticBezierCurve3 = new QuadraticBezierCurve3();
    assertTrue(object instanceof Curve, 'QuadraticBezierCurve3 extends from Curve');
  }

  public function testInstancing():Void {
    var object:QuadraticBezierCurve3 = new QuadraticBezierCurve3();
    assertNotNull(object, 'Can instantiate a QuadraticBezierCurve3.');
  }

  public function testType():Void {
    var object:QuadraticBezierCurve3 = new QuadraticBezierCurve3();
    assertEquals(object.type, 'QuadraticBezierCurve3', 'QuadraticBezierCurve3.type should be QuadraticBezierCurve3');
  }

  // todo: implement v0, v1, v2 tests

  public function testIsQuadraticBezierCurve3():Void {
    var object:QuadraticBezierCurve3 = new QuadraticBezierCurve3();
    assertTrue(object.isQuadraticBezierCurve3, 'QuadraticBezierCurve3.isQuadraticBezierCurve3 should be true');
  }

  // todo: implement getPoint, copy, toJSON, fromJSON tests

  public function testSimpleCurve():Void {
    var curve:QuadraticBezierCurve3 = new QuadraticBezierCurve3(
      new Vector3(-10, 0, 2),
      new Vector3(20, 15, -5),
      new Vector3(10, 0, 10)
    );

    var expectedPoints:Array<Vector3> = [
      new Vector3(-10, 0, 2),
      new Vector3(2.5, 5.625, -0.125),
      new Vector3(10, 7.5, 0.5),
      new Vector3(12.5, 5.625, 3.875),
      new Vector3(10, 0, 10)
    ];

    var points:Array<Vector3> = curve.getPoints(expectedPoints.length - 1);

    assertEquals(points.length, expectedPoints.length, 'Correct number of points');
    assertDeepEquals(points, expectedPoints, 'Correct points calculated');

    // symmetry
    var curveRev:QuadraticBezierCurve3 = new QuadraticBezierCurve3(
      curve.v2,
      curve.v1,
      curve.v0
    );

    points = curveRev.getPoints(expectedPoints.length - 1);

    assertEquals(points.length, expectedPoints.length, 'Reversed: Correct number of points');
    assertDeepEquals(points, expectedPoints.reverse(), 'Reversed: Correct points curve');
  }

  public function testGetLengthGetLengths():Void {
    var curve:QuadraticBezierCurve3 = new QuadraticBezierCurve3(
      new Vector3(-10, 0, 2),
      new Vector3(20, 15, -5),
      new Vector3(10, 0, 10)
    );

    var length:Float = curve.getLength();
    var expectedLength:Float = 35.47294274967861;

    assertEquals(length, expectedLength, 'Correct length of curve');

    var expectedLengths:Array<Float> = [
      0,
      13.871057998581074,
      21.62710402732536,
      26.226696400568883,
      34.91037361704809
    ];
    var lengths:Array<Float> = curve.getLengths(expectedLengths.length - 1);

    assertEquals(lengths.length, expectedLengths.length, 'Correct number of segments');

    for (i in 0...lengths.length) {
      assertEquals(lengths[i], expectedLengths[i], 'segment[' + i + '] correct');
    }
  }

  public function testGetPointAt():Void {
    var curve:QuadraticBezierCurve3 = new QuadraticBezierCurve3(
      new Vector3(-10, 0, 2),
      new Vector3(20, 15, -5),
      new Vector3(10, 0, 10)
    );

    var expectedPoints:Array<Vector3> = [
      new Vector3(-10, 0, 2),
      new Vector3(-0.4981634504454243, 4.427089043881476, 0.19308849757196012),
      new Vector3(6.149415812887238, 6.838853310980195, -0.20278120208668637),
      new Vector3(10, 0, 10)
    ];

    var points:Array<Vector3> = [
      curve.getPointAt(0, new Vector3()),
      curve.getPointAt(0.3, new Vector3()),
      curve.getPointAt(0.5, new Vector3()),
      curve.getPointAt(1, new Vector3())
    ];

    assertDeepEquals(points, expectedPoints, 'Correct points');
  }

  public function testGetTangentGetTangentAt():Void {
    var curve:QuadraticBezierCurve3 = new QuadraticBezierCurve3(
      new Vector3(-10, 0, 2),
      new Vector3(20, 15, -5),
      new Vector3(10, 0, 10)
    );

    var expectedTangents:Array<Vector3> = [
      new Vector3(0.8755715084258769, 0.4377711603816079, -0.2042815331129452),
      new Vector3(0.9060725703490549, 0.3984742932857448, -0.14230507668907377),
      new Vector3(0.9621604167456882, 0.2688562845452628, 0.044312872940942424),
      new Vector3(0.016586454041780826, -0.6163270940470614, 0.7873155674098058),
      new Vector3(-0.4263618889888853, -0.6396068005601663, 0.6396238584473043)
    ];

    var tangents:Array<Vector3> = [
      curve.getTangent(0, new Vector3()),
      curve.getTangent(0.25, new Vector3()),
      curve.getTangent(0.5, new Vector3()),
      curve.getTangent(0.75, new Vector3()),
      curve.getTangent(1, new Vector3())
    ];

    for (i in 0...expectedTangents.length) {
      assertEquals(tangents[i].x, expectedTangents[i].x, 'getTangent #' + i + ': x correct');
      assertEquals(tangents[i].y, expectedTangents[i].y, 'getTangent #' + i + ': y correct');
    }

    // ...

  }

  public function testGetUtoTmapping():Void {
    var curve:QuadraticBezierCurve3 = new QuadraticBezierCurve3(
      new Vector3(-10, 0, 2),
      new Vector3(20, 15, -5),
      new Vector3(10, 0, 10)
    );

    var start:Float = curve.getUtoTmapping(0, 0);
    var end:Float = curve.getUtoTmapping(0, curve.getLength());
    var somewhere:Float = curve.getUtoTmapping(0.5, 1);

    assertEquals(start, 0, 'getUtoTmapping( 0, 0 ) is the starting point');
    assertEquals(end, 1, 'getUtoTmapping( 0, length ) is the ending point');
    assertEquals(somewhere, 0.014760890927167196, 'getUtoTmapping( 0.5, 1 ) is correct');
  }

  public function testGetSpacedPoints():Void {
    var curve:QuadraticBezierCurve3 = new QuadraticBezierCurve3(
      new Vector3(-10, 0, 2),
      new Vector3(20, 15, -5),
      new Vector3(10, 0, 10)
    );

    var expectedPoints:Array<Vector3> = [
      new Vector3(-10, 0, 2),
      new Vector3(-3.712652983516992, 3.015179001762753, 0.6957120710270492),
      new Vector3(2.7830973773262975, 5.730399338061483, -0.1452668772806931),
      new Vector3(9.575825284074465, 7.48754187603603, 0.3461104039841496),
      new Vector3(12.345199937734154, 4.575759904730531, 5.142117429101656),
      new Vector3(10, 0, 10)
    ];

    var points:Array<Vector3> = curve.getSpacedPoints();

    assertEquals(points.length, expectedPoints.length, 'Correct number of points');
    assertDeepEquals(points, expectedPoints, 'Correct points calculated');
  }

  public function testComputeFrenetFrames():Void {
    var curve:QuadraticBezierCurve3 = new QuadraticBezierCurve3(
      new Vector3(-10, 0, 2),
      new Vector3(20, 15, -5),
      new Vector3(10, 0, 10)
    );

    var expected:Array<Dynamic> = {
      binormals: [
        new Vector3(-0.447201668889759, 0.8944331542056199, 0),
        new Vector3(-0.2684231751110917, 0.9631753839815436, -0.01556209353802903),
        new Vector3(0.3459273556592433, 0.53807011680075, 0.7686447905324219)
      ],
      normals: [
        new Vector3(-0.18271617600817133, -0.09135504253146765, -0.9789121795283909),
        new Vector3(0.046865035058597876, -0.003078628350883253, -0.9988964863970807),
        new Vector3(0.8357929194629689, -0.5489842348221077, 0.008155102228190641)
      ],
      tangents: [
        new Vector3(0.8755715084258767, 0.4377711603816078, -0.20428153311294514),
        new Vector3(0.9621604167456884, 0.26885628454526284, 0.04431287294094243),
        new Vector3(-0.4263618889888853, -0.6396068005601663, 0.6396238584473043)
      ]
    };

    var frames:Dynamic = curve.computeFrenetFrames(2, false);

    for (group in expected.keys()) {
      for (i in 0...expected[group].length) {
        assertEquals(frames[group][i].x, expected[group][i].x, 'Frenet frames [' + i + ', ' + group + '].x correct');
        assertEquals(frames[group][i].y, expected[group][i].y, 'Frenet frames [' + i + ', ' + group + '].y correct');
        assertEquals(frames[group][i].z, expected[group][i].z, 'Frenet frames [' + i + ', ' + group + '].z correct');
      }
    }
  }
}