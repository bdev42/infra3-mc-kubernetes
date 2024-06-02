FROM eclipse-temurin:21-jre-alpine
LABEL author="Boldi Olajos <boldizsar.olajos@student.kdg.be>"
WORKDIR /velocity
COPY velocity*.jar proxy.jar
COPY ./base-config ./
# Set up a user for the proxy server.
RUN addgroup -S velocity && adduser -S velocity -G velocity && chown -R velocity:velocity /velocity
USER velocity

# The files in the base configuration can be overwritten and/or new
# files can be appended by mounting them to the /proxyconfig volume at runtime.
# We therefore want to copy the updated config every time we restart the container.
ENTRYPOINT cp -fr /proxyconfig/. /velocity; ./start.sh
# Officially minecraft wants both udp and tcp protocols to be opened
EXPOSE 25577/tcp
EXPOSE 25577/udp

