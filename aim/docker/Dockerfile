# builder stage
FROM python:3.11-slim-bookworm AS builder

WORKDIR /app


RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*


RUN pip install --upgrade pip && \
    pip install --no-cache-dir "Cython==3.0.10" "aimrocks==0.5.*"

COPY . .

RUN pip install --no-cache-dir .

# Runtime stage 
FROM python:3.11-slim-bookworm


COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

EXPOSE 80

CMD ["aim", "up", "--host", "0.0.0.0", "--port", "80", "--yes"]
