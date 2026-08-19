use opentelemetry::{global, KeyValue};
use opentelemetry_sdk::{
    propagation::TraceContextPropagator,
    trace::{self, Sampler},
    Resource,
};
use opentelemetry_semantic_conventions::resource::SERVICE_NAME;
use std::env;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter, Layer};

pub fn init_telemetry() {
    // 1. Configurar o Propagador W3C Global
    global::set_text_map_propagator(TraceContextPropagator::new());

    // 2. Configurar o Exporter OTLP
    let otlp_endpoint =
        env::var("OTEL_EXPORTER_OTLP_ENDPOINT").unwrap_or_else(|_| "http://localhost:4317".to_string());

    let tracer = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(
            opentelemetry_otlp::new_exporter()
                .tonic()
                .with_endpoint(otlp_endpoint),
        )
        .with_trace_config(
            trace::config()
                .with_sampler(Sampler::AlwaysOn)
                .with_resource(Resource::new(vec![KeyValue::new(
                    SERVICE_NAME,
                    "system-bank-api",
                )])),
        )
        .install_batch(opentelemetry_sdk::runtime::Tokio)
        .expect("Falha ao inicializar o tracer OTLP");

    // 3. Layer do OpenTelemetry para o Tracing
    let telemetry_layer = tracing_opentelemetry::layer().with_tracer(tracer);

    // 4. Layer de formatação JSON para stdout
    let fmt_layer = tracing_subscriber::fmt::layer()
        .json()
        .with_current_span(true)
        .with_span_list(true);

    // 5. Configuração do filtro (RUST_LOG)
    let env_filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));

    // 6. Registrar o subscriber global
    tracing_subscriber::registry()
        .with(env_filter)
        .with(telemetry_layer)
        .with(fmt_layer)
        .init();
}
