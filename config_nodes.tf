# docker host

data "cloudinit_config" "docker_host" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.local_file.ssm_agent.content
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.local_file.web_server.content
  }

}

# script that installs ssm agent

data "local_file" "ssm_agent" {
  filename = "${path.module}/scripts/ssm-agent-install.sh"
}

data "local_file" "web_server" {
  filename = "${path.module}/scripts/web-server-install.sh"
}
