FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04

COPY sources.list /tmp/sources.list
RUN cat /tmp/sources.list > /etc/apt/sources.list
RUN rm /tmp/sources.list

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y wget bzip2 cmake gcc g++ openssh-server vim zip pigz htop
RUN mkdir /var/run/sshd
COPY sshd_config /etc/ssh/sshd_config
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN curl -s https://install.zerotier.com | bash

# install conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py39_23.1.0-1-Linux-x86_64.sh
RUN bash Miniconda3-py39_23.1.0-1-Linux-x86_64.sh -b
RUN rm Miniconda3-py39_23.1.0-1-Linux-x86_64.sh
ENV PATH /root/miniconda3/bin:$PATH
COPY .condarc /tmp/.condarc
RUN cat /tmp/.condarc > /root/.condarc
RUN rm /tmp/.condarc
RUN conda clean -i
RUN conda config --set remote_connect_timeout_secs 40
RUN conda config --set remote_read_timeout_secs 100

# install jupyterlab

RUN conda install -n base -y jupyterlab ipykernel cmake gcc_linux-64 gxx_linux-64
RUN conda install -n base -y -c conda-forge jupyterlab_widgets ipywidgets
RUN conda install -n base -y pandas numpy numba pyarrow scikit-learn catboost seaborn matplotlib tqdm
RUN conda install -n base -y pip

RUN python -m pip install --upgrade pip
RUN pip config set global.index-url https://mirrors.bfsu.edu.cn/pypi/web/simple
RUN pip install -U --timeout=100 setuptools wheel
RUN pip install -U --timeout=100 torch torchvision torchaudio
RUN pip install -U --timeout=100 tensorflow tensorboard
RUN pip install -U --timeout=100 accelerate transformers datasets diffusers peft
RUN pip install -U --timeout=100 scikit-learn scipy pandarallel optuna hyperopt statsmodels
RUN pip install -U --timeout=100 jupyterlab_execute_time==2.3.1 jupyterlab-tensorboard-pro theme-darcula
RUN pip install -U --timeout=100 plotly rich shap
RUN pip install -U --timeout=100 pymongo peewee diskcache polars
RUN pip install --timeout=100 lightgbm --config-settings=cmake.define.USE_CUDA=ON
RUN conda init

# add ubuntu alias
RUN alias ll='ls -l'

# set timezone to Asia/Shanghai
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
RUN echo "6\n70" | dpkg-reconfigure -f noninteractive tzdata

# configure jupyterlab
RUN jupyter notebook --generate-config && \
    echo "c.NotebookApp.terminado_settings = {'shell_command': ['/bin/bash']}" >> /root/.jupyter/jupyter_notebook_config.py

