import three.core.AnimationClip;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.loaders.Loader;
import three.math.Vector3;

class MD2Loader extends Loader {
  
  public function new(manager:Loader = null) {
    super(manager);
  }
  
  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(buffer:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(buffer));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }
  
  public function parse(buffer:haxe.io.Bytes):BufferGeometry {
    var data = new DataView(buffer.getData());
    
    // http://tfc.duke.free.fr/coding/md2-specs-en.html
    
    var header:Dynamic = {};
    var headerNames = [
      'ident', 'version',
      'skinwidth', 'skinheight',
      'framesize',
      'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
      'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
    ];
    
    for (i in 0...headerNames.length) {
      header[headerNames[i]] = data.getInt32(i * 4, true);
    }
    
    if (header.ident != 844121161 || header.version != 8) {
      console.error('Not a valid MD2 file');
      return null;
    }
    
    if (header.offset_end != data.byteLength) {
      console.error('Corrupted MD2 file');
      return null;
    }
    
    //
    
    var geometry = new BufferGeometry();
    
    // uvs
    
    var uvsTemp:Array<Float> = [];
    var offset = header.offset_st;
    
    for (i in 0...header.num_st) {
      var u = data.getInt16(offset + 0, true);
      var v = data.getInt16(offset + 2, true);
      
      uvsTemp.push(u / header.skinwidth, 1 - (v / header.skinheight));
      
      offset += 4;
    }
    
    // triangles
    
    offset = header.offset_tris;
    
    var vertexIndices:Array<Int> = [];
    var uvIndices:Array<Int> = [];
    
    for (i in 0...header.num_tris) {
      vertexIndices.push(
        data.getUint16(offset + 0, true),
        data.getUint16(offset + 2, true),
        data.getUint16(offset + 4, true)
      );
      
      uvIndices.push(
        data.getUint16(offset + 6, true),
        data.getUint16(offset + 8, true),
        data.getUint16(offset + 10, true)
      );
      
      offset += 12;
    }
    
    // frames
    
    var translation = new Vector3();
    var scale = new Vector3();
    
    var frames:Array<Dynamic> = [];
    
    offset = header.offset_frames;
    
    for (i in 0...header.num_frames) {
      scale.set(
        data.getFloat32(offset + 0, true),
        data.getFloat32(offset + 4, true),
        data.getFloat32(offset + 8, true)
      );
      
      translation.set(
        data.getFloat32(offset + 12, true),
        data.getFloat32(offset + 16, true),
        data.getFloat32(offset + 20, true)
      );
      
      offset += 24;
      
      var string:Array<Int> = [];
      
      for (j in 0...16) {
        var character = data.getUint8(offset + j);
        if (character == 0) break;
        string[j] = character;
      }
      
      var frame:Dynamic = {
        name: String.fromCharCode.apply(null, string),
        vertices: [],
        normals: []
      };
      
      offset += 16;
      
      for (j in 0...header.num_vertices) {
        var x = data.getUint8(offset++);
        var y = data.getUint8(offset++);
        var z = data.getUint8(offset++);
        var n = _normalData[data.getUint8(offset++)];
        
        x = x * scale.x + translation.x;
        y = y * scale.y + translation.y;
        z = z * scale.z + translation.z;
        
        frame.vertices.push(x, z, y); // convert to Y-up
        frame.normals.push(n[0], n[2], n[1]); // convert to Y-up
      }
      
      frames.push(frame);
    }
    
    // static
    
    var positions:Array<Float> = [];
    var normals:Array<Float> = [];
    var uvs:Array<Float> = [];
    
    var verticesTemp = frames[0].vertices;
    var normalsTemp = frames[0].normals;
    
    for (i in 0...vertexIndices.length) {
      var vertexIndex = vertexIndices[i];
      var stride = vertexIndex * 3;
      
      //
      
      var x = verticesTemp[stride];
      var y = verticesTemp[stride + 1];
      var z = verticesTemp[stride + 2];
      
      positions.push(x, y, z);
      
      //
      
      var nx = normalsTemp[stride];
      var ny = normalsTemp[stride + 1];
      var nz = normalsTemp[stride + 2];
      
      normals.push(nx, ny, nz);
      
      //
      
      var uvIndex = uvIndices[i];
      stride = uvIndex * 2;
      
      var u = uvsTemp[stride];
      var v = uvsTemp[stride + 1];
      
      uvs.push(u, v);
    }
    
    geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
    geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));
    geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    
    // animation
    
    var morphPositions:Array<Float32BufferAttribute> = [];
    var morphNormals:Array<Float32BufferAttribute> = [];
    
    for (i in 0...frames.length) {
      var frame = frames[i];
      var attributeName = frame.name;
      
      if (frame.vertices.length > 0) {
        var positions:Array<Float> = [];
        
        for (j in 0...vertexIndices.length) {
          var vertexIndex = vertexIndices[j];
          var stride = vertexIndex * 3;
          
          var x = frame.vertices[stride];
          var y = frame.vertices[stride + 1];
          var z = frame.vertices[stride + 2];
          
          positions.push(x, y, z);
        }
        
        var positionAttribute = new Float32BufferAttribute(positions, 3);
        positionAttribute.name = attributeName;
        morphPositions.push(positionAttribute);
      }
      
      if (frame.normals.length > 0) {
        var normals:Array<Float> = [];
        
        for (j in 0...vertexIndices.length) {
          var vertexIndex = vertexIndices[j];
          var stride = vertexIndex * 3;
          
          var nx = frame.normals[stride];
          var ny = frame.normals[stride + 1];
          var nz = frame.normals[stride + 2];
          
          normals.push(nx, ny, nz);
        }
        
        var normalAttribute = new Float32BufferAttribute(normals, 3);
        normalAttribute.name = attributeName;
        morphNormals.push(normalAttribute);
      }
    }
    
    geometry.morphAttributes.position = morphPositions;
    geometry.morphAttributes.normal = morphNormals;
    geometry.morphTargetsRelative = false;
    
    geometry.animations = AnimationClip.CreateClipsFromMorphTargetSequences(frames, 10);
    
    return geometry;
  }
}

