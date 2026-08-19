use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct StatementQuery {
    #[serde(default)]
    pub format: StatementFormat,
    pub from: String,
    pub to: String,
}

#[derive(Debug, Deserialize, Default, PartialEq, Eq, Clone, Copy)]
#[serde(rename_all = "lowercase")]
pub enum StatementFormat {
    #[default]
    Json,
    Ofx,
}
