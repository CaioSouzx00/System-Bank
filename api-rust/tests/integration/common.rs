use axum_test::TestServer;
use sqlx::postgres::PgPoolOptions;
use std::sync::Arc;
use testcontainers::runners::AsyncRunner;
use testcontainers_modules::{postgres::Postgres, rabbitmq::RabbitMq};
use system_bank_api::{app::create_router, AppState};
use jsonwebtoken::{encode, EncodingKey, Header, Algorithm};
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;
use system_bank_api::middleware::auth::Claims;

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

pub fn generate_token(user_id: Uuid) -> String {
    let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64;
    let claims = Claims {
        sub: user_id,
        role: "CLIENT".to_string(),
        iat: now as usize,
        exp: (now + 3600) as usize,
    };
    
    let key = EncodingKey::from_rsa_pem(PRIVATE_KEY_PEM).unwrap();
    encode(&Header::new(Algorithm::RS256), &claims, &key).unwrap()
}

pub struct TestApp {
    pub server: TestServer,
    pub db_pool: sqlx::PgPool,
    // Keep nodes alive for the duration of the test
    _pg_node: testcontainers::ContainerAsync<Postgres>,
    _rmq_node: testcontainers::ContainerAsync<RabbitMq>,
}

pub async fn setup() -> TestApp {
    std::env::set_var("JWT_PUBLIC_KEY", String::from_utf8(PUBLIC_KEY_PEM.to_vec()).unwrap());

    // Start containers
    let pg_node = Postgres::default().start().await.unwrap();
    let rmq_node = RabbitMq::default().start().await.unwrap();

    let pg_port = pg_node.get_host_port_ipv4(5432).await.unwrap();
    let rmq_port = rmq_node.get_host_port_ipv4(5672).await.unwrap();

    let db_url = format!("postgres://postgres:postgres@127.0.0.1:{}/postgres", pg_port);
    let rmq_url = format!("amqp://guest:guest@127.0.0.1:{}/%2f", rmq_port);

    // Run migrations
    let pool = PgPoolOptions::new().connect(&db_url).await.unwrap();
    sqlx::migrate!("../migrations").run(&pool).await.unwrap();

    // Create RabbitMQ connection
    let amqp_conn = lapin::Connection::connect(&rmq_url, lapin::ConnectionProperties::default()).await.unwrap();
    let amqp_channel = amqp_conn.create_channel().await.unwrap();
    system_bank_api::queue::publisher::declare_queues(&amqp_channel).await.unwrap();

    let state = Arc::new(AppState {
        db: pool.clone(),
        amqp_channel,
    });

    let app = create_router(state);
    let server = TestServer::new(app).unwrap();

    TestApp {
        server,
        db_pool: pool,
        _pg_node: pg_node,
        _rmq_node: rmq_node,
    }
}
