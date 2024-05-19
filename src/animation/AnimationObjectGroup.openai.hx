import PropertyBinding from './PropertyBinding';
import MathUtils from '../math/MathUtils';

class AnimationObjectGroup {
  
  public var isAnimationObjectGroup:Bool;
  public var uuid:String;
  public var _objects:Array<Dynamic>;
  public var nCachedObjects_:Int;
  public var _indicesByUUID:Map<String, Int>;
  public var _paths:Array<String>;
  public var _parsedPaths:Array<Dynamic>;
  public var _bindings:Array<Array<PropertyBinding>>;
  public var _bindingsIndicesByPath:Map<String, Int>;
  public var stats:Dynamic;
  
  public function new() {
    this.isAnimationObjectGroup = true;
    this.uuid = MathUtils.generateUUID();
    this._objects = [];
    this.nCachedObjects_ = 0;
    this._indicesByUUID = new Map<String, Int>();
    this._paths = [];
    this._parsedPaths = [];
    this._bindings = [];
    this._bindingsIndicesByPath = new Map<String, Int>();
    this.stats = {
      objects: {
        total: function() return this._objects.length,
        inUse: function() return this.stats.objects.total() - this.nCachedObjects_
      },
      bindingsPerObject: function() return this._bindings.length
    };
  }
  
  public function add(objects:Array<Dynamic>) {
    // implementation of add function
  }
  
  public function remove(objects:Array<Dynamic>) {
    // implementation of remove function
  }
  
  public function uncache(objects:Array<Dynamic>) {
    // implementation of uncache function
  }
  
  private function subscribe_(path:String, parsedPath:Dynamic):Array<PropertyBinding> {
    // implementation of subscribe_ function
  }
  
  private function unsubscribe_(path:String) {
    // implementation of unsubscribe_ function
  }
  
}