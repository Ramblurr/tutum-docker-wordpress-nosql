FROM tutum/apache-php:latest
MAINTAINER Borja Burgos <borja@tutum.co>, Feng Honglin <hfeng@tutum.co>

ENV WORDPRESS_VER latest
WORKDIR /
RUN apt-get update && \
    apt-get -yq install mysql-client curl && \
    rm -rf /app && \
    curl -0L https://wordpress.org/latest.tar.gz | tar zxv && \
    mv /wordpress /app && \
    rm -rf /var/lib/apt/lists/* \
    a2enmod rewrite

ADD wp-config.php /app/wp-config.php
ADD run_wordpress.sh /run_wordpress.sh
RUN chmod +x /*.sh

# Expose environment variables
ENV DB_HOST **LinkMe**
ENV DB_PORT **LinkMe**
ENV DATA_DB_NAME **LinkMe**
ENV DATA_DB_USER **LinkMe**
ENV DATA_DB_PASS **LinkMe**

EXPOSE 80
VOLUME ["/app/wp-content"]
CMD ["/run_wordpress.sh"]
