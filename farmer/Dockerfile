FROM python:3.7

RUN pip install --extra-index-url https://hosted.chia.net/simple/ chia-blockchain==1.2.5 miniupnpc==2.1

RUN useradd -ms /bin/bash chia
USER chia
WORKDIR /home/chia
RUN mkdir .chia/

COPY keyfile farmer.sh .

EXPOSE 8444

CMD bash farmer.sh