var _normalData:Array<Array<Float>> = [
  [ - 0.525731, 0.000000, 0.850651 ], [ - 0.442863, 0.238856, 0.864188 ],
  [ - 0.295242, 0.000000, 0.955423 ], [ - 0.309017, 0.500000, 0.809017 ],
  [ - 0.162460, 0.262866, 0.951056 ], [ 0.000000, 0.000000, 1.000000 ],
  [ 0.000000, 0.850651, 0.525731 ], [ - 0.147621, 0.716567, 0.681718 ],
  [ 0.147621, 0.716567, 0.681718 ], [ 0.000000, 0.525731, 0.850651 ],
  [ 0.309017, 0.500000, 0.809017 ], [ 0.525731, 0.000000, 0.850651 ],
  [ 0.295242, 0.000000, 0.955423 ], [ 0.442863, 0.238856, 0.864188 ],
  [ 0.162460, 0.262866, 0.951056 ], [ - 0.681718, 0.147621, 0.716567 ],
  [ - 0.809017, 0.309017, 0.500000 ], [ - 0.587785, 0.425325, 0.688191 ],
  [ - 0.850651, 0.525731, 0.000000 ], [ - 0.864188, 0.442863, 0.238856 ],
  [ - 0.716567, 0.681718, 0.147621 ], [ - 0.688191, 0.587785, 0.425325 ],
  [ - 0.500000, 0.809017, 0.309017 ], [ - 0.238856, 0.864188, 0.442863 ],
  [ - 0.425325, 0.688191, 0.587785 ], [ - 0.716567, 0.681718, - 0.147621 ],
  [ - 0.500000, 0.809017, - 0.309017 ], [ - 0.525731, 0.850651, 0.000000 ],
  [ 0.000000, 0.850651, - 0.525731 ], [ - 0.238856, 0.864188, - 0.442863 ],
  [ 0.000000, 0.955423, - 0.295242 ], [ - 0.262866, 0.951056, - 0.162460 ],
  [ 0.000000, 1.000000, 0.000000 ], [ 0.000000, 0.955423, 0.295242 ],
  [ - 0.262866, 0.951056, 0.162460 ], [ 0.238856, 0.864188, 0.442863 ],
  [ 0.262866, 0.951056, 0.162460 ], [ 0.500000, 0.809017, 0.309017 ],
  [ 0.238856, 0.864188, - 0.442863 ], [ 0.262866, 0.951056, - 0.162460 ],
  [ 0.500000, 0.809017, - 0.309017 ], [ 0.850651, 0.525731, 0.000000 ],
  [ 0.716567, 0.681718, 0.147621 ], [ 0.716567, 0.681718, - 0.147621 ],
  [ 0.525731, 0.850651, 0.000000 ], [ 0.425325, 0.688191, 0.587785 ],
  [ 0.864188, 0.442863, 0.238856 ], [ 0.688191, 0.587785, 0.425325 ],
  [ 0.809017, 0.309017, 0.500000 ], [ 0.681718, 0.147621, 0.716567 ],
  [ 0.587785, 0.425325, 0.688191 ], [ 0.955423, 0.295242, 0.000000 ],
  [ 1.000000, 0.000000, 0.000000 ], [ 0.951056, 0.162460, 0.262866 ],
  [ 0.850651, - 0.525731, 0.000000 ], [ 0.955423, - 0.295242, 0.000000 ],
  [ 0.864188, - 0.442863, 0.238856 ], [ 0.951056, - 0.162460, 0.262866 ],
  [ 0.809017, - 0.309017, 0.500000 ], [ 0.681718, - 0.147621, 0.716567 ],
  [ 0.850651, 0.000000, 0.525731 ], [ 0.864188, 0.442863, - 0.238856 ],
  [ 0.809017, 0.309017, - 0.500000 ], [ 0.951056, 0.162460, - 0.262866 ],
  [ 0.525731, 0.000000, - 0.850651 ], [ 0.681718, 0.147621, - 0.716567 ],
  [ 0.681718, - 0.147621, - 0.716567 ], [ 0.850651, 0.000000, - 0.525731 ],
  [ 0.809017, - 0.309017, - 0.500000 ], [ 0.864188, - 0.442863, - 0.238856 ],
  [ 0.951056, - 0.162460, - 0.262866 ], [ 0.147621, 0.716567, - 0.681718 ],
  [ 0.309017, 0.500000, - 0.809017 ], [ 0.425325, 0.688191, - 0.587785 ],
  [ 0.442863, 0.238856, - 0.864188 ], [ 0.587785, 0.425325, - 0.688191 ],
  [ 0.688191, 0.587785, - 0.425325 ], [ - 0.147621, 0.716567, - 0.681718 ],
  [ - 0.309017, 0.500000, - 0.809017 ], [ 0.000000, 0.525731, - 0.850651 ],
  [ - 0.525731, 0.000000, - 0.850651 ], [ - 0.442863, 0.238856, - 0.864188 ],
  [ - 0.295242, 0.000000, - 0.955423 ], [ - 0.162460, 0.262866, - 0.951056 ],
  [ 0.000000, 0.000000, - 1.000000 ], [ 0.295242, 0.000000, - 0.955423 ],
  [ 0.162460, 0.262866, - 0.951056 ], [ - 0.442863, - 0.238856, - 0.864188 ],
  [ - 0.309017, - 0.500000, - 0.809017 ], [ - 0.162460, - 0.262866, - 0.951056 ],
  [ 0.000000, - 0.850651, - 0.525731 ], [ - 0.147621, - 0.716567, - 0.681718 ],
  [ 0.147621, - 0.716567, - 0.681718 ], [ 0.000000, - 0.525731, - 0.850651 ],
  [ 0.309017, - 0.500000, - 0.809017 ], [ 0.442863, - 0.238856, - 0.864188 ],
  [ 0.162460, - 0.262866, - 0.951056 ], [ 0.238856, - 0.864188, - 0.442863 ],
  [ 0.500000, - 0.809017, - 0.309017 ], [ 0.425325, - 0.688191, - 0.587785 ],
  [ 0.716567, - 0.681718, - 0.147621 ], [ 0.688191, - 0.587785, - 0.425325 ],
  [ 0.587785, - 0.425325, - 0.688191 ], [ 0.000000, - 0.955423, - 0.295242 ],
  [ 0.000000, - 1.000000, 0.000000 ], [ 0.262866, - 0.951056, - 0.162460 ],
  [ 0.000000, - 0.850651, 0.525731 ], [ 0.000000, - 0.955423, 0.295242 ],
  [ 0.238856, - 0.864188, 0.442863 ], [ 0.262866, - 0.951056, 0.162460 ],
  [ 0.500000, - 0.809017, 0.309017 ], [ 0.716567, - 0.681718, 0.147621 ],
  [ 0.525731, - 0.850651, 0.000000 ], [ - 0.238856, - 0.864188, - 0.442863 ],
  [ - 0.500000, - 0.809017, - 0.309017 ], [ - 0.262866, - 0.951056, - 0.162460 ],
  [ - 0.850651, - 0.525731, 0.000000 ], [ - 0.716567, - 0.681718, - 0.147621 ],
  [ - 0.716567, - 0.681718, 0.147621 ], [ - 0.525731, - 0.850651, 0.000000 ],
  [ - 0.500000, - 0.809017, 0.309017 ], [ - 0.238856, - 0.864188, 0.442863 ],
  [ - 0.262866, - 0.951056, 0.162460 ], [ - 0.864188, - 0.442863, 0.238856 ],
  [ - 0.809017, - 0.309017, 0.500000 ], [ - 0.688191, - 0.587785, 0.425325 ],
  [ - 0.681718, - 0.147621, 0.716567 ], [ - 0.442863, - 0.238856, 0.864188 ],
  [ - 0.587785, - 0.425325, 0.688191 ], [ - 0.309017, - 0.500000, 0.809017 ],
  [ - 0.147621, - 0.716567, 0.681718 ], [ - 0.425325, - 0.688191, 0.587785 ],
  [ - 0.162460, - 0.262866, 0.951056 ], [ 0.442863, - 0.238856, 0.864188 ],
  [ 0.162460, - 0.262866, 0.951056 ], [ 0.309017, - 0.500000, 0.809017 ],
  [ 0.147621, - 0.716567, 0.681718 ], [ 0.000000, - 0.525731, 0.850651 ],
  [ 0.425325, - 0.688191, 0.587785 ], [ 0.587785, - 0.425325, 0.688191 ],
  [ 0.688191, - 0.587785, 0.425325 ], [ - 0.955423, 0.295242, 0.000000 ],
  [ - 0.951056, 0.162460, 0.262866 ], [ - 1.000000, 0.000000, 0.000000 ],
  [ - 0.850651, 0.000000, 0.525731 ], [ - 0.955423, - 0.295242, 0.000000 ],
  [ - 0.951056, - 0.162460, 0.262866 ], [ - 0.864188, 0.442863, - 0.238856 ],
  [ - 0.951056, 0.162460, - 0.262866 ], [ - 0.809017, 0.309017, - 0.500000 ],
  [ - 0.864188, - 0.442863, - 0.238856 ], [ - 0.951056, - 0.162460, - 0.262866 ],
  [ - 0.809017, - 0.309017, - 0.500000 ], [ - 0.681718, 0.147621, - 0.716567 ],
  [ - 0.681718, - 0.147621, - 0.716567 ], [ - 0.850651, 0.000000, - 0.525731 ],
  [ - 0.688191, 0.587785, - 0.425325 ], [ - 0.587785, 0.425325, - 0.688191 ],
  [ - 0.425325, 0.688191, - 0.587785 ], [ - 0.425325, - 0.688191, - 0.587785 ],
  [ - 0.587785, - 0.425325, - 0.688191 ], [ - 0.688191, - 0.587785, - 0.425325 ]
];

export class MD2Loader {
  
  public static function new(manager:Loader = null):MD2Loader {
    return new MD2Loader(manager);
  }
  
  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(buffer:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(buffer));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }
  
  public function parse(buffer:haxe.io.Bytes):BufferGeometry {
    var data = new DataView(buffer.getData());
    
    // http://tfc.duke.free.fr/coding/md2-specs-en.html
    
    var header:Dynamic = {};
    var headerNames = [
      'ident', 'version',
      'skinwidth', 'skinheight',
      'framesize',
      'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
      'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
    ];
    
    for (i in 0...headerNames.length) {
      header[headerNames[i]] = data.getInt32(i * 4, true);
    }
    
    if (header.ident != 844121161 || header.version != 8) {
      console.error('Not a valid MD2 file');
      return null;
    }
    
    if (header.offset_end != data.byte
import three.core.AnimationClip;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.loaders.Loader;
import three.math.Vector3;

class MD2Loader extends Loader {
  
  public function new(manager:Loader = null) {
    super(manager);
  }
  
  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(buffer:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(buffer));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }
  
  public function parse(buffer:haxe.io.Bytes):BufferGeometry {
    var data = new DataView(buffer.getData());
    
    // http://tfc.duke.free.fr/coding/md2-specs-en.html
    
    var header:Dynamic = {};
    var headerNames = [
      'ident', 'version',
      'skinwidth', 'skinheight',
      'framesize',
      'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
      'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
    ];
    
    for (i in 0...headerNames.length) {
      header[headerNames[i]] = data.getInt32(i * 4, true);
    }
    
    if (header.ident != 844121161 || header.version != 8) {
      console.error('Not a valid MD2 file');
      return null;
    }
    
    if (header.offset_end != data.byteLength) {
      console.error('Corrupted MD2 file');
      return null;
    }
    
    //
    
    var geometry = new BufferGeometry();
    
    // uvs
    
    var uvsTemp:Array<Float> = [];
    var offset = header.offset_st;
    
    for (i in 0...header.num_st) {
      var u = data.getInt16(offset + 0, true);
      var v = data.getInt16(offset + 2, true);
      
      uvsTemp.push(u / header.skinwidth, 1 - (v / header.skinheight));
      
      offset += 4;
    }
    
    // triangles
    
    offset = header.offset_tris;
    
    var vertexIndices:Array<Int> = [];
    var uvIndices:Array<Int> = [];
    
    for (i in 0...header.num_tris) {
      vertexIndices.push(
        data.getUint16(offset + 0, true),
        data.getUint16(offset + 2, true),
        data.getUint16(offset + 4, true)
      );
      
      uvIndices.push(
        data.getUint16(offset + 6, true),
        data.getUint16(offset + 8, true),
        data.getUint16(offset + 10, true)
      );
      
      offset += 12;
    }
    
    // frames
    
    var translation = new Vector3();
    var scale = new Vector3();
    
    var frames:Array<Dynamic> = [];
    
    offset = header.offset_frames;
    
    for (i in 0...header.num_frames) {
      scale.set(
        data.getFloat32(offset + 0, true),
        data.getFloat32(offset + 4, true),
        data.getFloat32(offset + 8, true)
      );
      
      translation.set(
        data.getFloat32(offset + 12, true),
        data.getFloat32(offset + 16, true),
        data.getFloat32(offset + 20, true)
      );
      
      offset += 24;
      
      var string:Array<Int> = [];
      
      for (j in 0...16) {
        var character = data.getUint8(offset + j);
        if (character == 0) break;
        string[j] = character;
      }
      
      var frame:Dynamic = {
        name: String.fromCharCode.apply(null, string),
        vertices: [],
        normals: []
      };
      
      offset += 16;
      
      for (j in 0...header.num_vertices) {
        var x = data.getUint8(offset++);
        var y = data.getUint8(offset++);
        var z = data.getUint8(offset++);
        var n = _normalData[data.getUint8(offset++)];
        
        x = x * scale.x + translation.x;
        y = y * scale.y + translation.y;
        z = z * scale.z + translation.z;
        
        frame.vertices.push(x, z, y); // convert to Y-up
        frame.normals.push(n[0], n[2], n[1]); // convert to Y-up
      }
      
      frames.push(frame);
    }
    
    // static
    
    var positions:Array<Float> = [];
    var normals:Array<Float> = [];
    var uvs:Array<Float> = [];
    
    var verticesTemp = frames[0].vertices;
    var normalsTemp = frames[0].normals;
    
    for (i in 0...vertexIndices.length) {
      var vertexIndex = vertexIndices[i];
      var stride = vertexIndex * 3;
      
      //
      
      var x = verticesTemp[stride];
      var y = verticesTemp[stride + 1];
      var z = verticesTemp[stride + 2];
      
      positions.push(x, y, z);
      
      //
      
      var nx = normalsTemp[stride];
      var ny = normalsTemp[stride + 1];
      var nz = normalsTemp[stride + 2];
      
      normals.push(nx, ny, nz);
      
      //
      
      var uvIndex = uvIndices[i];
      stride = uvIndex * 2;
      
      var u = uvsTemp[stride];
      var v = uvsTemp[stride + 1];
      
      uvs.push(u, v);
    }
    
    geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
    geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));
    geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    
    // animation
    
    var morphPositions:Array<Float32BufferAttribute> = [];
    var morphNormals:Array<Float32BufferAttribute> = [];
    
    for (i in 0...frames.length) {
      var frame = frames[i];
      var attributeName = frame.name;
      
      if (frame.vertices.length > 0) {
        var positions:Array<Float> = [];
        
        for (j in 0...vertexIndices.length) {
          var vertexIndex = vertexIndices[j];
          var stride = vertexIndex * 3;
          
          var x = frame.vertices[stride];
          var y = frame.vertices[stride + 1];
          var z = frame.vertices[stride + 2];
          
          positions.push(x, y, z);
        }
        
        var positionAttribute = new Float32BufferAttribute(positions, 3);
        positionAttribute.name = attributeName;
        morphPositions.push(positionAttribute);
      }
      
      if (frame.normals.length > 0) {
        var normals:Array<Float> = [];
        
        for (j in 0...vertexIndices.length) {
          var vertexIndex = vertexIndices[j];
          var stride = vertexIndex * 3;
          
          var nx = frame.normals[stride];
          var ny = frame.normals[stride + 1];
          var nz = frame.normals[stride + 2];
          
          normals.push(nx, ny, nz);
        }
        
        var normalAttribute = new Float32BufferAttribute(normals, 3);
        normalAttribute.name = attributeName;
        morphNormals.push(normalAttribute);
      }
    }
    
    geometry.morphAttributes.position = morphPositions;
    geometry.morphAttributes.normal = morphNormals;
    geometry.morphTargetsRelative = false;
    
    geometry.animations = AnimationClip.CreateClipsFromMorphTargetSequences(frames, 10);
    
    return geometry;
  }
}

