use rustls::{server::WebPkiClientVerifier, RootCertStore, ServerConfig};
use rustls_pemfile::{certs, private_key};
use std::env;
use std::sync::Arc;
use base64::{engine::general_purpose::STANDARD, Engine as _};
use anyhow::{Context, Result};
use std::io::Cursor;
use axum_server::tls_rustls::RustlsConfig;

pub async fn load_rustls_config() -> Result<Option<RustlsConfig>> {
    let ca_b64 = env::var("CA_CERT_B64").unwrap_or_default();
    let server_crt_b64 = env::var("SERVER_CERT_B64").unwrap_or_default();
    let server_key_b64 = env::var("SERVER_KEY_B64").unwrap_or_default();

    if ca_b64.is_empty() || server_crt_b64.is_empty() || server_key_b64.is_empty() {
        return Ok(None);
    }

    let ca_pem = STANDARD.decode(ca_b64)?;
    let server_crt_pem = STANDARD.decode(server_crt_b64)?;
    let server_key_pem = STANDARD.decode(server_key_b64)?;

    let mut ca_reader = Cursor::new(ca_pem);
    let mut root_cert_store = RootCertStore::empty();
    let ca_certs: Vec<_> = certs(&mut ca_reader).filter_map(Result::ok).collect();
    for cert in ca_certs {
        root_cert_store.add(cert)?;
    }

    let client_verifier = WebPkiClientVerifier::builder(Arc::new(root_cert_store))
        .build()
        .context("Failed to build WebPkiClientVerifier")?;

    let mut cert_reader = Cursor::new(server_crt_pem);
    let server_certs: Vec<_> = certs(&mut cert_reader).filter_map(Result::ok).collect();

    let mut key_reader = Cursor::new(server_key_pem);
    let server_key = private_key(&mut key_reader)?.context("No private key found")?;

    let config = ServerConfig::builder()
        .with_client_cert_verifier(client_verifier)
        .with_single_cert(server_certs, server_key)?;

    Ok(Some(RustlsConfig::from_config(Arc::new(config))))
}
