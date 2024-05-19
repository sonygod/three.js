import constants.WrapAroundEnding;
import constants.ZeroCurvatureEnding;
import constants.ZeroSlopeEnding;
import constants.LoopPingPong;
import constants.LoopOnce;
import constants.LoopRepeat;
import constants.NormalAnimationBlendMode;
import constants.AdditiveAnimationBlendMode;

class AnimationAction {
  
  private var _mixer:Mixer;
  private var _clip:Clip;
  private var _localRoot:Null<Dynamic>;
  private var blendMode:BlendMode;
  
  private var _interpolantSettings:{endingStart:EndingMode, endingEnd:EndingMode};
  private var _interpolants:Array<Interpolant>;
  private var _propertyBindings:Array<PropertyMixer>;
  
  private var _cacheIndex:Int;
  private var _byClipCacheIndex:Int;
  
  private var _timeScaleInterpolant:Null<Interpolant>;
  private var _weightInterpolant:Null<Interpolant>;
  
  public var loop:LoopMode;
  private var _loopCount:Int;
  
  private var _startTime:Null<Float>;
  public var time:Float;
  
  public var timeScale:Float;
  private var _effectiveTimeScale:Float;
  
  public var weight:Float;
  private var _effectiveWeight:Float;
  
  public var repetitions:Int;
  
  public var paused:Bool;
  public var enabled:Bool;
  
  public var clampWhenFinished:Bool;
  public var zeroSlopeAtStart:Bool;
  public var zeroSlopeAtEnd:Bool;
  
  public function new(mixer:Mixer, clip:Clip, ?localRoot:Null<Dynamic> = null, ?blendMode:BlendMode = clip.blendMode) {
    this._mixer = mixer;
    this._clip = clip;
    this._localRoot = localRoot;
    this.blendMode = blendMode;
    
    this._interpolantSettings = {endingStart: ZeroCurvatureEnding, endingEnd: ZeroCurvatureEnding};
    
    var tracks = clip.tracks;
    var nTracks = tracks.length;
    var interpolants = new Array<Interpolant>(nTracks);
    
    for (i in 0...nTracks) {
      var interpolant = tracks[i].createInterpolant(null);
      interpolants[i] = interpolant;
      interpolant.settings = interpolantSettings;
    }
    
    this._interpolants = interpolants;
    this._propertyBindings = new Array<PropertyMixer>(nTracks);
    
    this._cacheIndex = null;
    this._byClipCacheIndex = null;
    this._timeScaleInterpolant = null;
    this._weightInterpolant = null;
    
    this.loop = LoopRepeat;
    this._loopCount = -1;
    
    this._startTime = null;
    this.time = 0;
    
    this.timeScale = 1;
    this._effectiveTimeScale = 1;
    
    this.weight = 1;
    this._effectiveWeight = 1;
    
    this.repetitions = Infinity;
    
    this.paused = false;
    this.enabled = true;
    
    this.clampWhenFinished = false;
    this.zeroSlopeAtStart = true;
    this.zeroSlopeAtEnd = true;
  }
  
  public function play():AnimationAction {
    this._mixer._activateAction(this);
    return this;
  }
  
  public function stop():AnimationAction {
    this._mixer._deactivateAction(this);
    return reset();
  }
  
  public function reset():AnimationAction {
    this.paused = false;
    this.enabled = true;
    
    this.time = 0;
    this._loopCount = -1;
    this._startTime = null;
    
    return stopFading().stopWarping();
  }
  
  public function isRunning():Bool {
    return this.enabled && !this.paused && this.timeScale != 0 && this._startTime == null && this._mixer._isActiveAction(this);
  }
  
  public function isScheduled():Bool {
    return this._mixer._isActiveAction(this);
  }
  
  public function startAt(time:Float):AnimationAction {
    this._startTime = time;
    return this;
  }
  
  public function setLoop(mode:LoopMode, repetitions:Int):AnimationAction {
    this.loop = mode;
    this.repetitions = repetitions;
    return this;
  }
  
  public function setEffectiveWeight(weight:Float):AnimationAction {
    this.weight = weight;
    this._effectiveWeight = this.enabled ? weight : 0;
    return stopFading();
  }
  
  public function getEffectiveWeight():Float {
    return this._effectiveWeight;
  }
  
  // Implement other methods from JavaScript code accordingly
  
  private function _update(time:Float, deltaTime:Float, timeDirection:Float, accuIndex:Int):Void {
    // Implement _update method
  }
  
  private function _updateWeight(time:Float):Float {
    // Implement _updateWeight method
    return 0;
  }
  
  private function _updateTimeScale(time:Float):Float {
    // Implement _updateTimeScale method
    return 0;
  }
  
  private function _updateTime(deltaTime:Float):Float {
    // Implement _updateTime method
    return 0;
  }
  
  private function _setEndings(atStart:Bool, atEnd:Bool, pingPong:Bool):Void {
    // Implement _setEndings method
  }
  
  private function _scheduleFading(duration:Float, weightNow:Float, weightThen:Float):AnimationAction {
    // Implement _scheduleFading method
    return this;
  }
  
}