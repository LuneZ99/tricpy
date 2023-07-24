FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04

COPY sources.list /tmp/sources.list
RUN cat /tmp/sources.list > /etc/apt/sources.list
RUN rm /tmp/sources.list

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y wget bzip2 cmake gcc g++ openssh-server vim zip
RUN mkdir /var/run/sshd
COPY sshd_config /etc/ssh/sshd_config
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

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
RUN pip config set global.index-url https://pypi.doubanio.com/simple
RUN pip install -U jqdatasdk httplib2 setuptools wheel
RUN pip install -U --timeout=100 torch torchvision torchaudio
RUN pip install -U --timeout=100 tensorflow tensorboard
RUN pip install -U --timeout=100 scikit-learn scipy pandarallel optuna shap hyperopt statsmodels
RUN pip install -U --timeout=100 viztracer chinese_calendar autogluon.eda
RUN pip install -U --timeout=100 rich jupyterlab_execute_time jupyterlab-tensorboard-pro theme-darcula
RUN pip install -U --timeout=100 langchain openai faiss-cpu transformers jieba onnx
RUN pip install -U --timeout=100 plotly rich shap jupyterlab_execute_time viztracer streamlit streamlit_chat gradio
RUN pip install -U --timeout=100 pymongo peewee qdrant-client diskcache

RUN apt-get install -y --no-install-recommends \
    build-essential curl bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 git vim mercurial \
    subversion cmake libboost-dev libboost-system-dev libboost-filesystem-dev gcc g++
COPY LightGBM/ /tmp/LightGBM
RUN source deactivate && conda activate base && cd /tmp/LightGBM/ && mkdir build && \
    cmake -DUSE_GPU=1 -DOpenCL_LIBRARY=/usr/local/cuda/lib64/libOpenCL.so -DOpenCL_INCLUDE_DIR=/usr/local/cuda/include/ &&  \
    make OPENCL_HEADERS=/usr/local/cuda-11.7/targets/x86_64-linux/include LIBOPENCL=/usr/local/cuda-11.7/targets/x86_64-linux/lib &&  \
    cd python-package && pip install .
RUN mv /root/miniconda3/lib/libstdc++.so.6 /root/miniconda3/lib/libstdc++.so.6.bak && \
    ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /root/miniconda3/lib/libstdc++.so.6
RUN mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd
RUN rm -rf /tmp/LightGBM

#  install lightgbm-cuda
RUN conda init bash
RUN conda create -n lgbm_cuda python=3.9
RUN source activate /root/miniconda3/envs/lgbm_cuda
RUN conda install -n lgbm_cuda -y jupyterlab ipykernel cmake gcc_linux-64 gxx_linux-64
RUN conda install -n lgbm_cuda -y -c conda-forge jupyterlab_widgets ipywidgets
RUN conda install -n lgbm_cuda -y pandas numpy numba pyarrow scikit-learn catboost seaborn matplotlib tqdm
RUN conda install -n lgbm_cuda -y pip

RUN source deactivate && conda activate lgbm_cuda
RUN python -m pip install --upgrade pip
RUN pip config set global.index-url https://pypi.doubanio.com/simple
RUN pip install -U jqdatasdk httplib2 setuptools wheel
RUN pip install -U --timeout=100 torch torchvision torchaudio
RUN pip install -U --timeout=100 tensorflow tensorboard
RUN pip install -U --timeout=100 scikit-learn scipy pandarallel optuna shap hyperopt statsmodels
RUN pip install -U --timeout=100 chinese_calendar autogluon.eda
RUN pip install -U --timeout=100 plotly==5.13.1 rich jupyterlab_execute_time
RUN pip install -U --timeout=100 jupyterlab-tensorboard-pro theme-darcula

COPY LightGBM/ /tmp/LightGBM
#RUN mkdir /usr/local/src/lightgbm
#RUN cp -r /tmp/LightGBM /usr/local/src/lightgbm/
RUN source deactivate && conda activate lgbm_cuda && cd /tmp/LightGBM/ && mkdir build && \
    cmake -DUSE_CUDA=1 && make && cd python-package && pip install .

RUN source deactivate && conda activate lgbm_cuda && python -m ipykernel install --user --name lgbm_cuda --display-name lgbm_cuda

# create C++ env
RUN conda init bash
RUN conda create -n cpp
RUN source activate /root/miniconda3/envs/cpp
RUN conda install -n cpp -y xeus-cling -c conda-forge
RUN jupyter kernelspec install /root/miniconda3/envs/cpp/share/jupyter/kernels/xcpp11
RUN jupyter kernelspec install /root/miniconda3/envs/cpp/share/jupyter/kernels/xcpp14
RUN jupyter kernelspec install /root/miniconda3/envs/cpp/share/jupyter/kernels/xcpp17

# add ubuntu alias
RUN alias ll='ls -l'

# set timezone to Asia/Shanghai
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
RUN echo "6\n70" | dpkg-reconfigure -f noninteractive tzdata


# configure jupyterlab
RUN jupyter notebook --generate-config && \
    echo "c.NotebookApp.terminado_settings = {'shell_command': ['/bin/bash']}" >> /root/.jupyter/jupyter_notebook_config.py

