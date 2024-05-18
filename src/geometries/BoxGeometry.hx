package three.geometries;

import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class BoxGeometry extends BufferGeometry {
  public function new(width:Float = 1, height:Float = 1, depth:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1, depthSegments:Int = 1) {
    super();

    type = 'BoxGeometry';

    parameters = {
      width: width,
      height: height,
      depth: depth,
      widthSegments: widthSegments,
      heightSegments: heightSegments,
      depthSegments: depthSegments
    };

    var scope = this;

    // segments

    widthSegments = Math.floor(widthSegments);
    heightSegments = Math.floor(heightSegments);
    depthSegments = Math.floor(depthSegments);

    // buffers

    var indices:Array<Int> = [];
    var vertices:Array<Float> = [];
    var normals:Array<Float> = [];
    var uvs:Array<Float> = [];

    // helper variables

    var numberOfVertices:Int = 0;
    var groupStart:Int = 0;

    // build each side of the box geometry

    buildPlane('z', 'y', 'x', -1, -1, depth, height, width, depthSegments, heightSegments, 0); // px
    buildPlane('z', 'y', 'x', 1, -1, depth, height, -width, depthSegments, heightSegments, 1); // nx
    buildPlane('x', 'z', 'y', 1, 1, width, depth, height, widthSegments, depthSegments, 2); // py
    buildPlane('x', 'z', 'y', 1, -1, width, depth, -height, widthSegments, depthSegments, 3); // ny
    buildPlane('x', 'y', 'z', 1, -1, width, height, depth, widthSegments, heightSegments, 4); // pz
    buildPlane('x', 'y', 'z', -1, -1, width, height, -depth, widthSegments, heightSegments, 5); // nz

    // build geometry

    setIndex(indices);
    setAttribute('position', new Float32BufferAttribute(vertices, 3));
    setAttribute('normal', new Float32BufferAttribute(normals, 3));
    setAttribute('uv', new Float32BufferAttribute(uvs, 2));
  }

  function buildPlane(u:String, v:String, w:String, udir:Float, vdir:Float, width:Float, height:Float, depth:Float, gridX:Int, gridY:Int, materialIndex:Int) {
    var segmentWidth:Float = width / gridX;
    var segmentHeight:Float = height / gridY;

    var widthHalf:Float = width / 2;
    var heightHalf:Float = height / 2;
    var depthHalf:Float = depth / 2;

    var gridX1:Int = gridX + 1;
    var gridY1:Int = gridY + 1;

    var vertexCounter:Int = 0;
    var groupCount:Int = 0;

    var vector:Vector3 = new Vector3();

    // generate vertices, normals and uvs

    for (iy in 0...gridY1) {
      var y:Float = iy * segmentHeight - heightHalf;

      for (ix in 0...gridX1) {
        var x:Float = ix * segmentWidth - widthHalf;

        // set values to correct vector component

        vector.setComponent(u, x * udir);
        vector.setComponent(v, y * vdir);
        vector.setComponent(w, depthHalf);

        // now apply vector to vertex buffer

        vertices.push(vector.x);
        vertices.push(vector.y);
        vertices.push(vector.z);

        // set values to correct vector component

        vector.setComponent(u, 0);
        vector.setComponent(v, 0);
        vector.setComponent(w, depth > 0 ? 1 : -1);

        // now apply vector to normal buffer

        normals.push(vector.x);
        normals.push(vector.y);
        normals.push(vector.z);

        // uvs

        uvs.push(ix / gridX);
        uvs.push(1 - (iy / gridY));

        // counters

        vertexCounter++;

      }
    }

    // indices

    for (iy in 0...gridY) {
      for (ix in 0...gridX) {
        var a:Int = numberOfVertices + ix + gridX1 * iy;
        var b:Int = numberOfVertices + ix + gridX1 * (iy + 1);
        var c:Int = numberOfVertices + (ix + 1) + gridX1 * (iy + 1);
        var d:Int = numberOfVertices + (ix + 1) + gridX1 * iy;

        // faces

        indices.push(a);
        indices.push(b);
        indices.push(d);

        indices.push(b);
        indices.push(c);
        indices.push(d);

        // increase counter

        groupCount += 6;
      }
    }

    // add a group to the geometry. this will ensure multi material support

    addGroup(groupStart, groupCount, materialIndex);

    // calculate new start value for groups

    groupStart += groupCount;

    // update total number of vertices

    numberOfVertices += vertexCounter;
  }

  override public function copy(source:BoxGeometry):BoxGeometry {
    super.copy(source);

    parameters = Object.assign({}, source.parameters);

    return this;
  }

  static public function fromJSON(data:Dynamic):BoxGeometry {
    return new BoxGeometry(data.width, data.height, data.depth, data.widthSegments, data.heightSegments, data.depthSegments);
  }
}