var _normalData:Array<Array<Float>> = [
  [ - 0.525731, 0.000000, 0.850651 ], [ - 0.442863, 0.238856, 0.864188 ],
  [ - 0.295242, 0.000000, 0.955423 ], [ - 0.309017, 0.500000, 0.809017 ],
  [ - 0.162460, 0.262866, 0.951056 ], [ 0.000000, 0.000000, 1.000000 ],
  [ 0.000000, 0.850651, 0.525731 ], [ - 0.147621, 0.716567, 0.681718 ],
  [ 0.147621, 0.716567, 0.681718 ], [ 0.000000, 0.525731, 0.850651 ],
  [ 0.309017, 0.500000, 0.809017 ], [ 0.525731, 0.000000, 0.850651 ],
  [ 0.295242, 0.000000, 0.955423 ], [ 0.442863, 0.238856, 0.864188 ],
  [ 0.162460, 0.262866, 0.951056 ], [ - 0.681718, 0.147621, 0.716567 ],
  [ - 0.809017, 0.309017, 0.500000 ], [ - 0.587785, 0.425325, 0.688191 ],
  [ - 0.850651, 0.525731, 0.000000 ], [ - 0.864188, 0.442863, 0.238856 ],
  [ - 0.716567, 0.681718, 0.147621 ], [ - 0.688191, 0.587785, 0.425325 ],
  [ - 0.500000, 0.809017, 0.309017 ], [ - 0.238856, 0.864188, 0.442863 ],
  [ - 0.425325, 0.688191, 0.587785 ], [ - 0.716567, 0.681718, - 0.147621 ],
  [ - 0.500000, 0.809017, - 0.309017 ], [ - 0.525731, 0.850651, 0.000000 ],
  [ 0.000000, 0.850651, - 0.525731 ], [ - 0.238856, 0.864188, - 0.442863 ],
  [ 0.000000, 0.955423, - 0.295242 ], [ - 0.262866, 0.951056, - 0.162460 ],
  [ 0.000000, 1.000000, 0.000000 ], [ 0.000000, 0.955423, 0.295242 ],
  [ - 0.262866, 0.951056, 0.162460 ], [ 0.238856, 0.864188, 0.442863 ],
  [ 0.262866, 0.951056, 0.162460 ], [ 0.500000, 0.809017, 0.309017 ],
  [ 0.238856, 0.864188, - 0.442863 ], [ 0.262866, 0.951056, - 0.162460 ],
  [ 0.500000, 0.809017, - 0.309017 ], [ 0.850651, 0.525731, 0.000000 ],
  [ 0.716567, 0.681718, 0.147621 ], [ 0.716567, 0.681718, - 0.147621 ],
  [ 0.525731, 0.850651, 0.000000 ], [ 0.425325, 0.688191, 0.587785 ],
  [ 0.864188, 0.442863, 0.238856 ], [ 0.688191, 0.587785, 0.425325 ],
  [ 0.809017, 0.309017, 0.500000 ], [ 0.681718, 0.147621, 0.716567 ],
  [ 0.587785, 0.425325, 0.688191 ], [ 0.955423, 0.295242, 0.000000 ],
  [ 1.000000, 0.000000, 0.000000 ], [ 0.951056, 0.162460, 0.262866 ],
  [ 0.850651, - 0.525731, 0.000000 ], [ 0.955423, - 0.295242, 0.000000 ],
  [ 0.864188, - 0.442863, 0.238856 ], [ 0.951056, - 0.162460, 0.262866 ],
  [ 0.809017, - 0.309017, 0.500000 ], [ 0.681718, - 0.147621, 0.716567 ],
  [ 0.850651, 0.000000, 0.525731 ], [ 0.864188, 0.442863, - 0.238856 ],
  [ 0.809017, 0.309017, - 0.500000 ], [ 0.951056, 0.162460, - 0.262866 ],
  [ 0.525731, 0.000000, - 0.850651 ], [ 0.681718, 0.147621, - 0.716567 ],
  [ 0.681718, - 0.147621, - 0.716567 ], [ 0.850651, 0.000000, - 0.525731 ],
  [ 0.809017, - 0.309017, - 0.500000 ], [ 0.864188, - 0.442863, - 0.238856 ],
  [ 0.951056, - 0.162460, - 0.262866 ], [ 0.147621, 0.716567, - 0.681718 ],
  [ 0.309017, 0.500000, - 0.809017 ], [ 0.425325, 0.688191, - 0.587785 ],
  [ 0.442863, 0.238856, - 0.864188 ], [ 0.587785, 0.425325, - 0.688191 ],
  [ 0.688191, 0.587785, - 0.425325 ], [ - 0.147621, 0.716567, - 0.681718 ],
  [ - 0.309017, 0.500000, - 0.809017 ], [ 0.000000, 0.525731, - 0.850651 ],
  [ - 0.525731, 0.000000, - 0.850651 ], [ - 0.442863, 0.238856, - 0.864188 ],
  [ - 0.295242, 0.000000, - 0.955423 ], [ - 0.162460, 0.262866, - 0.951056 ],
  [ 0.000000, 0.000000, - 1.000000 ], [ 0.295242, 0.000000, - 0.955423 ],
  [ 0.162460, 0.262866, - 0.951056 ], [ - 0.442863, - 0.238856, - 0.864188 ],
  [ - 0.309017, - 0.500000, - 0.809017 ], [ - 0.162460, - 0.262866, - 0.951056 ],
  [ 0.000000, - 0.850651, - 0.525731 ], [ - 0.147621, - 0.716567, - 0.681718 ],
  [ 0.147621, - 0.716567, - 0.681718 ], [ 0.000000, - 0.525731, - 0.850651 ],
  [ 0.309017, - 0.500000, - 0.809017 ], [ 0.442863, - 0.238856, - 0.864188 ],
  [ 0.162460, - 0.262866, - 0.951056 ], [ 0.238856, - 0.864188, - 0.442863 ],
  [ 0.500000, - 0.809017, - 0.309017 ], [ 0.425325, - 0.688191, - 0.587785 ],
  [ 0.716567, - 0.681718, - 0.147621 ], [ 0.688191, - 0.587785, - 0.425325 ],
  [ 0.587785, - 0.425325, - 0.688191 ], [ 0.000000, - 0.955423, - 0.295242 ],
  [ 0.000000, - 1.000000, 0.000000 ], [ 0.262866, - 0.951056, - 0.162460 ],
  [ 0.000000, - 0.850651, 0.525731 ], [ 0.000000, - 0.955423, 0.295242 ],
  [ 0.238856, - 0.864188, 0.442863 ], [ 0.262866, - 0.951056, 0.162460 ],
  [ 0.500000, - 0.809017, 0.309017 ], [ 0.716567, - 0.681718, 0.147621 ],
  [ 0.525731, - 0.850651, 0.000000 ], [ - 0.238856, - 0.864188, - 0.442863 ],
  [ - 0.500000, - 0.809017, - 0.309017 ], [ - 0.262866, - 0.951056, - 0.162460 ],
  [ - 0.850651, - 0.525731, 0.000000 ], [ - 0.716567, - 0.681718, - 0.147621 ],
  [ - 0.716567, - 0.681718, 0.147621 ], [ - 0.525731, - 0.850651, 0.000000 ],
  [ - 0.500000, - 0.809017, 0.309017 ], [ - 0.238856, - 0.864188, 0.442863 ],
  [ - 0.262866, - 0.951056, 0.162460 ], [ - 0.864188, - 0.442863, 0.238856 ],
  [ - 0.809017, - 0.309017, 0.500000 ], [ - 0.688191, - 0.587785, 0.425325 ],
  [ - 0.681718, - 0.147621, 0.716567 ], [ - 0.442863, - 0.238856, 0.864188 ],
  [ - 0.587785, - 0.425325, 0.688191 ], [ - 0.309017, - 0.500000, 0.809017 ],
  [ - 0.147621, - 0.716567, 0.681718 ], [ - 0.425325, - 0.688191, 0.587785 ],
  [ - 0.162460, - 0.262866, 0.951056 ], [ 0.442863, - 0.238856, 0.864188 ],
  [ 0.162460, - 0.262866, 0.951056 ], [ 0.309017, - 0.500000, 0.809017 ],
  [ 0.147621, - 0.716567, 0.681718 ], [ 0.000000, - 0.525731, 0.850651 ],
  [ 0.425325, - 0.688191, 0.587785 ], [ 0.587785, - 0.425325, 0.688191 ],
  [ 0.688191, - 0.587785, 0.425325 ], [ - 0.955423, 0.295242, 0.000000 ],
  [ - 0.951056, 0.162460, 0.262866 ], [ - 1.000000, 0.000000, 0.000000 ],
  [ - 0.850651, 0.000000, 0.525731 ], [ - 0.955423, - 0.295242, 0.000000 ],
  [ - 0.951056, - 0.162460, 0.262866 ], [ - 0.864188, 0.442863, - 0.238856 ],
  [ - 0.951056, 0.162460, - 0.262866 ], [ - 0.809017, 0.309017, - 0.500000 ],
  [ - 0.864188, - 0.442863, - 0.238856 ], [ - 0.951056, - 0.162460, - 0.262866 ],
  [ - 0.809017, - 0.309017, - 0.500000 ], [ - 0.681718, 0.147621, - 0.716567 ],
  [ - 0.681718, - 0.147621, - 0.716567 ], [ - 0.850651, 0.000000, - 0.525731 ],
  [ - 0.688191, 0.587785, - 0.425325 ], [ - 0.587785, 0.425325, - 0.688191 ],
  [ - 0.425325, 0.688191, - 0.587785 ], [ - 0.425325, - 0.688191, - 0.587785 ],
  [ - 0.587785, - 0.425325, - 0.688191 ], [ - 0.688191, - 0.587785, - 0.425325 ]
];

