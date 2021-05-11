FROM python:3.7

RUN pip install --extra-index-url https://hosted.chia.net/simple/ chia-blockchain==1.1.5 miniupnpc==2.1

RUN chia init

COPY keyfile plotter.sh /root/

RUN chia keys add -f /root/keyfile && \
    rm /root/keyfile && \
    chia plots add -d /plots

CMD bash /root/plotter.sh
