use std::sync::Arc;
use actix_web::{get, web, Responder, HttpResponse, http::header::ContentType};
use crate::{db::{self, queries::QueryResponse}, remove_duplicates};

#[get("/votes")]
pub async fn votes(
    pg_client: web::Data<Arc<tokio_postgres::Client>>
) -> impl Responder {
    let response = db::queries::get_canonical_and_pending_votes_query(&pg_client).await.unwrap();
    let result = remove_duplicates(&response);
    let data = result.into_values().collect::<Vec<QueryResponse>>();

    HttpResponse::Ok().content_type(ContentType::json()).body(serde_json::to_string(&data).unwrap())
}
