import three.animation.AnimationMixer;
import three.cameras.Camera;
import three.cameras.PerspectiveCamera;
import three.core.Object3D;
import three.core.Raycaster;
import three.geometries.SphereGeometry;
import three.helpers.CameraHelper;
import three.helpers.DirectionalLightHelper;
import three.helpers.HemisphereLight;
import three.helpers.HemisphereLightHelper;
import three.helpers.PointLightHelper;
import three.helpers.SkeletonHelper;
import three.helpers.SpotLightHelper;
import three.lights.AmbientLight;
import three.lights.DirectionalLight;
import three.lights.HemisphereLight;
import three.lights.PointLight;
import three.lights.SpotLight;
import three.loaders.ObjectLoader;
import three.materials.MeshBasicMaterial;
import three.math.Vector2;
import three.math.Vector3;
import three.objects.Bone;
import three.objects.Mesh;
import three.objects.SkinnedMesh;
import three.scenes.Scene;

import js.Browser;
import js.html.AnchorElement;
import js.html.Blob;
import js.html.MouseEvent;

class Editor {

  public static function main(): Void {
    
  }

  private static var _DEFAULT_CAMERA:PerspectiveCamera = (function() {
    var camera = new PerspectiveCamera(50, 1, 0.01, 1000);
    camera.name = "Camera";
    camera.position.set(0, 5, 10);
    camera.lookAt(new Vector3());
    return camera;
  })();

  public var signals : {
    // script
    var editScript:Signal<Void->Void>;

    // player
    var startPlayer:Signal<Void->Void>;
    var stopPlayer:Signal<Void->Void>;

    // xr
    var enterXR:Signal<Void->Void>;
    var offerXR:Signal<Void->Void>;
    var leaveXR:Signal<Void->Void>;

    // notifications
    var editorCleared:Signal<Void->Void>;

    var savingStarted:Signal<Void->Void>;
    var savingFinished:Signal<Void->Void>;

    var transformModeChanged:Signal<Void->Void>;
    var snapChanged:Signal<Void->Void>;
    var spaceChanged:Signal<Void->Void>;
    var rendererCreated:Signal<Void->Void>;
    var rendererUpdated:Signal<Void->Void>;
    var rendererDetectKTX2Support:Signal<Void->Void>;

    var sceneBackgroundChanged:Signal<Void->Void>;
    var sceneEnvironmentChanged:Signal<Dynamic->Void>;
    var sceneFogChanged:Signal<Void->Void>;
    var sceneFogSettingsChanged:Signal<Void->Void>;
    var sceneGraphChanged:Signal<Void->Void>;
    var sceneRendered:Signal<Void->Void>;

    var cameraChanged:Signal<Void->Void>;
    var cameraResetted:Signal<Void->Void>;

    var geometryChanged:Signal<Void->Void>;

    var objectSelected:Signal<Dynamic->Void>;
    var objectFocused:Signal<Dynamic->Void>;

    var objectAdded:Signal<Object3D->Void>;
    var objectChanged:Signal<Void->Void>;
    var objectRemoved:Signal<Object3D->Void>;

    var cameraAdded:Signal<Camera->Void>;
    var cameraRemoved:Signal<Camera->Void>;

    var helperAdded:Signal<Object3D->Void>;
    var helperRemoved:Signal<Object3D->Void>;

    var materialAdded:Signal<Void->Void>;
    var materialChanged:Signal<Void->Void>;
    var materialRemoved:Signal<Void->Void>;

    var scriptAdded:Signal<Dynamic->Void>;
    var scriptChanged:Signal<Void->Void>;
    var scriptRemoved:Signal<Dynamic->Void>;

    var windowResize:Signal<Void->Void>;

    var showGridChanged:Signal<Void->Void>;
    var showHelpersChanged:Signal<Void->Void>;
    var refreshSidebarObject3D:Signal<Void->Void>;
    var refreshSidebarEnvironment:Signal<Void->Void>;
    var historyChanged:Signal<Void->Void>;

    var viewportCameraChanged:Signal<Void->Void>;
    var viewportShadingChanged:Signal<Void->Void>;

    var intersectionsDetected:Signal<Void->Void>;
  };
  public var config:Config;
  public var history:History;
  public var selector:Selector;
  public var storage:Storage;
  public var strings:Strings;

  public var loader:Loader;

  public var camera:PerspectiveCamera;

  public var scene:Scene;
  public var sceneHelpers:Scene;

  public var object:{
    [key:String]:Dynamic
  };
  public var geometries:{
    [key:String]:Dynamic
  };
  public var materials:{
    [key:String]:Dynamic
  };
  public var textures:{
    [key:String]:Dynamic
  };
  public var scripts:{
    [key:String]:Dynamic
  };

  public var materialsRefCounter:Map<Dynamic, Int>;

  public var mixer:AnimationMixer;

