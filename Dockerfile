FROM rust as builder
WORKDIR /usr/src
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y musl-tools && \
    rustup target add x86_64-unknown-linux-musl

RUN USER=root cargo new app_server
WORKDIR /usr/src/app_server
COPY Cargo.toml Cargo.lock ./
RUN cargo build --target x86_64-unknown-linux-musl --release
RUN rm src/*.rs

COPY src ./src
RUN rm ./target/x86_64-unknown-linux-musl/release/deps/untitled*
RUN cargo build --target x86_64-unknown-linux-musl --release

FROM scratch
COPY --from=builder usr/src/app_server/target/x86_64-unknown-linux-musl/release/untitled .
USER 1000
CMD ["./untitled"]
