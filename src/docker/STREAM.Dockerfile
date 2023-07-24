FROM ubuntu:22.04

COPY sources.list /tmp/sources.list
RUN cat /tmp/sources.list > /etc/apt/sources.list
RUN rm /tmp/sources.list

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y wget bzip2 openssh-server vim proxychains git

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

WORKDIR /root/
COPY proxychains.conf /etc/proxychains.conf
RUN git config --global https.proxy http://127.0.0.1:7888
RUN git config --global https.proxy https://127.0.0.1:7888
RUN git clone https://github.com/xingyaoww/crypto-futures/tree/master
RUN cd crypto-futures/

RUN conda init bash
RUN pip config set global.index-url https://pypi.doubanio.com/simple
RUN conda env create -f environment.yml
RUN source activate /root/miniconda3/envs/crypto

CMD proxychains python3 src/scripts/stream-orderbook.py --output-dir data/collected/
