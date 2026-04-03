//! InfiniClient API 测试

use codexbar::providers::infini::{InfiniClient, InfiniError, InfiniUsage};

#[tokio::test]
async fn test_fetch_usage_success() {
    let mut server = mockito::Server::new();
    let mock = server
        .mock("GET", "/maas/coding/usage")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            r#"{
            "5_hour": {"quota": 5000, "used": 1000, "remain": 4000},
            "7_day": {"quota": 30000, "used": 5000, "remain": 25000},
            "30_day": {"quota": 60000, "used": 10000, "remain": 50000}
        }"#,
        )
        .create();

    let client = InfiniClient::new("sk-cp-test-key".to_string()).with_base_url(server.url());

    let usage = client.fetch_usage().await.unwrap();

    mock.assert();
    assert_eq!(usage.five_hour.quota, 5000);
    assert_eq!(usage.seven_day.used, 5000);
}

#[tokio::test]
async fn test_fetch_usage_unauthorized() {
    let mut server = mockito::Server::new();
    let mock = server.mock("GET", "/maas/coding/usage").with_status(401).create();

    let client = InfiniClient::new("invalid-key".to_string()).with_base_url(server.url());

    let result = client.fetch_usage().await;

    mock.assert();
    assert!(matches!(result, Err(InfiniError::Unauthorized)));
}
