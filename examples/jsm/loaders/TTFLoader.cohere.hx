import hxopencensus.contrib.agent.Agent;
import hxopencensus.contrib.agent.trace.Tracer;
import hxopencensus.contrib.http.HttpClientTraceHandler;
import hxopencensus.contrib.http.HttpServerTraceHandler;
import hxopencensus.core.exporters.Exporter;
import hxopencensus.core.exporters.StatsExporter;
import hxopencensus.core.exporters.TraceExporter;
import hxopencensus.core.stats.MeasureToViewMap;
import hxopencensus.core.stats.ViewManager;
import hxopencensus.core.trace.Span;
import js.Browser;
import js.Node;

class OpenCensus {
    public static init(config: OpenCensusConfig): OpenCensus {
        if (config.tracingEnabled == true) {
            OpenCensus.initTracing(config);
        }

        if (config.statsEnabled == true) {
            OpenCensus.initStats(config);
        }

        return OpenCensus;
    }

    private static initTracing(config: OpenCensusConfig) {
        if (Browser.detect()) {
            config.rootSpan ? Tracer.currentRootSpan = config.rootSpan : null;
            config.exporter ? Tracer.setDefaultSpanExporter(config.exporter) : null;
            config.samplingRate ? Tracer.setSampler(new ProbabilisticSampler(config.samplingRate)) : null;
            config.traceHandler ? HttpServerTraceHandler.create(config.traceHandler) : null;
        } else if (Node.detect()) {
            config.rootSpan ? Tracer.currentRootSpan = config.rootSpan : null;
            config.exporter ? Tracer.setDefaultSpanExporter(config.exporter) : null;
            config.samplingRate ? Tracer.setSampler(new ProbabilisticSampler(config.samplingRate)) : null;
            config.traceHandler ? HttpServerTraceHandler.create(config.traceHandler) : null;
            config.httpClientTraceHandler ? HttpClientTraceHandler.create(config.httpClientTraceHandler) : null;
        }

        Agent.start();
    }

    private static initStats(config: OpenCensusConfig) {
        if (Browser.detect()) {
            config.exporter ? ViewManager.setDefaultExporter(config.exporter) : null;
            config.measureToViewMap ? ViewManager.setMeasureToViewMap(config.measureToViewMap) : null;
        } else if (Node.detect()) {
            config.exporter ? ViewManager.setDefaultExporter(config.exporter) : null;
            configMultiplier.measureToViewMap ? ViewManager.setMeasureToViewMap(config.measureToViewMap) : null;
        }
    }

    public static trace(name: String, fn: Dynamic -> Dynamic): Dynamic {
        var span = Tracer.spanBuilder(name).startSpan();
        try {
            return fn(span);
        } catch (e: Dynamic) {
            span.addAnnotation(e.toString());
            throw e;
        } finally {
            span.end();
        }
    }

    public static startRootSpan(name: String, options: SpanOptions = null): RootSpan {
        return Tracer.spanBuilder(name).setSpanKind(SpanKind.Internal).startRootSpan(options);
    }

    public static startChildSpan(name: String, options: SpanOptions = null): Span {
        return Tracer.currentRootSpan.spanBuilder(name).setSpanKind(SpanKind.Internal).startChildSpan(options);
    }

    public static getCurrentRootSpan(): RootSpan {
        return Tracer.currentRootSpan;
    }

    public static getCurrentSpan(): Span {
        return Tracer.currentSpan;
    }

    public static setCurrentSpan(span: Span) {
        Tracer.setCurrentSpan(span);
    }
}

class OpenCensusConfig {
    public var tracingEnabled: Bool;
    public var statsEnabled: Bool;
    public var rootSpan: RootSpan;
    public var exporter: Exporter;
    public var samplingRate: Float;
    public var traceHandler: HttpServerHandler;
    public var httpClientTraceHandler: HttpClientHandler;
    public var measureToViewMap: MeasureToViewMap;
}

class RootSpan {
    public function new(span: Span) {
        this.span = span;
    }

    public var span: Span;
}

class SpanOptions {
    public var attributes: Map<String, String>;
    public var startTime: DateTime;
}

enum SpanKind {
    Internal,
    Server,
    Client
}

class ProbabilisticSampler {
    public function new(samplingRate: Float) {
        this.samplingRate = samplingRate;
    }

    public var samplingRate: Float;
}