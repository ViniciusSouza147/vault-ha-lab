# ─────────────────────────────────────────────
# Data sources: ler recursos das fases anteriores
# ─────────────────────────────────────────────
data "azurerm_resource_group" "lab" {
    name = "rg-vault-ha-lab"
}
data "azurerm_subnet" "aks" {
    name                 = "snet-aks"
    resource_group_name  = data.azurerm_resource_group.lab.name
    virtual_network_name = "vnet-vault-ha-lab"
}

# ─────────────────────────────────────────────
# AKS cluster
# ─────────────────────────────────────────────

resource "azurerm_kubernetes_cluster" "lab" {
    name                = "aks-vault-ha-lab"
    location            = data.azurerm_resource_group.lab.location
    resource_group_name = data.azurerm_resource_group.lab.name
    dns_prefix          = "aks-vault-lab"

    kubernetes_version  = "1.33"

    # --- Identidade do cluster (como o AKS se autentica no Azure) ---
    identity {
        type = "SystemAssigned"
    }
    default_node_pool {
        name                        = "default"
        node_count                  = 1
        vm_size                     = "Standard_b2s_v2"
        vnet_subnet_id              = data.azurerm_subnet.aks.id
        os_disk_size_gb             = 30
        temporary_name_for_rotation = "temppool"
    }

    # --- Rede ---
    network_profile {
        network_plugin = "azure"
        service_cidr   = "10.1.0.0/16"
        dns_service_ip = "10.1.0.10"
    }

    # --- OIDC + Workload Identity (essenciais para Vault auto-unseal) ---
    oidc_issuer_enabled       = true
    workload_identity_enabled = true
    storage_profile {
        snapshot_controller_enabled     = true
        disk_driver_enabled             = true
        file_driver_enabled             = true
        blob_driver_enabled             = false
    }
    tags = {
        environment = "lab"
        project     = "vault-ha-migration"
    }
}

# ─────────────────────────────────────────────
# Service Account
# ─────────────────────────────────────────────
resource "kubernetes_service_account" "snapshot_controller" {
    metadata {
        name      = "snapshot-controller"
        namespace = "kube-system"
    }
}

# ─────────────────────────────────────────────
# ClusterRole
# ─────────────────────────────────────────────

resource "kubernetes_cluster_role" "snapshot_controller" {
    metadata {
        name = "snapshot-controller-role"
    }
    rule {
        api_groups = [""]
        resources  = ["pods"]
        verbs      = ["get ", "list", "watch"]
    }
    rule {
        api_groups = ["snapshot.storage.k8s.io"]
        resources  = [
            "volumesnapshots",
            "volumesnapshotcontents",
            "volumesnapshotclasses"
        ]
        verbs      = ["*"]
    }
}
# ─────────────────────────────────────────────
# ClusterRoleBinding
# ─────────────────────────────────────────────
resource "kubernetes_cluster_role_binding" "snapshot_controller" {
    metadata {
        name = "snapshot-controller-binding"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind      = "ClusterRole"
        name      = kubernetes_cluster_role.snapshot_controller.metadata[0].name
    }
    subject {
        kind      = "ServiceAccount"
        name      = kubernetes_service_account.snapshot_controller.metadata[0].name
        namespace = kubernetes_service_account.snapshot_controller.metadata[0].namespace
    }
}

# ─────────────────────────────────────────────
# Snapshot Controller (ESSENCIAL)
# ─────────────────────────────────────────────

resource "kubernetes_deployment" "snapshot_controller" {
    metadata {
        name      = "snapshot-controller"
        namespace = "kube-system"
        labels = {
            app = "snapshot-controller"
        }
    }

    spec {
        replicas = 1
        selector {
            match_labels = {
                app = "snapshot-controller"
            }
        }
        template {
            metadata {
                labels = {
                    app = "snapshot-controller"
                }
            }
            spec {
                service_account_name = kubernetes_service_account.snapshot_controller.metadata[0].name
                container {
                    name  = "snapshot-controller"
                    image = "registry.k8s.io/sig-storage/snapshot-controller:v6.2.1"
                    args = [
                        "--v=5",
                        "--leader-election=true"
                    ]
                }
            }
        }
    }
    depends_on = [
        azurerm_kubernetes_cluster.lab
    ]
}