export class MD2Loader {
  
  public static function new(manager:Loader = null):MD2Loader {
    return new MD2Loader(manager);
  }
  
  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(buffer:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(buffer));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }
  
  public function parse(buffer:haxe.io.Bytes):BufferGeometry {
    var data = new DataView(buffer.getData());
    
    // http://tfc.duke.free.fr/coding/md2-specs-en.html
    
    var header:Dynamic = {};
    var headerNames = [
      'ident', 'version',
      'skinwidth', 'skinheight',
      'framesize',
      'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
      'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
    ];
    
    for (i in 0...headerNames.length) {
      header[headerNames[i]] = data.getInt32(i * 4, true);
    }
    
    if (header.ident != 844121161 || header.version != 8) {
      console.error('Not a valid MD2 file');
      return null;
    }
    
    if (header.offset_end != data.byte
import three.core.AnimationClip;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.loaders.Loader;
import three.math.Vector3;

class MD2Loader extends Loader {
  
  public function new(manager:Loader = null) {
    super(manager);
  }
  
  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(buffer:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(buffer));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }
  
  public function parse(buffer:haxe.io.Bytes):BufferGeometry {
    var data = new DataView(buffer.getData());
    
    // http://tfc.duke.free.fr/coding/md2-specs-en.html
    
    var header:Dynamic = {};
    var headerNames = [
      'ident', 'version',
      'skinwidth', 'skinheight',
      'framesize',
      'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
      'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
    ];
    
    for (i in 0...headerNames.length) {
      header[headerNames[i]] = data.getInt32(i * 4, true);
    }
    
    if (header.ident != 844121161 || header.version != 8) {
      console.error('Not a valid MD2 file');
      return null;
    }
    
    if (header.offset_end != data.byteLength) {
      console.error('Corrupted MD2 file');
      return null;
    }
    
    //
    
    var geometry = new BufferGeometry();
    
    // uvs
    
    var uvsTemp:Array<Float> = [];
    var offset = header.offset_st;
    
    for (i in 0...header.num_st) {
      var u = data.getInt16(offset + 0, true);
      var v = data.getInt16(offset + 2, true);
      
      uvsTemp.push(u / header.skinwidth, 1 - (v / header.skinheight));
      
      offset += 4;
    }
    
    // triangles
    
    offset = header.offset_tris;
    
    var vertexIndices:Array<Int> = [];
    var uvIndices:Array<Int> = [];
    
    for (i in 0...header.num_tris) {
      vertexIndices.push(
        data.getUint16(offset + 0, true),
        data.getUint16(offset + 2, true),
        data.getUint16(offset + 4, true)
      );
      
      uvIndices.push(
        data.getUint16(offset + 6, true),
        data.getUint16(offset + 8, true),
        data.getUint16(offset + 10, true)
      );
      
      offset += 12;
    }
    
    // frames
    
    var translation = new Vector3();
    var scale = new Vector3();
    
    var frames:Array<Dynamic> = [];
    
    offset = header.offset_frames;
    
    for (i in 0...header.num_frames) {
      scale.set(
        data.getFloat32(offset + 0, true),
        data.getFloat32(offset + 4, true),
        data.getFloat32(offset + 8, true)
      );
      
      translation.set(
        data.getFloat32(offset + 12, true),
        data.getFloat32(offset + 16, true),
        data.getFloat32(offset + 20, true)
      );
      
      offset += 24;
      
      var string:Array<Int> = [];
      
      for (j in 0...16) {
        var character = data.getUint8(offset + j);
        if (character == 0) break;
        string[j] = character;
      }
      
      var frame:Dynamic = {
        name: String.fromCharCode.apply(null, string),
        vertices: [],
        normals: []
      };
      
      offset += 16;
      
      for (j in 0...header.num_vertices) {
        var x = data.getUint8(offset++);
        var y = data.getUint8(offset++);
        var z = data.getUint8(offset++);
        var n = _normalData[data.getUint8(offset++)];
        
        x = x * scale.x + translation.x;
        y = y * scale.y + translation.y;
        z = z * scale.z + translation.z;
        
        frame.vertices.push(x, z, y); // convert to Y-up
        frame.normals.push(n[0], n[2], n[1]); // convert to Y-up
      }
      
      frames.push(frame);
    }
    
    // static
    
    var positions:Array<Float> = [];
    var normals:Array<Float> = [];
    var uvs:Array<Float> = [];
    
    var verticesTemp = frames[0].vertices;
    var normalsTemp = frames[0].normals;
    
    for (i in 0...vertexIndices.length) {
      var vertexIndex = vertexIndices[i];
      var stride = vertexIndex * 3;
      
      //
      
      var x = verticesTemp[stride];
      var y = verticesTemp[stride + 1];
      var z = verticesTemp[stride + 2];
      
      positions.push(x, y, z);
      
      //
      
      var nx = normalsTemp[stride];
      var ny = normalsTemp[stride + 1];
      var nz = normalsTemp[stride + 2];
      
      normals.push(nx, ny, nz);
      
      //
      
      var uvIndex = uvIndices[i];
      stride = uvIndex * 2;
      
      var u = uvsTemp[stride];
      var v = uvsTemp[stride + 1];
      
      uvs.push(u, v);
    }
    
    geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
    geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));
    geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    
    // animation
    
    var morphPositions:Array<Float32BufferAttribute> = [];
    var morphNormals:Array<Float32BufferAttribute> = [];
    
    for (i in 0...frames.length) {
      var frame = frames[i];
      var attributeName = frame.name;
      
      if (frame.vertices.length > 0) {
        var positions:Array<Float> = [];
        
        for (j in 0...vertexIndices.length) {
          var vertexIndex = vertexIndices[j];
          var stride = vertexIndex * 3;
          
          var x = frame.vertices[stride];
          var y = frame.vertices[stride + 1];
          var z = frame.vertices[stride + 2];
          
          positions.push(x, y, z);
        }
        
        var positionAttribute = new Float32BufferAttribute(positions, 3);
        positionAttribute.name = attributeName;
        morphPositions.push(positionAttribute);
      }
      
      if (frame.normals.length > 0) {
        var normals:Array<Float> = [];
        
        for (j in 0...vertexIndices.length) {
          var vertexIndex = vertexIndices[j];
          var stride = vertexIndex * 3;
          
          var nx = frame.normals[stride];
          var ny = frame.normals[stride + 1];
          var nz = frame.normals[stride + 2];
          
          normals.push(nx, ny, nz);
        }
        
        var normalAttribute = new Float32BufferAttribute(normals, 3);
        normalAttribute.name = attributeName;
        morphNormals.push(normalAttribute);
      }
    }
    
    geometry.morphAttributes.position = morphPositions;
    geometry.morphAttributes.normal = morphNormals;
    geometry.morphTargetsRelative = false;
    
    geometry.animations = AnimationClip.CreateClipsFromMorphTargetSequences(frames, 10);
    
    return geometry;
  }
}

