output "frontend_url" {
  description = "Public URL of the Lottery Corporation-branded demo (managed TLS)."
  value       = "https://${azurerm_container_app.tlc.ingress[0].fqdn}"
}

output "write_token_hint" {
  description = "Operator unlock: append ?write_token=<demo-write-token from Key Vault> to the URL once per browser session."
  value       = "az keyvault secret show --vault-name ${data.azurerm_key_vault.main.name} -n demo-write-token --query value -o tsv"
}
