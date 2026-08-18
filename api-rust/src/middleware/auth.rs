use axum::{
    extract::{Request, State},
    middleware::Next,
    response::Response,
};
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use uuid::Uuid;

use crate::{errors::AppError, AppState};

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct Claims {
    pub sub: Uuid,    // user_id
    pub role: String, // CLIENT | OPERATOR | ADMIN
    pub exp: usize,
    pub iat: usize,
}

/// Extrai e valida o JWT do header Authorization: Bearer <token>
/// Injeta `Claims` no request para uso downstream
pub async fn require_auth(
    State(_state): State<Arc<AppState>>,
    mut req: Request,
    next: Next,
) -> Result<Response, AppError> {
    let token = req
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(AppError::Unauthorized)?;

    let public_key = std::env::var("JWT_PUBLIC_KEY").map_err(|_| AppError::Unauthorized)?;
    let key = DecodingKey::from_rsa_pem(public_key.as_bytes()).map_err(|_| AppError::Unauthorized)?;
    
    let mut validation = Validation::new(Algorithm::RS256);
    // Assegura que o token será validado considerando a expiração (exp)
    validation.validate_exp = true;

    let token_data = decode::<Claims>(token, &key, &validation)
        .map_err(|_| AppError::Unauthorized)?;

    req.extensions_mut().insert(token_data.claims);
    Ok(next.run(req).await)
}

#[cfg(test)]
mod tests {
    use super::*;
    use jsonwebtoken::{encode, EncodingKey, Header};
    use std::time::{SystemTime, UNIX_EPOCH};

    const PRIVATE_KEY_PEM: &[u8] = b"-----BEGIN RSA PRIVATE KEY-----\n\
MIIEpAIBAAKCAQEAvo0072jw/9OIbLfojlJ636jtN2pubUFRZ/BzuHMsFk+Ed1Mq\n\
pzJqlEHxK9bFdY/EibW6za8doRNnE6m35vptNgAjR/hWoSnyzYWIyeej9NYWq7Cc\n\
ubGc+3tc8wITPjwibVl47Rmb/me0mTxl0f+PKlgetqoZNhpmOqJrGINmF2HjY0mF\n\
yMysmsvhXKs+MzBG4L99GWVLK5WxqFp76CkDO3tIGpasl2XQjukOR2CgdpUKKpfG\n\
qCCFlVyIpiUk+6ZKm6U0pjfcLg6Zua2UOvmy0WwAsYG0w7ePZW4r079SdsxwJeMh\n\
M+ga973feRYzei0PVPyPSBsMgFLecX1HLn6ojwIDAQABAoIBAFJ+JzCOKedW2HTY\n\
mWEj6/Xv1+JpvSynXmq0+iQcGDYAbsSJyKlhdiqA8buc2xcuClPjzN9GtHkLQVCN\n\
5QOl3qnGHYAGztououK+sJ1YHu7b0Cy75N2vOtrUaUT63QHQXscgOO3MbHASzWiZ\n\
cSscjAo04/cIZKm7fA5eSibum7/67XKvr62keIV5ycWmN/5cOJB/+nJ8IEZQNeWH\n\
vPUTyJIhCa+DymOy6a4GEeaCArFWVRuuYK1qfkuUGAuPjuYUKUsuz2iRTCw0j6eh\n\
uJ1WQ4lQVv3DFBPoRZfUYefnG4Jt0QD2QwtbGJg1270NF4OZJobDYY8mpn6WOERr\n\
kQ4S2EECgYEA5F4HH3hbGFV1upDooj/apSc0+QzOJKNlVgiI+REfTFf2ZL9BxyIH\n\
7qYozfivQgXcK7b+Kmsgw6m2eUk33ZjQkuSf5jFB4N2Im8PZ0+zpb19yGbC0/G26\n\
2031HgvaRM2EOzVbJyPEjjz4bQGdHAvR1ihMBSdvy1HAWD9HaFJs/8cCgYEA1ZvJ\n\
3g4kNvSmdn3yMxkoKmX7vuSTzh7wwxWJFpfMV+CnP9G8ZAmVoc0t07ObTlAocW+P\n\
+HR61WQ10Um6w5mFx5nuAPkfhE5Qr36jo3CdFhTcMinjxCWoKaRk3N+rkHHL+8fv\n\
MxwaIVOGuEc/KK1CMUVuc8zKGS5QMpVbP5t3IPkCgYEAzc7rznHSbyi9tAjajzbK\n\
3uJpvDXNJnnXXuTMROMoeM4hcYRoTIWf7nTy+0Wu9OqBFSiTATmQyqWNnNrerSgG\n\
eQvwCy3DOFuOvQqRqoutiUDUfNCjG4fsya4FRTHbYPxyukWIw8pZXvMV1G+K3vbM\n\
ApxIfrCe8PbZSO6mdR8ruosCgYACUuySTuMT+ftppJsi9S4br/paLFBzWKDT7oMM\n\
TOB7QEVxi02aZQRMu1e5SuXwpyyZd1ZApLvFYI65VS0D/cKX1lPhjNRL8zIrhpwv\n\
JgV/fQCcRxpkQuiec1xpjsFmE+bdOWKf0rlyDV+U16mXPrNOp+u4tMyqE3fp5PgW\n\
LBHSuQKBgQCJgtcCuwHoAhlsLee/gNJ+zZUi7EKE2nmJqHPEJ4iOmfrQJLV+uC0z\n\
qzdsV9F9EgFvm5ayXRmtaD4adfldFovppa8y+EKpvWu3fEMvkdOwfX9teebD4/yj\n\
LOA6uWJxsyT92j4eAebcLHwWtx2VBmBSQU0k4dQdvZ+fnOMowTP9vg==\n\
-----END RSA PRIVATE KEY-----";

