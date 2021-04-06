FROM alpine as builder
RUN apk add git build-base cmake linux-headers
RUN cd /; git clone --depth 1 https://github.com/microsoft/mimalloc; cd mimalloc; mkdir build; cd build; cmake ..; make -j$(nproc); make install

FROM rust:alpine3.13 as builder2

WORKDIR /usr/src
RUN apk add --no-cache musl-dev && \
    rustup target add x86_64-unknown-linux-musl 

RUN USER=root cargo new app_server
WORKDIR /usr/src/app_server
COPY Cargo.toml Cargo.lock ./
RUN cargo build --target x86_64-unknown-linux-musl --release
RUN rm src/*.rs

COPY src ./src
RUN rm ./target/x86_64-unknown-linux-musl/release/deps/untitled*
RUN cargo build --target x86_64-unknown-linux-musl --release

FROM alpine
COPY --from=builder /mimalloc/build/*.so.* /lib
RUN ln -s /lib/libmimalloc.so.* /lib/libmimalloc.so
ENV LD_PRELOAD=/lib/libmimalloc.so
ENV MIMALLOC_LARGE_OS_PAGES=1

COPY --from=builder2 usr/src/app_server/target/x86_64-unknown-linux-musl/release/untitled .
USER 1000
CMD ["./untitled"]
