FROM eclipse-temurin:21-jre-alpine
LABEL author="Boldi Olajos <boldizsar.olajos@student.kdg.be>"
WORKDIR /paper
COPY paper*.jar server.jar
COPY ./base-config ./
# Run the server once to download and patch official server jar, 
# it will then stop because the EULA was not yet accepted.
# Then proceed to set up a user for the server.
RUN ./start.sh && addgroup -S paper && adduser -S paper -G paper && chown -R paper:paper /paper
USER paper

# The files in the base configuration can be overwritten and/or new 
# files can be appended by mounting them to the /serverconfig volume at runtime.
# We therefore want to copy the updated config every time we restart the container.
ENTRYPOINT cp -fr /serverconfig/. /paper; ./start.sh
# Officially minecraft wants both udp and tcp protocols to be opened
EXPOSE 25565/tcp
EXPOSE 25565/udp

