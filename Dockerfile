FROM ubuntu:22.04
ENV TIMEZONE 'America/Chicago'
RUN apt update && apt install curl ffmpeg telnet tzdata -y
RUN ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime && \
        dpkg-reconfigure --frontend noninteractive tzdata
CMD [ "/bin/bash", "-c" ]