    const PUBLIC_KEY_PEM: &[u8] = b"-----BEGIN PUBLIC KEY-----\n\
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvo0072jw/9OIbLfojlJ6\n\
36jtN2pubUFRZ/BzuHMsFk+Ed1MqpzJqlEHxK9bFdY/EibW6za8doRNnE6m35vpt\n\
NgAjR/hWoSnyzYWIyeej9NYWq7CcubGc+3tc8wITPjwibVl47Rmb/me0mTxl0f+P\n\
KlgetqoZNhpmOqJrGINmF2HjY0mFyMysmsvhXKs+MzBG4L99GWVLK5WxqFp76CkD\n\
O3tIGpasl2XQjukOR2CgdpUKKpfGqCCFlVyIpiUk+6ZKm6U0pjfcLg6Zua2UOvmy\n\
0WwAsYG0w7ePZW4r079SdsxwJeMhM+ga973feRYzei0PVPyPSBsMgFLecX1HLn6o\n\
jwIDAQAB\n\
-----END PUBLIC KEY-----";

    const INVALID_PRIVATE_KEY_PEM: &[u8] = b"-----BEGIN RSA PRIVATE KEY-----\n\
MIIEpQIBAAKCAQEA0YCkqjI7o67wIHCkValREXhSuwvXGCoPx7VlKBHN7IMh/jAy\n\
CJ1pcctVUz6+1x+pRX92KvHcRWh+UbUJ+b0NGmcFC+g/yJXAOS0Y3iE4hg2MfTtA\n\
eLvRPPNLt49hePvnMdPg0U0w1zfr3wSDxJgCep/A3SqkmuTiqy/XFz7tAQb5l77x\n\
iGbm93bcrPaauJ6jrUTRrZ3u9kcS/pKhPwJTdyAfUe8fu/IoUVesZShiZ1z/NmsZ\n\
D3TUua0S3Mzz9NlOte1H+dRi57cZSqhi6VOaLNsIaJXQxULSYKlRI9eyulxsRRSw\n\
jgjiC2ChFxhmh9+NVchYxk/f44lgYYqathhNDwIDAQABAoIBABcU8c9wlmKL0Rf5\n\
4Rkw/OYMWC0Uel/GrpNluF3oTERNFE8xlymc0jO/38g6pwMDkX4/M1E68XZSM2yk\n\
IhO6UPnCNOuhbHmYiiOihNVgWp5mWr6nawyCQOTSt1pjeS0/r7KtMd1NgF6N4jZh\n\
hHUB/G/vLuwPGTCZnCGZNTzx6WHN5GT2hOW0MI/fC0Pp8J4RofsBLmkJi3ZCo9c+\n\
28lbL2PNKuFTXs7ccAEBoDz0K/P2+0ZzfeCu6/Ifqh5//DOIaP9fxSE8XFCekkZC\n\
kGIsBTD+dtR6a24zq7d4clKSWPngqhSkDDOrFswGsNxExE5ChIbTZU8SEuoAYh9R\n\
niEmqzkCgYEA6ETubySNGUq6nUqXQEiKquXcfYe+OmqWwL8rg1My3x/irVzukfXd\n\
oQVVSEKPM3Res63/bLYAlAHVsQGhgWsytfl1ma++jmDV5Q4qx+UF+kKrp0d3vyqO\n\
Qc0Tv0Vflx0Sj4OqlmWBrnqJrjtnNdcW3ZypC1RwMIlXNunv8XLLjTcCgYEA5ug9\n\
sl608F1rbImGWivs5ikPv5Xb28PvEoWmJ27ejKU4bAA7fgqa8RPl125C/x237Ud5\n\
3HSDWhWUVDfPFL3stQBM55oAE7UrcyOEwySfnkiKwI63blBV8HVfAzLzk6xnqdT2\n\
j6o6fyIY/KUkBmj1i0gGWv1bOiMAE/TyBe6EaukCgYEAt03XQj19YW15czLvxRq6\n\
3P6FEUh0l1ORX9I/O+gIKNDYKutBmE2KOE6mLF3i97+qEXGLODc2o5gDFitsU1/P\n\
aI/UAJMS9vhzNc8FcjZLjmLZZy3e0i56kHGRWQ0d0HtwL3TAxuqa+qDYUXmuDW6P\n\
LBw7yKY92AA7pSngZBOtkucCgYEA17mpyndIvDfLIP/rEVtwXCeImwk6+rq3JKrQ\n\
bI7cRLInYF9nNX5a+1gHp5lP5mCxcXERnLEN9p+qkHQDd/FosEGzl7z8zWy5Rzyr\n\
0FTq+0nyt6ueG+XaJGjDd42mmxS7VKOuJtJ3DEei6IawfXyZyqJjraZ+EHaaoAp8\n\
Aqav9+ECgYEA3vfcaGlIOjiHs80P7gfF+ux8snCxxnPk+CNV9ya06ENR/QT2hEmw\n\
xoLw5hCSpJSuaeY2riXFWYFkPESBDOIOm6wbBD4iiT7bUic5rN3KZRg0ZfsMvjr/\n\
wJpoe343b/CWvU+OPAyVIySAD/Mxe/qYs1Iqwljsd93Zsx7BLt9gYos=\n\
-----END RSA PRIVATE KEY-----";

