# % Last Change: Mon Feb 07 06:43:15 PM 2022 CST
# Base Image
FROM continuumio/miniconda3:4.10.3p1

# File Author / Maintainer
LABEL Author="Tiandao Li <litd99@gmail.com>"

# Install CutRunTools2
RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
    bc \
    jq \
    ghostscript \
    patch && \
    cd /opt && \
    git clone https://github.com/fl-yu/CUT-RUNTools-2.0.git && \
    cd CUT-RUNTools-2.0 && \
    apt-get clean all && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/log/dpkg.log /var/tmp/*

# Installation
RUN conda init bash && \
    . ~/.bashrc && \
    conda update -y -n base conda && \
    conda create -n app python=3.6 && \
    conda activate app && \
    conda install -y -c bioconda bowtie2 && \
    conda install -y tbb=2020.2 && \
    conda install -y -c bioconda samtools=1.12 && \
    conda install -y -c bioconda macs2 && \
    conda install -y -c bioconda bedops && \
    conda install -y -c bioconda bedtools && \
    conda install -y -c bioconda deeptools && \
    conda install -y -c conda-forge parallel && \
    conda install -y -c bioconda tabix && \
    conda install -y -c conda-forge python-igraph && \
    pip install umap-learn leidenalg python3-ghostscript && \
    conda deactivate && \
    # create env for meme since it will conflict with others
    conda create -n meme python=3.6 && \
    conda activate meme && \
    conda install -y -c bioconda -c conda-forge meme=5.0.2 icu=58.2 && \
    pip install python3-ghostscript && \
    conda deactivate

# Install R4.0.4 and R packages
RUN mkdir -p /usr/share/man/man1 && \
    apt-get update --fix-missing && \
    apt-get -y install --no-install-recommends software-properties-common dirmngr gpg-agent r-base && \
    apt-get -y install curl make gcc g++ cmake gfortran libcurl4-openssl-dev libreadline-dev libz-dev libbz2-dev liblzma-dev libpcre3-dev libssl-dev libopenblas-dev default-jre unzip libboost-all-dev libpng-dev libcairo2-dev tabix libxml2-dev && \
    /usr/bin/Rscript /opt/CUT-RUNTools-2.0/install/r-pkgs-install.r && \
    apt-get clean all && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/log/dpkg.log /var/tmp/*

# Install Atactk and kseq
RUN conda init bash && \
    . ~/.bashrc && \
    conda activate app && \
    cd /opt/CUT-RUNTools-2.0/install && \
    cur=`pwd` && \
    mkdir git && \
    cd git && \
    git clone https://github.com/ParkerLab/atactk && \
    cd atactk && \
    git checkout 6cd7de0 && \
    cd .. && \
    pip install ./atactk && \
    cd /opt/conda/envs/app/bin/ && \
    cp $cur/make_cut_matrix.patch . && \
    patch -p0 -N --dry-run --silent make_cut_matrix < make_cut_matrix.patch 2> /dev/null && \
    if [ $? -eq 0 ]; then patch -p0 -N make_cut_matrix < make_cut_matrix.patch; fi && \
    cd /opt/conda/envs/app/lib/python3.6/site-packages/atactk && \
    cp $cur/metrics.py.patch . && \
    patch -p0 -N --dry-run --silent metrics.py < metrics.py.patch 2> /dev/null && \
    if [ $? -eq 0 ]; then patch -p0 -N metrics.py < metrics.py.patch; fi && \
    cd $cur && \
    gcc -O2 kseq_test.c -lz -o kseq_test && \
    conda install -y -c bioconda deeptools=3.5.1 && \
    conda deactivate && \
    chmod +x *.sh && \
    chmod +x *.py && \
    conda clean --yes --all

# set timezone, debian and ubuntu
RUN ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime && \
    echo "America/Chicago" > /etc/timezone

ENV PATH /opt/conda/envs/app/bin:/opt/conda/envs/meme/bin:$PATH

CMD [ "/bin/bash" ]

