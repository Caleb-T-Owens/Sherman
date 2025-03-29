use std::collections::HashMap;

use axum::{routing::get, Router, Json};
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
#[serde(untagged)]
enum Record {
    Present(PresentRecord),
    Deleted(DeletedRecord),
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct PresentRecord {
    created_at: i64,
    values: HashMap<String, Value>,
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct Value {
    current: PrimativeValue,
    updated_at: i64,
}

#[derive(Serialize, Deserialize)]
#[serde(untagged)]
enum PrimativeValue {
    String(String),
    Number(f64),
    Boolean(bool),
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct DeletedRecord {
    deleted_at: i64,
}

async fn sync() -> Json<Record> {
    Json(Record::Present(PresentRecord {
        created_at: 69420,
        values: HashMap::from([(
            "foo".into(),
            Value {
                current: PrimativeValue::Number(42.0),
                updated_at: 69500,
            },
        )]),
    }))
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/", get(|| async { "Sup" }))
        .route("/api/sync", get(sync));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