    fn setup_env() {
        std::env::set_var("JWT_PUBLIC_KEY", String::from_utf8(PUBLIC_KEY_PEM.to_vec()).unwrap());
    }

    fn generate_token(claims: &Claims, invalid_key: bool) -> String {
        let key = if invalid_key {
            EncodingKey::from_rsa_pem(INVALID_PRIVATE_KEY_PEM).unwrap()
        } else {
            EncodingKey::from_rsa_pem(PRIVATE_KEY_PEM).unwrap()
        };
        encode(&Header::new(Algorithm::RS256), claims, &key).unwrap()
    }

    fn create_claims(exp_offset: i64) -> Claims {
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64;
        Claims {
            sub: Uuid::new_v4(),
            role: "CLIENT".to_string(),
            iat: now as usize,
            exp: (now + exp_offset) as usize,
        }
    }

    #[tokio::test]
    async fn test_valid_token() {
        setup_env();
        let claims = create_claims(3600); // Expiracao de 1 hora
        let token = generate_token(&claims, false);

        let public_key = std::env::var("JWT_PUBLIC_KEY").unwrap();
        let key = DecodingKey::from_rsa_pem(public_key.as_bytes()).unwrap();
        let mut validation = Validation::new(Algorithm::RS256);
        validation.validate_exp = true;

        let result = decode::<Claims>(&token, &key, &validation);
        assert!(result.is_ok());
        let decoded = result.unwrap().claims;
        assert_eq!(decoded.sub, claims.sub);
    }

    #[tokio::test]
    async fn test_expired_token() {
        setup_env();
        let claims = create_claims(-3600); // Expirado ha 1 hora
        let token = generate_token(&claims, false);

        let public_key = std::env::var("JWT_PUBLIC_KEY").unwrap();
        let key = DecodingKey::from_rsa_pem(public_key.as_bytes()).unwrap();
        let mut validation = Validation::new(Algorithm::RS256);
        validation.validate_exp = true;

        let result = decode::<Claims>(&token, &key, &validation);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().kind(), &jsonwebtoken::errors::ErrorKind::ExpiredSignature);
    }

    #[tokio::test]
    async fn test_invalid_signature() {
        setup_env();
        let claims = create_claims(3600);
        let token = generate_token(&claims, true); // Chave incorreta para simular adulteracao

        let public_key = std::env::var("JWT_PUBLIC_KEY").unwrap();
        let key = DecodingKey::from_rsa_pem(public_key.as_bytes()).unwrap();
        let mut validation = Validation::new(Algorithm::RS256);
        validation.validate_exp = true;

        let result = decode::<Claims>(&token, &key, &validation);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().kind(), &jsonwebtoken::errors::ErrorKind::InvalidSignature);
    }
}