  public var selected:Dynamic;
  public var helpers:{
    [key:String]:Dynamic
  };
  public var raycaster:Raycaster;
  public var mouse:Vector2;

  public var cameras:{
    [key:String]:Dynamic
  };

  public var viewportCamera:Camera;
  public var viewportShading:String;
  
  public function new() {
    // this.signals = {};

    this.config = new Config();
    this.history = new History(this);
    this.selector = new Selector(this);
    this.storage = new Storage();
    this.strings = new Strings(this.config);

    this.loader = new Loader(this);

    this.camera = _DEFAULT_CAMERA.clone();

    this.scene = new Scene();
    this.scene.name = "Scene";

    this.sceneHelpers = new Scene();
    this.sceneHelpers.add(new HemisphereLight(0xffffff, 0x888888, 2));

    this.object = {};
    this.geometries = {};
    this.materials = {};
    this.textures = {};
    this.scripts = {};

    this.materialsRefCounter = new Map();

    this.mixer = new AnimationMixer(this.scene);

    this.selected = null;
    this.helpers = {};
    this.raycaster = new Raycaster();
    this.mouse = new Vector2();

    this.cameras = {};

    this.viewportCamera = this.camera;
    this.viewportShading = "default";

    this.addCamera(this.camera);
  }

  public function setScene(scene:Scene):Void {
    this.scene.uuid = scene.uuid;
    this.scene.name = scene.name;

    this.scene.background = scene.background;
    this.scene.environment = scene.environment;
    this.scene.fog = scene.fog;
    // this.scene.backgroundBlurriness = scene.backgroundBlurriness; // Not supported in Haxe three.js
    // this.scene.backgroundIntensity = scene.backgroundIntensity; // Not supported in Haxe three.js

    this.scene.userData = JSON.parse(JSON.stringify(scene.userData));

    // avoid render per object
    // this.signals.sceneGraphChanged.active = false; // Not supported in Haxe Signals

    for (i in 0...scene.children.length) {
      this.addObject(scene.children[i]);
    }

    // this.signals.sceneGraphChanged.active = true;
    // this.signals.sceneGraphChanged.dispatch();
  }

  public function addObject(object:Object3D, ?parent:Object3D, ?index:Int):Void {
    var scope = this;

    object.traverse(function(child) {
      if (child.geometry != null) {
        scope.addGeometry(cast child.geometry);
      }

      if (child.material != null) {
        scope.addMaterial(cast child.material);
      }

      if (Std.is(child, Camera)) {
        scope.addCamera(cast child);
      }

      // if (Std.is(child, Helper)) {
      //   scope.addHelper(cast child);
      // }
    });

    if (parent == null) {
      this.scene.add(object);
    } else {
      if (index != null) {
        parent.children.insert(index, object);
      } else {
        parent.add(object);
      }
    }

    // this.signals.objectAdded.dispatch(object);
    // this.signals.sceneGraphChanged.dispatch();
  }

  public function moveObject(object:Object3D, ?parent:Object3D, ?before:Object3D):Void {
    if (parent == null) {
      parent = this.scene;
    }

    parent.add(object);

    // sort children array
    if (before != null) {
      var index = parent.children.indexOf(before);
      parent.children.insert(index, object);
      parent.children.pop();
    }

    // this.signals.sceneGraphChanged.dispatch();
  }

  public function nameObject(object:Object3D, name:String):Void {
    object.name = name;
    // this.signals.sceneGraphChanged.dispatch();
  }

  public function removeObject(object:Object3D):Void {
    if (object.parent == null) {
      return; // avoid deleting the camera or scene
    }

    var scope = this;

    object.traverse(function(child) {
      if (Std.is(child, Camera)) {
        scope.removeCamera(cast child);
      }
      // if (Std.is(child, Helper)) {
      //   scope.removeHelper(cast child);
      // }
      if (child.material != null) {
        scope.removeMaterial(cast child.material);
      }
    });

    object.parent.remove(object);

    // this.signals.objectRemoved.dispatch(object);
    // this.signals.sceneGraphChanged.dispatch();
  }

  public function addGeometry(geometry:Dynamic):Void {
    this.geometries[geometry.uuid] = geometry;
  }

  public function setGeometryName(geometry:Dynamic, name:String):Void {
    geometry.name = name;
    // this.signals.sceneGraphChanged.dispatch();
  }

  public function addMaterial(material:Dynamic):Void {
    if (Std.is(material, Array)) {
      for (i in 0...material.length) {
        this.addMaterialToRefCounter(material[i]);
      }
    } else {
      this.addMaterialToRefCounter(material);
    }

    // this.signals.materialAdded.dispatch();
  }

