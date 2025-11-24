# Proxy VM Security Group
resource "scaleway_instance_security_group" "proxy" {
  name                    = "proxy-${var.env_name}"
  description             = "Security group for the egress proxy VM"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
}

# Proxy VM
resource "scaleway_instance_server" "proxy" {
  name              = "proxy-${var.env_name}"
  type              = var.proxy_node_type
  image             = var.proxy_image
  zone              = var.proxy_zone
  ip_ids            = [scaleway_instance_ip.proxy.id]
  security_group_id = scaleway_instance_security_group.proxy.id

  private_network {
    pn_id = var.private_network_id
  }

  tags = ["proxy", "egress", "${var.env_name}"]

  user_data = {
    "cloud-init" = file("${path.module}/cloudinit/proxy.yml")
  }
}

# Flexible IP for the proxy VM
resource "scaleway_instance_ip" "proxy" {
  zone = var.proxy_zone
}

# Proxy VM Security Group Rules
resource "scaleway_instance_security_group_rules" "proxy" {
  security_group_id = scaleway_instance_security_group.proxy.id

  dynamic "inbound_rule" {
    for_each = var.proxy_security_group_rules
    content {
      action   = inbound_rule.value.action
      protocol = inbound_rule.value.protocol
      port     = inbound_rule.value.port
      ip_range = inbound_rule.value.ip_range
    }
  }

  outbound_rule {
    action   = "accept"
    protocol = "ANY"
    port     = 0
  }
}

data "scaleway_instance_private_nic" "private_nic" {
  # private_network_id = var.private_network_id
  server_id = scaleway_instance_server.proxy.id
}
