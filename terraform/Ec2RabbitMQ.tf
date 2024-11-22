resource "aws_instance" "Instance_20_7" {
  ami                         = "ami-04b54ebf295fe01d7"
  instance_type               = "t3.micro"
  key_name                    = "pair-key"
  subnet_id                   = aws_subnet.subnet_20_0.id  
  vpc_security_group_ids      = [aws_security_group.sg_80_433_RMQ.id]
  associate_public_ip_address = true
  private_ip                  = "10.10.20.7"
  iam_instance_profile        = "IAM_CERT_ROLE"

  user_data_replace_on_change = true
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Import RabbitMQ signing keys
    rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc'
    rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key'
    rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key'

    # Create Yum repository file for RabbitMQ and Erlang
    cat > /etc/yum.repos.d/rabbitmq.repo << 'EOL'
    ##
    ## Zero dependency Erlang RPM
    ##

    [modern-erlang]
    name=modern-erlang-el9
    baseurl=https://yum1.rabbitmq.com/erlang/el/9/$basearch
            https://yum2.rabbitmq.com/erlang/el/9/$basearch
    repo_gpgcheck=1
    enabled=1
    gpgkey=https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key
    gpgcheck=1
    sslverify=1
    sslcacert=/etc/pki/tls/certs/ca-bundle.crt
    metadata_expire=300
    pkg_gpgcheck=1
    autorefresh=1
    type=rpm-md

    [modern-erlang-noarch]
    name=modern-erlang-el9-noarch
    baseurl=https://yum1.rabbitmq.com/erlang/el/9/noarch
            https://yum2.rabbitmq.com/erlang/el/9/noarch
    repo_gpgcheck=1
    enabled=1
    gpgkey=https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key
           https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc
    gpgcheck=1
    sslverify=1
    sslcacert=/etc/pki/tls/certs/ca-bundle.crt
    metadata_expire=300
    pkg_gpgcheck=1
    autorefresh=1
    type=rpm-md

    [modern-erlang-source]
    name=modern-erlang-el9-source
    baseurl=https://yum1.rabbitmq.com/erlang/el/9/SRPMS
            https://yum2.rabbitmq.com/erlang/el/9/SRPMS
    repo_gpgcheck=1
    enabled=1
    gpgkey=https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key
           https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc
    gpgcheck=1
    sslverify=1
    sslcacert=/etc/pki/tls/certs/ca-bundle.crt
    metadata_expire=300
    pkg_gpgcheck=1
    autorefresh=1

    ##
    ## RabbitMQ Server
    ##

    [rabbitmq-el9]
    name=rabbitmq-el9
    baseurl=https://yum2.rabbitmq.com/rabbitmq/el/9/$basearch
            https://yum1.rabbitmq.com/rabbitmq/el/9/$basearch
    repo_gpgcheck=1
    enabled=1
    gpgkey=https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key
           https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc
    gpgcheck=1
    sslverify=1
    sslcacert=/etc/pki/tls/certs/ca-bundle.crt
    metadata_expire=300
    pkg_gpgcheck=1
    autorefresh=1
    type=rpm-md

    [rabbitmq-el9-noarch]
    name=rabbitmq-el9-noarch
    baseurl=https://yum2.rabbitmq.com/rabbitmq/el/9/noarch
            https://yum1.rabbitmq.com/rabbitmq/el/9/noarch
    repo_gpgcheck=1
    enabled=1
    gpgkey=https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key
           https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc
    gpgcheck=1
    sslverify=1
    sslcacert=/etc/pki/tls/certs/ca-bundle.crt
    metadata_expire=300
    pkg_gpgcheck=1
    autorefresh=1
    type=rpm-md

    [rabbitmq-el9-source]
    name=rabbitmq-el9-source
    baseurl=https://yum2.rabbitmq.com/rabbitmq/el/9/SRPMS
            https://yum1.rabbitmq.com/rabbitmq/el/9/SRPMS
    repo_gpgcheck=1
    enabled=1
    gpgkey=https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key
    gpgcheck=0
    sslverify=1
    sslcacert=/etc/pki/tls/certs/ca-bundle.crt
    metadata_expire=300
    pkg_gpgcheck=1
    autorefresh=1
    type=rpm-md
    EOL

    # Update package metadata
    dnf update -y

    # Install dependencies
    dnf install -y socat logrotate

    # Install Erlang and RabbitMQ
    dnf install -y erlang rabbitmq-server

    # Enable and start RabbitMQ service
    systemctl enable rabbitmq-server
    systemctl start rabbitmq-server

    # Enable RabbitMQ management plugin
    rabbitmq-plugins enable rabbitmq_management

    # Add RabbitAdm user
    rabbitmqctl add_user RabbitAdm "${var.RabbitAdm_pwd}"
    rabbitmqctl set_user_tags RabbitAdm administrator
    rabbitmqctl set_permissions -p / RabbitAdm ".*" ".*" ".*"

    # Optionally: delete guest user
    #rabbitmqctl delete_user guest

    # Add RabbitReader user
    rabbitmqctl add_user RabbitReader "${var.RabbitReader_pwd}" || true
    rabbitmqctl set_permissions -p / RabbitReader "" "" "^my_queue$"

    # Add RabbitWriter user
    rabbitmqctl add_user RabbitWriter "${var.RabbitWriter_pwd}" || true
    rabbitmqctl set_permissions -p / RabbitWriter "^my_queue$|^amq\.default$" "^amq\.default$" ""

    # Install rabbitmqadmin if not installed
    if ! command -v rabbitmqadmin &> /dev/null
    then
        wget http://localhost:15672/cli/rabbitmqadmin
        chmod +x rabbitmqadmin
        mv rabbitmqadmin /usr/local/bin/
    fi

    # Wait for RabbitMQ Management API to be available
    while ! curl -s http://localhost:15672/api/overview > /dev/null; do
        sleep 5
    done

    # Check if my_queue exists and create it if it does not
    QUEUE_EXISTS=$(rabbitmqadmin list queues name | grep "^my_queue$" || true)
    if [ -z "$QUEUE_EXISTS" ]; then
        rabbitmqadmin declare queue name=my_queue durable=true
    fi
  EOF

  provisioner "local-exec" {
    command = "python3 update_hetzner.py"
    environment = {
      HETZNER_DNS_KEY     = var.hetzner_dns_key
      NEW_IP              = self.public_ip
      HETZNER_RECORD_NAME = "rmq"
      HETZNER_DOMAIN_NAME = "pam4.com"
    }
  }
    tags = {
    Name           = "RabbitMQ1"
  }
}
