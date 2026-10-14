FROM debian:bookworm-slim AS builder
RUN apt-get update && apt-get install -y gnucobol make && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . .
RUN make all

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libcob4 curl postgresql-client && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/bin ./bin
COPY scripts/run-job.sh ./run-job.sh
RUN chmod +x run-job.sh
CMD ["./run-job.sh"]
