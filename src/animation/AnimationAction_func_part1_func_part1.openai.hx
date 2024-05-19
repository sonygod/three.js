import AnimationBlendMode from "../constants/AnimationBlendMode";
import {
    ZeroCurvatureEnding,
    ZeroSlopeEnding,
    LoopPingPong,
    LoopOnce,
    LoopRepeat,
} from "../constants/EndingMode";
import { Interpolant } from "../Interpolant";
import { Mixer } from "../Mixer";
import { Clip } from "../Clip";

class AnimationAction {
    
    public var mixer:Mixer;
    public var clip:Clip;
    public var localRoot:Null<Dynamic>;
    public var blendMode:AnimationBlendMode;
    
    public var interpolants:Array<Interpolant>;
    public var interpolantSettings:Dynamic;
    
    public var propertyBindings:Array<Dynamic>;
    
    public var cacheIndex:Null<Int>;
    public var byClipCacheIndex:Null<Int>;
    
    public var timeScaleInterpolant:Null<Interpolant>;
    public var weightInterpolant:Null<Interpolant>;
    
    public var loop:EndingMode;
    public var loopCount:Int;
    
    public var startTime:Null<Float>;
    
    public var time:Float;
    
    public var timeScale:Float;
    public var effectiveTimeScale:Float;
    
    public var weight:Float;
    public var effectiveWeight:Float;
    
    public var repetitions:Int;
    
    public var paused:Bool;
    public var enabled:Bool;
    
    public var clampWhenFinished:Bool;
    
    public var zeroSlopeAtStart:Bool;
    public var zeroSlopeAtEnd:Bool;
    
    public function new(mixer:Mixer, clip:Clip, localRoot:Null<Dynamic> = null, blendMode:AnimationBlendMode = clip.blendMode) {
        this.mixer = mixer;
        this.clip = clip;
        this.localRoot = localRoot;
        this.blendMode = blendMode;
        
        this.interpolants = new Array<Interpolant>(clip.tracks.length);
        
        this.interpolantSettings = {
            endingStart: ZeroCurvatureEnding,
            endingEnd: ZeroCurvatureEnding
        };
        
        for (i in 0...clip.tracks.length) {
            var interpolant = clip.tracks[i].createInterpolant(null);
            interpolants[i] = interpolant;
            interpolant.settings = interpolantSettings;
        }
        
        this.propertyBindings = new Array<Dynamic>(clip.tracks.length);
        
        this.cacheIndex = null;
        this.byClipCacheIndex = null;
        
        this.timeScaleInterpolant = null;
        this.weightInterpolant = null;
        
        this.loop = LoopRepeat;
        this.loopCount = -1;
        
        this.startTime = null;
        
        this.time = 0;
        
        this.timeScale = 1;
        this.effectiveTimeScale = 1;
        
        this.weight = 1;
        this.effectiveWeight = 1;
        
        this.repetitions = Int32.max;
        
        this.paused = false;
        this.enabled = true;
        
        this.clampWhenFinished = false;
        
        this.zeroSlopeAtStart = true;
        this.zeroSlopeAtEnd = true;
    }
    
    public function play():AnimationAction {
        this.mixer._activateAction(this);
        return this;
    }
    
    public function stop():AnimationAction {
        this.mixer._deactivateAction(this);
        return this.reset();
    }
    
    public function reset():AnimationAction {
        this.paused = false;
        this.enabled = true;
        
        this.time = 0;
        this.loopCount = -1;
        this.startTime = null;
        
        return this.stopFading().stopWarping();
    }
    
    // Implement other functions as needed
}