var _normalData:Array<Array<Float>> = [
  [ - 0.525731, 0.000000, 0.850651 ], [ - 0.442863, 0.238856, 0.864188 ],
  [ - 0.295242, 0.000000, 0.955423 ], [ - 0.309017, 0.500000, 0.809017 ],
  [ - 0.162460, 0.262866, 0.951056 ], [ 0.000000, 0.000000, 1.000000 ],
  [ 0.000000, 0.850651, 0.525731 ], [ - 0.147621, 0.716567, 0.681718 ],
  [ 0.147621, 0.716567, 0.681718 ], [ 0.000000, 0.525731, 0.850651 ],
  [ 0.309017, 0.500000, 0.809017 ], [ 0.525731, 0.000000, 0.850651 ],
  [ 0.295242, 0.000000, 0.955423 ], [ 0.442863, 0.238856, 0.864188 ],
  [ 0.162460, 0.262866, 0.951056 ], [ - 0.681718, 0.147621, 0.716567 ],
  [ - 0.809017, 0.309017, 0.500000 ], [ - 0.587785, 0.425325, 0.688191 ],
  [ - 0.850651, 0.525731, 0.000000 ], [ - 0.864188, 0.442863, 0.238856 ],
  [ - 0.716567, 0.681718, 0.147621 ], [ - 0.688191, 0.587785, 0.425325 ],
  [ - 0.500000, 0.809017, 0.309017 ], [ - 0.238856, 0.864188, 0.442863 ],
  [ - 0.425325, 0.688191, 0.587785 ], [ - 0.716567, 0.681718, - 0.147621 ],
  [ - 0.500000, 0.809017, - 0.309017 ], [ - 0.525731, 0.850651, 0.000000 ],
  [ 0.000000, 0.850651, - 0.525731 ], [ - 0.238856, 0.864188, - 0.442863 ],
  [ 0.000000, 0.955423, - 0.295242 ], [ - 0.262866, 0.951056, - 0.162460 ],
  [ 0.000000, 1.000000, 0.000000 ], [ 0.000000, 0.955423, 0.295242 ],
  [ - 0.262866, 0.951056, 0.162460 ], [ 0.238856, 0.864188, 0.442863 ],
  [ 0.262866, 0.951056, 0.162460 ], [ 0.500000, 0.809017, 0.309017 ],
  [ 0.238856, 0.864188, - 0.442863 ], [ 0.262866, 0.951056, - 0.162460 ],
  [ 0.500000, 0.809017, - 0.309017 ], [ 0.850651, 0.525731, 0.000000 ],
  [ 0.716567, 0.681718, 0.147621 ], [ 0.716567, 0.681718, - 0.147621 ],
  [ 0.525731, 0.850651, 0.000000 ], [ 0.425325, 0.688191, 0.587785 ],
  [ 0.864188, 0.442863, 0.238856 ], [ 0.688191, 0.587785, 0.425325 ],
  [ 0.809017, 0.309017, 0.500000 ], [ 0.681718, 0.147621, 0.716567 ],
  [ 0.587785, 0.425325, 0.688191 ], [ 0.955423, 0.295242, 0.000000 ],
  [ 1.000000, 0.000000, 0.000000 ], [ 0.951056, 0.162460, 0.262866 ],
  [ 0.850651, - 0.525731, 0.000000 ], [ 0.955423, - 0.295242, 0.000000 ],
  [ 0.864188, - 0.442863, 0.238856 ], [ 0.951056, - 0.162460, 0.262866 ],
  [ 0.809017, - 0.309017, 0.500000 ], [ 0.681718, - 0.147621, 0.716567 ],
  [ 0.850651, 0.000000, 0.525731 ], [ 0.864188, 0.442863, - 0.238856 ],
  [ 0.809017, 0.309017, - 0.500000 ], [ 0.951056, 0.162460, - 0.262866 ],
  [ 0.525731, 0.000000, - 0.850651 ], [ 0.681718, 0.147621, - 0.716567 ],
  [ 0.681718, - 0.147621, - 0.716567 ], [ 0.850651, 0.000000, - 0.525731 ],
  [ 0.809017, - 0.309017, - 0.500000 ], [ 0.864188, - 0.442863, - 0.238856 ],
  [ 0.951056, - 0.162460, - 0.262866 ], [ 0.147621, 0.716567, - 0.681718 ],
  [ 0.309017, 0.500000, - 0.809017 ], [ 0.425325, 0.688191, - 0.587785 ],
  [ 0.442863, 0.238856, - 0.864188 ], [ 0.587785, 0.425325, - 0.688191 ],
  [ 0.688191, 0.587785, - 0.425325 ], [ - 0.147621, 0.716567, - 0.681718 ],
  [ - 0.309017, 0.500000, - 0.809017 ], [ 0.000000, 0.525731, - 0.850651 ],
  [ - 0.525731, 0.000000, - 0.850651 ], [ - 0.442863, 0.238856, - 0.864188 ],
  [ - 0.295242, 0.000000, - 0.955423 ], [ - 0.162460, 0.262866, - 0.951056 ],
  [ 0.000000, 0.000000, - 1.000000 ], [ 0.295242, 0.000000, - 0.955423 ],
  [ 0.162460, 0.262866, - 0.951056 ], [ - 0.442863, - 0.238856, - 0.864188 ],
  [ - 0.309017, - 0.500000, - 0.809017 ], [ - 0.162460, - 0.262866, - 0.951056 ],
  [ 0.000000, - 0.850651, - 0.525731 ], [ - 0.147621, - 0.716567, - 0.681718 ],
  [ 0.147621, - 0.716567, - 0.681718 ], [ 0.000000, - 0.525731, - 0.850651 ],
  [ 0.309017, - 0.500000, - 0.809017 ], [ 0.442863, - 0.238856, - 0.864188 ],
  [ 0.162460, - 0.262866, - 0.951056 ], [ 0.238856, - 0.864188, - 0.442863 ],
  [ 0.500000, - 0.809017, - 0.309017 ], [ 0.425325, - 0.688191, - 0.587785 ],
  [ 0.716567, - 0.681718, - 0.147621 ], [ 0.688191, - 0.587785, - 0.425325 ],
  [ 0.587785, - 0.425325, - 0.688191 ], [ 0.000000, - 0.955423, - 0.295242 ],
  [ 0.000000, - 1.000000, 0.000000 ], [ 0.262866, - 0.951056, - 0.162460 ],
  [ 0.000000, - 0.850651, 0.525731 ], [ 0.000000, - 0.955423, 0.295242 ],
  [ 0.238856, - 0.864188, 0.442863 ], [ 0.262866, - 0.951056, 0.162460 ],
  [ 0.500000, - 0.809017, 0.309017 ], [ 0.716567, - 0.681718, 0.147621 ],
  [ 0.525731, - 0.850651, 0.000000 ], [ - 0.238856, - 0.864188, - 0.442863 ],
  [ - 0.500000, - 0.809017, - 0.309017 ], [ - 0.262866, - 0.951056, - 0.162460 ],
  [ - 0.850651, - 0.525731, 0.000000 ], [ - 0.716567, - 0.681718, - 0.147621 ],
  [ - 0.716567, - 0.681718, 0.147621 ], [ - 0.525731, - 0.850651, 0.000000 ],
  [ - 0.500000, - 0.809017, 0.309017 ], [ - 0.238856, - 0.864188, 0.442863 ],
  [ - 0.262866, - 0.951056, 0.162460 ], [ - 0.864188, - 0.442863, 0.238856 ],
  [ - 0.809017, - 0.309017, 0.500000 ], [ - 0.688191, - 0.587785, 0.425325 ],
  [ - 0.681718, - 0.147621, 0.716567 ], [ - 0.442863, - 0.238856, 0.864188 ],
  [ - 0.587785, - 0.425325, 0.688191 ], [ - 0.309017, - 0.500000, 0.809017 ],
  [ - 0.147621, - 0.716567, 0.681718 ], [ - 0.425325, - 0.688191, 0.587785 ],
  [ - 0.162460, - 0.262866, 0.951056 ], [ 0.442863, - 0.238856, 0.864188 ],
  [ 0.162460, - 0.262866, 0.951056 ], [ 0.309017, - 0.500000, 0.809017 ],
  [ 0.147621, - 0.716567, 0.681718 ], [ 0.000000, - 0.525731, 0.850651 ],
  [ 0.425325, - 0.688191, 0.587785 ], [ 0.587785, - 0.425325, 0.688191 ],
  [ 0.688191, - 0.587785, 0.425325 ], [ - 0.955423, 0.295242, 0.000000 ],
  [ - 0.951056, 0.162460, 0.262866 ], [ - 1.000000, 0.000000, 0.000000 ],
  [ - 0.850651, 0.000000, 0.525731 ], [ - 0.955423, - 0.295242, 0.000000 ],
  [ - 0.951056, - 0.162460, 0.262866 ], [ - 0.864188, 0.442863, - 0.238856 ],
  [ - 0.951056, 0.162460, - 0.262866 ], [ - 0.809017, 0.309017, - 0.500000 ],
  [ - 0.864188, - 0.442863, - 0.238856 ], [ - 0.951056, - 0.162460, - 0.262866 ],
  [ - 0.809017, - 0.309017, - 0.500000 ], [ - 0.681718, 0.147621, - 0.716567 ],
  [ - 0.681718, - 0.147621, - 0.716567 ], [ - 0.850651, 0.000000, - 0.525731 ],
  [ - 0.688191, 0.587785, - 0.425325 ], [ - 0.587785, 0.425325, - 0.688191 ],
  [ - 0.425325, 0.688191, - 0.587785 ], [ - 0.425325, - 0.688191, - 0.587785 ],
  [ - 0.587785, - 0.425325, - 0.688191 ], [ - 0.688191, - 0.587785, - 0.425325 ]
];

export class MD2Loader {
  
