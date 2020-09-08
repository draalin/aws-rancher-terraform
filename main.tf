resource "random_id" "rancher" {
  byte_length = 5
}

resource "aws_security_group" "rancher_elb" {
  name   = "${local.project_name}-rancher-elb"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rancher" {
  name   = "${local.project_name}-rancher-server"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "TCP"
    security_groups = [aws_security_group.rancher_elb.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "TCP"
    security_groups = [aws_security_group.rancher_elb.id]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "rancher-master" {
  count         = local.nodes
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.instance_type
  key_name      = aws_key_pair.ssh.id
  user_data     = data.template_file.cloud_config.rendered

  vpc_security_group_ids      = [aws_security_group.rancher.id]
  subnet_id                   = element(tolist(data.aws_subnet_ids.available.ids), 0)
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = "50"
  }

  tags = {
    Name = "${local.project_name}-master-${count.index}"
  }
}

resource "aws_elb" "rancher" {
  name            = local.project_name
  subnets         = data.aws_subnet_ids.available.ids
  security_groups = [aws_security_group.rancher_elb.id]

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    target              = "tcp:80"
    interval            = 5
  }

  instances    = aws_instance.rancher-master.*.id
  idle_timeout = 1800

  tags = {
    Name = local.project_name
  }
}

resource "aws_route53_record" "rancher" {
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name    = "${local.project_name}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_elb.rancher.dns_name
    zone_id                = aws_elb.rancher.zone_id
    evaluate_target_health = true
  }
}

resource "null_resource" "wait_for_docker" {
  count = local.nodes

  triggers = {
    instance_ids = join(",", concat(aws_instance.rancher-master.*.id))
  }

  provisioner "local-exec" {
    command = <<EOF
while [ "$${RET}" -gt 0 ]; do
    ssh -q -o StrictHostKeyChecking=no -i $${KEY} $${USER}@$${IP} 'docker ps 2>&1 >/dev/null'
    RET=$?
    if [ "$${RET}" -gt 0 ]; then
        sleep 10
    fi
done
EOF

    environment = {
      RET  = "1"
      USER = "ubuntu"
      IP   = element(concat(aws_instance.rancher-master.*.public_ip), count.index)
      KEY  = "${path.root}/outputs/id_rsa"
    }
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  sensitive_content = tls_private_key.ssh.private_key_pem
  filename          = "${path.module}/outputs/id_rsa"

  provisioner "local-exec" {
    command = "chmod 0600 ${path.module}/outputs/id_rsa"
  }
}

resource "local_file" "public_key" {
  content  = tls_private_key.ssh.public_key_openssh
  filename = "${path.module}/outputs/id_rsa.pub"
}

resource "aws_key_pair" "ssh" {
  key_name_prefix = local.project_name
  public_key      = tls_private_key.ssh.public_key_openssh
}

resource "null_resource" "cert-manager-crds" {
  provisioner "local-exec" {
    command = <<EOF
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
kubectl create namespace cattle-system
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.14/deploy/manifests/00-crds.yaml
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
helm repo update
EOF

    environment = {
      KUBECONFIG = local_file.kube_cluster_yaml.filename
    }
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [null_resource.cert-manager-crds]
  version    = "v0.14.2"
  name       = "cert-manager"
  chart      = "jetstack/cert-manager"
  namespace  = "cert-manager"
  set {
    name  = "tf_link"
    value = rke_cluster.rancher_server.api_server_url
  }
}

resource "helm_release" "rancher" {
  name      = "rancher"
  chart     = "rancher-latest/rancher"
  version   = local.rancher_version
  namespace = "cattle-system"
  set {
    name  = "hostname"
    value = "${local.project_name}.${local.domain_name}"
  }

  set {
    name  = "ingress.tls.source"
    value = "letsEncrypt"
  }

  set {
    name  = "letsEncrypt.email"
    value = local.email
  }

  set {
    name  = "letsEncrypt.environment"
    value = "production"
  }

  set {
    name  = "tf_link"
    value = helm_release.cert_manager.name
  }
}

resource "null_resource" "wait_for_rancher" {
  provisioner "local-exec" {
    command = <<EOF
while [ "$${subject}" != "*  subject: CN=$${RANCHER_HOSTNAME}" ]; do
    subject=$(curl -vk -m 2 "https://$${RANCHER_HOSTNAME}/ping" 2>&1 | grep "subject:")
    echo "Cert Subject Response: $${subject}"
    if [ "$${subject}" != "*  subject: CN=$${RANCHER_HOSTNAME}" ]; then
      sleep 10
    fi
done
while [ "$${resp}" != "pong" ]; do
    resp=$(curl -sSk -m 2 "https://$${RANCHER_HOSTNAME}/ping")
    echo "Rancher Response: $${resp}"
    if [ "$${resp}" != "pong" ]; then
      sleep 10
    fi
done
EOF

    environment = {
      RANCHER_HOSTNAME = "${local.project_name}.${local.domain_name}"
      TF_LINK          = helm_release.rancher.name
    }
  }
}

resource "rancher2_bootstrap" "admin" {
  provider   = rancher2.bootstrap
  depends_on = [null_resource.wait_for_rancher]
  password   = var.password
}

resource "rke_cluster" "rancher_server" {
  depends_on = [null_resource.wait_for_docker]

  dynamic nodes {
    for_each = aws_instance.rancher-master
    content {
      address          = nodes.value.public_ip
      internal_address = nodes.value.private_ip
      user             = "ubuntu"
      role             = ["controlplane", "etcd", "worker"]
      ssh_key          = tls_private_key.ssh.private_key_pem
    }
  }

  cluster_name       = "rancher-management"
  addons             = file("${path.module}/files/addons.yaml")
  kubernetes_version = local.kubernetes_version

  services {
    etcd {
      snapshot = true
      backup_config {
        interval_hours = 4
        retention      = 12
      }
    }
  }
}

resource "local_file" "kube_cluster_yaml" {
  filename = "${path.root}/outputs/kube_config_cluster.yml"
  content  = rke_cluster.rancher_server.kube_config_yaml
}
