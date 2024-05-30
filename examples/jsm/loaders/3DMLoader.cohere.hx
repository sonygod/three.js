import haxe.io.Bytes;
import js.Browser;
import js.html.ArrayBuffer;
import js.html.Blob;
import js.html.CanvasElement;
import js.html.Document;
import js.html.HTMLElement;
import js.html.HTMLImageElement;
import js.html.ImageData;
import js.html.ImageElement;
import js.html.Window;
import js.lib.File;
import js.node.Buffer;
import js.node.Fs;
import js.node.URL;
import js.node.process;

import haxe.Resource;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.io.Path;
import haxe.io.PathTools;
import haxe.io.StringInput;
import haxe.rtti.Meta;
import haxe.rtti.System;
import haxe.unit.TestCase;
import haxe.xml.Parser;

import js.html.CanvasRenderingContext2D;
import js.html.CanvasRenderingContext2D.CompositeOperation;
import js.html.CanvasRenderingContext2D.LineCap;
import js.html.CanvasRenderingContext2D.LineJoin;
import js.html.CanvasRenderingContext2D.TextAlign;
import js.html.CanvasRenderingContext2D.TextBaseline;
import js.html.CanvasRenderingContext2D.FillRule;
import js.html.CanvasRenderingContext2D.ImageData as CanvasImageData;

import js.html.CanvasGradient;
import js.html.CanvasPattern;
import js.html.ImageData;

import js.html.Location;

import js.html.performance;

import js.html.Event;
import js.html.EventTarget;
import js.html.WindowEventHandlers;

import js.html.Storage;
import js.html.LocalStorage;
import js.html.SessionStorage;

import js.html.XMLHttpRequest;
import js.html.XMLHttpRequestUpload;

import js.html.DataTransfer;
import js.html.DataTransferItem;

import js.html.DeviceMotionEvent;
import js.html.DeviceOrientationEvent;

import js.html.PopStateEvent;

import js.html.HashChangeEvent;

import js.html.ErrorEvent;

import js.html.FileList;

import js.html.Blob;
import js.html.File;

import js.html.TimeRanges;

import js.html.AudioContext;
import js.html.AudioNode;
import js.html.AudioParam;
import js.html.AudioBuffer;
import js.html.AudioBufferSourceNode;
import js.html.AudioProcessingEvent;
import js.html.BaseAudioContext;
import js.html.MediaElementAudioSourceNode;
import js.html.MediaStreamAudioSourceNode;
import js.html.MediaStreamTrackAudioSourceNode;
import js.html.OscillatorNode;
import js.html.AnalyserNode;
import js.html.GainNode;
import js.html.BiquadFilterNode;
import js.html.IIRFilterNode;
import js.html.DelayNode;
import js.html.StereoPannerNode;
import js.html.PannerNode;
import js.html.ConvolverNode;
import js.html.DynamicsCompressorNode;
import js.html.WaveShaperNode;
import js.html.MediaStreamAudioDestinationNode;
import js.html.MediaStreamAudioSourceNode;
import js.html.MediaStreamAudioDestinationNode;

import js.html.AudioListener;

import js.html.AudioContextOptions;

import js.html.AudioBufferOptions;

import js.html.AnalyserOptions;

import js.html.BaseAudioContextOptions;

import js.html.OscillatorOptions;

import js.html.ChannelMergerOptions;
import js.html.ChannelSplitterOptions;

import jsCoefficientArrays.AudioChannel;

import js.html.BiquadFilterOptions;

import js.html.ConvolverOptions;

import js.html.DelayOptions;

import js.html.DynamicsCompressorOptions;

import js.html.GainOptions;

import js.html.IIRFilterOptions;

import js.html.MediaElementAudioSourceOptions;

import js.html.MediaStreamAudioDestinationOptions;

import js.html.MediaStreamAudioSourceOptions;

import js.html.PannerOptions;

import js.html.ScriptProcessorOptions;

import js.html.StereoPannerOptions;

import js.html.WaveShaperOptions;

import js.html.AudioBufferSourceOptions;

import js.html.AudioProcessingEventInit;

import js.html.OfflineAudioContext;
import js.html.OfflineAudioContextOptions;

import js.html.AudioNodeRenderer;

import js.html.AudioParamDescriptor;

import js.html.AudioParamMap;

import js.html.AudioParamOptions;

import js.html.AudioProcessingEventHandler;

import js.html.AudioListenerOptions;

import js.html.AudioContextLatencyCategory;

import js.html.MediaElementAudioSourceNode;

import js.html.MediaStreamAudioSourceNode;

import js.html.MediaStreamTrackAudioSourceNode;

import js.html.OscillatorNode;

import js.html.AnalyserNode;


import js.html.GainNode;

import js.html.BiquadFilterNode;