  public function addMaterialToRefCounter(material:Dynamic):Void {
    var materialsRefCounter = this.materialsRefCounter;

    var count:Null<Int> = materialsRefCounter.get(material);

    if (count == null) {
      materialsRefCounter.set(material, 1);
      this.materials[material.uuid] = material;
    } else {
      count++;
      materialsRefCounter.set(material, count);
    }
  }

  public function removeMaterial(material:Dynamic):Void {
    if (Std.is(material, Array)) {
      for (i in 0...material.length) {
        this.removeMaterialFromRefCounter(material[i]);
      }
    } else {
      this.removeMaterialFromRefCounter(material);
    }
    // this.signals.materialRemoved.dispatch();
  }

  public function removeMaterialFromRefCounter(material:Dynamic):Void {
    var materialsRefCounter = this.materialsRefCounter;

    var count:Null<Int> = materialsRefCounter.get(material);
    if (count != null) {
      count--;

      if (count == 0) {
        materialsRefCounter.remove(material);
        this.materials.remove(material.uuid);
      } else {
        materialsRefCounter.set(material, count);
      }
    }
  }

  public function getMaterialById(id:Int):Dynamic {
    var material:Dynamic = null;
    var materials:Array<Dynamic> = Lambda.array(this.materials);

    for (i in 0...materials.length) {
      if (materials[i].id == id) {
        material = materials[i];
        break;
      }
    }
    return material;
  }

  public function setMaterialName(material:Dynamic, name:String):Void {
    material.name = name;
    // this.signals.sceneGraphChanged.dispatch();
  }

  public function addTexture(texture:Dynamic):Void {
    this.textures[texture.uuid] = texture;
  }

  public function addCamera(camera:Camera):Void {
    this.cameras[camera.uuid] = camera;
    // this.signals.cameraAdded.dispatch(camera);
  }

  public function removeCamera(camera:Camera):Void {
    if (this.cameras.exists(camera.uuid)) {
      this.cameras.remove(camera.uuid);
      // this.signals.cameraRemoved.dispatch(camera);
    }
  }

  public function addHelper(object:Object3D, ?helper:Object3D):Void {
    var geometry = new SphereGeometry(2, 4, 2);
    var material = new MeshBasicMaterial({ color: 0xff0000, visible: false });

    if (helper == null) {
      if (Std.is(object, Camera)) {
        helper = new CameraHelper(cast object);
      } else if (Std.is(object, PointLight)) {
        helper = new PointLightHelper(cast object, 1);
      } else if (Std.is(object, DirectionalLight)) {
        helper = new DirectionalLightHelper(cast object, 1);
      } else if (Std.is(object, SpotLight)) {
        helper = new SpotLightHelper(cast object);
      } else if (Std.is(object, HemisphereLight)) {
        helper = new HemisphereLightHelper(cast object, 1);
      } else if (Std.is(object, SkinnedMesh)) {
        helper = new SkeletonHelper(cast(cast object, SkinnedMesh).skeleton.bones[0]);
      } else if (Std.is(object, Bone)
        && object.parent != null
        && !Std.is(object.parent, Bone)) {
        helper = new SkeletonHelper(cast object);
      } else {
        // No helper for this object type
        return;
      }

      var picker = new Mesh(geometry, material);
      picker.name = 'picker';
      // picker.userData.object = object; // Not supported in Haxe three.js
      if (helper != null) {
        helper.add(picker);
        this.sceneHelpers.add(helper);
        this.helpers[object.id] = helper;
        // this.signals.helperAdded.dispatch(helper);
      }
    }
  }

  public function removeHelper(object:Object3D):Void {
    if (this.helpers.exists(object.id)) {
      var helper = this.helpers[object.id];
      helper.parent.remove(helper);
      this.helpers.remove(object.id);
      // this.signals.helperRemoved.dispatch(helper);
    }
  }

  public function addScript(object:Object3D, script:Dynamic):Void {
    if (this.scripts.exists(object.uuid)) {
      this.scripts[object.uuid] = [];
    }

    this.scripts[object.uuid].push(script);

    // this.signals.scriptAdded.dispatch(script);
  }

  public function removeScript(object:Object3D, script:Dynamic):Void {
    if (!this.scripts.exists(object.uuid)) {
      return;
    }

    var index = this.scripts[object.uuid].indexOf(script);
    if (index != -1) {
      this.scripts[object.uuid].splice(index, 1);
    }

    // this.signals.scriptRemoved.dispatch(script);
  }

  public function getObjectMaterial(object:Object3D, ?slot:Int):Dynamic {
    var material = object.material;
    if (Std.is(material, Array) && slot != null) {
      material = material[slot];
    }
    return material;
  }

  public function setObjectMaterial(object:Object3D, ?slot:Int, newMaterial:Dynamic):Void {
    if (Std.is(object.material, Array) && slot != null) {
      cast(object.material, Array<Dynamic>)[slot] = newMaterial;
    } else {
      object.material = newMaterial;
    }
  }

