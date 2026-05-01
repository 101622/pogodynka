# syntax=docker/dockerfile:1

# Użycie języka golang jako buildera
FROM golang:alpine AS builder
RUN apk add --no-cache openssh-client git
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
WORKDIR /app

# Pobieranie kodu z GitHuba
RUN --mount=type=ssh git clone git@github.com:101622/pogodynka.git .

# Wyłączamy CGO
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o weatherapp main.go

FROM scratch

LABEL org.opencontainers.image.authors="Wojciech Makowka"

# Kopia certyfikatów buildera
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /app/weatherapp /weatherapp

# Port 8080
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s CMD ["/weatherapp", "-health"]

ENTRYPOINT ["/weatherapp"]