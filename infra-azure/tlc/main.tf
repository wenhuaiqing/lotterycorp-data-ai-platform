locals {
  rg         = "rg-${var.prefix}"
  use_gemini = var.chat_provider == "gemini"
}

# ---------------------------------------------------------------------
# Existing resources, found by type inside the resource group so the
# random suffixes on the Key Vault, storage and OpenAI names never have
# to be typed. Each lookup must return exactly one resource.
# ---------------------------------------------------------------------

data "azurerm_resource_group" "main" {
  name = local.rg
}

data "azurerm_resources" "env" {
  resource_group_name = local.rg
  type                = "Microsoft.App/managedEnvironments"
}

data "azurerm_resources" "kv" {
  resource_group_name = local.rg
  type                = "Microsoft.KeyVault/vaults"
}

data "azurerm_resources" "storage" {
  resource_group_name = local.rg
  type                = "Microsoft.Storage/storageAccounts"
}

data "azurerm_resources" "openai" {
  resource_group_name = local.rg
  type                = "Microsoft.CognitiveServices/accounts"
}

data "azurerm_resources" "mysql" {
  resource_group_name = local.rg
  type                = "Microsoft.DBforMySQL/flexibleServers"
}

check "one_of_each" {
  assert {
    condition = alltrue([
      length(data.azurerm_resources.env.resources) == 1,
      length(data.azurerm_resources.kv.resources) == 1,
      length(data.azurerm_resources.storage.resources) == 1,
      length(data.azurerm_resources.openai.resources) == 1,
      length(data.azurerm_resources.mysql.resources) == 1,
    ])
    error_message = "Expected exactly one Container Apps environment, Key Vault, storage account, OpenAI account and MySQL server in ${local.rg}."
  }
}

data "azurerm_user_assigned_identity" "backend" {
  name                = "id-${var.prefix}-backend"
  resource_group_name = local.rg
}

data "azurerm_key_vault" "main" {
  name                = data.azurerm_resources.kv.resources[0].name
  resource_group_name = local.rg
}

data "azurerm_key_vault_secret" "tavily" {
  name         = "tavily-api-key"
  key_vault_id = data.azurerm_key_vault.main.id
}

data "azurerm_key_vault_secret" "llm_api_key" {
  name         = "llm-api-key"
  key_vault_id = data.azurerm_key_vault.main.id
}

data "azurerm_key_vault_secret" "chat_api_key" {
  name         = "chat-api-key"
  key_vault_id = data.azurerm_key_vault.main.id
}

data "azurerm_key_vault_secret" "mysql_app_password" {
  name         = "mysql-app-password"
  key_vault_id = data.azurerm_key_vault.main.id
}

data "azurerm_key_vault_secret" "demo_write_token" {
  name         = "demo-write-token"
  key_vault_id = data.azurerm_key_vault.main.id
}

data "azurerm_storage_account" "artefacts" {
  name                = data.azurerm_resources.storage.resources[0].name
  resource_group_name = local.rg
}

data "azurerm_cognitive_account" "openai" {
  name                = data.azurerm_resources.openai.resources[0].name
  resource_group_name = local.rg
}

data "azurerm_mysql_flexible_server" "main" {
  name                = data.azurerm_resources.mysql.resources[0].name
  resource_group_name = local.rg
}

# ---------------------------------------------------------------------
# The app. Same sidecar layout as the main app: nginx (public ingress)
# proxies to FastAPI on 127.0.0.1 in the same replica.
# ---------------------------------------------------------------------

resource "azurerm_container_app" "tlc" {
  name                         = var.app_name
  container_app_environment_id = data.azurerm_resources.env.resources[0].id
  resource_group_name          = data.azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.backend.id]
  }

  lifecycle {
    ignore_changes = [workload_profile_name]
  }

  ingress {
    external_enabled = true
    target_port      = 80 # nginx
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  # Pull credential for private GHCR packages (omitted when the packages
  # are public).
  dynamic "secret" {
    for_each = var.ghcr_token != "" ? [1] : []
    content {
      name  = "ghcr-token"
      value = var.ghcr_token
    }
  }
  dynamic "registry" {
    for_each = var.ghcr_token != "" ? [1] : []
    content {
      server               = "ghcr.io"
      username             = var.ghcr_username
      password_secret_name = "ghcr-token"
    }
  }

  secret {
    name                = "tavily-api-key"
    key_vault_secret_id = data.azurerm_key_vault_secret.tavily.versionless_id
    identity            = data.azurerm_user_assigned_identity.backend.id
  }
  secret {
    name                = "llm-api-key" # Azure OpenAI - embeddings
    key_vault_secret_id = data.azurerm_key_vault_secret.llm_api_key.versionless_id
    identity            = data.azurerm_user_assigned_identity.backend.id
  }
  secret {
    name                = "chat-api-key"
    key_vault_secret_id = data.azurerm_key_vault_secret.chat_api_key.versionless_id
    identity            = data.azurerm_user_assigned_identity.backend.id
  }
  secret {
    name                = "mysql-app-password"
    key_vault_secret_id = data.azurerm_key_vault_secret.mysql_app_password.versionless_id
    identity            = data.azurerm_user_assigned_identity.backend.id
  }
  secret {
    name                = "demo-write-token"
    key_vault_secret_id = data.azurerm_key_vault_secret.demo_write_token.versionless_id
    identity            = data.azurerm_user_assigned_identity.backend.id
  }

  template {
    min_replicas = 0 # scale to zero
    max_replicas = 1

    container {
      name   = "frontend"
      image  = var.frontend_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "BACKEND_UPSTREAM"
        value = "127.0.0.1:8000"
      }
    }

    container {
      name   = "backend"
      image  = var.backend_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "ARTEFACT_BASE_URL"
        value = "${data.azurerm_storage_account.artefacts.primary_blob_endpoint}artefacts"
      }
      env {
        name  = "LLM_BASE_URL"
        value = local.use_gemini ? "https://generativelanguage.googleapis.com/v1beta/openai/" : "${data.azurerm_cognitive_account.openai.endpoint}openai/v1/"
      }
      env {
        name        = "LLM_API_KEY"
        secret_name = "chat-api-key"
      }
      env {
        name  = "LLM_CHAT_MODEL"
        value = local.use_gemini ? var.gemini_chat_model : var.azure_chat_deployment
      }
      env {
        name  = "EMBED_BASE_URL"
        value = "${data.azurerm_cognitive_account.openai.endpoint}openai/v1/"
      }
      env {
        name        = "EMBED_API_KEY"
        secret_name = "llm-api-key"
      }
      env {
        name  = "LLM_EMBED_MODEL"
        value = var.azure_embed_deployment
      }
      env {
        name        = "TAVILY_API_KEY"
        secret_name = "tavily-api-key"
      }
      env {
        name  = "MYSQL_HOST"
        value = data.azurerm_mysql_flexible_server.main.fqdn
      }
      env {
        name  = "MYSQL_USER"
        value = "app"
      }
      env {
        name        = "MYSQL_PASSWORD"
        secret_name = "mysql-app-password"
      }
      env {
        name  = "MYSQL_DATABASE"
        value = var.mysql_database
      }
      env {
        name  = "MYSQL_SSL"
        value = "true"
      }
      env {
        name        = "DEMO_WRITE_TOKEN"
        secret_name = "demo-write-token"
      }
    }
  }
}
