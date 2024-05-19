import haxe.ds.StringMap;
import haxe.ds.StringSet;
import js.html.FileLoader;
import js.html.URL;
import js.html.URLSearchParams;
import js.typedarrays.Float32Array;
import js.typedarrays.Uint8Array;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.Face3;
import three.core.Face4;
import three.core.Loader;
import three.core.LoaderUtils;
import three.core.Material;
import three.core.Mesh;
import three.core.Object3D;
import three.core.Quaternion;
import three.core.Scene;
import three.core.Vector2;
import three.core.Vector3;
import three.extras.curve.SplineCurve3;
import three.materials.LineBasicMaterial;
import three.materials.LineDashMaterial;
import three.materials.MeshBasicMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.PointsMaterial;
import three.objects.BufferGeometryUtils;
import three.objects.Lines;
import three.objects.LineSegments;
import three.objects.Points;

class VRMLLoader extends Loader {

 public function new(manager:Loader) {
 super(manager);
 }

 override public function load(url:String, onLoad:Void -> Void, onProgress:Float -> Void, onError:Dynamic -> Void):Void {
 const scope = this;
 const path = (scope.path == "") ? LoaderUtils.extractUrlBase(url) : scope.path;
 const loader = new FileLoader(scope.manager);
 loader.setPath(scope.path);
 loader.setRequestHeader(scope.requestHeader);
 loader.setWithCredentials(scope.withCredentials);
 loader.load(url, function(text) {
 try {
 onLoad(scope.parse(text, path));
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

 public function parse(data:String, path:String):Object3D {
 // Implement the parsing logic here
 }

}