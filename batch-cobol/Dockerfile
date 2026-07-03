FROM gnucobol/gnucobol:3.2 AS builder
WORKDIR /app
COPY . .
RUN make all

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libcob4 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/bin ./bin
COPY scripts/run-job.sh ./run-job.sh
RUN chmod +x run-job.sh
CMD ["./run-job.sh"]
