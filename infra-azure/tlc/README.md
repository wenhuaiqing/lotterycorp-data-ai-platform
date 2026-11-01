# Deploying app-tlc

One scale-to-zero container app (`app-tlc`) in the existing `rg-aipapp`
resource group on the personal subscription. It reuses that group's
Container Apps environment, backend managed identity, Key Vault secrets,
Blob artefacts, MySQL and Azure OpenAI, all found by type at plan time, so
the only resource created here is the app itself. Nothing new is billed
beyond replica seconds while someone is looking at it.

Credential-free: public images on GHCR pulled anonymously, Terraform files
uploaded to Azure Cloud Shell by hand, no token typed or stored anywhere.

## 1. Images

`.github/workflows/deploy.yml` builds and publishes on every push to `main`:

- `ghcr.io/wenhuaiqing/lotterycorp-data-ai-platform/backend:<sha>` and `:latest`
- `ghcr.io/wenhuaiqing/lotterycorp-data-ai-platform/frontend:<sha>` and `:latest`

Wait for a green run under Actions. If the repository is private the
packages are private too: github.com -> profile -> Packages -> `backend`
-> Package settings -> Change visibility -> Public, and the same for
`frontend`. Container Apps then pulls anonymously. Leave `ghcr_username`
and `ghcr_token` unset; the registry block in `main.tf` is conditional and
is not rendered.

## 2. Terraform (Cloud Shell, Bash, personal subscription)

Upload the four `.tf` files from this folder with the shell's Upload
button, then:

```bash
mkdir -p ~/tlc && mv ~/*.tf ~/tlc/ && cd ~/tlc
az account show --query name -o tsv     # must be the personal subscription
terraform init
terraform apply                          # type yes
terraform output -raw frontend_url; echo
```

One to two minutes. The first request after apply or after idle takes
30-60 s (image pull, artefact download, DuckDB rebuild from MySQL).

**Before closing the shell, download `~/tlc/terraform.tfstate`**
(`download ~/tlc/terraform.tfstate`). The session is ephemeral; without the
state the next change needs

```bash
terraform import azurerm_container_app.tlc \
  /subscriptions/<sub>/resourceGroups/rg-aipapp/providers/Microsoft.App/containerApps/app-tlc
```

## 3. Smoke

```bash
URL=$(terraform output -raw frontend_url)
curl -s "$URL/health"
```

Open the URL, check the dashboard renders and the co-pilot answers one
question. For writes and trusted runs, append `?write_token=<token>`, with
the token from the command printed by `terraform output write_token_hint`.

## 4. Budget

`rg-aipapp` carries a small monthly budget alert. A second app's cold
starts can trip it; raise it to about A$3 or expect the email:

```bash
az consumption budget list --query "[].{name:name,amount:amount}" -o table
az consumption budget update --budget-name <name> --amount 3 \
  --category cost --time-grain monthly --start-date <existing> --end-date <existing>
```

The budget only alerts; it never stops spend.

## 5. Rolling a new build

Push to `main`; when the workflow is green:

```bash
az containerapp update -g rg-aipapp -n app-tlc --container-name backend \
  --image ghcr.io/wenhuaiqing/lotterycorp-data-ai-platform/backend:<sha>
az containerapp update -g rg-aipapp -n app-tlc --container-name frontend \
  --image ghcr.io/wenhuaiqing/lotterycorp-data-ai-platform/frontend:<sha>
```

## 6. Afterwards

`terraform destroy`, or `az containerapp delete -g rg-aipapp -n app-tlc`.
Nothing else was created.
