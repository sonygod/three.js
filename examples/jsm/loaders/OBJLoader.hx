import three.math.Vector3;
import three.math.Color;
import three.core.BufferGeometry;
import three.core.FileLoader;
import three.core.Float32BufferAttribute;
import three.objects.Group;
import three.materials.LineBasicMaterial;
import three.objects.LineSegments;
import three.core.Loader;
import three.materials.Material;
import three.objects.Mesh;
import three.materials.MeshPhongMaterial;
import three.objects.Points;
import three.materials.PointsMaterial;

class OBJLoader extends Loader {

 public var materials:Dynamic;

 public function new(manager:LoaderManager) {
 super(manager);
 this.materials = null;
 }

 override public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
 var scope = this;
 var loader = new FileLoader(this.manager);
 loader.setPath(this.path);
 loader.setRequestHeader(this.requestHeader);
 loader.setWithCredentials(this.withCredentials);
 loader.load(url, function (text:String) {
 try {
 onLoad(scope.parse(text));
 } catch (e:Dynamic) {
 if (onError != null) {
 onError(e);
 } else {
 trace(e);
 }
 scope.manager.itemError(url);
 }
 }
 , onProgress, onError);
 }

 public function setMaterials(materials:Dynamic):OBJLoader {
 this.materials = materials;
 return this;
 }

 public function parse(text:String):Group {
 var state = new ParserState();

 if (text.indexOf('\r\n') != -1) {
 // This is faster than String.split with regex that splits on both
 text = text.replace(_global.RegExp('\\r\\n', 'g'), '\n');
 }

 if (text.indexOf('\\\n') != -1) {
 // join lines separated by a line continuation character (\)
 text = text.replace(_global.RegExp('\\\\\n', 'g'), '');
 }

 var lines = text.split('\n');
 var result:Array<Dynamic>;

 for (var i in 0...lines.length) {
 var line = lines[i].trimStart();

 if (line.length == 0) continue;

 var lineFirstChar = line.charAt(0);

 // @todo invoke passed in handler if any
 if (lineFirstChar == '#') continue; // skip comments

 if (lineFirstChar == 'v') {
 switch (line.charAt(1)) {
 case 'v':
 state.vertices.push(
 parseFloat(line.split(_global.RegExp('\\s+'), 4)[1]),
 parseFloat(line.split(_global.RegExp('\\s+'), 4)[2]),
 parseFloat(line.split(_global.RegExp('\\s+'), 4)[3])
 );
 if (line.split(_global.RegExp('\\s+')).length >= 7) {
 var _color = new Color();
 _color.setRGB(
 parseFloat(line.split(_global.RegExp('\\s+'), 8)[4]),
 parseFloat(line.split(_global.RegExp('\\s+'), 8)[5]),
 parseFloat(line.split(_global.RegExp('\\s+'), 8)[6])
 ).convertSRGBToLinear();
 state.colors.push(_color.r, _color.g, _color.b);
 } else {
 // if no colors are defined, add placeholders so color and vertex indices match
 state.colors.push(undefined, undefined, undefined);
 }
 break;
 case 'vn':
 state.normals.push(
 parseFloat(line.split(_global.RegExp('\\s+'), 4)[1]),
 parseFloat(line.split(_global.RegExp('\\s+'), 4)[2]),
 parseFloat(line.split(_global.RegExp('\\s+'), 4)[3])
 );
 break;
 case 'vt':
 state.uvs.push(
 parseFloat(line.split(_global.RegExp('\\s+'), 3)[1]),
 parseFloat(line.split(_global.RegExp('\\s+'), 3)[2])
 );
 break;
 }

 } else if (lineFirstChar == 'f') {
 var lineData = line.slice(1).trim();
 var vertexData = lineData.split(_global.RegExp('\\s+'));
 var faceVertices = [];

 // Parse the face vertex data into an easy to work with format

 for (var j in 0...vertexData.length) {
 var vertex = vertexData[j];

 if (vertex.length > 0) {
 var vertexParts = vertex.split('/');
 faceVertices.push(vertexParts);
 }

 }

 // Draw an edge between the first vertex and all subsequent vertices to form an n-gon

 var v1 = faceVertices[0];

 for (var j in 1...faceVertices.length-1) {
 var v2 = faceVertices[j];
 var v3 = faceVertices[parseInt(j)+1];

 state.addFace(
 parseInt(v1[0])-1, parseInt(v2[0])-1, parseInt(v3[0])-1,
 parseInt(v1[1])-1, parseInt(v2[1])-1, parseInt(v3[1])-1,
 parseInt(v1[2])-1, parseInt(v2[2])-1, parseInt(v3[2])-1
 );

 }

 } else if (lineFirstChar == 'l') {
 var lineParts = line.substring(1).trim().split(' ');
 var lineVertices = [];
 var lineUVs = [];

 if (line.indexOf('/') == -1) {
 lineVertices = lineParts;

 } else {

 for (var li in 0...lineParts.length) {
 var parts = lineParts[li].split('/');

 if (parts[0] != '') lineVertices.push(parseInt(parts[0])-1);
 if (parts[1] != '') lineUVs.push(parseInt(parts[1])-1);

 }

 }

 state.addLineGeometry(lineVertices, lineUVs);

 } else if (lineFirstChar == 'p') {

 var lineData = line.slice(1).trim();
 var pointData = lineData.split(' ');

 state.addPointGeometry(pointData);

 } else if ((result = _global.RegExp('^[og]\\s*(.+)?').exec(line)) != null) {
 // o object_name
 // or
 // g group_name

 // WORKAROUND: https://bugs.chromium.org/p/v8/issues/detail?id=2869
 // let name = result[ 0 ].slice( 1 ).trim();
 var name = ( ' ' + result[ 0 ].slice(1).trim() ).slice(1);

 state.startObject(name);

 } else if (_global.RegExp('^usemtl\\s*(.+)').test(line)) {

 // material

 state.object.startMaterial(line.substring(7).trim(), state.materialLibraries);

 } else if (_global.RegExp('^mtllib\\s*(.+)').test(line)) {

 // mtl file

 state.materialLibraries.push(line.substring(7).trim());

 } else if (_global.RegExp('^usemap\\s*(.+)').test(line)) {

 // the line is parsed but ignored since the loader assumes textures are defined MTL files
 // (according to https://www.okino.com/conv/imp_wave.htm, 'usemap' is the old-style Wavefront texture reference method)

 trace('THREE.OBJLoader: Rendering identifier "usemap" not supported. Textures must be defined in MTL files.');

 } else if (lineFirstChar == 's') {

 result = line.split(' ');

 // smooth shading

 // @todo Handle files that have varying smooth values for a set of faces inside one geometry,
 // but does not define a usemtl for each face set.
 // This should be detected and a dummy material created (later MultiMaterial and geometry groups).
 // This requires some care to not create extra material on each smooth value for "normal" obj files.
 // where explicit usemtl defines geometry groups.
 // Example asset: examples/models/obj/cerberus/Cerberus.obj
 if (result.length > 1) {
 var value = result[1].trim().toLowerCase();
 state.object.smooth = (value != '0' && value != 'off');
 } else {
 // ZBrush can produce "s" lines #11707
 state.object.smooth = true;
 }

 var material = state.object.currentMaterial();
 if (material != null) material.smooth = state.object.smooth;

 } else {

 // Handle null terminated files without exception
 if (line == '\0') continue;

 trace('THREE.OBJLoader: Unexpected line: "' + line + '"');

 }

 }

 state.finalize();

 var container = new Group();
 container.materialLibraries = [].concat(state.materialLibraries);

 var hasPrimitives = !(state.objects.length == 1 && state.objects[0].geometry.vertices.length == 0);

 if (hasPrimitives == true) {

 for (var i in 0...state.objects.length) {
 var object = state.objects[i];
 var geometry = object.geometry;
 var materials = object.materials;
 var isLine = (geometry.type == 'Line');
 var isPoints = (geometry.type == 'Points');
 var hasVertexColors = false;

 // Skip o/g line declarations that did not follow with any faces
 if (geometry.vertices.length == 0) continue;

 var buffergeometry = new BufferGeometry();

 buffergeometry.setAttribute('position', new Float32BufferAttribute(geometry.vertices, 3));

 if (geometry.normals.length > 0) {

 buffergeometry.setAttribute('normal', new Float32BufferAttribute(geometry.normals, 3));

 }

 if (geometry.colors.length > 0) {

 hasVertexColors = true;
 buffergeometry.setAttribute('color', new Float32BufferAttribute(geometry.colors, 3));

 }

 if (geometry.hasUVIndices == true) {

 buffergeometry.setAttribute('uv', new Float32BufferAttribute(geometry.uvs, 2));

 }

 // Create materials

 var createdMaterials:Array<Dynamic> = [];

 for (var mi in 0...materials.length) {
 var sourceMaterial = materials[mi];
 var materialHash = sourceMaterial.name + '_' + sourceMaterial.smooth + '_' + hasVertexColors;
 var material:Dynamic;

 if (this.materials != null) {

 material = this.materials.create(sourceMaterial.name);

 // mtl etc. loaders probably can't create line materials correctly, copy properties to a line material.
 if (isLine && material != null && !(material instanceof LineBasicMaterial)) {
 var materialLine = new LineBasicMaterial();
 Material.prototype.copy.call(materialLine, material);
 materialLine.color.copy(material.color);
 material = materialLine;
 } else if (isPoints && material != null && !(material instanceof PointsMaterial)) {
 var materialPoints = new PointsMaterial({size:10, sizeAttenuation:false});
 Material.prototype.copy.call(materialPoints, material);
 materialPoints.color.copy(material.color);
 materialPoints.map = material.map;
 material = materialPoints;
 }

 }

 if (material == undefined) {

 if (isLine) {

 material = new LineBasicMaterial();

 } else if (isPoints) {

 material = new PointsMaterial({size:1, sizeAttenuation:false});

 } else {

 material = new MeshPhongMaterial();

 }

 material.name = sourceMaterial.name;
 material.flatShading = sourceMaterial.smooth ? false : true;
 material.vertexColors = hasVertexColors;

 state.materials[materialHash] = material;

 }

 createdMaterials.push(material);

 }

 // Create mesh

 var mesh:Dynamic;

 if (createdMaterials.length > 1) {

 for (var mi in 0...materials.length) {
 sourceMaterial = materials[mi];
 buffergeometry.addGroup(sourceMaterial.groupStart, sourceMaterial.groupCount, mi);
 }

 if (isLine) {

 mesh = new LineSegments(buffergeometry, createdMaterials);

 } else if (isPoints) {

 mesh = new Points(buffergeometry, createdMaterials);

 } else {

 mesh = new Mesh(buffergeometry, createdMaterials);

 }

 } else {

 if (isLine) {

 mesh = new LineSegments(buffergeometry, createdMaterials[0]);

 } else if (isPoints) {

 mesh = new Points(buffergeometry, createdMaterials[0]);

 } else {

 mesh = new Mesh(buffergeometry, createdMaterials[0]);

 }

 }

 mesh.name = object.name;

 container.add(mesh);

 }

 }

 } else {

 // if there is only the default parser state object with no geometry data, interpret data as point cloud

 if (state.vertices.length > 0) {

 var material = new PointsMaterial({size:1, sizeAttenuation:false});

 var buffergeometry = new BufferGeometry();

 buffergeometry.setAttribute('position', new Float32BufferAttribute(state.vertices, 3));

 if (state.colors.length > 0 && state.colors[0] != undefined) {

 buffergeometry.setAttribute('color', new Float32BufferAttribute(state.colors, 3));
 material.vertexColors = true;

 }

 var points = new Points(buffergeometry, material);
 container.add(points);

 }

 }

 return container;

 }

}