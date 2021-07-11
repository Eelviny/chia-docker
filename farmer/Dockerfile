FROM python:3.7

RUN pip install --extra-index-url https://hosted.chia.net/simple/ chia-blockchain==1.2.0 miniupnpc==2.1

COPY keyfile farmer.sh /root/

EXPOSE 8444

CMD bash /root/farmer.sh
