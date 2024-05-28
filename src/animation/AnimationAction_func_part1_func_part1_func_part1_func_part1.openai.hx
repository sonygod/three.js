import WrapAroundEnding, ZeroCurvatureEnding, ZeroSlopeEnding, LoopPingPong, LoopOnce, LoopRepeat, NormalAnimationBlendMode, AdditiveAnimationBlendMode from "./constants";

class AnimationAction {
  public var _mixer:Dynamic; // replace Dynamic with a specific class if known
  public var _clip:Dynamic; // replace Dynamic with a specific class if known
  public var _localRoot:Dynamic; // replace Dynamic with a specific class if known
  public var blendMode:Int = 0;
  public var _interpolantSettings:Dynamic; // replace Dynamic with a specific class if known
  public var _interpolants:Array<Dynamic>; // replace Dynamic with a specific class if known
  public var _propertyBindings:Array<Dynamic>; // replace Dynamic with a specific class if known
  public var _cacheIndex:Int = 0;
  public var _byClipCacheIndex:Dynamic; // replace Dynamic with a specific class if known
  public var _timeScaleInterpolant:Dynamic; // replace Dynamic with a specific class if known
  public var _weightInterpolant:Dynamic; // replace Dynamic with a specific class if known
  public var loop:Int = 0;
  public var _loopCount:Int = -1;
  public var _startTime:Float = 0.0;
  public var time:Float = 0.0;
  public var timeScale:Float = 1.0;
  public var _effectiveTimeScale:Float = 1.0;
  public var weight:Float = 1.0;
  public var _effectiveWeight:Float = 1.0;
  public var repetitions:Int = Int.MAX_VALUE; // no. of repetitions when looping
  public var paused:Bool = false;
  public var enabled:Bool = true;
  public var clampWhenFinished:Bool = false;
  public var zeroSlopeAtStart:Bool = true;
  public var zeroSlopeAtEnd:Bool = true;

  constructor(mixer:Dynamic, clip:Dynamic, localRoot:Dynamic = null, blendMode:Int = clip.blendMode) {
    this._mixer = mixer;
    this._clip = clip;
    this._localRoot = localRoot;
    this.blendMode = blendMode;
    var tracks = clip.tracks;
    var nTracks = tracks.length;
    var interpolants = [];
    for (i in 0...nTracks) {
      var interpolant = tracks[i].createInterpolant(null);
      interpolants.push(interpolant);
      interpolant.settings = interpolantSettings;
    }
    this._interpolantSettings = interpolantSettings;
    this._interpolants = interpolants; // bound by the mixer
    this._propertyBindings = [];
    this._cacheIndex = null;
    this._byClipCacheIndex = null;
    this._timeScaleInterpolant = null;
    this._weightInterpolant = null;
  }

  // implement the rest of the methods from the original JavaScript code

}