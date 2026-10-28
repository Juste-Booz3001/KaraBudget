from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="KARA_")

    database_url: str = "sqlite:///./karabudget.db"
    secret_key: str = "dev-only-change-me-use-KARA_SECRET_KEY-in-prod"
    access_minutes: int = 30
    refresh_days: int = 30
    max_attachment_bytes: int = 4 * 1024 * 1024
    max_clock_skew_ms: int = 5 * 60 * 1000  # un timestamp client ne peut pas dépasser now + 5 min


settings = Settings()
