FROM debian:buster
ARG DEBIAN_FRONTEND=noninteractive
ENV MINICONDA_VERSION="4.7.12"

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

COPY sources.list /etc/apt/
COPY 99pinning /etc/apt/preferences.d/
RUN apt-get update --fix-missing && apt-get install -y \
    apt-clone \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

############ Clone env

# Obtained with apt-clone clone --with-dpkg-repack godot
COPY godot.apt-clone.tar.gz /tmp/
RUN apt-get update && apt-clone restore godot.apt-clone.tar.gz

# Manually compiled things
#RUN mkdir /opt

# R
# root@godot:/opt/R# tar cvvzf R_compiled.tar.gz R-3.6.3 R-3.6.3_X11
RUN mkdir /opt/R
ADD R_compiled.tar.gz /opt/R/

# bcltools
# root@godot:/opt# tar cvvzf bcftools_comp.tar.gz bcftools/
ADD bcftools_comp.tar.gz /opt/

# bcl2fastq
# root@godot:/opt# tar cvvzf bcl2fastq-2.20.0_comp.tar.gz bcl2fastq-2.20.0
#
ADD bcl2fastq-2.20.0_comp.tar.gz /opt/

# bit and common tools
RUN mkdir /opt/tools
ADD tools.tar.gz /opt/tools/
RUN chmod ugo+x /opt/tools/*

# setup path for everyone
ENV PATH /opt/tools:/opt/bcftools/bin:/opt/R/R-3.6.3_X11/bin:/opt/bcl2fastq-2.20.0/bin/:${PATH}

# user
RUN useradd -rm -d /home/turbo -s /bin/bash -u 1001 turbo && echo "turbo:turb4MENTO!" | chpasswd
#RUN echo "turbo:turbo" | chpasswd

############ RStudio
COPY rstudio-server-1.2.5033-amd64.deb /tmp/
RUN dpkg -i rstudio-server-1.2.5033-amd64.deb
COPY rserver.conf /etc/rstudio/
RUN cd /usr/bin && ln -s /bin/sed sed

############ To setup conda:
#RUN wget -O miniconda.sh https://repo.anaconda.com/miniconda/Miniconda2-${MINICONDA_VERSION}-Linux-x86_64.sh 
#RUN chmod ugo+x miniconda.sh 

#RUN ./miniconda.sh -b -p /opt/conda && \
#    rm miniconda.sh && \
#    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
#    echo ". /opt/conda/etc/profile.d/conda.sh" >> /etc/profile


# Does not find conda binary?
#RUN conda config --add channels bioconda && conda config --add channels conda-forge
#ENV PATH /opt/conda/bin:${PATH} 

# example conda env to be activated by default - I'd produce a docker image for each conda env we need
#RUN conda create -n ${CONDA_ENV_NAME} bcftools=1.9 bedtools=2.27 picard=2.18.15 samtools=1.9 trimmomatic=0.38  ucsc-liftover=357 bwa=0.7.17 fastqc=0.11.7 mosdepth=0.2.3 ensembl-vep=94.5 python=3.7.3

#ENV CONDA_ENV_NAME="whatever"
#ENV PATH "/opt/conda/envs/${CONDA_ENV_NAME}/bin:${PATH}"
#ENV CONDA_DEFAULT_ENV $CONDA_ENV_NAME
#ENV CONDA_PREFIX /opt/conda/envs/$CONDA_ENV_NAME

# parallel was missing, adding here to avoid having to re-build everything. FIXME for efficiency
RUN apt-get install -y parallel

# this is needed to run our pipeline who expect some base directories (such as task/annoations) to be defined in env vars
ENV SNAKE_ROOT="/mnt/trcanmed/snaketree"
USER turbo
WORKDIR /home/turbo
CMD ["/bin/bash"]