  public static function new(manager:Loader = null):MD2Loader {
    return new MD2Loader(manager);
  }
  
  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(buffer:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(buffer));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }
  
  public function parse(buffer:haxe.io.Bytes):BufferGeometry {
    var data = new DataView(buffer.getData());
    
    // http://tfc.duke.free.fr/coding/md2-specs-en.html
    
    var header:Dynamic = {};
    var headerNames = [
      'ident', 'version',
      'skinwidth', 'skinheight',
      'framesize',
      'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
      'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
    ];
    
    for (i in 0...headerNames.length) {
      header[headerNames[i]] = data.getInt32(i * 4, true);
    }
    
    if (header.ident != 844121161 || header.version != 8) {
      console.error('Not a valid MD2 file');
      return null;
    }
    
    if (header.offset_end != data.byte
import three.core.AnimationClip;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.loaders.Loader;
import three.math.Vector3;

class MD2Loader extends Loader {
  
  public function new(manager:Loader = null) {
    super(manager);
  }
  
  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(buffer:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(buffer));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }
  
  public function parse(buffer:haxe.io.Bytes):BufferGeometry {
    var data = new DataView(buffer.getData());
    
    // http://tfc.duke.free.fr/coding/md2-specs-en.html
    
    var header:Dynamic = {};
    var headerNames = [
      'ident', 'version',
      'skinwidth', 'skinheight',
      'framesize',
      'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
      'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
    ];
    
    for (i in 0...headerNames.length) {
      header[headerNames[i]] = data.getInt32(i * 4, true);
    }
    
    if (header.ident != 844121161 || header.version != 8) {
      console.error('Not a valid MD2 file');
      return null;
    }
    
    if (header.offset_end != data.byteLength) {
      console.error('Corrupted MD2 file');
      return null;
    }
    
    //
    
    var geometry = new BufferGeometry();
    
    // uvs
    
    var uvsTemp:Array<Float> = [];
    var offset = header.offset_st;
    
    for (i in 0...header.num_st) {
      var u = data.getInt16(offset + 0, true);
      var v = data.getInt16(offset + 2, true);
      
      uvsTemp.push(u / header.skinwidth, 1 - (v / header.skinheight));
      
      offset += 4;
    }
    
    // triangles
    
    offset = header.offset_tris;
    
    var vertexIndices:Array<Int> = [];
    var uvIndices:Array<Int> = [];
    
    for (i in 0...header.num_tris) {
      vertexIndices.push(
        data.getUint16(offset + 0, true),
        data.getUint16(offset + 2, true),
        data.getUint16(offset + 4, true)
      );
      
      uvIndices.push(
        data.getUint16(offset + 6, true),
        data.getUint16(offset + 8, true),
        data.getUint16(offset + 10, true)
      );
      
      offset += 12;
    }
    
    // frames
    
    var translation = new Vector3();
    var scale = new Vector3();
    
    var frames:Array<Dynamic> = [];
    
    offset = header.offset_frames;
    
    for (i in 0...header.num_frames) {
      scale.set(
        data.getFloat32(offset + 0, true),
        data.getFloat32(offset + 4, true),
        data.getFloat32(offset + 8, true)
      );
      
      translation.set(
        data.getFloat32(offset + 12, true),
        data.getFloat32(offset + 16, true),
        data.getFloat32(offset + 20, true)
      );
      
      offset += 24;
      
      var string:Array<Int> = [];
      
      for (j in 0...16) {
        var character = data.getUint8(offset + j);
        if (character == 0) break;
        string[j] = character;
      }
      
      var frame:Dynamic = {
        name: String.fromCharCode.apply(null, string),
        vertices: [],
        normals: []
      };
      
      offset += 16;
      
      for (j in 0...header.num_vertices) {
        var x = data.getUint8(offset++);
        var y = data.getUint8(offset++);
        var z = data.getUint8(offset++);
        var n = _normalData[data.getUint8(offset++)];
        
        x = x * scale.x + translation.x;
        y = y * scale.y + translation.y;
        z = z * scale.z + translation.z;
        
        frame.vertices.push(x, z, y); // convert to Y-up
        frame.normals.push(n[0], n[2], n[1]); // convert to Y-up
      }
      
      frames.push(frame);
    }
    
    // static
    
    var positions:Array<Float> = [];
    var normals:Array<Float> = [];
    var uvs:Array<Float> = [];
    
    var verticesTemp = frames[0].vertices;
    var normalsTemp = frames[0].normals;
    
    for (i in 0...vertexIndices.length) {
      var vertexIndex = vertexIndices[i];
      var stride = vertexIndex * 3;
      
      //
      
      var x = verticesTemp[stride];
      var y = verticesTemp[stride + 1];
      var z = verticesTemp[stride + 2];
      
      positions.push(x, y, z);
      
      //
      
      var nx = normalsTemp[stride];
      var ny = normalsTemp[stride + 1];
      var nz = normalsTemp[stride + 2];
      
      normals.push(nx, ny, nz);
      
      //
      
      var uvIndex = uvIndices[i];
      stride = uvIndex * 2;
      
      var u = uvsTemp[stride];
      var v = uvsTemp[stride + 1];
      
      uvs.push(u, v);
    }
    
    geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
    geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));
    geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    
    // animation
    
    var morphPositions:Array<Float32BufferAttribute> = [];
    var morphNormals:Array<Float32BufferAttribute> = [];
    
    for (i in 0...frames.length) {
      var frame = frames[i];
      var attributeName = frame.name;
      
      if (frame.vertices.length > 0) {
        var positions:Array<Float> = [];
        
        for (j in 0...vertexIndices.length) {
          var vertexIndex = vertexIndices[j];
          var stride = vertexIndex * 3;
          
          var x = frame.vertices[stride];
          var y = frame.vertices[stride + 1];
          var z = frame.vertices[stride + 2];
          
          positions.push(x, y, z);
        }
        
        var positionAttribute = new Float32BufferAttribute(positions, 3);
        positionAttribute.name = attributeName;
        morphPositions.push(positionAttribute);
      }
      
      if (frame.normals.length > 0) {
        var normals:Array<Float> = [];
        
        for (j in 0...vertexIndices.length) {
          var vertexIndex = vertexIndices[j];
          var stride = vertexIndex * 3;
          
          var nx = frame.normals[stride];
          var ny = frame.normals[stride + 1];
          var nz = frame.normals[stride + 2];
          
          normals.push(nx, ny, nz);
        }
        
        var normalAttribute = new Float32BufferAttribute(normals, 3);
        normalAttribute.name = attributeName;
        morphNormals.push(normalAttribute);
      }
    }
    
    geometry.morphAttributes.position = morphPositions;
    geometry.morphAttributes.normal = morphNormals;
    geometry.morphTargetsRelative = false;
    
    geometry.animations = AnimationClip.CreateClipsFromMorphTargetSequences(frames, 10);
    
    return geometry;
  }
}

var _normalData:Array<Array<Float>> = [
  [ - 0.525731, 0.000000, 0.850651 ], [ - 0.442863, 0.238856, 0.864188 ],
  [ - 0.295242, 0.000000, 0.955423 ], [ - 0.309017, 0.500000, 0.809017 ],
  [ - 0.162460, 0.262866, 0.951056 ], [ 0.000000, 0.000000, 1.000000 ],
  [ 0.000000, 0.850651, 0.525731 ], [ - 0.147621, 0.716567, 0.681718 ],
  [ 0.147621, 0.716567, 0.681718 ], [ 0.000000, 0.525731, 0.850651 ],
  [ 0.309017, 0.500000, 0.809017 ], [ 0.525731, 0.000000, 0.850651 ],
  [ 0.295242, 0.000000, 0.955423 ], [ 0.442863, 0.238856, 0.864188 ],
  [ 0.162460, 0.262866, 0.951056 ], [ - 0.681718, 0.147621, 0.716567 ],
  [ - 0.809017, 0.309017, 0.500000 ], [ - 0.587785, 0.425325, 0.688191 ],
  [ - 0.850651, 0.525731, 0.000000 ], [ - 0.864188, 0.442863, 0.238856 ],
  [ - 0.716567, 0.681718, 0.147621 ], [ - 0.688191, 0.587785, 0.425325 ],
  [ - 0.500000, 0.809017, 0.309017 ], [ - 0.238856, 0.864188, 0.442863 ],
  [ - 0.425325, 0.688191, 0.587785 ], [ - 0.716567, 0.681718, - 0.147621 ],
  [ - 0.500000, 0.809017, - 0.309017 ], [ - 0.525731, 0.850651, 0.000000 ],
  [ 0.000000, 0.850651, - 0.525731 ], [ - 0.238856, 0.864188, - 0.442863 ],
  [ 0.000000, 0.955423, - 0.295242 ], [ - 0.262866, 0.951056, - 0.162460 ],
  [ 0.000000, 1.000000, 0.000000 ], [ 0.000000, 0.955423, 0.295242 ],
  [ - 0.262866, 0.951056, 0.162460 ], [ 0.238856, 0.864188, 0.442863 ],
  [ 0.262866, 0.951056, 0.162460 ], [ 0.500000, 0.809017, 0.309017 ],
  [ 0.238856, 0.864188, - 0.442863 ], [ 0.262866, 0.951056, - 0.162460 ],
  [ 0.500000, 0.809017, - 0.309017 ], [ 0.850651, 0.525731, 0.000000 ],
  [ 0.716567, 0.681718, 0.147621 ], [ 0.716567, 0.681718, - 0.147621 ],
  [ 0.525731, 0.850651, 0.000000 ], [ 0.425325, 0.688191, 0.587785 ],
  [ 0.864188, 0.442863, 0.238856 ], [ 0.688191, 0.587785, 0.425325 ],
  [ 0.809017, 0.309017, 0.500000 ], [ 0.681718, 0.147621, 0.716567 ],
  [ 0.587785, 0.425325, 0.688191 ], [ 0.955423, 0.295242, 0.000000 ],
  [ 1.000000, 0.000000, 0.000000 ], [ 0.951056, 0.162460, 0.262866 ],
  [ 0.850651, - 0.525731, 0.000000 ], [ 0.955423, - 0.295242, 0.000000 ],
  [ 0.864188, - 0.442863, 0.238856 ], [ 0.951056, - 0.162460, 0.262866 ],
  [ 0.809017, - 0.309017, 0.500000 ], [ 0.681718, - 0.147621, 0.716567 ],
  [ 0.850651, 0.000000, 0.525731 ], [ 0.864188, 0.442863, - 0.238856 ],
  [ 0.809017, 0.309017, - 0.500000 ], [ 0.951056, 0.162460, - 0.262866 ],
  [ 0.525731, 0.000000, - 0.850651 ], [ 0.681718, 0.147621, - 0.716567 ],
  [ 0.681718, - 0.147621, - 0.716567 ], [ 0.850651, 0.000000, - 0.525731 ],
  [ 0.809017, - 0.309017, - 0.500000 ], [ 0.864188, - 0.442863, - 0.238856 ],
  [ 0.951056, - 0.162460, - 0.262866 ], [ 0.147621, 0.716567, - 0.681718 ],
  [ 0.309017, 0.500000, - 0.809017 ], [ 0.425325, 0.688191, - 0.587785 ],
  [ 0.442863, 0.238856, - 0.864188 ], [ 0.587785, 0.425325, - 0.688191 ],
  [ 0.688191, 0.587785, - 0.425325 ], [ - 0.147621, 0.716567, - 0.681718 ],
  [ - 0.309017, 0.500000, - 0.809017 ], [ 0.000000, 0.525731, - 0.850651 ],
  [ - 0.525731, 0.000000, - 0.850651 ], [ - 0.442863, 0.238856, - 0.864188 ],
  [ - 0.295242, 0.000000, - 0.955423 ], [ - 0.162460, 0.262866, - 0.951056 ],
  [ 0.000000, 0.000000, - 1.000000 ], [ 0.295242, 0.000000, - 0.955423 ],
  [ 0.162460, 0.262866, - 0.951056 ], [ - 0.442863, - 0.238856, - 0.864188 ],
  [ - 0.309017, - 0.500000, - 0.809017 ], [ - 0.162460, - 0.262866, - 0.951056 ],
  [ 0.000000, - 0.850651, - 0.525731 ], [ - 0.147621, - 0.716567, - 0.681718 ],
  [ 0.147621, - 0.716567, - 0.681718 ], [ 0.000000, - 0.525731, - 0.850651 ],
  [ 0.309017, - 0.500000, - 0.809017 ], [ 0.442863, - 0.238856, - 0.864188 ],
  [ 0.162460, - 0.262866, - 0.951056 ], [ 0.238856, - 0.864188, - 0.442863 ],
  [ 0.500000, - 0.809017, - 0.309017 ], [ 0.425325, - 0.688191, - 0.587785 ],
  [ 0.716567, - 0.681718, - 0.147621 ], [ 0.688191, - 0.587785, - 0.425325 ],
  [ 0.587785, - 0.425325, - 0.688191 ], [ 0.000000, - 0.955423, - 0.295242 ],
  [ 0.000000, - 1.000000, 0.000000 ], [ 0.262866, - 0.951056, - 0.162460 ],
  [ 0.000000, - 0.850651, 0.525731 ], [ 0.000000, - 0.955423, 0.295242 ],
  [ 0.238856, - 0.864188, 0.442863 ], [ 0.262866, - 0.951056, 0.162460 ],
  [ 0.500000, - 0.809017, 0.309017 ], [ 0.716567, - 0.681718, 0.147621 ],
  [ 0.525731, - 0.850651, 0.000000 ], [ - 0.238856, - 0.864188, - 0.442863 ],
  [ - 0.500000, - 0.809017, - 0.309017 ], [ - 0.262866, - 0.951056, - 0.162460 ],
  [ - 0.850651, - 0.525731, 0.000000 ], [ - 0.716567, - 0.681718, - 0.147621 ],
  [ - 0.716567, - 0.681718, 0.147621 ], [ - 0.525731, - 0.850651, 0.000000 ],
  [ - 0.500000, - 0.809017, 0.309017 ], [ - 0.238856, - 0.864188, 0.442863 ],
  [ - 0.262866, - 0.951056, 0.162460 ], [ - 0.864188, - 0.442863, 0.238856 ],
  [ - 0.809017, - 0.309017, 0.500000 ], [ - 0.688191, - 0.587785, 0.425325 ],
  [ - 0.681718, - 0.147621, 0.716567 ], [ - 0.442863, - 0.238856, 0.864188 ],
  [ - 0.587785, - 0.425325, 0.688191 ], [ - 0.309017, - 0.500000, 0.809017 ],
  [ - 0.147621, - 0.716567, 0.681718 ], [ - 0.425325, - 0.688191, 0.587785 ],
  [ - 0.162460, - 0.262866, 0.951056 ], [ 0.442863, - 0.238856, 0.864188 ],
  [ 0.162460, - 0.262866, 0.951056 ], [ 0.309017, - 0.500000, 0.809017 ],
  [ 0.147621, - 0.716567, 0.681718 ], [ 0.000000, - 0.525731, 0.850651 ],
  [ 0.425325, - 0.688191, 0.587785 ], [ 0.587785, - 0.425325, 0.688191 ],
  [ 0.688191, - 0.587785, 0.425325 ], [ - 0.955423, 0.295242, 0.000000 ],
  [ - 0.951056, 0.162460, 0.262866 ], [ - 1.000000, 0.000000, 0.000000 ],
  [ - 0.850651, 0.000000, 0.525731 ], [ - 0.955423, - 0.295242, 0.000000 ],
  [ - 0.951056, - 0.162460, 0.262866 ], [ - 0.864188, 0.442863, - 0.238856 ],
  [ - 0.951056, 0.162460, - 0.262866 ], [ - 0.809017, 0.309017, - 0.500000 ],
  [ - 0.864188, - 0.442863, - 0.238856 ], [ - 0.951056, - 0.162460, - 0.262866 ],
  [ - 0.809017, - 0.309017, - 0.500000 ], [ - 0.681718, 0.147621, - 0.716567 ],
  [ - 0.681718, - 0.147621, - 0.716567 ], [ - 0.850651, 0.000000, - 0.525731 ],
  [ - 0.688191, 0.587785, - 0.425325 ], [ - 0.587785, 0.425325, - 0.688191 ],
  [ - 0.425325, 0.688191, - 0.587785 ], [ - 0.425325, - 0.688191, - 0.587785 ],
  [ - 0.587785, - 0.425325, - 0.688191 ], [ - 0.688191, - 0.587785, - 0.425325 ]
];