import js.html.DelayNode;

import js.html.IIRFilterNode;

import js.html.StereoPannerNode;

import js.html.PannerNode;

import js.html.ConvolverNode;

import js.html.DynamicsCompressorNode;

import js.html.WaveShaperNode;

import js.html.MediaStreamAudioDestinationNode;

import js.html.MediaStreamAudioSourceNode;

import js.html.MediaStreamAudioDestinationNode;

import js.html.AudioListener;

import js.html.AudioNode;

import js.html.AudioParam;
import js.html.AudioBuffer;
import js.html.AudioBufferSourceNode;
import js.html.BaseAudioContext;
import js.html.MediaElementAudioSourceNode;
import js.html.MediaStreamAudioSourceNode;
import js.html.MediaStreamTrackAudioSourceNode;
import js.html.OscillatorNode;
import js.html.AnalyserNode;
import js.html.GainNode;
import js.html.BiquadFilterNode;
import js.html.DelayNode;
import js.html.IIRFilterNode;
import js.html.StereoPannerNode;
import js.html.PannerNode;
import js.html.ConvolverNode;
import js.html.DynamicsCompressorNode;
import js.html.WaveShaperNode;
import js.html.MediaStreamAudioDestinationNode;
import js.html.MediaStreamAudioSourceNode;
import js.html.MediaStreamAudioDestinationNode;

import js.html.AudioListener;

import js.html.AudioContext;
import js.html.AudioNode;
import js.html.AudioParam;
import js.html.AudioBuffer;
import js.html.AudioBufferSourceNode;
import js.html.BaseAudioContext;
import js.html.MediaElementAudioSourceNode;
import js.html.MediaStreamAudioSourceNode;
import js.html.MediaStreamTrackAudioSourceNode;
import js.html.OscillatorNode;
import js.html.AnalyserNode;
import js.html.GainNode;
import js.html.BiquadFilterNode;
import js.html.DelayNode;
import js.html.IIRFilterNode;
import js.html.StereoPannerNode;
import js.html.PannerNode;
import js.html.ConvolverNode;
import js.html.DynamicsCompressorNode;
import js.html.WaveShaperNode;
import js.html.MediaStreamAudioDestinationNode;
import js.html.MediaStreamAudioSourceNode;
import js.html.MediaStreamAudioDestinationNode;

import js.html.AudioListener;

import js.html.AudioContext;
import js.html.AudioNode;
import js.html.AudioParam;
import js.html.AudioBuffer;
import js.html.AudioBufferSourceNode;
import js.html.BaseAudioContext;
import js.html.MediaElementAudioSourceNode;
import js.html.MediaStreamAudioSourceNode;
import js.html.MediaStreamTrackAudioSourceNode;
import js.html.OscillatorNode;
import js.html.AnalyserNode;
import js.html.GainNode;
import js.html.BiquadFilterNode;
import js.html.DelayNode;
import js.html.IIRFilterNode;
import js.html.StereoPannerNode;
import js.html.PannerNode;
import js.html.ConvolverNode;
import js.html.DynamicsCompressorNode;
import js.html.WaveShaperNode;
import js.html.MediaStreamAudioDestinationNode;
import js.html.MediaStreamAudioSourceNode;
import js.html.MediaStreamAudioDestinationNode;

import js.html.AudioListener;

import js.html.AudioContext;
import js.html.AudioNode;
import js.html.AudioParam;
import js.html.AudioBuffer;
import js.html.AudioBufferSourceNode;
import js.html.BaseAudioContext;
import js.html.MediaElementAudioSourceNode;
import js.html.MediaStreamAudioSourceNode;
import js.html.MediaStreamTrackAudioSourceNode;
import js.html.OscillatorNode;
import js.html.AnalyserNode;
import js.html.GainNode;
import js.html.BiquadFilterNode;
import js.html.DelayNode;
import js.html.IIRFilterNode;
import js.html.StereoPannerNode;
import js.html.PannerNode;
import js.html.ConvolverNode;
import js.html.DynamicsCompressorNode;
import js.html.WaveShaperNode;
import js.html.MediaStreamAudioDestinationNode;
import js.html.MediaStreamAudioSourceNode;
import js.html.MediaStreamAudioDestinationNode;

import js.html.AudioListener;

import js.html.AudioContext;
import js.html.AudioNode;
import js.html.AudioParam;
import js.html.AudioBuffer;
import js.html.AudioBufferSourceNode;
import js.html.BaseAudioContext;
import js.html.MediaElementAudioSourceNode;
import js.html.MediaStreamAudioSourceNode;
import js.html.MediaStreamTrackAudioSourceNode;
import js.html.OscillatorNode;
import js.html.AnalyserNode;
import js.html.GainNode;
import js.html.Biqu