  public function setViewportCamera(uuid:String):Void {
    this.viewportCamera = this.cameras[uuid];
    // this.signals.viewportCameraChanged.dispatch();
  }

  public function setViewportShading(value:String):Void {
    this.viewportShading = value;
    // this.signals.viewportShadingChanged.dispatch();
  }

  public function select(object:Object3D):Void {
    this.selector.select(object);
  }

  public function selectById(id:Int):Void {
    if (id == this.camera.id) {
      this.select(this.camera);
      return;
    }
    this.select(this.scene.getObjectById(id));
  }

  public function selectByUuid(uuid:String):Void {
    var scope = this;
    this.scene.traverse(function(child) {
      if (child.uuid == uuid) {
        scope.select(child);
      }
    });
  }

  public function deselect():Void {
    this.selector.deselect();
  }

  public function focus(?object:Object3D):Void {
    if (object != null) {
      // this.signals.objectFocused.dispatch(object);
    }
  }

  public function focusById(id:Int):Void {
    this.focus(this.scene.getObjectById(id));
  }

  public function clear():Void {
    this.history.clear();
    this.storage.clear();

    this.camera.copy(_DEFAULT_CAMERA);
    // this.signals.cameraResetted.dispatch();

    this.scene.name = "Scene";
    this.scene.userData = {};
    this.scene.background = null;
    this.scene.environment = null;
    this.scene.fog = null;

    var objects = this.scene.children;
    // this.signals.sceneGraphChanged.active = false; // Not supported in Haxe Signals

    while (objects.length > 0) {
      this.removeObject(objects[0]);
    }
    // this.signals.sceneGraphChanged.active = true;

    this.geometries = {};
    this.materials = {};
    this.textures = {};
    this.scripts = {};

    this.materialsRefCounter = new Map();

    // this.animations = {};
    this.mixer.stopAllAction();

    this.deselect();
    // this.signals.editorCleared.dispatch();
  }

  public async function fromJSON(json:Dynamic):Promise<Void> {
    var loader = new ObjectLoader();
    var camera = await loader.parseAsync(json.camera);
    // var camera = loader.parse(json.camera);

    var existingUuid = this.camera.uuid;
    var incomingUuid = camera.uuid;

    this.camera.copy(camera);
    this.camera.uuid = incomingUuid;

    this.cameras.remove(existingUuid);
    this.cameras[incomingUuid] = this.camera;

    // this.signals.cameraResetted.dispatch();

    this.history.fromJSON(json.history);
    this.scripts = json.scripts;

    this.setScene(await loader.parseAsync(json.scene));

    if (json.environment == "ModelViewer") {
      // this.signals.sceneEnvironmentChanged.dispatch(json.environment);
      // this.signals.refreshSidebarEnvironment.dispatch();
    }
  }

  public function toJSON():Dynamic {
    // Scene cleanup
    var scene = this.scene;
    var scripts = this.scripts;

    for (key => script in scripts) {
      if (script.length == 0 || scene.getObjectByProperty("uuid", key) == null) {
        scripts.remove(key);
      }
    }

    var environment:Dynamic = null;
    if (this.scene.environment != null && Reflect.getProperty(this.scene.environment, "isRenderTargetTexture")) {
      environment = "ModelViewer";
    }

    return {
      metadata: {},
      project: {
        shadows: this.config.getKey("project/renderer/shadows"),
        shadowType: this.config.getKey("project/renderer/shadowType"),
        toneMapping: this.config.getKey("project/renderer/toneMapping"),
        toneMappingExposure: this.config.getKey("project/renderer/toneMappingExposure"),
      },
      camera: this.viewportCamera.toJSON(),
      scene: this.scene.toJSON(),
      scripts: this.scripts,
      history: this.history.toJSON(),
      environment: environment,
    };
  }

  public function objectByUuid(uuid:String):Dynamic {
    return this.scene.getObjectByProperty("uuid", uuid, true);
  }

  public function execute(cmd:Dynamic, ?optionalName:String):Void {
    this.history.execute(cmd, optionalName);
  }

  public function undo():Void {
    this.history.undo();
  }

  public function redo():Void {
    this.history.redo();
  }
}

class Utils {
  public static var link:AnchorElement = Browser.document.createElement("a");

  public static function save(blob:Blob, ?filename:String):Void {
    if (link.href != null) {
      URL.revokeObjectURL(link.href);
    }
    link.href = URL.createObjectURL(blob);
    link.download = (filename != null) ? filename : "data.json";
    link.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }));
  }

  public static function saveArrayBuffer(buffer:ArrayBuffer, filename:String):Void {
    save(new Blob([buffer], { type: "application/octet-stream" }), filename);
  }

  public static function saveString(text:String, filename:String):Void {
    save(new Blob([text], { type: "text/plain" }), filename);
  }
}