export class MD2Loader {
  
  public static function new(manager:Loader = null):MD2Loader {
    return new MD2Loader(manager);
  }
  
  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(buffer:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(buffer));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }
  
  public function parse(buffer:haxe.io.Bytes):BufferGeometry {
    var data = new DataView(buffer.getData());
    
    // http://tfc.duke.free.fr/coding/md2-specs-en.html
    
    var header:Dynamic = {};
    var headerNames = [
      'ident', 'version',
      'skinwidth', 'skinheight',
      'framesize',
      'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
      'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
    ];
    
    for (i in 0...headerNames.length) {
      header[headerNames[i]] = data.getInt32(i * 4, true);
    }
    
    if (header.ident != 844121161 || header.version != 8) {
      console.error('Not a valid MD2 file');
      return null;
    }
    
    if (header.offset_end != data.byte
import three.core.AnimationClip;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.loaders.Loader;
import three.math.Vector3;

class MD2Loader extends Loader {
  
  public function new(manager:Loader = null) {
    super(manager);
  }
  
  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(buffer:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(buffer));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }
  
  public function parse(buffer:haxe.io.Bytes):BufferGeometry {
    var data = new DataView(buffer.getData());
    
    // http://tfc.duke.free.fr/coding/md2-specs-en.html
    
    var header:Dynamic = {};
    var headerNames = [
      'ident', 'version',
      'skinwidth', 'skinheight',
      'framesize',
      'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
      'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
    ];
    
    for (i in 0...headerNames.length) {
      header[headerNames[i]] = data.getInt32(i * 4, true);
    }
    
    if (header.ident != 844121161 || header.version != 8) {
      console.error('Not a valid MD2 file');
      return null;
    }
    
    if (header.offset_end != data.byteLength) {
      console.error('Corrupted MD2 file');
      return null;
    }
    
    //
    
    var geometry = new BufferGeometry();
    
    // uvs
    
    var uvsTemp:Array<Float> = [];
    var offset = header.offset_st;
    
    for (i in 0...header.num_st) {
      var u = data.getInt16(offset + 0, true);
      var v = data.getInt16(offset + 2, true);
      
      uvsTemp.push(u / header.skinwidth, 1 - (v / header.skinheight));
      
      offset += 4;
    }
    
    // triangles
    
    offset = header.offset_tris;
    
    var vertexIndices:Array<Int> = [];
    var uvIndices:Array<Int> = [];
    
    for (i in 0...header.num_tris) {
      vertexIndices.push(
        data.getUint16(offset + 0, true),
        data.getUint16(offset + 2, true),
        data.getUint16(offset + 4, true)
      );
      
      uvIndices.push(
        data.getUint16(offset + 6, true),
        data.getUint16(offset + 8, true),
        data.getUint16(offset + 10, true)
      );
      
      offset += 12;
    }
    
    // frames
    
    var translation = new Vector3();
    var scale = new Vector3();
    
    var frames:Array<Dynamic> = [];
    
    offset = header.offset_frames;
    
    for (i in 0...header.num_frames) {
      scale.set(
        data.getFloat32(offset + 0, true),
        data.getFloat32(offset + 4, true),
        data.getFloat32(offset + 8, true)
      );
      
      translation.set(
        data.getFloat32(offset + 12, true),
        data.getFloat32(offset + 16, true),
        data.getFloat32(offset + 20, true)
      );
      
      offset += 24;
      
      var string:Array<Int> = [];
      
      for (j in 0...16) {
        var character = data.getUint8(offset + j);
        if (character == 0) break;
        string[j] = character;
      }
      
      var frame:Dynamic = {
        name: String.fromCharCode.apply(null, string),
        vertices: [],
        normals: []
      };
      
      offset += 16;
      
      for (j in 0...header.num_vertices) {
        var x = data.getUint8(offset++);
        var y = data.getUint8(offset++);
        var z = data.getUint8(offset++);
        var n = _normalData[data.getUint8(offset++)];
        
        x = x * scale.x + translation.x;
        y = y * scale.y + translation.y;
        z = z * scale.z + translation.z;
        
        frame.vertices.push(x, z, y); // convert to Y-up
        frame.normals.push(n[0], n[2], n[1]); // convert to Y-up
      }
      
      frames.push(frame);
    }
    
    // static
    
    var positions:Array<Float> = [];
    var normals:Array<Float> = [];
    var uvs:Array<Float> = [];
    
    var verticesTemp = frames[0].vertices;
    var normalsTemp = frames[0].normals;
    
    for (i in 0...vertexIndices.length) {
      var vertexIndex = vertexIndices[i];
      var stride = vertexIndex * 3;
      
      //
      
      var x = verticesTemp[stride];
      var y = verticesTemp[stride + 1];
      var z = verticesTemp[stride + 2];
      
      positions.push(x, y, z);
      
      //
      
      var nx = normalsTemp[stride];
      var ny = normalsTemp[stride + 1];
      var nz = normalsTemp[stride + 2];
      
      normals.push(nx, ny, nz);
      
      //
      
      var uvIndex = uvIndices[i];
      stride = uvIndex * 2;
      
      var u = uvsTemp[stride];
      var v = uvsTemp[stride + 1];
      
      uvs.push(u, v);
    }
    
    geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
    geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));
    geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    
    // animation
    
    var morphPositions:Array<Float32BufferAttribute> = [];
    var morphNormals:Array<Float32BufferAttribute> = [];
    
    for (i in 0...frames.length) {
      var frame = frames[i];
      var attributeName = frame.name;
      
      if (frame.vertices.length > 0) {
        var positions:Array<Float> = [];
        
        for (j in 0...vertexIndices.length) {
          var vertexIndex = vertexIndices[j];
          var stride = vertexIndex * 3;
          
          var x = frame.vertices[stride];
          var y = frame.vertices[stride + 1];
          var z = frame.vertices[stride + 2];
          
          positions.push(x, y, z);
        }
        
        var positionAttribute = new Float32BufferAttribute(positions, 3);
        positionAttribute.name = attributeName;
        morphPositions.push(positionAttribute);
      }
      
      if (frame.normals.length > 0) {
        var normals:Array<Float> = [];
        
        for (j in 0...vertexIndices.length) {
          var vertexIndex = vertexIndices[j];
          var stride = vertexIndex * 3;
          
          var nx = frame.normals[stride];
          var ny = frame.normals[stride + 1];
          var nz = frame.normals[stride + 2];
          
          normals.push(nx, ny, nz);
        }
        
        var normalAttribute = new Float32BufferAttribute(normals, 3);
        normalAttribute.name = attributeName;
        morphNormals.push(normalAttribute);
      }
    }
    
    geometry.morphAttributes.position = morphPositions;
    geometry.morphAttributes.normal = morphNormals;
    geometry.morphTargetsRelative = false;
    
    geometry.animations = AnimationClip.CreateClipsFromMorphTargetSequences(frames, 10);
    
    return geometry;
  }
}

