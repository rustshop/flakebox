use openssl::ssl::{SslConnector, SslMethod};

fn main() {
    let _connector = SslConnector::builder(SslMethod::tls())
        .expect("OpenSSL supports TLS")
        .build();
}
