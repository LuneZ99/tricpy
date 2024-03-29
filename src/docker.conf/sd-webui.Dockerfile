FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

COPY CorgiLab/.condarc /tmp/.condarc
COPY proxychains.conf /etc/proxychains.conf
COPY CorgiLab/sources.list /tmp/sources.list
RUN cat /tmp/sources.list > /etc/apt/sources.list && rm /tmp/sources.list

RUN apt-get update && apt-get install -y wget openssh-server vim pigz sudo git python3 python3-venv proxychains4 libgl1 libglib2.0-0

# set timezone to Asia/Shanghai
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && echo "6\n70" | dpkg-reconfigure -f noninteractive tzdata

# 配置 SSH
RUN mkdir /var/run/sshd
RUN echo 'root:webui' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN echo 'PermitEmptyPasswords no' >> /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 4222/' /etc/ssh/sshd_config

# 创建新用户 webui，设置密码为 webui
RUN useradd -m -d /home/webui -s /bin/bash webui
RUN echo 'webui:webui' | chpasswd
RUN usermod -aG sudo webui
RUN echo "webui ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 暴露 SSH 端口
EXPOSE 4222

# 启动 SSH 服务
# CMD ["/usr/sbin/sshd", "-D"]