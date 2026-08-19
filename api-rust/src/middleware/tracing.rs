use axum::{
    extract::{MatchedPath, Request},
    middleware::Next,
    response::Response,
};
use opentelemetry::{global, propagation::Extractor};
use tracing::{info_span, Instrument, Span};
use tracing_opentelemetry::OpenTelemetrySpanExt;

struct HeaderExtractor<'a>(&'a http::HeaderMap);

impl<'a> Extractor for HeaderExtractor<'a> {
    fn get(&self, key: &str) -> Option<&str> {
        self.0.get(key).and_then(|value| value.to_str().ok())
    }

    fn keys(&self) -> Vec<&str> {
        self.0.keys().map(|k| k.as_str()).collect()
    }
}

pub async fn tracing_middleware(
    request: Request,
    next: Next,
) -> Response {
    let method = request.method().as_str().to_string();
    let route = if let Some(matched_path) = request.extensions().get::<MatchedPath>() {
        matched_path.as_str().to_string()
    } else {
        request.uri().path().to_string()
    };

    let parent_context = global::get_text_map_propagator(|propagator| {
        propagator.extract(&HeaderExtractor(request.headers()))
    });

    let span = info_span!(
        "http_request",
        http.method = %method,
        http.route = %route,
        http.status_code = tracing::field::Empty,
    );

    // Conecta o span filho ao traceparent se houver um na requisição
    span.set_parent(parent_context);

    // Passamos o request para o próximo layer dentro do escopo do span
    let response = next.run(request).instrument(span.clone()).await;

    // Registra o status code no span
    span.record("http.status_code", response.status().as_u16());

    response
}
