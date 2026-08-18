use axum::{
    body::{Body, Bytes},
    extract::Request,
    http::{HeaderValue, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
};
use dashmap::DashMap;
use http_body_util::BodyExt;
use std::{
    net::IpAddr,
    sync::{Mutex, OnceLock},
    time::Instant,
};
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct TokenBucket {
    pub capacity: f64,
    pub fill_rate: f64,
    pub tokens: f64,
    pub last_update: Instant,
}

impl TokenBucket {
    pub fn new(capacity: f64, fill_rate: f64) -> Self {
        Self {
            capacity,
            fill_rate,
            tokens: capacity,
            last_update: Instant::now(),
        }
    }

    pub fn take(&mut self, tokens_to_take: f64) -> (bool, f64, u64) {
        let now = Instant::now();
        let elapsed = now.duration_since(self.last_update).as_secs_f64();

        self.tokens += elapsed * self.fill_rate;
        if self.tokens > self.capacity {
            self.tokens = self.capacity;
        }
        self.last_update = now;

        let allowed = if self.tokens >= tokens_to_take {
            self.tokens -= tokens_to_take;
            true
        } else {
            false
        };

        let remaining = self.tokens.floor();
        let reset_secs = if self.tokens < self.capacity {
            ((self.capacity - self.tokens) / self.fill_rate).ceil() as u64
        } else {
            0
        };

        (allowed, remaining, reset_secs)
    }
}

pub fn ip_rate_limits() -> &'static DashMap<IpAddr, Mutex<TokenBucket>> {
    static MAP: OnceLock<DashMap<IpAddr, Mutex<TokenBucket>>> = OnceLock::new();
    MAP.get_or_init(DashMap::new)
}

pub fn account_rate_limits() -> &'static DashMap<Uuid, Mutex<TokenBucket>> {
    static MAP: OnceLock<DashMap<Uuid, Mutex<TokenBucket>>> = OnceLock::new();
    MAP.get_or_init(DashMap::new)
}

pub async fn ip_rate_limit(req: Request, next: Next) -> Result<Response, StatusCode> {
    let rpm = std::env::var("RATE_LIMIT_IP_RPM")
        .unwrap_or_else(|_| "100".to_string())
        .parse::<f64>()
        .unwrap_or(100.0);

    let ip = req
        .headers()
        .get("X-Forwarded-For")
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.split(',').next())
        .and_then(|s| s.parse::<IpAddr>().ok())
        .unwrap_or_else(|| std::net::Ipv4Addr::new(127, 0, 0, 1).into());

    let map = ip_rate_limits();
    let (allow, remaining, reset_secs) = {
        let mut entry = map
            .entry(ip)
            .or_insert_with(|| Mutex::new(TokenBucket::new(rpm, rpm / 60.0)));
        let mut bucket = entry.lock().unwrap();
        bucket.take(1.0)
    };

    if !allow {
        let mut response = StatusCode::TOO_MANY_REQUESTS.into_response();
        if let Ok(hv) = HeaderValue::from_str(&reset_secs.to_string()) {
            response.headers_mut().insert("Retry-After", hv);
        }
        if let Ok(hv) = HeaderValue::from_str(&rpm.to_string()) {
            response.headers_mut().insert("X-RateLimit-Limit", hv);
        }
        response.headers_mut().insert("X-RateLimit-Remaining", HeaderValue::from_static("0"));
        if let Ok(hv) = HeaderValue::from_str(&reset_secs.to_string()) {
            response.headers_mut().insert("X-RateLimit-Reset", hv);
        }
        return Ok(response);
    }

    let mut response = next.run(req).await;
    if let Ok(hv) = HeaderValue::from_str(&rpm.to_string()) {
        response.headers_mut().insert("X-RateLimit-Limit", hv);
    }
    if let Ok(hv) = HeaderValue::from_str(&remaining.to_string()) {
        response.headers_mut().insert("X-RateLimit-Remaining", hv);
    }
    if let Ok(hv) = HeaderValue::from_str(&reset_secs.to_string()) {
        response.headers_mut().insert("X-RateLimit-Reset", hv);
    }
    Ok(response)
}

pub async fn account_rate_limit(req: Request, next: Next) -> Result<Response, StatusCode> {
    if req.method() != axum::http::Method::POST {
        return Ok(next.run(req).await);
    }

    let (parts, body) = req.into_parts();
    let bytes = match body.collect().await {
        Ok(c) => c.to_bytes(),
        Err(_) => return Err(StatusCode::BAD_REQUEST),
    };

    if let Ok(payload) = serde_json::from_slice::<crate::models::transaction::CreateTransactionRequest>(&bytes) {
        let account_id = payload.account_id;

        let tpm = std::env::var("RATE_LIMIT_ACCOUNT_TPM")
            .unwrap_or_else(|_| "20".to_string())
            .parse::<f64>()
            .unwrap_or(20.0);

        let map = account_rate_limits();
        let (allow, remaining, reset_secs) = {
            let mut entry = map
                .entry(account_id)
                .or_insert_with(|| Mutex::new(TokenBucket::new(tpm, tpm / 60.0)));
            let mut bucket = entry.lock().unwrap();
            bucket.take(1.0)
        };

        if !allow {
            let mut response = StatusCode::TOO_MANY_REQUESTS.into_response();
            if let Ok(hv) = HeaderValue::from_str(&reset_secs.to_string()) {
                response.headers_mut().insert("Retry-After", hv);
            }
            if let Ok(hv) = HeaderValue::from_str(&tpm.to_string()) {
                response.headers_mut().insert("X-RateLimit-Limit", hv);
            }
            response.headers_mut().insert("X-RateLimit-Remaining", HeaderValue::from_static("0"));
            if let Ok(hv) = HeaderValue::from_str(&reset_secs.to_string()) {
                response.headers_mut().insert("X-RateLimit-Reset", hv);
            }
            return Ok(response);
        }
        
        let req = Request::from_parts(parts, Body::from(bytes));
        let mut response = next.run(req).await;
        
        if let Ok(hv) = HeaderValue::from_str(&tpm.to_string()) {
            response.headers_mut().insert("X-RateLimit-Limit", hv);
        }
        if let Ok(hv) = HeaderValue::from_str(&remaining.to_string()) {
            response.headers_mut().insert("X-RateLimit-Remaining", hv);
        }
        if let Ok(hv) = HeaderValue::from_str(&reset_secs.to_string()) {
            response.headers_mut().insert("X-RateLimit-Reset", hv);
        }
        return Ok(response);
    }

    let req = Request::from_parts(parts, Body::from(bytes));
    Ok(next.run(req).await)
}