var _normalData:Array<Array<Float>> = [
  [ - 0.525731, 0.000000, 0.850651 ], [ - 0.442863, 0.238856, 0.864188 ],
  [ - 0.295242, 0.000000, 0.955423 ], [ - 0.309017, 0.500000, 0.809017 ],
  [ - 0.162460, 0.262866, 0.951056 ], [ 0.000000, 0.000000, 1.000000 ],
  [ 0.000000, 0.850651, 0.525731 ], [ - 0.147621, 0.716567, 0.681718 ],
  [ 0.147621, 0.716567, 0.681718 ], [ 0.000000, 0.525731, 0.850651 ],
  [ 0.309017, 0.500000, 0.809017 ], [ 0.525731, 0.000000, 0.850651 ],
  [ 0.295242, 0.000000, 0.955423 ], [ 0.442863, 0.238856, 0.864188 ],
  [ 0.162460, 0.262866, 0.951056 ], [ - 0.681718, 0.147621, 0.716567 ],
  [ - 0.809017, 0.309017, 0.500000 ], [ - 0.587785, 0.425325, 0.688191 ],
  [ - 0.850651, 0.525731, 0.000000 ], [ - 0.864188, 0.442863, 0.238856 ],
  [ - 0.716567, 0.681718, 0.147621 ], [ - 0.688191, 0.587785, 0.425325 ],
  [ - 0.500000, 0.809017, 0.309017 ], [ - 0.238856, 0.864188, 0.442863 ],
  [ - 0.425325, 0.688191, 0.587785 ], [ - 0.716567, 0.681718, - 0.147621 ],
  [ - 0.500000, 0.809017, - 0.309017 ], [ - 0.525731, 0.850651, 0.000000 ],
  [ 0.000000, 0.850651, - 0.525731 ], [ - 0.238856, 0.864188, - 0.442863 ],
  [ 0.000000, 0.955423, - 0.295242 ], [ - 0.262866, 0.951056, - 0.162460 ],
  [ 0.000000, 1.000000, 0.000000 ], [ 0.000000, 0.955423, 0.295242 ],
  [ - 0.262866, 0.951056, 0.162460 ], [ 0.238856, 0.864188, 0.442863 ],
  [ 0.262866, 0.951056, 0.162460 ], [ 0.500000, 0.809017, 0.309017 ],
  [ 0.238856, 0.864188, - 0.442863 ], [ 0.262866, 0.951056, - 0.162460 ],
  [ 0.500000, 0.809017, - 0.309017 ], [ 0.850651, 0.525731, 0.000000 ],
  [ 0.716567, 0.681718, 0.147621 ], [ 0.716567, 0.681718, - 0.147621 ],
  [ 0.525731, 0.850651, 0.000000 ], [ 0.425325, 0.688191, 0.587785 ],
  [ 0.864188, 0.442863, 0.238856 ], [ 0.688191, 0.587785, 0.425325 ],
  [ 0.809017, 0.309017, 0.500000 ], [ 0.681718, 0.147621, 0.716567 ],
  [ 0.587785, 0.425325, 0.688191 ], [ 0.955423, 0.295242, 0.000000 ],
  [ 1.000000, 0.000000, 0.000000 ], [ 0.951056, 0.162460, 0.262866 ],
  [ 0.850651, - 0.525731, 0.000000 ], [ 0.955423, - 0.295242, 0.000000 ],
  [ 0.864188, - 0.442863, 0.238856 ], [ 0.951056, - 0.162460, 0.262866 ],
  [ 0.809017, - 0.309017, 0.500000 ], [ 0.681718, - 0.147621, 0.716567 ],
  [ 0.850651, 0.000000, 0.525731 ], [ 0.864188, 0.442863, - 0.238856 ],
  [ 0.809017, 0.309017, - 0.500000 ], [ 0.951056, 0.162460, - 0.262866 ],
  [ 0.525731, 0.000000, - 0.850651 ], [ 0.681718, 0.147621, - 0.716567 ],
  [ 0.681718, - 0.147621, - 0.716567 ], [ 0.850651, 0.000000, - 0.525731 ],
  [ 0.809017, - 0.309017, - 0.500000 ], [ 0.864188, - 0.442863, - 0.238856 ],
  [ 0.951056, - 0.162460, - 0.262866 ], [ 0.147621, 0.716567, - 0.681718 ],
  [ 0.309017, 0.500000, - 0.809017 ], [ 0.425325, 0.688191, - 0.587785 ],
  [ 0.442863, 0.238856, - 0.864188 ], [ 0.587785, 0.425325, - 0.688191 ],
  [ 0.688191, 0.587785, - 0.425325 ], [ - 0.147621, 0.716567, - 0.681718 ],
  [ - 0.309017, 0.500000, - 0.809017 ], [ 0.000000, 0.525731, - 0.850651 ],
  [ - 0.525731, 0.000000, - 0.850651 ], [ - 0.442863, 0.238856, - 0.864188 ],
  [ - 0.295242, 0.000000, - 0.955423 ], [ - 0.162460, 0.262866, - 0.951056 ],
  [ 0.000000, 0.000000, - 1.000000 ], [ 0.295242, 0.000000, - 0.955423 ],
  [ 0.162460, 0.262866, - 0.951056 ], [ - 0.442863, - 0.238856, - 0.864188 ],
  [ - 0.309017, - 0.500000, - 0.809017 ], [ - 0.162460, - 0.262866, - 0.951056 ],
  [ 0.000000, - 0.850651, - 0.525731 ], [ - 0.147621, - 0.716567, - 0.681718 ],
  [ 0.147621, - 0.716567, - 0.681718 ], [ 0.000000, - 0.525731, - 0.850651 ],
  [ 0.309017, - 0.500000, - 0.809017 ], [ 0.442863, - 0.238856, - 0.864188 ],
  [ 0.162460, - 0.262866, - 0.951056 ], [ 0.238856, - 0.864188, - 0.442863 ],
  [ 0.500000, - 0.809017, - 0.309017 ], [ 0.425325, - 0.688191, - 0.587785 ],
  [ 0.716567, - 0.681718, - 0.147621 ], [ 0.688191, - 0.587785, - 0.425325 ],
  [ 0.587785, - 0.425325, - 0.688191 ], [ 0.000000, - 0.955423, - 0.295242 ],
  [ 0.000000, - 1.000000, 0.000000 ], [ 0.262866, - 0.951056, - 0.162460 ],
  [ 0.000000, - 0.850651, 0.525731 ], [ 0.000000, - 0.955423, 0.295242 ],
  [ 0.238856, - 0.864188, 0.442863 ], [ 0.262866, - 0.951056, 0.162460 ],
  [ 0.500000, - 0.809017, 0.309017 ], [ 0.716567, - 0.681718, 0.147621 ],
  [ 0.525731, - 0.850651, 0.000000 ], [ - 0.238856, - 0.864188, - 0.442863 ],
  [ - 0.500000, - 0.809017, - 0.309017 ], [ - 0.262866, - 0.951056, - 0.162460 ],
  [ - 0.850651, - 0.525731, 0.000000 ], [ - 0.716567, - 0.681718, - 0.147621 ],
  [ - 0.716567, - 0.681718, 0.147621 ], [ - 0.525731, - 0.850651, 0.000000 ],
  [ - 0.500000, - 0.809017, 0.309017 ], [ - 0.238856, - 0.864188, 0.442863 ],
  [ - 0.262866, - 0.951056, 0.162460 ], [ - 0.864188, - 0.442863, 0.238856 ],
  [ - 0.809017, - 0.309017, 0.500000 ], [ - 0.688191, - 0.587785, 0.425325 ],
  [ - 0.681718, - 0.147621, 0.716567 ], [ - 0.442863, - 0.238856, 0.864188 ],
  [ - 0.587785, - 0.425325, 0.688191 ], [ - 0.309017, - 0.500000, 0.809017 ],
  [ - 0.147621, - 0.716567, 0.681718 ], [ - 0.425325, - 0.688191, 0.587785 ],
  [ - 0.162460, - 0.262866, 0.951056 ], [ 0.442863, - 0.238856, 0.864188 ],
  [ 0.162460, - 0.262866, 0.951056 ], [ 0.309017, - 0.500000, 0.809017 ],
  [ 0.147621, - 0.716567, 0.681718 ], [ 0.000000, - 0.525731, 0.850651 ],
  [ 0.425325, - 0.688191, 0.587785 ], [ 0.587785, - 0.425325, 0.688191 ],
  [ 0.688191, - 0.587785, 0.425325 ], [ - 0.955423, 0.295242, 0.000000 ],
  [ - 0.951056, 0.162460, 0.262866 ], [ - 1.000000, 0.000000, 0.000000 ],
  [ - 0.850651, 0.000000, 0.525731 ], [ - 0.955423, - 0.295242, 0.000000 ],
  [ - 0.951056, - 0.162460, 0.262866 ], [ - 0.864188, 0.442863, - 0.238856 ],
  [ - 0.951056, 0.162460, - 0.262866 ], [ - 0.809017, 0.309017, - 0.500000 ],
  [ - 0.864188, - 0.442863, - 0.238856 ], [ - 0.951056, - 0.162460, - 0.262866 ],
  [ - 0.809017, - 0.309017, - 0.500000 ], [ - 0.681718, 0.147621, - 0.716567 ],
  [ - 0.681718, - 0.147621, - 0.716567 ], [ - 0.850651, 0.000000, - 0.525731 ],
  [ - 0.688191, 0.587785, - 0.425325 ], [ - 0.587785, 0.425325, - 0.688191 ],
  [ - 0.425325, 0.688191, - 0.587785 ], [ - 0.425325, - 0.688191, - 0.587785 ],
  [ - 0.587785, - 0.425325, - 0.688191 ], [ - 0.688191, - 0.587785, - 0.425325 ]
];

export class MD2Loader {
  
  public static function new(manager:Loader = null):MD2Loader {
    return new MD2Loader(manager);
  }
  
  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(buffer:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(buffer));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }
  
  public function parse(buffer:haxe.io.Bytes):BufferGeometry {
    var data = new DataView(buffer.getData());
    
    // http://tfc.duke.free.fr/coding/md2-specs-en.html
    
    var header:Dynamic = {};
    var headerNames = [
      'ident', 'version',
      'skinwidth', 'skinheight',
      'framesize',
      'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
      'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
    ];
    
    for (i in 0...headerNames.length) {
      header[headerNames[i]] = data.getInt32(i * 4, true);
    }
    
    if (header.ident != 844121161 || header.version != 8) {
      console.error('Not a valid MD2 file');
      return null;
    }
    
    if (header.offset_end != data.byte