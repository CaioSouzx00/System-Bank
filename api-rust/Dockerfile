FROM rust:latest AS builder

ARG DATABASE_URL=postgres://bankuser:bankpass@host.docker.internal:5432/system_bank
ENV DATABASE_URL=$DATABASE_URL

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir -p src/bin && echo "fn main() {}" > src/main.rs && echo "fn main() {}" > src/bin/worker.rs && touch src/lib.rs
RUN cargo build --release

COPY src ./src
RUN touch src/main.rs src/lib.rs src/bin/worker.rs && cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libssl3 ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/system-bank-api .
EXPOSE 8080
CMD ["./system-bank-api"]
