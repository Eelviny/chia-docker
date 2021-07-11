FROM python:3.7

RUN pip install --extra-index-url https://hosted.chia.net/simple/ chia-blockchain==1.2.0 miniupnpc==2.1

RUN chia init

COPY plotter.sh /root/

RUN chia plots add -d /plots

# Replace these two values, see readme
ENV POOL_CONTRACT_ADDRESS=<contract address>
ENV FARMER_PUBLIC_KEY=<public key>

CMD bash /root/plotter.sh
