FROM ubuntu:22.04
ENV TIMEZONE 'America/Chicago'
RUN apt-get update && apt-get install curl ffmpeg telnet tzdata cron coreutils apt-utils -y
RUN ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime && \
        dpkg-reconfigure --frontend noninteractive tzdata
RUN mkdir /opt/glosbuoys
COPY . /opt/glosbuoys
RUN crontab < /opt/glosbuoys/crontab
WORKDIR .
CMD sleep infinity

