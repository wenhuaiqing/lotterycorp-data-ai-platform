variable "prefix" {
  description = "Prefix of the existing stack (resource group rg-<prefix>, identity id-<prefix>-backend, ...)."
  type        = string
  default     = "aipapp"
}

variable "app_name" {
  description = "Name of the new container app."
  type        = string
  default     = "app-tlc"
}

variable "backend_image" {
  description = "Backend image built by .github/workflows/deploy.yml."
  type        = string
  default     = "ghcr.io/wenhuaiqing/lotterycorp-data-ai-platform/backend:latest"
}

variable "frontend_image" {
  description = "Frontend image built by .github/workflows/deploy.yml."
  type        = string
  default     = "ghcr.io/wenhuaiqing/lotterycorp-data-ai-platform/frontend:latest"
}

# Default path: the two GHCR packages are made public (GitHub web UI,
# package settings) and pulled anonymously, so both stay empty and the
# registry block in main.tf is not rendered. The token path is kept only
# as a fallback; it stores the PAT as a container app secret.
variable "ghcr_username" {
  description = "GitHub login that owns the token (only when the packages are private)."
  type        = string
  default     = ""
}

variable "ghcr_token" {
  description = "GitHub PAT with read:packages (only when the packages are private)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "chat_provider" {
  description = "Endpoint serving chat: \"gemini\" or \"azure\". Embeddings always stay on Azure OpenAI."
  type        = string
  default     = "gemini"

  validation {
    condition     = contains(["gemini", "azure"], var.chat_provider)
    error_message = "chat_provider must be \"gemini\" or \"azure\"."
  }
}

variable "gemini_chat_model" {
  description = "Gemini model id for chat. Stay on a Lite model: one Orb run is 5-9 sequential calls."
  type        = string
  default     = "gemini-3.5-flash-lite"
}

variable "azure_chat_deployment" {
  description = "Azure OpenAI chat deployment name in the existing account (used when chat_provider = azure)."
  type        = string
  default     = "gpt-4-1-mini"
}

variable "azure_embed_deployment" {
  description = "Azure OpenAI embedding deployment name in the existing account."
  type        = string
  default     = "text-embedding-3-small"
}

variable "mysql_database" {
  description = "Existing MySQL database the app reads (shared with the main app)."
  type        = string
  default     = "reapit_demo"
}
